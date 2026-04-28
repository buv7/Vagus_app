# HARBOR status: READY-FOR-REVIEW

**Started:** 2026-04-28 00:00 UTC
**Last update:** 2026-04-28 14:30 UTC
**Branch:** agent/harbor-init
**Mission:** Enforce locale parity (EN/AR/KU) for every user-visible string; block PRs with untranslated strings; flag RTL layout issues.

## Current state

READY-FOR-REVIEW: Bootstrap PR #15 is CI-green (all checks pass). Proactive locale debt scan complete across all 17 open PRs — advisory comments posted on 5 high-debt PRs. Waiting for OXBAR to merge PR #15.

## Progress

- [x] Read COORDINATION_PROTOCOL.md and agent-status files (TONGUE = PENDING)
- [x] Author `.github/workflows/harbor.yml` — locale parity CI check (bootstrap + enforce modes)
- [x] Author `lib/l10n/glossary.json` — 200 fitness/coaching terms seeded with EN/AR/KU equivalents
- [x] Author `scripts/harbor_freshness_check.py` — weekly staleness checker
- [x] Author `.oxbar/handoffs/HARBOR-to-PRISM.md` — RTL pass instructions for top 30 screens
- [x] Open PR #15 — all CI checks green (harbor-locale-parity ✓ in bootstrap mode)
- [x] Proactive locale debt scan: all 17 open PRs scanned for hardcoded EN strings
- [x] Advisory comments posted on PRs #22, #24, #27, #28, #17
- [x] Locale debt report: `.oxbar/reports/harbor-locale-debt.md` (~65 ARB keys catalogued)
- [ ] OXBAR merges PR #15 → harbor-locale-parity becomes required on all future PRs
- [ ] Post-merge: flip status to RUNNING, continue watching all incoming PRs
- [ ] Post-TONGUE: strict enforcement mode activates automatically when app_en.arb lands

## Files touched

- `.github/workflows/harbor.yml`
- `lib/l10n/glossary.json`
- `scripts/harbor_freshness_check.py`
- `.oxbar/handoffs/HARBOR-to-PRISM.md`
- `.oxbar/reports/harbor-locale-debt.md`
- `.oxbar/agent-status/HARBOR.md` (this file)

## Locale debt scan summary (2026-04-28)

| PR | Agent | ~Keys | Risk |
|----|-------|-------|------|
| #22 | TRIAL | 23 | High |
| #24 | DANGERZONE | 20 | High (safety-critical) |
| #27 | UX-ADAPT | 20 | High |
| #28 | TIER v2 | 9 | Medium |
| #17 | SIGNAL v2 | 10 | Medium |
| Others | — | ~5 | Low |

Full catalogue at `.oxbar/reports/harbor-locale-debt.md`.

## Workflow behaviour summary

**Bootstrap mode** (current — TONGUE not done):
- `harbor-locale-parity` CI passes with a `::notice` annotation on every PR.
- No PRs are blocked. HARBOR posts advisory (non-blocking) comments.

**Enforce mode** (auto-activates when `lib/l10n/app_en.arb` exists on main):
- Runs `flutter gen-l10n` — fails PR if codegen errors.
- Compares all keys in `app_en.arb` vs `app_ar.arb` and `app_ku.arb`.
- Posts / updates a markdown comment on the PR listing missing keys with owner tags.
- Fails CI if any key is missing in either locale.

## Questions for OXBAR

1. TONGUE is PENDING. Enforce mode triggers automatically on TONGUE merge — no HARBOR action needed. Confirm sequencing OK.
2. Should `harbor_freshness_check.py` be wired into a weekly GitHub Actions cron? HARBOR can author that workflow in a follow-up PR.
3. PR #15 is CI-green and MERGEABLE. Ready for `gh pr merge --admin` when OXBAR is ready.

## Blockers

BLOCKED on TONGUE (soft): Enforce mode requires `lib/l10n/app_en.arb`. CI is live in pass-through bootstrap mode.

## Next step

Await OXBAR merge of PR #15. After merge, set status to RUNNING and monitor all subsequent PRs.
