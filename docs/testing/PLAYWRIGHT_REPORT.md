# VAGUS Web — Playwright Test Report

## Run summary
- Date: 2026-04-27
- Flutter build: release web (built in 53.5s)
- Tests run: 8
- Passed: 8
- Failed: 0
- Total runtime: 31.6s
- Browser: Chromium headless (Playwright 1217 / Chrome 147)
- Server: `python3 -m http.server 8080 --directory build/web`

## Test results
| # | Test | Result | Duration | Notes |
|---|------|--------|----------|-------|
| 01 | App loads and splash screen renders | PASS | 4.5s | body innerHTML > 100 chars |
| 02 | Auth screen renders (login or signup) | PASS | 5.3s | Page title: `VAGUS` |
| 03 | No JavaScript console errors on load | PASS | 5.2s | 1 console error captured (text: "Error" — unhelpful) |
| 04 | App is mobile-sized (390x844) and not broken layout | PASS | 4.3s | Clean single-column login form |
| 05 | App renders on tablet viewport (768x1024) | PASS | 4.5s | Two-column landing + login layout |
| 06 | Performance: page load under 10 seconds | PASS | 666ms | Load time: 516ms (networkidle) |
| 07 | No broken images or assets | PASS | 5.2s | 0 failed requests |
| 08 | App bundle size is reasonable | PASS | 669ms | Measurement caveat below |

## Console errors found
- Captured 1 console error during test 03. The error message text was just `"Error"` — the JS error did not surface a useful message string through Playwright's `console`/`pageerror` events. Worth re-running with `msg.location()` and `err.stack` logged to identify it.

## Failed asset requests
- None. `requestfailed` count = 0.

## Performance
- Page load (networkidle): **516 ms** in test 06 (well under the 10s budget).
- The 4–5s waits in tests 01/02/04/05/07 are `waitForTimeout` floors I deliberately added for screenshot stability, not actual app load times.
- Bundle size on disk: **33 MB total** for `build/web/`, with `main.dart.js` at **8.9 MB** uncompressed.
- Test 08 reported `0.01 MB transferred` — this is **incorrect**. Python's `http.server` does not emit `Content-Length` on most responses (it streams), so the listener's `parseInt(headers['content-length'] || '0')` totalled to ~0. Trust the on-disk number (33 MB) instead, or re-run behind a server that sets content-length (`npx http-server` or nginx).

## Screenshots created
All under `testing/playwright/test-results/screenshots/`:
- `01-splash.png` — mobile splash with VAGUS logo, "Welcome to VAGUS — Your Personal Fitness & Nutrition Coach", and a loading spinner
- `02-auth.png` — mobile login form rendered after splash
- `03-console-check.png` — same auth view, captured during error listener test
- `04-mobile-layout.png` — full-page mobile (390x844) login screen
- `05-tablet-layout.png` — full-page tablet (768x1024) two-column landing + login
- `06-performance.png` — auth view captured after networkidle
- `07-assets.png` — auth view captured during request-failure listener
- `08-bundle.png` — auth view captured during bundle-size listener

Playwright also emitted automatic `test-finished-1.png` snapshots into per-test folders under `test-results/`.

## Issues for Claude to review
1. **Generic console error** — test 03 caught an error whose printed text is literally `"Error"`. Improve the listener to capture `msg.location()`, `msg.args()`, and `err.stack` so we can name it. This is the single most actionable finding from the run.
2. **Bundle size measurement is broken under `python3 -m http.server`** — swap to a server that sets `Content-Length` (e.g. `npx http-server -p 8080 build/web`) or measure transferred bytes via `await res.body()` length.
3. **`main.dart.js` is 8.9 MB uncompressed.** Consider running with `--source-maps` separated and gzip/brotli at the edge in production. For Flutter web this is typical but worth tracking.
4. **All splash screenshots show the loading spinner**, not a fully-rendered post-splash state — the 3–5 s `waitForTimeout` is enough to bypass splash on the auth route but not on `/`. Tests 01–03 capture the splash; tests 04–08 (which navigate after a viewport change) catch the post-splash login UI.
5. **No real interaction tested.** This suite confirms the app boots, doesn't error visibly, and renders responsive layouts — but nothing actually clicks the LOG IN button, fills the form, or routes anywhere. Next step: a happy-path login test against a seeded test account.
6. **Layout is responsive and clean** at 390x844 (mobile single-column) and 768x1024 (tablet two-column with marketing copy on the left, form on the right). No visible overflow, clipping, or font issues in the screenshots.

## Raw Playwright output
```
Running 8 tests using 1 worker

  ✓  1 tests\vagus_smoke.spec.js:5:3 › VAGUS Web Smoke Tests › 01 - App loads and splash screen renders (4.5s)
Page title: VAGUS
  ✓  2 tests\vagus_smoke.spec.js:17:3 › VAGUS Web Smoke Tests › 02 - Auth screen renders (login or signup) (5.3s)
Console errors found: 1
 - Error
  ✓  3 tests\vagus_smoke.spec.js:29:3 › VAGUS Web Smoke Tests › 03 - No JavaScript console errors on load (5.2s)
  ✓  4 tests\vagus_smoke.spec.js:45:3 › VAGUS Web Smoke Tests › 04 - App is mobile-sized and not broken layout (4.3s)
  ✓  5 tests\vagus_smoke.spec.js:55:3 › VAGUS Web Smoke Tests › 05 - App renders on tablet viewport (4.5s)
Load time: 516ms
  ✓  6 tests\vagus_smoke.spec.js:65:3 › VAGUS Web Smoke Tests › 06 - Performance: page load under 10 seconds (666ms)
Failed asset requests: 0
  ✓  7 tests\vagus_smoke.spec.js:77:3 › VAGUS Web Smoke Tests › 07 - No broken images or assets (5.2s)
Total transferred: 0.01 MB
  ✓  8 tests\vagus_smoke.spec.js:89:3 › VAGUS Web Smoke Tests › 08 - App bundle size is reasonable (669ms)

  8 passed (31.6s)
```
