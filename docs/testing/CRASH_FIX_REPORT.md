# VAGUS — Startup Crash Fix Report (Round 2)

## Symbolized stack

`flutter symbolize --debug-info=build/web/main.dart.js.map` failed with
"Failed to decode symbols file for loading unit 1" — that tool expects
AOT debug-info bundles, not JS source maps. Decoded the source map
directly via Node + VLQ to recover the Dart frames:

| JS frame | Dart symbol |
|---|---|
| `main.dart.js:3864:20` (`Object.n`) | `wrapException` (js_helper.dart:1353) — Dart "throw" wrapper |
| `main.dart.js:127578:15` | **`MethodChannel._invokeMethod`** (services/platform_channel.dart:368) |
| `main.dart.js:5226` (`cJl.a`) | `_wrapJsFunctionForAsync` (async_patch.dart:339) |
| `main.dart.js:74420` (`cJl.$2`) | `_wrapJsFunctionForAsync.<anonymous>` |
| `main.dart.js:74414` (`cI3.$1`) | `_awaitOnObject.<anonymous>` |
| `main.dart.js:75656` (`aOl.a9r`) | `_RootZone.runUnary` |
| `main.dart.js:74892` (`c3x.$0`) | `_Future._propagateToListeners.handleValueCallback` |
| `main.dart.js:5372` (`Object.Nd`) | `_Future._propagateToListeners` |
| `main.dart.js:74798` (`b2.BP`) | `_Future._completeWithValue` |
| `main.dart.js:74855` (`c3p.$0`) | `_Future._asyncCompleteWithValue.<anonymous>` |

Inspecting `build/web/main.dart.js:127578` directly:

```js
throw A.n(A.bhO("No implementation found for method "+a+" on channel "+m))
```

Confirmed: a `MissingPluginException` is thrown after a `MethodChannel`
call returns null on web (no plugin registered).

## Root cause identified

**File:** `lib/services/auth/biometric_auth_service.dart`
**Class:** `BiometricAuthService`
**Function:** `isBiometricAvailable()` (line 17 — `await _localAuth.canCheckBiometrics`)

**Plugin culprit:** `local_auth: ^2.3.0` — has **no web implementation**.
A secondary risk was `flutter_secure_storage` (web support is partial).

**Cold-load call chain:**

```
main()
  → Supabase.initialize() → runApp()
  → AnimatedSplashScreen (1.2 s) → pushReplacement
  → AuthGate.initState → _initializeApp → user == null
  → setState _role = 'unauthenticated'
  → build() returns PremiumLoginScreen
  → PremiumLoginScreen.initState (line 43) → _checkBiometricAvailability()
  → BiometricAuthService.isBiometricAvailable()
  → await _localAuth.canCheckBiometrics            ← MethodChannel, no web impl
  → throws MissingPluginException
  → catch only handled `PlatformException` (MissingPluginException is NOT a subclass)
  → exception escapes → uncaught Future error → Playwright captures as top-level Error
```

## Fix applied

`lib/services/auth/biometric_auth_service.dart` — added `if (kIsWeb)` early-returns
to every method that touches `local_auth` or `flutter_secure_storage`, and added
`MissingPluginException` catch clauses alongside the existing `PlatformException`
ones for defence-in-depth on non-web platforms missing the plugin.

| Method | Before | After |
|---|---|---|
| `isBiometricAvailable()` | line 15 | added `if (kIsWeb) return false;` + `MissingPluginException` catch |
| `getAvailableBiometrics()` | line 28 | added `if (kIsWeb) return const <BiometricType>[];` + `MissingPluginException` catch |
| `getBiometricEnabled()` | line 38 | added `if (kIsWeb) return false;` |
| `setBiometricEnabled()` | line 49 | added `if (kIsWeb) return;` |
| `getStoredUserEmail()` | line 69 | added `if (kIsWeb) return null;` |
| `authenticateWithBiometrics()` | line 79 | added `if (kIsWeb) return false;` + `MissingPluginException` catch |
| `clearBiometricData()` | line 103 | added `if (kIsWeb) return;` |
| `getBiometricDescription()` | line 113 | added `if (kIsWeb) return 'No biometric authentication available';` |

`main.dart` was not modified — its earlier guards (NotificationHelper, DeepLinkService) were already correct.

## PF01 result after fix

```
Startup errors after fix: 0
✓ tests/vagus_post_fix.spec.js:6:3 › PF01 - No startup console errors (6.2s)
```

**Crash eliminated.** No top-level errors during cold load.

## Full post-fix suite results

| Test | Result | Detail |
|---|---|---|
| **PF01** | **PASS** | 0 startup console errors (was 1 before) |
| **PF02** | **PASS** | 17 `flt-semantics` nodes present |
| **PF03** | **PASS** | 3 accessible buttons found (labels still null — see remaining) |
| **PF04** | **FAIL** | `/dashboard` returns 404 — http-server SPA fallback misconfigured (not a Flutter issue) |
| **PF05** | **PASS** | 0 calling buttons visible (feature flag working) |

`4 passed, 1 failed` — the only failure is unrelated to the crash; it is a
test-server config issue (`http-server --proxy http://localhost:8080?` is not
correctly catching the SPA route).

## Remaining issues

1. **PF04 SPA routing**: `playwright.config.js` uses `npx http-server --proxy http://localhost:8080?` for SPA fallback, but a fresh GET to `/dashboard` returns 404 instead of serving `index.html`. Switch to a proper SPA-aware server (e.g. `serve -s`) or update the http-server flag.
2. **PF03 button labels are null**: Buttons are detected but `aria-label` attributes are empty. Likely needs `Semantics(label: ...)` wrappers on the Premium Login screen's icon buttons.
3. **191 analyzer warnings/infos** remain in unrelated files (workout/cardio widgets) — cosmetic, no errors.

## Bundle size after rebuild

`build/web/main.dart.js`: **8,316,971 bytes** (≈ 7.93 MiB) — unchanged from
prior round (the fix added only ~16 lines of code, well below noise).

## Next recommended action for Claude

Fix the Playwright `webServer` to use an SPA-aware server (`npx serve -s ../../build/web -l 8080`) so PF04 passes — it is a 1-line config change and the only remaining failing test in the post-fix suite.
