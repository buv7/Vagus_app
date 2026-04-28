# Handoff from VAULT to PERIODS-FORGE

**Date:** 2026-04-27
**PR:** #6 (`agent/vault-init`)

## What's now available

Same primitives as the LABKIT handoff. PERIODS-FORGE uses `data_class = 'period_tracking'`.

- **`public.vault_audit_access(...)`** — RPC for writing one append-only row to `public.data_access_audit`.
- **`public.vault_encrypt_text(text) -> bytea`** and **`public.vault_decrypt_text(bytea) -> text`** — symmetric column encryption keyed off `app.vault_data_key` GUC.
- **`vault_data_class`** enum value: `'period_tracking'`.
- **`vault_access_action`** enum: `'read' | 'write' | 'export' | 'share'`.

## How to use it

### Schema pattern for cycle data
Cycle dates and symptom notes are sensitive — encrypt at rest:
```sql
CREATE TABLE public.cycle_entries (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  entry_date    date NOT NULL,                -- the calendar date itself is queryable; OK in plaintext
  cycle_day     int  NULL,                    -- ordinal day within cycle; non-PII
  flow_enc      bytea NULL,                   -- encrypted enum: spotting/light/medium/heavy
  symptoms_enc  bytea NULL,                   -- encrypted free-text or jsonb-as-text
  notes_enc     bytea NULL,                   -- encrypted free text
  created_at    timestamptz NOT NULL DEFAULT now()
);
```

### On read
```sql
PERFORM public.vault_audit_access(
  p_accessed_user_id := target_user_id,
  p_data_class       := 'period_tracking',
  p_action           := 'read',
  p_resource_table   := 'cycle_entries',
  p_resource_id      := entry_id,
  p_justification    := 'self_view'  -- or 'coach_view; consent=' || consent_id
);

SELECT entry_date, cycle_day,
       public.vault_decrypt_text(flow_enc)     AS flow,
       public.vault_decrypt_text(symptoms_enc) AS symptoms,
       public.vault_decrypt_text(notes_enc)    AS notes
FROM public.cycle_entries
WHERE id = entry_id;
```

## Caveats — period-tracking specific

- **Coach access requires explicit per-feature consent.** Periods are arguably more sensitive than lab work for many users — VAULT recommends PERIODS-FORGE design the consent UX as opt-in-per-coach, not a blanket "share medical data" toggle.
- **Predicted cycle data should never go to an LLM.** If PERIODS-FORGE adds AI-driven cycle prediction, the model runs server-side on encrypted-at-rest data with the key never leaving the database environment — or, more realistically, runs client-side on decrypted data that never crosses the network. **Do not send cycle dates + name to a third-party LLM endpoint.** `lib/services/ai/pii_sanitizer.dart`'s `assertSafe` will catch this if you forget, but design to avoid it.
- **Symptom strings can contain PII.** Users sometimes write "called Dr. <name> at <hospital>" in symptom notes. Encrypt at rest and never include them in analytics.
- **Audit-on-read also applies to cycle predictions / charts.** When PERIODS-UI builds a chart that aggregates the past 12 cycles, the SELECT that fans out to the encrypted columns is still a "read" of medical data. Audit each render, not each row — one audit row per UI session is fine, with `p_justification := 'cycle_chart_render'`.

## Caveats — same as LABKIT
- `vault_audit_access` is `SECURITY INVOKER`; callers must be authenticated.
- `data_access_audit` is append-only.
- Encryption key differs per environment; do not hard-code.

## Related
- `VAULT-to-LABKIT.md` — same primitives, different `data_class`
- `VAULT-to-WEARABLE-HUB.md`
- `SECURITY.md`

---

## Update 2026-04-28 — GUC → vault.decrypted_secrets

The original handoff said `vault_encrypt_text` / `vault_decrypt_text` read the
key from `current_setting('app.vault_data_key')`. That GUC was never provisioned
(Supabase blocks ALTER DATABASE for non-superusers). The functions now read
from `vault.decrypted_secrets WHERE name = 'app_vault_data_key'` per the
refactor migration `20260428210000_vault_guc_refactor.sql`.

**For consumers:** no API change — keep calling `public.vault_encrypt_text(text)`
and `public.vault_decrypt_text(bytea)` exactly as before. The change is internal.

**Operator action required on each new environment:** create the
`app_vault_data_key` secret via `vault.create_secret(...)` before any encrypted
insert runs, or every call will raise.
