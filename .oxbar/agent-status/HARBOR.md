# HARBOR status: READY-FOR-REVIEW

**Started:** 2026-04-28 00:00 UTC
**Last update:** 2026-04-28 00:00 UTC
**Branch:** agent/harbor-init
**Mission:** Enforce locale parity (EN/AR/KU) for every user-visible string; block PRs with untranslated strings; flag RTL layout issues.

## Current state

READY-FOR-REVIEW: Bootstrap PR open. All four initial deliverables are authored and committed on `agent/harbor-init`. CI check (harbor-locale-parity) runs on every PR to main. In bootstrap mode until TONGUE ships `lib/l10n/app_en.arb`.

## Progress

- [x] Read COORDINATION_PROTOCOL.md and agent-status files (TONGUE = PENDING)
- [x] Author `.github/workflows/harbor.yml` — locale parity CI check (bootstrap + enforce modes)
- [x] Author `lib/l10n/glossary.json` — 200 fitness/coaching terms seeded with EN/AR/KU equivalents
- [x] Author `scripts/harbor_freshness_check.py` — weekly staleness checker → `.oxbar/reports/harbor-stale.md`
- [x] Author `.oxbar/handoffs/HARBOR-to-PRISM.md` — RTL pass instructions for top 30 screens
- [x] Update this status file to READY-FOR-REVIEW
- [x] Open PR [HARBOR] Locale parity CI workflow + glossary skeleton
- [ ] Post-merge: flip status to RUNNING, watch all incoming PRs
- [ ] Post-TONGUE: strict enforcement mode activates automatically when app_en.arb lands

## Files touched

- `.github/workflows/harbor.yml`
- `lib/l10n/glossary.json`
- `scripts/harbor_freshness_check.py`
- `.oxbar/handoffs/HARBOR-to-PRISM.md`
- `.oxbar/agent-status/HARBOR.md` (this file)

## Workflow behaviour summary

**Bootstrap mode** (current — TONGUE not done):
- `harbor-locale-parity` job passes with a `::notice` annotation.
- No PRs are blocked. HARBOR is passive.

**Enforce mode** (activates automatically when `lib/l10n/app_en.arb` exists):
- Runs `flutter gen-l10n` — fails PR if codegen errors.
- Compares all keys in `app_en.arb` vs `app_ar.arb` and `app_ku.arb`.
- Posts / updates a markdown comment on the PR listing missing keys with owner tags (POLYGLOT-AR / POLYGLOT-KU).
- Fails the CI check if any key is missing in either locale.

## Questions for OXBAR

1. TONGUE is still PENDING. Once TONGUE marks DONE and their PR merges, `harbor.yml` will automatically flip to enforce mode — no HARBOR action needed. Confirm this is the expected sequencing.
2. Should the freshness check (`scripts/harbor_freshness_check.py`) be wired into a GitHub Actions scheduled workflow, or will OXBAR run it manually on a weekly cron? HARBOR can author the cron workflow if preferred.

## Blockers

BLOCKED on TONGUE (soft): Parity enforcement is bootstrap-only until `lib/l10n/app_en.arb` lands. CI is live but in pass-through mode.

## Next step

Await OXBAR merge. After merge, enter RUNNING state and monitor every PR for locale drift.
