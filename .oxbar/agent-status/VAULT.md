# VAULT status: RUNNING

**Started:** 2026-04-27 21:15 UTC
**Last update:** 2026-04-27 22:35 UTC
**Branch:** agent/vault-init
**Mission:** Stop secret leaks, GPL/AGPL contamination, RLS regressions, and PII-in-LLM exfiltration. Run as the in-tree security review on every PR.

## Current state
RUNNING: PR #6 open with init + CI fixes (commits `6bf45f7`, `f31d090`). All four planned handoff docs and the week-1 report authored. Awaiting CI to go green on the second run, then will flip to READY-FOR-REVIEW.

## Progress
- [x] Read COORDINATION_PROTOCOL.md
- [x] Inventory pubspec.yaml (49 direct deps, 8 dev deps — all permissive; transitive scan on every PR via vault.yml)
- [x] Confirm `.env`, `.oxbar/staging-secrets.md` are gitignored
- [x] Confirm migrations baseline (164 archived, top level was empty before this PR)
- [x] Author `.github/workflows/vault.yml` (gitleaks + license_scan + rls_validation jobs)
- [x] Author `lib/services/ai/pii_sanitizer.dart`
- [x] Author `supabase/migrations/20260427211500_vault_audit_table.sql`
- [x] Author `SECURITY.md`
- [x] Commit `6bf45f7` (init) + push, open PR — https://github.com/buv7/Vagus_app/pull/6
- [x] First CI run: gitleaks pass, flutter-analyze pass, Vercel pass; license_scan + rls_validation + Supabase Preview fail
- [x] Diagnose failures and apply commit `f31d090` (Flutter pin, multi-line policy grep, drop profiles cross-table dep)
- [x] Author 4 handoff docs (`VAULT-to-LABKIT`, `VAULT-to-PERIODS-FORGE`, `VAULT-to-WEARABLE-HUB`, `VAULT-to-ALL`)
- [x] Author `.oxbar/reports/vault-week-1.md`
- [ ] Second CI run goes green → flip status to READY-FOR-REVIEW

## Files touched (cumulative on `agent/vault-init`)
- `.github/workflows/vault.yml` (new + 1 fix)
- `lib/services/ai/pii_sanitizer.dart` (new)
- `supabase/migrations/20260427211500_vault_audit_table.sql` (new + 1 fix)
- `SECURITY.md` (new)
- `.oxbar/agent-status/VAULT.md` (this file)
- `.oxbar/handoffs/VAULT-to-LABKIT.md` (new)
- `.oxbar/handoffs/VAULT-to-PERIODS-FORGE.md` (new)
- `.oxbar/handoffs/VAULT-to-WEARABLE-HUB.md` (new)
- `.oxbar/handoffs/VAULT-to-ALL.md` (new)
- `.oxbar/reports/vault-week-1.md` (new)

## Questions for OXBAR
1. **Per-environment encryption key (`app.vault_data_key`)** — VAULT's audit migration introduces `vault_encrypt_text` / `vault_decrypt_text` that read the symmetric key from a Postgres GUC. The key needs to be set on the database role via `ALTER ROLE postgres SET app.vault_data_key = '<value>'` (or via Supabase Vault). Please provision this on the staging project (`xjrwmzctsmmcdmwzgptw`) before LABKIT and PERIODS-FORGE start writing encrypted columns. VAULT can author the bootstrap script once OXBAR confirms the key delivery channel (`.oxbar/staging-secrets.md`?).
2. **gitleaks-action v2 licensing** — buv7/Vagus_app is a personal-account repo, so no GITLEAKS_LICENSE secret is required. If we ever transfer ownership to a GitHub Organization, VAULT must add `GITLEAKS_LICENSE` to repo secrets or the workflow will start failing.
3. **Concurrent-agent worktree collisions observed** — While shipping #6, the local worktree's HEAD got switched out from under VAULT three times (to `agent/shield-init`, `agent/keel-cleanup`, then `agent/mason-fitness-math`). VAULT recovered each time and is now operating from an isolated worktree at `C:/Users/alhas/StudioProjects/vagus_app_vault`. **Recommendation**: any always-on agent (HARBOR, PRISM, VAULT, SHIELD) should get its own worktree; otherwise OXBAR will keep paying recovery cost on shared-tree commits. Will write up as a candidate decision for `.oxbar/decisions.md` if OXBAR concurs.
4. **Staged-but-not-mine pollution.** During the same incident, KEEL's bulk legacy-SQL archive renames were pre-staged in the index when VAULT ran `git commit`, so they got dragged into VAULT's fix commit. Recovered via a clean reset + force-push (commit `f31d090` is now clean). Same root cause as #3 — isolated worktrees would prevent this.

## Blockers
(none)

## Next step
Watch CI on PR #6. When green: flip state to READY-FOR-REVIEW, commit handoffs + week-1 report (separate commit on top of fix), push.

## Incoming alerts
(none)

## Outgoing handoffs
- `.oxbar/handoffs/VAULT-to-LABKIT.md` — `vault_audit_access` + `vault_encrypt_text/decrypt_text` for lab work
- `.oxbar/handoffs/VAULT-to-PERIODS-FORGE.md` — same primitives for cycle data
- `.oxbar/handoffs/VAULT-to-WEARABLE-HUB.md` — same primitives for wearable signals (with volume guidance)
- `.oxbar/handoffs/VAULT-to-ALL.md` — every agent: CI checks + PII sanitizer + how to react if VAULT blocks

## License inventory snapshot — direct deps in pubspec.yaml
All 49 direct runtime deps + 8 dev deps appear permissive (MIT / Apache-2.0 / BSD-3-Clause). No GPL/AGPL/SSPL/BUSL detected at the top level. Transitive dep graph is scanned on every PR by `vault.yml` → `license_scan`.

Notable callouts:
- `flutter_inappwebview` (MIT) — webview usage is fine, but any in-app loaded HTML should be CSP'd
- `health` 13.1.4 (BSD-3-Clause) — Apple Health / Google Health Connect; medical-data-flagged. Reads must hit `data_access_audit`.
- `google_generative_ai` (BSD-3-Clause) — Gemini SDK. Every call site MUST go through `pii_sanitizer.dart`.
- `flutter_secure_storage` (BSD-3-Clause) — keychain access; correct for tokens.
- `flutter_dotenv` (BSD-3-Clause) — `.env` is listed as a Flutter asset; that's normal but means anyone decompiling the APK sees its contents. Production secrets MUST come from `--dart-define` / `String.fromEnvironment`, NOT the dotenv file. Documented in SECURITY.md.
