# Pending Wiring — Agent 3

All six routes are live and backed by existing tables / services. Nothing
blocks shipping, but the items below are soft TODOs for future polish.

## 1. Devices screen — true session list
- **File**: `lib/screens/settings/devices_screen.dart`
- **Current behaviour**: lists entries in the `user_devices` table
  (the project's canonical device registry, populated by notification
  registration) + pinned "this device" card from
  `Supabase.instance.client.auth.currentSession`.
- **Gap**: Supabase's Flutter SDK does not expose `auth.sessions` for the
  signed-in user from the client. The UI therefore cannot show the list of
  "active auth sessions" that the spec mentioned.
- **To fully wire**: add a `list_user_sessions()` SECURITY DEFINER RPC
  (out of scope — would require a new migration), or surface sessions from
  `auth.sessions` via an edge function. Guardrails forbid either in this
  task.
- **TODO marker in code**: `lib/screens/settings/devices_screen.dart` —
  `_buildBody()` around the "This device" card and the devices list (no
  inline TODO comment added to keep the file clean; tracked here instead).

## 2. AI usage — per-feature breakdown
- **File**: `lib/screens/settings/ai_usage_screen.dart`
- **Current behaviour**: reads `requests_this_month`, `monthly_limit`,
  `tokens_used`, `tokens_limit` from
  `AIUsageService.instance.getCurrentUsage()` and shows two progress bars.
- **Gap**: the existing `get_ai_usage_summary` RPC does not appear to
  return a per-feature split (Notes / Nutrition / Workout / Messaging /
  Transcription). The previous hardcoded screen showed those — the new
  screen shows only what the service actually returns.
- **To fully wire**: extend the RPC to return a per-request-type breakdown,
  or aggregate from whatever tracking table `update-ai-usage` writes to.
- **TODO marker**: N/A — service contract change required; this is a
  data-layer task.

## 3. Support — email edge function
- **File**: `lib/screens/support/support_screen.dart`
- **Current behaviour**: inserts into `support_requests`, then best-effort
  invokes `send-support-email` with type `new_request`.
- **Gap**: per `supabase/functions/send-support-email/README.md`, the
  function only documents `type: "support_reply"`. Sending
  `type: "new_request"` may be ignored. Failures are already swallowed.
- **To fully wire**: teach the edge function to handle `type: "new_request"`
  and notify the support team (or remove the invocation and rely on admin
  dashboard polling).

## 4. Localization (l10n)
- **Files**: all six new screens.
- **Current behaviour**: English strings inline; `MaterialApp` declares
  `en`, `ar`, `ku` locales and the standard Flutter localization delegates,
  matching the rest of the app.
- **Gap**: the project does not use a generated ARB pipeline for most
  screens, so these new screens follow the same pattern. If an ARB catalog
  is introduced later, these strings should be extracted.
