# VAGUS Web — Post-Fix Validation Report

Date: 2026-04-27
Branch: 21-1-2026-mr-universe
Build: `flutter build web --source-maps` (succeeded, 49.3s, main.dart.js = 8.32 MB)

## Changes made

1. **Startup crash fix** — wrapped non-web plugin initializations in `kIsWeb` guards.
   - File changed: `lib/main.dart`
   - What was missing: `if (!kIsWeb)` guards around two platform-channel initializations:
     - `await NotificationHelper.instance.init()` — uses `flutter_local_notifications` (no web impl)
     - `DeepLinkService().initialize(context)` (postFrameCallback) and `dispose()` — uses `app_links` (no/limited web impl)
   - Added global error handlers so future failures show real messages:
     - `FlutterError.onError` — surfaces framework errors with full stack
     - `PlatformDispatcher.instance.onError` — catches unhandled async/zone errors
   - Also added missing imports: `dart:ui`, `package:flutter/foundation.dart`, `package:flutter/semantics.dart`.

2. **Semantics enabled** — added `if (kIsWeb) SemanticsBinding.instance.ensureSemantics();` immediately after `WidgetsFlutterBinding.ensureInitialized()` in `main()`.

3. **Bundle audit** — see `docs/testing/bundle-audit.txt`. No changes made; documented findings only:
   - Total assets: 2.2 MB (dominated by 1.9 MB `exercise_knowledge_seed_en.json`)
   - Zero deferred-loading splits (largest single optimization opportunity)
   - No `dart:mirrors` / reflectable, so dart2js can fully tree-shake
   - Heavy stack: 3 PDF libs (`pdf` + `printing` + `pdfx`), 2 animation engines (`rive` + `lottie`), Supabase, InAppWebView, mobile_scanner, fl_chart, video_player, just_audio, google_generative_ai

4. **Test suite** — added http-server SPA webServer to `playwright.config.js` (using `--proxy http://localhost:8080?` SPA-fallback flag). Added new spec `tests/vagus_post_fix.spec.js` with PF01–PF05.

## Test results — `testing/playwright/test-results/post-fix-output.txt`

```
3 passed, 2 failed (27.5s)
  ✘  PF01 - No startup console errors
  ✓  PF02 - Semantics tree is populated
  ✓  PF03 - Can find interactive elements by label
  ✘  PF04 - SPA routing works (dashboard route)
  ✓  PF05 - Feature flags: calling button hidden
```

## PF01 — Startup errors after fix

Full content of `testing/playwright/test-results/post-fix-errors.json`:

```json
[
  {
    "text": "Error",
    "stack": "Error\n    at Object.n (http://localhost:8080/main.dart.js:3864:20)\n    at http://localhost:8080/main.dart.js:127578:15\n    at cJl.a (http://localhost:8080/main.dart.js:5226:63)\n    at cJl.$2 (http://localhost:8080/main.dart.js:74420:14)\n    at cI3.$1 (http://localhost:8080/main.dart.js:74414:21)\n    at aOl.a9r (http://localhost:8080/main.dart.js:75656:34)\n    at c3x.$0 (http://localhost:8080/main.dart.js:74892:11)\n    at Object.Nd (http://localhost:8080/main.dart.js:5372:40)\n    at b2.BP (http://localhost:8080/main.dart.js:74798:3)\n    at c3p.$0 (http://localhost:8080/main.dart.js:74855:13)"
  }
]
```

Was the original error resolved? **CHANGED.** Error count dropped from many to **1**. The remaining error has the same top frame as the original (`main.dart.js:3864`), which means the kIsWeb guards on `NotificationHelper` and `DeepLinkService` did not eliminate the underlying source — there is a third platform-channel call still firing on cold load.

Notable: the error is captured as a `pageerror` event (not a console.error), with `text: "Error"` and no message body. This means it is being thrown raw at the JS layer **before** our `FlutterError.onError` / `PlatformDispatcher.instance.onError` handlers have a chance to format it. The stack is now available with source-maps enabled, so a future agent can run `flutter symbolize` or open `main.dart.js.map` against frames `cI3.$1`, `aOl.a9r`, `c3x.$0`, `c3p.$0` to identify the culprit.

Per task rules, I did not attempt further fixes here.

## PF02 — Semantics tree

`flt-semantics` count: **17**
Resolved: **YES.** The semantics tree is populated. Pre-fix the count was 0.

## PF03 — Accessible buttons found

3 elements matched `flt-semantics[role="button"]`. All three returned `null` for `aria-label`, suggesting they're splash-screen interactive elements without explicit semantic labels. Real screens are not yet rendered at the t+6s checkpoint (the splash screen takes longer than 6s, or the AuthGate is gated on the still-pending startup error). PF03 still **passes** the assertion (count > 0).

```
Button [0]: null
Button [1]: null
Button [2]: null
```

## PF04 — SPA routing

`/dashboard` status: **404**. PF04 **fails**.

The `npx http-server ... --proxy http://localhost:8080?` flag did not perform SPA fallback as expected with http-server v14.1.1; the server returned a 404 page (title "Error response") instead of `index.html`. This is a test-infrastructure issue, not an app issue — Flutter's hash-routing strategy on web means the actual app uses `/#/dashboard` style URLs anyway, so production routing is unaffected. A future fix could swap to `serve -s` or a tiny custom node SPA server.

## PF05 — Feature flags

Calling buttons visible: **0** (expected 0). **PASS** — calling/video features are correctly gated off by feature flags.

## Remaining issues

1. **One unresolved startup exception** (PF01). Top frame `main.dart.js:3864` survived the `flutter_local_notifications` and `app_links` guards. Likely candidates not yet ruled out: `local_auth`, `permission_handler`, `device_info_plus`, `health`, `flutter_inappwebview`, or something inside `Supabase.initialize` (e.g. its realtime channel bootstrap on a cold session). Need to symbolize against the new source-maps to identify it.
2. **PF04 SPA routing** — http-server v14.1.1 `--proxy ?` syntax did not fall back as configured. Test-infra-only, not a product bug.
3. **PF03 button labels are null.** Real semantics labels won't appear until the auth/dashboard screens render. Either bump the wait beyond 6s in PF03 or anchor the test to a known-rendered screen.

## Recommended next step for Claude

Symbolize the PF01 stack: run `flutter symbolize -i build/web/main.dart.js.map` against frames `cI3.$1` / `aOl.a9r` / `c3p.$0` to identify the third unguarded platform-channel call, then add a `kIsWeb` guard around it.
