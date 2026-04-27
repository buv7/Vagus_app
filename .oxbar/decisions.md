# OXBAR Decisions

> Every non-trivial decision OXBAR makes within its pipeline authority.
> Format: timestamp · short title · what · why. Append-only.

---

## 2026-04-27

**20:49 UTC · Do not touch pre-existing dirty WIP**
What: 10 Dart files were modified in the working tree on arrival, plus untracked Playwright test artifacts and `vagus_scan_report.txt`. OXBAR will NOT stage, commit, stash, or revert any of them.
Why: They predate the campaign. They likely represent in-progress user work. Per OXBAR's "executing actions with care" principle, only stage explicit OXBAR-owned files.

**20:49 UTC · Initialize 51 agent status files (not 49)**
What: Init list is HARBOR PRISM VAULT SHIELD KEEL MUSIC-PURGE PALETTE MASON GUARDIAN MEDIC TONGUE POLYGLOT-AR POLYGLOT-KU DRIFTKIT CONDUIT SIGNAL IAP-APPLE IAP-GOOGLE TIER TRIAL BRAIN THRIFT EX-FORGE EX-AUDIT EX-MEDIA POLYGLOT-EX HYDRA DICTATE SHEETIFY BAZAAR WATERMARK UX-ADAPT DANGERZONE ADMIN-BUTTONS LABKIT POSEKIT WEARABLE-HUB REEL CALLBACK PERIODS-FORGE PERIODS-UI PERIODS-INTEGRATE WEB-WARDEN TODO-KILLER NUTRITION-FINISH MESSAGE-FINISH FILE-FINISH ANALYTICA STORE TESTBED E2E.
Why: AGENT_PROMPTS.md ToC enumerates 4 + 7 + 10 + 22 + 8 = 51 entries; the doc itself notes the 49-terminal "ceiling" is approximate due to overlap. Init all 51 — collapse if/when bandwidth forces it.

---
