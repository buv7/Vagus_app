# VAULT status: RUNNING

**Started:** 2026-04-27 21:15 UTC
**Last update:** 2026-04-27 21:35 UTC
**Branch:** agent/vault-init
**Mission:** Stop secret leaks, GPL/AGPL contamination, RLS regressions, and PII-in-LLM exfiltration. Run as the in-tree security review on every PR.

## Current state
RUNNING: initial four deliverables authored on `agent/vault-init`. Committing, pushing, opening PR `[VAULT] init: gitleaks workflow + audit table + PII sanitizer + SECURITY.md`. Will move to READY-FOR-REVIEW once CI is green.

## Progress
- [x] Read COORDINATION_PROTOCOL.md
- [x] Inventory pubspec.yaml (49 direct deps, 8 dev deps — all permissive on first read; transitive scan on every PR via vault.yml)
- [x] Confirm `.env`, `.oxbar/staging-secrets.md` are gitignored
- [x] Confirm migrations baseline (164 archived, top level was empty before this PR)
- [x] Author `.github/workflows/vault.yml` (gitleaks + license_scan + rls_validation jobs)
- [x] Author `lib/services/ai/pii_sanitizer.dart` (sanitize / sanitizeMessages / assertSafe / sanitizeAndAssert)
- [x] Author `supabase/migrations/20260427211500_vault_audit_table.sql` (data_access_audit + vault_audit_access RPC + vault_encrypt/decrypt helpers + RLS)
- [x] Author `SECURITY.md` (public security posture)
- [ ] Commit + push
- [ ] Open PR
- [ ] CI green → READY-FOR-REVIEW

## Files touched
- `.github/workflows/vault.yml`           (new)
- `lib/services/ai/pii_sanitizer.dart`    (new)
- `supabase/migrations/20260427211500_vault_audit_table.sql` (new)
- `SECURITY.md`                           (new)
- `.oxbar/agent-status/VAULT.md`          (this file)

## Questions for OXBAR
1. **Per-environment encryption key (`app.vault_data_key`)** — VAULT's audit migration introduces `vault_encrypt_text` / `vault_decrypt_text` that read the symmetric key from a Postgres GUC. The key needs to be set on the database role via `ALTER ROLE postgres SET app.vault_data_key = '<value>'` (or via Supabase Vault). Please provision this on the staging project (`xjrwmzctsmmcdmwzgptw`) before LABKIT and PERIODS-FORGE start writing encrypted columns. VAULT can author the bootstrap script once OXBAR confirms the key delivery channel (`.oxbar/staging-secrets.md`?).
2. **gitleaks-action v2 licensing** — buv7/Vagus_app is a personal-account repo, so no GITLEAKS_LICENSE secret is required. If we ever transfer ownership to a GitHub Organization, VAULT must add `GITLEAKS_LICENSE` to repo secrets or the workflow will start failing.

## Blockers
(none)

## Next step
Push branch, open PR, wait for CI. Then start weekly report at `.oxbar/reports/vault-week-1.md`.

## Incoming alerts
(none)

## Outgoing handoffs (planned)
- `.oxbar/handoffs/VAULT-to-LABKIT.md` — once this PR merges, lab-work code can call `public.vault_audit_access(...)` and `public.vault_encrypt_text(...)`.
- `.oxbar/handoffs/VAULT-to-PERIODS-FORGE.md` — same primitives.
- `.oxbar/handoffs/VAULT-to-WEARABLE-HUB.md` — same primitives.
- `.oxbar/handoffs/VAULT-to-ALL.md` — `lib/services/ai/pii_sanitizer.dart` is the required wrapper for any LLM call.

## License inventory snapshot — direct deps in pubspec.yaml
All 49 direct runtime deps + 8 dev deps appear permissive (MIT / Apache-2.0 / BSD-3-Clause). No GPL/AGPL/SSPL/BUSL detected at the top level. Transitive dep graph is scanned on every PR by `vault.yml` → `license_scan`.

Notable callouts:
- `flutter_inappwebview` (MIT) — webview usage is fine, but any in-app loaded HTML should be CSP'd
- `health` 13.1.4 (BSD-3-Clause) — Apple Health / Google Health Connect; medical-data-flagged. Reads must hit `data_access_audit`.
- `google_generative_ai` (BSD-3-Clause) — Gemini SDK. Every call site MUST go through `pii_sanitizer.dart`.
- `flutter_secure_storage` (BSD-3-Clause) — keychain access; correct for tokens.
- `flutter_dotenv` (BSD-3-Clause) — `.env` is listed as a Flutter asset; that's normal but means anyone decompiling the APK sees its contents. Production secrets MUST come from `--dart-define` / `String.fromEnvironment`, NOT the dotenv file. Documented in SECURITY.md.
