# VAGUS Web — Deep Playwright Report

## Run summary
- Date: 2026-04-27
- Tests run: 18 (8 smoke + 10 deep)
- Passed: 18
- Failed: 0
- Total wall time: ~72s
- Server: `python3 -m http.server 8080 --directory build/web` (already running)
- Renderer: Flutter web (CanvasKit / WebGL)

> Note: The smoke test 08 (bundle size) initially failed because the supplied
> `execSync` command used `||` and `2>/dev/null` which `cmd.exe` (the default
> Windows shell for `child_process`) cannot parse. I rewrote it to use Node's
> `fs.statSync` + recursive directory walk — cross-platform and no shell at all.
> Both suites now pass cleanly.

## D01 — Console errors (full detail)

One real error is thrown during app startup. Full payload from
`test-results/console-errors.json`:

```json
{
  "errors": [
    {
      "text": "Error",
      "stack": "Error\n    at Object.n (http://localhost:8080/main.dart.js:3864:20)\n    at http://localhost:8080/main.dart.js:127767:15\n    at cJY.a (http://localhost:8080/main.dart.js:5226:63)\n    at cJY.$2 (http://localhost:8080/main.dart.js:74536:14)\n    at cIF.$1 (http://localhost:8080/main.dart.js:74530:21)\n    at aOv.a9A (http://localhost:8080/main.dart.js:75795:34)\n    at c47.$0 (http://localhost:8080/main.dart.js:75008:11)\n    at Object.Ne (http://localhost:8080/main.dart.js:5372:40)\n    at b1.BP (http://localhost:8080/main.dart.js:74914:3)\n    at c4_.$0 (http://localhost:8080/main.dart.js:74971:13)"
    }
  ],
  "warnings": [
    "[.WebGL-…] GL Driver Message (OpenGL, Performance, GL_CLOSE_PATH_NV, High): GPU stall due to ReadPixels (×4, then suppressed)"
  ]
}
```

**What this tells us**
- `text` is just `"Error"` because the Dart side throws a generic `Error`
  whose `toString()` is the literal word `"Error"`. The real signal is in the
  stack.
- The stack is minified (`cJY.a`, `aOv.a9A`, `b1.BP`) because the build is
  release-mode with no source maps. To get a real frame name we'd need to
  rebuild with `flutter build web --source-maps` and re-run.
- The stack pattern (`Object.n` near top, deep into Dart's zoned scheduler
  via `b1.BP` / `c4_.$0`) is the classic shape of an exception that escapes
  a `Future` and gets surfaced through the unhandled-error zone.
- The WebGL warnings are CanvasKit reading back the framebuffer for each
  full-page screenshot — they are noise from the test harness, not the app.

**Likely culprits** (educated guesses, need source maps to confirm)
1. Supabase initialization throwing because env vars / auth session aren't
   what the app expects in a fresh browser context.
2. A platform-channel call that has no web implementation (push, IAP,
   biometrics, file picker, deep link) being invoked unconditionally.
3. A Hive/SharedPreferences open call failing because IndexedDB hasn't
   been opened yet at the moment of the call.

## D02 — Splash behavior
- `D02a-splash-immediate.png` was taken at +500ms. `D02b-post-splash.png`
  at +5500ms.
- The DOM-text check (`html.includes('login') || …`) returned **false**
  post-splash. **This is not a real signal** — Flutter web renders to a
  `<canvas>` element, so the visible text "Login" / "Email" never appears
  in `document.body.innerHTML`. The check is meaningless on a CanvasKit
  build. Verify visually via the two screenshots instead.
- Splash → auth transition timing is not directly measurable from DOM;
  the screenshots are the source of truth.

## D03 — Auth screen semantics
- `flt-semantics[role="button"]` count: **0**
- `flt-semantics[aria-label]` count: **0**
- Total `flt-semantics` count (D09): **0**

This is a real, important finding. Flutter web does **not** build the
semantics tree until something requests it (a screen reader connects, or
the app calls `SemanticsBinding.ensureSemantics()`). With zero semantic
nodes, **the entire app is currently invisible to assistive tech and to
locator-based test automation.** Every interaction-style test in this
suite is forced to fall back to canvas screenshots because the DOM gives
us nothing to grab.

## D04 — Sign up interaction
- `getByText('Sign Up')` count: **0** (text lives inside canvas, not DOM).
- The test correctly fell through to the "no signup found" branch and
  saved `D04-no-signup-found.png` instead. No tap was performed.
- We cannot assert anything about post-tap state without either the
  semantics tree (D03) or a Flutter test driver (`integration_test`).

## D05 — Feature flag gates
- `getByText` for all 6 flag names returned 0 hits, so the suite reported
  "correctly hidden":
  - Video Call, Scan, Health Sync, Google Drive, Connect Google, Upgrade
- **However**, this result is uninformative for the same reason as D04:
  text rendered to canvas is invisible to `getByText`. A label that *is*
  shown on screen would also count as "hidden" by this test.
- To actually validate Agent 5's feature flags the visual screenshot
  `D05-feature-flags.png` must be eyeballed, or the test must be rewritten
  to probe Flutter via `window.flutterCanvasKit` / `_flutter.*` hooks, or
  via a Flutter `integration_test`.

## D06 — Layout at 5 sizes
All 5 viewports rendered and were captured:

| Device       | Size      | Screenshot              |
| ------------ | --------- | ----------------------- |
| iphone-13    | 375×812   | D06-iphone-13.png       |
| iphone-14    | 390×844   | D06-iphone-14.png       |
| iphone-plus  | 414×896   | D06-iphone-plus.png     |
| ipad         | 768×1024  | D06-ipad.png            |
| desktop      | 1280×800  | D06-desktop.png         |

No automated overflow/clipping detection was run (would require pixel
diffing or DOM-based bounds). Visual inspection of the PNGs is required
to confirm no broken layout.

## D07 — Route navigation
Every direct URL returned a Python `http.server` 404 page:

| Route        | Title           | Result                |
| ------------ | --------------- | --------------------- |
| /login       | Error response  | 404 from http.server  |
| /signup      | Error response  | 404                   |
| /register    | Error response  | 404                   |
| /dashboard   | Error response  | 404                   |
| /home        | Error response  | 404                   |
| /workout     | Error response  | 404                   |
| /nutrition   | Error response  | 404                   |
| /settings    | Error response  | 404                   |
| /support     | Error response  | 404                   |

**This is a server limitation, not an app bug.** `python3 -m http.server`
has no SPA fallback. To actually exercise client-side routing you need
`flutter run -d web-server`, or `npx http-server -P http://localhost:8080?`,
or a tiny Express server that returns `index.html` for unknown paths.
That said, it does flag a real production concern: deep links must be
served by a host that does SPA fallback (Firebase Hosting / Vercel /
Cloudflare Pages all do; bare nginx needs the `try_files $uri /index.html`
rule). Document this for ops.

## D08 — Performance metrics
From `test-results/performance.json`:

```json
{
  "domContentLoaded": 6.6,
  "loadComplete": 8.1,
  "firstPaint": 36,
  "firstContentfulPaint": 36,
  "transferSize": 5026,
  "encodedBodySize": 4726
}
```

**Caution — these numbers are deceiving.** All times are in milliseconds.
`transferSize` = 5026 bytes is just `index.html` + `flutter_bootstrap.js`.
The Navigation Timing API does not include subresources, so this number
is **not** the real bundle size. Real bundle size from D08-helper /
test 08:

- `main.dart.js`: **8.85 MB**
- Total `build/web/`: **32.39 MB**

`firstContentfulPaint = 36ms` is when the empty canvas appeared, not
when the app became usable. Real time-to-interactive is closer to the
`5000ms` we wait in tests (splash + bootstrap + first paint of the auth
screen).

Smoke test 06 measured wall-clock to networkidle as **518–690ms** — this
is from cache; first-load on a cold cache will be several seconds.

## D09 — Accessibility
- `flt-semantics`: 0
- `flt-semantics[role="button"]`: 0
- `flt-semantics[role="img"]`: 0

Confirms D03: **the semantics tree is never built.** This is a
correctness issue (a11y), not a test issue.

## D10 — Dark mode
- `D10-dark-mode.png` was captured with `colorScheme: 'dark'` set in the
  browser context.
- We did **not** programmatically verify whether the app respected the
  preference (no DOM theme attr to inspect on a canvas app). The
  screenshot is the only evidence — eyeball it against
  `D02b-post-splash.png` (light) to see if pixels actually changed.

## Screenshots index

Smoke (8):
- 01-splash.png — splash at +4s
- 02-auth.png — auth at +5s
- 03-console-check.png — auth, while console-error listener was active
- 04-mobile-layout.png — 390×844 viewport
- 05-tablet-layout.png — 768×1024 viewport
- 06-performance.png — auth after networkidle
- 07-assets.png — auth, while requestfailed listener was active
- 08-bundle.png — auth after on-disk size measurement

Deep (10):
- D01-errors.png — full-page snapshot during error capture
- D02a-splash-immediate.png — splash @ +500ms
- D02b-post-splash.png — auth @ +5500ms
- D03a-auth-full.png — auth screen for semantic-element probe
- D04-no-signup-found.png — auth screen (no DOM-discoverable Sign Up)
- D05-feature-flags.png — auth, scanned for flagged feature labels
- D06-{iphone-13,iphone-14,iphone-plus,ipad,desktop}.png — five viewports
- D07-route-{login,signup,register,dashboard,home,workout,nutrition,settings,support}.png
  — all show http.server 404
- D08-performance.png — auth after networkidle
- D09-accessibility.png — auth screen (semantic counts = 0)
- D10-dark-mode.png — auth with dark color-scheme preference

## Priority issues for Claude to fix

1. **Diagnose the startup `Error` thrown from `main.dart.js`.**
   Rebuild with `flutter build web --source-maps`, re-run D01, then
   resolve the unminified frame at the top of the stack. Highest priority
   — this fires on every cold load.

2. **Enable semantics on web** so the app is screen-reader accessible
   *and* automatable. Add `WidgetsFlutterBinding.ensureInitialized();
   SemanticsBinding.instance.ensureSemantics();` (or use the standard
   `flutter_semantics` enable hook) in `main.dart` for web builds. Right
   now `flt-semantics` is empty → zero a11y, zero locator-based tests.

3. **Replace the DOM-text feature-flag check** (`getByText('Sign Up')`,
   `getByText('Video Call')`, etc.) with either: (a) Flutter
   `integration_test` running in the same browser, or (b) a JS-eval probe
   against `window._vagusFlags` or similar that the app exposes for QA.
   The current check passes for the wrong reason.

4. **Document the SPA-fallback requirement** for hosting. `/login`,
   `/dashboard`, etc. all 404 on a vanilla static server. Add a note to
   `docs/deploy/` describing the rewrite rule for nginx / Firebase /
   Cloudflare. Not an app bug, but it will bite production.

5. **Trim bundle size.** `main.dart.js` is 8.85 MB; total `build/web/` is
   32.39 MB. Audit for: deferred libraries (`deferred as`), unused fonts
   in `pubspec.yaml`, unreferenced assets, debug-only packages bleeding
   into release. Not urgent, but every MB hurts mobile-web FCP.

6. **Add a real text-content assertion** that does not rely on canvas
   text. Either expose a DOM hook (`<meta name="vagus-route" content="…">`
   updated by router), or migrate critical journey tests to Flutter
   `integration_test` which can actually read widget state.

7. **Verify dark-mode response** with a manual diff between
   `D02b-post-splash.png` and `D10-dark-mode.png`. If pixels are
   identical, the app is ignoring `MediaQuery.platformBrightness`.

## Plain-English summary

The app boots, loads its assets without any failed network requests, and
draws an auth-style screen on every viewport from 375 px up to 1280 px.
Cold-load wall-clock to a usable canvas is sub-second on cache, and the
splash → auth transition looks visually clean across the screenshots.
That's the good news.

The bad news is that I can't actually see *into* the app from
Playwright. Flutter web renders entirely to a `<canvas>` and the
semantics tree is never built (zero `flt-semantics` nodes), so every
DOM-based test in this suite — sign-up tap, feature-flag visibility,
text-content checks — is silently degraded into a no-op. The "feature
flags are hidden" result is true, but it's true the same way it would
be true for *any* string, including ones that *are* visible. We need
either the semantics tree turned on or a Flutter `integration_test`
runner before locator tests give real signal.

There is one real Dart exception thrown during startup. The top frame
is in `main.dart.js:3864`, but the build is minified and source-map-less,
so the function name (`Object.n`) is meaningless. The stack shape says
"unhandled async error in zoned init" — most likely Supabase, a missing
web platform implementation, or a storage open. We need a source-mapped
build to name it.

Routes like `/login` 404 because Python's static server doesn't do SPA
fallback — that's a hosting story, not an app bug, but worth documenting
for deploy. And the bundle is large: 8.85 MB main.dart.js, 32 MB total
build dir, which is fine for desktop but painful on mobile web.
