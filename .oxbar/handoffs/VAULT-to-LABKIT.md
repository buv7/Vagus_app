# Handoff from VAULT to LABKIT

**Date:** 2026-04-27
**PR:** #6 (`agent/vault-init`)

## What's now available

Once #6 merges, LABKIT can rely on these primitives in any migration or Edge Function that touches lab-work data:

### Audit logging
- **Function:** `public.vault_audit_access(p_accessed_user_id uuid, p_data_class vault_data_class, p_action vault_access_action DEFAULT 'read', p_resource_table text DEFAULT NULL, p_resource_id uuid DEFAULT NULL, p_justification text DEFAULT NULL, p_client_info jsonb DEFAULT '{}')`
- **Returns:** `uuid` (the new audit row id)
- **Behavior:** writes one row to `public.data_access_audit` with `accessor_id = auth.uid()`. Raises if `auth.uid()` is null (anonymous calls are not allowed).

### Symmetric column encryption
- **Function:** `public.vault_encrypt_text(text)` → `bytea`
- **Function:** `public.vault_decrypt_text(bytea)` → `text`
- Both read the symmetric key from the GUC `app.vault_data_key`. OXBAR provisions this on each environment (see VAULT's question #1 in `.oxbar/agent-status/VAULT.md`). If the key isn't set the helpers raise `vault_encrypt_text: app.vault_data_key is not set`.

### Enums
- `vault_data_class` — values: `lab_work`, `period_tracking`, `wearable`, `medical_other`. **LABKIT uses `lab_work`.**
- `vault_access_action` — values: `read`, `write`, `export`, `share`.

## How to use it

### In a server-side Edge Function or RPC
```sql
-- Inside the function that returns lab results to a coach:
PERFORM public.vault_audit_access(
  p_accessed_user_id := target_user_id,
  p_data_class       := 'lab_work',
  p_action           := 'read',
  p_resource_table   := 'lab_results',
  p_resource_id      := result_id,
  p_justification    := 'coach view; consent_grant_id=' || consent_id::text
);
```

### In a Dart call site
Use a Supabase RPC wrapper:
```dart
await Supabase.instance.client.rpc('vault_audit_access', params: {
  'p_accessed_user_id': targetUserId,
  'p_data_class': 'lab_work',
  'p_action': 'read',
  'p_resource_table': 'lab_results',
  'p_resource_id': resultId,
  'p_justification': 'self_view',
});
```

### Encrypted columns
For new lab-work tables, declare biomarker values as `bytea` and pipe through the helpers:
```sql
CREATE TABLE public.lab_results (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  marker      text NOT NULL,                -- "ferritin", "TSH", etc. — non-PII
  value_enc   bytea NOT NULL,               -- encrypted numeric value
  unit        text NOT NULL,
  collected_at timestamptz NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- Insert
INSERT INTO public.lab_results (user_id, marker, value_enc, unit, collected_at)
VALUES (
  auth.uid(),
  'ferritin',
  public.vault_encrypt_text('142'),
  'ng/mL',
  '2026-04-15 09:30:00+00'
);

-- Select
SELECT id, marker, public.vault_decrypt_text(value_enc) AS value, unit
FROM public.lab_results
WHERE user_id = auth.uid();
```

## Caveats

- **`vault_audit_access` is `SECURITY INVOKER`** — it runs with the caller's auth context and inserts under the caller's RLS. Callers must be authenticated.
- **The `data_access_audit` table is append-only.** No UPDATE or DELETE policy exists. If LABKIT ever needs to "correct" an audit row, the right approach is to insert a corrective row (with `action = 'write'` and a `justification` explaining what's being corrected), not to mutate.
- **Coach-reads-client-lab is a privileged operation.** LABKIT should:
  1. First verify a per-resource consent grant exists (LABKIT will own that consent table).
  2. Then call `vault_audit_access` with `p_justification` referencing the consent grant id.
  3. Then return the data.
  Skipping the audit call is a security regression — VAULT will track this in PR review.
- **Encryption key is set per environment.** Staging uses one key; prod uses another. Decrypting prod ciphertext on staging will raise. This is intended.
- **The `health` Dart package** (BSD-3-Clause) is the wearable-data ingestion path on device, not lab work. Lab work is OCR + manual entry; that path is LABKIT's to design.

## Related
- VAULT-to-PERIODS-FORGE.md — same primitives, different `data_class`
- VAULT-to-WEARABLE-HUB.md — same primitives, different `data_class`
- `SECURITY.md` (repo root) — public posture
