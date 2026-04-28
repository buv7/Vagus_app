# VAULT status: READY-FOR-REVIEW

**Started:** 2026-04-27 21:15 UTC
**Last update:** 2026-04-27 22:55 UTC
**Branch:** agent/vault-license-scan-fix (follow-up); agent/vault-init merged
**Mission:** Stop secret leaks, GPL/AGPL contamination, RLS regressions, and PII-in-LLM exfiltration. Run as the in-tree security review on every PR.

## Current state
READY-FOR-REVIEW: PR #6 was merged by OXBAR at 19:35 UTC — VAULT's four core deliverables are live on main (vault.yml workflow, pii_sanitizer.dart, audit migration, SECURITY.md) plus 4 handoff docs and week-1 report. PR #12 is the urgent follow-up that fixes the license_scan job from hanging 18+ min on pub.dev — needs to merge before any other PR touches `pubspec.yaml`, otherwise the slow scan will block the swarm.

## PRs
- ✅ **#6 — merged 19:35 UTC** — `[VAULT] init: gitleaks workflow + audit table + PII sanitizer + SECURITY.md`. Final commits on the merged branch: `6bf45f7` (init), `f31d090` (Flutter pin + multi-line policy grep + drop profiles dep), `0ec5f36` (handoffs + week-1 report).
- 🟡 **#12 — open** — `[VAULT] license_scan: parallelize pub.dev queries, 8m job timeout`. Single-commit fix (`4498f4c` cherry-picked onto main as `10da205`). Needed because the original sequential pub.dev fetcher hung 18m52s on its own first run.

## Progress
- [x] Read COORDINATION_PROTOCOL.md
- [x] Inventory pubspec.yaml (49 direct + 8 dev deps — all permissive on direct)
- [x] Author + ship `.github/workflows/vault.yml` (3 jobs)
- [x] Author + ship `lib/services/ai/pii_sanitizer.dart`
- [x] Author + ship `supabase/migrations/20260427211500_vault_audit_table.sql`
- [x] Author + ship `SECURITY.md`
- [x] Author + ship 4 handoff docs (`VAULT-to-LABKIT`, `VAULT-to-PERIODS-FORGE`, `VAULT-to-WEARABLE-HUB`, `VAULT-to-ALL`)
- [x] Author + ship `.oxbar/reports/vault-week-1.md`
- [x] First-run CI shakedown completed (gitleaks/RLS pass; license_scan + Supabase Preview revealed bugs)
- [x] PR #6 merged
- [x] Follow-up PR #12 open with license_scan fix
- [ ] PR #12 CI green → merge → state transitions to DONE for week-1
- [ ] Audit existing 11 LLM call sites and open per-domain retrofit issues (week-2 plan)

## Files now live on main
- `.github/workflows/vault.yml`
- `lib/services/ai/pii_sanitizer.dart`
- `supabase/migrations/20260427211500_vault_audit_table.sql`
- `SECURITY.md`
- `.oxbar/agent-status/VAULT.md`
- `.oxbar/handoffs/VAULT-to-LABKIT.md`
- `.oxbar/handoffs/VAULT-to-PERIODS-FORGE.md`
- `.oxbar/handoffs/VAULT-to-WEARABLE-HUB.md`
- `.oxbar/handoffs/VAULT-to-ALL.md`
- `.oxbar/reports/vault-week-1.md`

## Questions for OXBAR
1. **Per-environment encryption key (`app.vault_data_key`)** — provision on staging (`xjrwmzctsmmcdmwzgptw`) before LABKIT/PERIODS-FORGE start writing encrypted columns. VAULT can author the bootstrap script once OXBAR confirms the delivery channel (`.oxbar/staging-secrets.md`?).
2. **gitleaks-action v2 licensing** — buv7/Vagus_app is a personal-account repo, no license needed. If we transfer to a GitHub Org, VAULT must add `GITLEAKS_LICENSE` secret.
3. **Worktree isolation for always-on agents** — VAULT spent ~half its first session recovering from concurrent-agent branch flips and pre-staged-pollution incidents in the shared worktree. Now operating from `vagus_app_vault` worktree. Recommend HARBOR / PRISM / SHIELD do the same. (Memory updated to reflect OXBAR runs from `vagus_app_oxbar` — same principle.)
4. **Supabase Preview infra failure on PR #6** — `Resource has been removed` for project ref `yktvvxacqashqxdsjlrh` (different from staging `xjrwmzctsmmcdmwzgptw`). Looks like a stale Supabase GitHub-integration config. OXBAR-owned, but VAULT flagging because it'll fail on every migration PR until reconfigured.

## Blockers
(none for VAULT itself — but if PR #12 isn't merged before another PR adds a `pubspec.yaml` dep, that PR will hang on license_scan for 18+ min)

## Next step
Watch PR #12 CI; flip state to DONE-for-week-1 when it merges. Then start week-2 plan: audit 11 existing LLM call sites for sanitizer retrofit, draft custom-lint rule.

## Incoming alerts
(none)

## Outgoing handoffs (live on main)
- `.oxbar/handoffs/VAULT-to-LABKIT.md`
- `.oxbar/handoffs/VAULT-to-PERIODS-FORGE.md`
- `.oxbar/handoffs/VAULT-to-WEARABLE-HUB.md`
- `.oxbar/handoffs/VAULT-to-ALL.md`

## License inventory snapshot
All 49 direct runtime deps + 8 dev deps appear permissive (MIT / Apache-2.0 / BSD-3-Clause). Transitive scan now runs in parallel via `vault.yml` → `license_scan` (after PR #12 merges).

## LLM call-site survey for week-2 retrofit
11 distinct files reference an LLM provider or call `aiClient.chat`/`embed`:
- `lib/services/ai/ai_client.dart` (the wrapper itself — entry point)
- `lib/services/ai/workout_ai.dart`
- `lib/services/ai/messaging_ai.dart`
- `lib/services/ai/embedding_helper.dart`
- `lib/services/ai/food_vision_service.dart`
- `lib/services/ai/calendar_ai.dart`
- `lib/services/ai/contextual_memory_service.dart`
- `lib/services/ai/transcription_ai.dart`
- `lib/services/ai/nutrition_ai.dart`
- `lib/services/ocr/ocr_cardio_service.dart`
- `lib/screens/nutrition/food_snap_screen.dart`
- `lib/screens/coach/client_weekly_review_screen.dart`

Week-2 plan: audit each call site, file a per-domain retrofit issue (BRAIN / NUTRITION-FINISH / MESSAGE-FINISH / CALLBACK / etc), add a soft-fail grep to `vault.yml` that flags any call within 20 lines that doesn't pass through `PiiSanitizer.sanitize*` first.
