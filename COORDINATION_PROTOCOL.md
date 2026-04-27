# COORDINATION PROTOCOL — How Vagus Agents Communicate

> Every worker agent MUST read this before starting. OXBAR has read it. The rules here are the social contract that keeps 50 agents from stepping on each other.

---

## CORE RULE: NO PINGING TERMINALS

You (a worker agent) will never see another worker's terminal. You communicate with the swarm through **files in the repo** under `.oxbar/`, and through **GitHub PRs**.

If you need something from another agent, you do NOT wait for them. You either:
1. Read their `.oxbar/agent-status/<NAME>.md` to see if they've published their output yet
2. Read their handoff doc at `.oxbar/handoffs/<THEM>-to-<YOU>.md` if it exists
3. Open a PR commenting on theirs if there's overlap on a file
4. Add a question to your own status file under `## Questions for OXBAR` — OXBAR resolves

---

## YOUR STATUS FILE

You own `.oxbar/agent-status/<YOUR_NAME>.md`. Update it at every meaningful state change. Format:

```markdown
# <YOUR_NAME> status: <STATE>

**Started:** YYYY-MM-DD HH:MM UTC
**Last update:** YYYY-MM-DD HH:MM UTC
**Branch:** agent/<your-name>
**Mission:** <one-line>

## Current state
<STATE>: <one paragraph explaining where you are>

## Progress
- [x] Task 1 done
- [x] Task 2 done
- [ ] Task 3 in progress
- [ ] Task 4 pending

## Files touched
- lib/foo/bar.dart
- supabase/migrations/20260427_xxx.sql

## Questions for OXBAR
(none) | <list>

## Blockers
(none) | <list>

## Next step
<one line>
```

### Valid states (uppercase, exact strings — OXBAR greps these)
- `PENDING` — agent has not started yet
- `STARTING` — environment setup in progress
- `RUNNING` — actively working
- `BLOCKED` — stuck, see Blockers section, OXBAR will respond
- `READY-FOR-REVIEW` — PR open, awaiting OXBAR/CI
- `DONE` — PR merged, agent retiring
- `ABANDONED` — task scoped out, see Last update for reason

Update the state field on the very first line every time it changes.

---

## YOUR BRANCH AND PR

- Always work on `agent/<your-name>-<short-task-tag>` (e.g. `agent/keel-archive-sql`, `agent/harbor-arabic-pass-1`)
- Never push directly to `main`
- Open PR against `main` titled exactly: `[<YOUR_NAME>] <short description>`
- PR body must include:
  ```
  Mission: <one-line from your prompt>
  Wave: A|B|C|D|always-on
  Closes part of: #<github-issue-if-applicable>
  Status: ready-for-review
  Validation: <commands you ran and their output>
  ```
- Add label corresponding to your wave
- When CI is green, set status to `READY-FOR-REVIEW` in your status file. OXBAR merges.

---

## DEPENDENCIES BETWEEN AGENTS

Each prompt lists **`Depends on:`** at the top. Hard rules:
- If your dep has status not yet `DONE`, you do NOT start. Update your status to `PENDING — waiting on <DEP>`.
- If your dep is `DONE`, read their last status file + their merged PR to understand what's now available before you begin.
- If you discover a hidden dependency mid-work (something you need that another agent owns and hasn't shipped), update status to `BLOCKED — discovered hidden dep on <AGENT>` and let OXBAR resolve.

---

## HANDOFF DOCS

When your output is something another agent will consume, write a handoff doc:

```
.oxbar/handoffs/<YOU>-to-<THEM>.md
```

Format:

```markdown
# Handoff from <YOU> to <THEM>

**Date:** YYYY-MM-DD
**PR:** #<number>

## What's now available
- <thing 1, with file path or API endpoint>
- <thing 2>

## How to use it
<short example or note>

## Caveats
<anything they need to know>
```

Examples:
- `EX-FORGE-to-POLYGLOT-EX.md` — "350 exercises curated, here's the JSON path, here are the fields that need translation"
- `DRIFTKIT-to-CONDUIT.md` — "Local DB schema is at this path, here are the tables, sync queue should write to this table"

---

## FILE COLLISION RULES

If you must edit a file another agent might also be editing:

1. Check `git log --since="48 hours ago" -- <file>` for recent edits
2. Check open PRs for that file: `gh pr list --search "<file>" --state open`
3. If conflict possible, post in your status file under `Questions for OXBAR`: "potential file collision with <AGENT> on <file>"
4. OXBAR will sequence you. Wait.

Files highly likely to be touched by multiple agents:
- `pubspec.yaml` (everyone touches this — sequence carefully)
- `lib/main.dart`
- `lib/app.dart`
- `lib/theme/app_theme.dart` (PALETTE owns; everyone reads)
- `supabase/migrations/` (only one migration per timestamp; coordinate)
- `assets/translations/*.arb` (HARBOR owns; coordinate adds)

For these, prefer **smallest possible diffs**. Open a focused PR for just your line.

---

## DATABASE MIGRATIONS

If your task includes a Supabase migration:
- File name: `supabase/migrations/YYYYMMDDHHMMSS_<your_name>_<short>.sql`
- Use UTC timestamp at the moment you create it
- Migration must be idempotent (`CREATE TABLE IF NOT EXISTS`, `ADD COLUMN IF NOT EXISTS` via DO blocks, etc.)
- Migration must include rollback in a comment block at the bottom
- Never modify a migration that's already merged. Add a new one.
- Test against staging first via OXBAR (you do NOT push to production):
  - Open your PR
  - In status file, ask: "Migration ready for staging dry-run"
  - OXBAR applies to staging and reports back
  - You verify, mark READY-FOR-REVIEW

---

## SECRETS HANDLING

- NEVER commit secrets. Use `.env.example` for documentation, real `.env` is git-ignored.
- All Supabase credentials live in `.oxbar/staging-secrets.md` (gitignored), OXBAR manages.
- API keys (Cerebras, Groq, Gemini, etc.) live in environment variables. Reference them as `String.fromEnvironment(...)` in Dart.
- If you see a secret accidentally committed, immediately:
  1. Stop your work
  2. Update status to `BLOCKED — secret leak`
  3. Tell VAULT (via VAULT's status file: append a line under `## Incoming alerts`)
  4. Wait for VAULT to rotate

---

## LICENSE DISCIPLINE

You may freely use packages with: **MIT, Apache 2.0, BSD, CC0, ISC, Public Domain, Unlicense, Zlib**.

You may NEVER copy code from packages with: **GPL-2.0, GPL-3.0, AGPL-3.0, SSPL, BUSL, Commons Clause, "Research-only"**.

If you find yourself wanting to copy ≥20 lines from a GPL repo: **STOP**. Open VAULT's status file with the alert. VAULT will tell you whether the use is OK (rare — usually the answer is "rewrite from scratch in your own words").

LibreTranslate is AGPL but used as a **separate self-hosted service** — that's safe. Embedding its code in the Flutter app is NOT safe.

---

## CHILD SAFETY GUARDS

This app handles minors (some clients are <18 with coach supervision). Hard rules:
- Never log a client's full name + DOB together in any analytics event
- Account creation flow asks for DOB; if <18, certain features (marketplace post, public leaderboard, social sharing) auto-disable
- If your task touches anything related to minors, escalate to VAULT to confirm safe defaults

---

## MEDICAL DATA GUARDS

LABKIT, PERIODS-*, WEARABLE-HUB, and parts of NUTRITION-FINISH touch medical-grade data. Any of those agents:
- Strip PII (name, DOB, MRN) before any LLM call. Send only biomarker text.
- Use Supabase pgcrypto column encryption for raw values
- Add a row to `data_access_audit` table on every read (see VAULT for schema)
- Never display "you have <condition>" — only "value below typical range, discuss with healthcare provider"

If your task touches medical data and you're not sure about the safety guards, ask VAULT in their status file before proceeding.

---

## PERFORMANCE BUDGET

Whole-app rules you must not violate:
- App startup time: must not regress beyond +200ms vs main
- Cold launch RAM: must not regress beyond +30MB
- APK size: must not regress beyond +5MB
- Frame rate: 60fps on a baseline device (Pixel 5 / iPhone 12)

If your work pushes any of these, profile and optimize before opening PR. Use `flutter analyze --no-pub --no-current-package` and Flutter DevTools.

---

## TEST DISCIPLINE

Every PR must include:
- At least one widget test or unit test for the new behavior (unless you're TESTBED, who builds tests for everything)
- Updates to existing tests if your change broke them
- `flutter analyze` must pass with zero new warnings

If your task is "documentation only" or "config only," explicit OK to skip tests but state it in PR body.

---

## DAILY CHECK-IN

At the end of each working session, before you wind down:
1. Update your status file with `Last update` timestamp
2. If you're not done, set state to `RUNNING` (or `BLOCKED` with detail)
3. If you're done, ensure PR is open, state is `READY-FOR-REVIEW`, and CI is green
4. Commit + push (don't leave uncommitted work in your local tree overnight)

---

## FAILURE MODES — what to do

| Situation | Action |
|---|---|
| CI fails on your PR | Fix it. State stays `RUNNING`. Don't move to ready-for-review. |
| Test you didn't write fails | Read the failure, fix if obvious, else `BLOCKED` and ask OXBAR who owns that test |
| Flutter analyzer warnings new | Fix before opening PR |
| You realize the task is bigger than your prompt described | Stop, update status to `BLOCKED — scope unclear`, post a sub-task list in your status file, wait for OXBAR |
| Another agent's PR breaks your branch | Rebase. If conflict you can't resolve, ask OXBAR who wins |
| Supabase staging is down | Wait. Don't apply migrations to production as a workaround. |
| You're confused | Re-read your prompt. Re-read this protocol. If still confused, `BLOCKED — clarification needed`. |

---

## WHEN YOU'RE DONE

When all your tasks are complete and PR is merged:
1. Update status file to `DONE` on the first line
2. Add summary section:
   ```markdown
   ## Summary
   - Files added/modified: <count>
   - Tests added: <count>
   - PRs merged: #<num>, #<num>
   - Total commits: <count>
   - Effort: ~<hours>
   ```
3. Stop. Do not start a new task without a new prompt from OXBAR.

---

## SHARED VOCABULARY

| Term | Meaning |
|---|---|
| **wild** | The trigger word from Alhassan that started this campaign. |
| **OXBAR** | The supervisor agent. Outranks all workers. |
| **wave** | A,B,C,D — temporal grouping of agents. |
| **always-on** | HARBOR, PRISM, VAULT, SHIELD — agents that run continuously. |
| **handoff** | A markdown doc describing output ready for downstream consumption. |
| **escalation** | A blocker that requires Alhassan; goes in `.oxbar/escalations.md`. |
| **RC** | Release candidate. Tag `v1.0.0-rc.N`. |
| **MENA** | Middle East + North Africa — primary launch market. |
| **Sorani** | The Kurdish dialect we support. (Not Kurmanji.) |

---

## ONE-PAGE CHEAT SHEET (PRINT THIS)

```
Branch:        agent/<my-name>-<task>
PR title:      [<MY_NAME>] <description>
Status file:   .oxbar/agent-status/<MY_NAME>.md
Handoff dir:   .oxbar/handoffs/
Secrets:       NEVER commit. Use env vars.
Licenses:      OK: MIT, Apache, BSD, CC0, ISC | NEVER: GPL, AGPL, SSPL, BUSL
Tests:         Add at least one per PR. flutter analyze clean.
Migrations:    Idempotent + rollback + UTC timestamp + staging dry-run
Medical data:  PII-strip before LLM. Encrypt at rest. Audit log every read.
PI logging:    Never log name+DOB together.
Wait on deps:  Don't start unless `Depends on:` agents are DONE.
Stuck >2hr:    Update status to BLOCKED with detail. OXBAR will reply.
```

---

— end of COORDINATION_PROTOCOL —
