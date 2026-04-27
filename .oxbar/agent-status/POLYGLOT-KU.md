# POLYGLOT-KU status: BLOCKED

**Started:** 2026-04-27 21:05 UTC
**Last update:** 2026-04-27 21:05 UTC
**Branch:** agent/polyglot-ku-translations
**Mission:** Translate `app_en.arb` to Kurdish-Sorani; deliver `lib/l10n/app_ku.arb` + `lib/l10n/glossary_ku.json`.

## Current state
BLOCKED: cannot start translation work. Three independent prerequisites are unmet — see Blockers. Marking BLOCKED on first cycle rather than RUNNING because the FORBIDDEN section of the mission ("pretending unconfident translations are confident") rules out doing speculative work while waiting.

## Progress
- [x] Read mission, COORDINATION_PROTOCOL.md, and HARBOR→POLYGLOT-KU handoff
- [x] Verified TONGUE status (PENDING)
- [x] Verified `app_en.arb` does not exist anywhere in repo
- [x] Verified Flutter l10n is not initialized (no `l10n.yaml`, no `lib/l10n/`)
- [x] Created agent branch `agent/polyglot-ku-translations`
- [x] Filed escalation E-001 (see `.oxbar/escalations.md`)
- [ ] Awaiting TONGUE → DONE (provides `app_en.arb`)
- [ ] Awaiting HARBOR PR merge (`agent/harbor-glossary-skeleton` → main, provides `assets/translations/glossary.json` with 60 clean KU + 170 `needs_review:["ku"]`)
- [ ] Awaiting Alhassan decision on translation pipeline (Gemini API key + Sorani reviewer arrangement)
- [ ] Build Sorani fitness glossary
- [ ] Translate `app_en.arb` → `app_ku.arb`
- [ ] Manual review pass
- [ ] Pair with PRISM for RTL visual inspection
- [ ] Open PR `[POLYGLOT-KU] Kurdish-Sorani translations`

## Files touched
- .oxbar/agent-status/POLYGLOT-KU.md (this file)
- .oxbar/escalations.md (filed E-001)

## Questions for OXBAR
(none — questions promoted to escalation E-001 because they require Alhassan)

## Blockers

1. **TONGUE not DONE.** No `app_en.arb` exists. POLYGLOT-KU's mission is literally "translate every key in app_en.arb"; with no source artifact, no translation work is possible. Per Wave B / depends-on, this is expected — flagging for visibility.

2. **HARBOR's glossary not on main.** `assets/translations/glossary.json` exists locally as untracked file on `agent/harbor-glossary-skeleton` (PR pending). Once merged, the 170 KU `needs_review` entries become POLYGLOT-KU's review queue. Until then, building `glossary_ku.json` would either duplicate HARBOR's work or diverge from it.

3. **No translation pipeline available.** Mission specifies Gemini Flash API + native-Sorani reviewer pass. Neither is provisioned in this agent's environment. The mission's FORBIDDEN section ("Auto-accepting Gemini output without review", "Pretending unconfident translations are confident") makes proceeding without these unsafe — Sorani output quality from LLMs is uneven and POLYGLOT-KU is held to a higher review bar than POLYGLOT-AR by the mission itself.

## Next step
Hold at BLOCKED. Re-check TONGUE status daily. When TONGUE flips to DONE and HARBOR's PR merges, escalation E-001 is the gating item — resume only after Alhassan responds.
