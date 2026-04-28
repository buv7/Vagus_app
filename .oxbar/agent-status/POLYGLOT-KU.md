# POLYGLOT-KU status: PENDING — waiting on TONGUE + GEMINI_API_KEY

**Started:** 2026-04-28
**Last update:** 2026-04-28
**Branch:** agent/polyglot-ku-v2
**Mission:** Translate app_en.arb to Kurdish-Sorani (Arabic script, Iraqi Kurdistan dialect)

## Current state

PENDING on two prerequisites:

1. **TONGUE not launched** — `lib/l10n/app_en.arb` does not exist. TONGUE branch `agent/tongue-i18n` has no commits ahead of main. Cannot translate until source strings exist.

2. **GEMINI_API_KEY not set** — `$GEMINI_API_KEY` is empty in the agent environment. This key is required to call Gemini Flash for translation. Must be provisioned before translation work begins.

E-002 resolution accepted: "best AI can do" quality, all uncertain strings marked `// review-pending`, no indefinite block on perfection.

## Progress

- [x] Read coordination protocol (no COORDINATION_PROTOCOL.md found — skipped)
- [x] Read escalations log (E-002 resolution: Gemini + review-pending markers approved)
- [x] Created `lib/l10n/` directory
- [x] Built `lib/l10n/glossary_ku.json` — 218 Sorani fitness terms across 8 categories
- [ ] Await `app_en.arb` from TONGUE
- [ ] Await `GEMINI_API_KEY` provisioning
- [ ] Translate all keys → `lib/l10n/app_ku.arb`
- [ ] Mark uncertain strings `// review-pending: <reason>`
- [ ] Write `.oxbar/reports/polyglot-ku-needs-human.md`
- [ ] Run `flutter gen-l10n` validation
- [ ] Open PR

## Files touched

- `lib/l10n/glossary_ku.json` (created — 218 Sorani fitness terms)

## Glossary summary (lib/l10n/glossary_ku.json)

218 terms across 8 categories:
- `workout_training` (30): sets/reps/warm-up/volume/AMRAP/periodization etc.
- `exercises` (32): squat/deadlift/push-up/plank/kettlebell etc.
- `muscles_body` (31): chest/back/biceps/quads/glutes etc.
- `nutrition` (29): calories/protein/carbs/meal/supplement/TDEE etc.
- `fitness_concepts` (30): hypertrophy/HIIT/progressive overload/BMI/1RM etc.
- `health_recovery` (18): recovery/sleep/DOMS/fatigue/adaptation etc.
- `app_features` (40): goal/progress/streak/coach/settings/timer etc.
- `body_composition_metrics` (8): bulking/cutting/recomp/waist etc.

Script: Arabic (Perso-Arabic, Sorani Kurdish). RTL.
Borrowed terms flagged in `notes` field. Many borrowed fitness terms are deeply established in Iraqi gym culture (سکوات, دەمبێل, کاردیۆ).

## Questions for OXBAR

1. **TONGUE launch status** — TONGUE hasn't been launched yet (branch `agent/tongue-i18n` is at same commit as main). When does TONGUE go live? POLYGLOT-KU is ready to start as soon as `app_en.arb` lands.

2. **GEMINI_API_KEY** — needs to be set in the environment where POLYGLOT-KU runs. Same key used for POLYGLOT-AR if that's also Gemini-based.

## Blockers

- TONGUE: `app_en.arb` does not exist
- `GEMINI_API_KEY` environment variable not set

## Next step

Once both blockers are resolved: read `app_en.arb`, batch-translate via Gemini Flash with Sorani context + glossary excerpts, write `app_ku.arb`, mark review-pending strings, open PR.
