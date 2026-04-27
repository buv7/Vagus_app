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

**20:55 UTC · CI: flutter test as soft-fail step**
What: Added `flutter test` to `.github/workflows/flutter-analyze.yml` with `continue-on-error: true`. Branch protection requires `flutter analyze (fail on errors)` only.
Why: Current suite is ~16 tests (target 120+). If we hard-require tests on day 0, every worker PR is blocked until TESTBED stabilizes the suite. Soft-fail surfaces breakage without gating the swarm. TESTBED flips to required at end of Wave D.

**20:55 UTC · Branch protection on main**
What: PUT `repos/buv7/Vagus_app/branches/main/protection` — requires `flutter analyze (fail on errors)` status check + 1 approving PR review, strict mode (branch must be up-to-date). `enforce_admins: false` so OXBAR can hotpatch infra. Force pushes + deletions disabled.
Why: Workers must go through PR → review → merge. OXBAR retains admin bypass for emergency CI fixes. Pre-authorized by Alhassan.

**21:08 UTC · Staging Supabase project: vagus-staging (free tier)**
What: Created project `vagus-staging` (ref `xjrwmzctsmmcdmwzgptw`) in eu-central-1 (Frankfurt), free tier ($0/mo). Captured URL + publishable + legacy anon keys in `.oxbar/staging-secrets.md` (gitignored). Service-role key + DB password not retrieved (dashboard-only) — fetched on demand when a worker needs them.
Why: Pre-authorized by Alhassan up to $25/mo with free tier preferred. eu-central-1 is closest to Iraq for latency and matches prod region.

**21:08 UTC · Defer prod-→-staging schema baseline**
What: `supabase/migrations/` is intentionally empty post-baseline (164 files archived, prod is schema source-of-truth per `supabase/migrations/README.md`). Per the literal playbook, "push the current schema" is a no-op against an empty migrations dir, so staging starts bare. Tracked as task #6 — bridge via `pg_dump --schema-only` from prod (read-only) when the first worker writing a table-altering migration needs staging parity.
Why: No worker has requested it yet, and any premature dump risks introducing drift before workers begin. Pull on demand. Production schema is NOT touched.

**21:08 UTC · Skip `supabase link` step in CLI**
What: Local Supabase CLI is unauthenticated (`supabase projects list` → 401). OXBAR uses Supabase MCP tools (`mcp__claude_ai_Supabase__*`) for staging operations — that's the persisted-on-machine path per `.claude/memory/reference_local_tooling.md`. CLI link is unnecessary for OXBAR; workers needing local CLI for their flows will auth their own session.
Why: The MCP route is already auth'd, idempotent, and avoids the friction of refreshing a CLI access token mid-campaign.

---
