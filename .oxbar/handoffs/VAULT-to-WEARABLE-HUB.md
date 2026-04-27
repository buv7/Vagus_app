# Handoff from VAULT to WEARABLE-HUB

**Date:** 2026-04-27
**PR:** #6 (`agent/vault-init`)

## What's now available

Same primitives as LABKIT and PERIODS-FORGE. WEARABLE-HUB uses `data_class = 'wearable'`.

- `public.vault_audit_access(...)` RPC
- `public.vault_encrypt_text(text) -> bytea`
- `public.vault_decrypt_text(bytea) -> text`
- `vault_data_class` enum value: `'wearable'`
- `vault_access_action` enum

## How to use it

### Volume considerations
Wearable signals are high-volume (HR every minute, sleep stages every 30 seconds, step counts every minute). Encrypting and audit-logging at the per-sample granularity is overkill and will balloon storage and audit-log size.

VAULT's recommendation:
- **Aggregate first, then encrypt.** Store hourly / daily aggregates encrypted, raw per-minute streams either unencrypted-but-RLS-protected or aged out after 30 days.
- **Audit at the session level, not the sample level.** When the user opens "Sleep details for last night," that's *one* audit row with `p_resource_table := 'wearable_sleep_sessions'` and `p_resource_id := session_id`, not 480 rows for the 480 30-second samples returned.
- **Coach access is by aggregate, not raw stream.** Coach UIs should query the aggregate views; raw streams stay client-side or behind a separate consent gate.

### Schema pattern
```sql
CREATE TABLE public.wearable_daily (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  day             date NOT NULL,
  source          text NOT NULL,                -- 'apple_health' | 'google_health_connect'
  steps           int  NULL,                    -- aggregate counts are not PII; OK in plaintext
  resting_hr      int  NULL,
  hrv_ms_enc      bytea NULL,                   -- HRV is more diagnostic; encrypt
  sleep_minutes   int  NULL,
  vo2max_enc      bytea NULL,                   -- VO2max is medical-grade
  ingested_at     timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, day, source)
);
```

### On read
```sql
PERFORM public.vault_audit_access(
  p_accessed_user_id := target_user_id,
  p_data_class       := 'wearable',
  p_action           := 'read',
  p_resource_table   := 'wearable_daily',
  p_justification    := 'coach_dashboard; consent=' || consent_id
);
```

## Caveats — wearable specific

- **The `health` Dart package (BSD-3-Clause) is the on-device ingestion path.** Data flows: device → `health` SDK → app → Supabase. Don't introduce intermediate proxies that store raw signals — that just creates another regulated data store.
- **Apple Health / Google Health Connect have their own consent prompts.** WEARABLE-HUB's UI must explain which categories are read and offer a per-category opt-out. The OS prompt alone isn't enough for medical-grade categories like HRV / VO2max / blood oxygen.
- **Raw stream data sent to LLMs?** Almost never. If WEARABLE-HUB adds a "summarize my week" AI feature, send aggregates and trends only — never raw per-minute HR with the user's name. Use `lib/services/ai/pii_sanitizer.dart`.
- **Background sync ≠ user-initiated read.** A nightly cron that pulls fresh data from Apple Health is *not* a "read of medical data" in the audit-log sense — there's no human accessor. Use `accessor_id = user_id` and `p_justification := 'background_sync'` to record it, OR skip the audit call entirely for system-driven ingestion. VAULT prefers the explicit-but-self-attributed audit row so that "no audit row = bug" stays a meaningful invariant.

## Caveats — same as LABKIT/PERIODS
- `SECURITY INVOKER` on the helpers
- Append-only audit log
- Per-environment encryption key

## Related
- `VAULT-to-LABKIT.md`
- `VAULT-to-PERIODS-FORGE.md`
- `SECURITY.md`
