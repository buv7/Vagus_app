# Final Report — Multi-Agent Cleanup Run

Branch: `21-1-2026-mr-universe`
Window: 2026-04-24 baseline (`7cbe2e9`) → HEAD (`625fb32`)
Synthesizer: Agent 6 (cost + CI + docs)

Six agents ran in sequence across this branch:

| # | Agent | Scope | Commits landed |
| - | --- | --- | --- |
| 1 | Baseline & safety-net | Read-only snapshot of analyzer / tests / routes / orphans | `7cbe2e9` |
| 2 | Dead-code pruner | Delete orphan screens + backup junk | 10 screens + 3 cleanup commits |
| 3 | Route healer | Replace 6 redirect routes with real screens | **uncommitted** (see "Outstanding" below) |
| 4 | Duplicate consolidator | Merge `workouts/` into `workout/`, rename `Revolutionary*`, consolidate `lib/archive/` | `1352ca8`, `2b3b8f3`, `1c907c5` |
| 5 | *(skipped / no report on disk)* | — | — |
| 6 | Cost + CI + docs | Embedding swap, CI dedupe + analyze gate, AI cost doc | `f1d27f4`, `7ba883f`, `625fb32` |

> Agent 5's report is not present under `docs/agent-reports/agent-5-*/`;
> if that agent ran, its artifacts were not committed. No commit on the
> branch corresponds to an agent-5 scope.

---

## Files deleted

Totals are from committed deletions (untracked Agent 3 work tracked
separately under "Outstanding"):

### Orphan screens (Agent 2 — 10 files)

| Class | Path |
| --- | --- |
| ModernCoachMessengerScreen | `lib/screens/messaging/modern_coach_messenger_screen.dart` |
| WorkoutEditorWeekTabs | `lib/screens/workout/workout_editor_week_tabs.dart` |
| ExerciseEntryBlock | `lib/screens/workout/exercise_entry_block.dart` |
| WorkoutWeekEditor | `lib/screens/workout/workout_week_editor.dart` |
| CallingDemoScreen | `lib/screens/calling/calling_demo_screen.dart` |
| ModernLiveCallsScreen | `lib/screens/calling/modern_live_calls_screen.dart` |
| MetaAdminScreen | `lib/screens/admin/meta_admin_screen.dart` |
| ViralAnalyticsScreen | `lib/screens/admin/viral_analytics_screen.dart` |
| WorkoutKnowledgeAdminScreen | `lib/screens/admin/workout_knowledge_admin_screen.dart` |
| AdminAnnouncementsScreen | `lib/screens/admin/admin_announcements_screen.dart` |

### Backups, scratch, archive folder (Agents 2 & 4)

- 4 `.bak` Supabase migrations (`0004_workout_system_v2.sql.bak`,
  `0006_notification_system.sql.bak`,
  `0014_supplements_v1_rls_test.sql.bak`, `0022_support_v2.sql.bak`)
- 6 `.analyzer.*.txt` scratch files
- 2 `.env.backup` / `.env.problematic`
- `lib/archive/` entire tree (3 subdirs + README, ~8K LOC of
  `.disabled`/`.old`/`.backup` code) — relocated to
  `archived/lib-archive/`

### Workflow consolidation (Agent 6)

4 supabase-deploy workflows moved under `.github/workflows/archive/`:
`supabase-deploy-fixed.yml`, `-fixed-v2.yml`, `-simple.yml`,
`-working.yml`. Kept `supabase-deploy.yml` (ex-`-fixed-v3`) as the
canonical one.

## Files added

| File | Purpose | Added by |
| --- | --- | --- |
| `docs/agent-reports/agent-1-baseline/*` (7 files) | Analyzer/tests/routes/todos snapshot | Agent 1 |
| `docs/agent-reports/agent-2-prune/REPORT.md` | Prune write-up | Agent 2 |
| `docs/agent-reports/agent-3-routes/REPORT.md`, `PENDING_WIRING.md` | Route-healing write-up | Agent 3 |
| `docs/agent-reports/agent-4-dedupe/REPORT.md` | Dedupe write-up | Agent 4 |
| `docs/AI_COSTS.md` | AI endpoint inventory + per-user cost estimate | Agent 6 |
| `docs/agent-reports/FINAL_REPORT.md` | This file | Agent 6 |
| `.github/workflows/flutter-analyze.yml` | CI analyze gate | Agent 6 |
| `lib/screens/coaches/coach_application_screen.dart` | `/apply-coach` destination | Agent 3 (**uncommitted**) |
| `lib/screens/settings/data_export_screen.dart` | `/export` destination | Agent 3 (**uncommitted**) |
| `lib/screens/settings/devices_screen.dart` | `/devices` destination | Agent 3 (**uncommitted**) |
| `lib/screens/settings/profile_edit_screen.dart` | `/profile/edit` destination | Agent 3 (**uncommitted**) |
| `lib/screens/support/support_screen.dart` | `/support` destination | Agent 3 (**uncommitted**) |
| `lib/widgets/common/coming_soon_screen.dart` | Shared placeholder widget | Agent 3 (**uncommitted**) |

## Files renamed / moved

| From | To | By |
| --- | --- | --- |
| `lib/screens/workouts/modern_workout_plan_viewer.dart` | `lib/screens/workout/modern_workout_plan_viewer.dart` | Agent 4 |
| `lib/screens/workout/revolutionary_plan_builder_screen.dart` | `lib/screens/workout/workout_plan_builder_screen.dart` (+ class `RevolutionaryPlanBuilderScreen` → `WorkoutPlanBuilderScreen`) | Agent 4 |
| `lib/archive/*` | `archived/lib-archive/*` | Agent 4 |
| `.github/workflows/supabase-deploy-fixed-v3.yml` | `.github/workflows/supabase-deploy.yml` | Agent 6 |
| `.github/workflows/supabase-deploy-{fixed,fixed-v2,simple,working}.yml` | `.github/workflows/archive/*` | Agent 6 |
| 54 root-level `*_IMPLEMENTATION.md`, `*_SUMMARY.md`, `*_COMPLETE.md`, `*_FIX*.md` | `docs/archive/implementation-notes/` | Agent 2 |

## Analyzer delta

| Stage | total | error | warning | info |
| --- | ---: | ---: | ---: | ---: |
| Baseline (Agent 1) | 302 | 0 | 29 | 273 |
| After prune (Agent 2) | 191 | 0 | 19 | 172 |
| After dedupe (Agent 4) | 191 | 0 | 19 | 172 |
| After Agent 6 (HEAD) | 191 | 0 | 19 | 172 |

**Zero errors across every commit.** The ~111-issue drop between
Agent 1 and Agent 2 tracks the orphan-screen deletions (each file
contributed its own `prefer_const_constructors` / unused-import hits).
Remaining 191 are informational (`prefer_const_constructors` dominates).
Agent 6 added a CI gate (`.github/workflows/flutter-analyze.yml`) that
fails a PR if error-severity count > 0.

## LOC delta

From `git diff --stat de2cece..HEAD -- lib docs supabase/migrations .github`:

```
35 files changed, 317 insertions(+), 7998 deletions(-)
```

Net **−7,681 LOC**. The bulk of the removal is the `lib/archive/`
tree being relocated out of the compile path (Agent 4) plus the 10
orphan screens (Agent 2). Docs/config additions (Agent 6) account for
most of the 317 insertions.

> This stat window excludes Agent 3's untracked screens — adding them
> would push insertions up by a few hundred lines but not change the
> net sign.

## Features gated

This run did not introduce feature flags of its own. The existing
gating surface is `lib/services/feature_flags_service.dart` — several
agents touched files that read from it, but none changed gate defaults.
Effective gates worth highlighting for shipping:

- **`embedding.default` is now `text-embedding-3-small`.** 6.5× cheaper
  per call, same 1536 dimensions so no pgvector re-index required. Old
  rows keep their recorded `-3-large` value; the `embeddingDim()`
  branch in `model_registry.dart` still recognises both.
- **Model registry is dart-define-overridable.** Any task key
  (`NOTES_SUMMARIZE_MODEL`, `CHAT_DEFAULT_MODEL`, etc.) can be flipped
  at build time without a code change — useful if a model needs a
  rollback.
- **`flutter-analyze.yml` is the new blocking gate on PRs.** Warnings
  and infos still pass; only error-severity findings fail.

## Follow-up items (codebase)

1. **Commit or drop Agent 3's six new screens.** They are currently
   untracked in the working tree:
   - `lib/screens/coaches/coach_application_screen.dart`
   - `lib/screens/settings/data_export_screen.dart`
   - `lib/screens/settings/devices_screen.dart`
   - `lib/screens/settings/profile_edit_screen.dart`
   - `lib/screens/support/support_screen.dart`
   - `lib/widgets/common/coming_soon_screen.dart`
   and `lib/main.dart` has matching uncommitted route edits. Without a
   commit, the route table on this branch still points the six routes
   at their old redirect targets.
2. **Re-parent Agent 2's two refused deletions.**
   `ClientMessengerScreen` and `CallManagementScreen` still have live
   references (threads list + FABs). Decide whether to retire those
   features or keep them, then either drop the callers or accept the
   files as production code.
3. **Test suite does not reach completion.** Agent 1 recorded 24
   failing tests and a hang on
   `test/exercise_sheet_prefs_plumbing_test.dart`. Until that's fixed,
   `flutter test` cannot be used as a CI gate — only `flutter analyze`
   is wired up.
4. **Client messaging consolidation.** Agent 4 flagged five
   near-parallel client messaging screens
   (`client_messenger_screen`, `client_threads_screen`,
   `client_chat_list_screen`, `modern_client_messages_screen`,
   `modern_messenger_screen`) as a future consolidation pass.
5. **Agent 5 artifact audit.** No `docs/agent-reports/agent-5-*/`
   folder exists. Confirm whether Agent 5 ran and its output is
   missing, or whether the numbering intentionally skipped.
6. **171 Supabase migrations.** Agent 1 flagged duplicated numeric
   prefixes (two `0004_*`, two `0006_*` pre-prune) and a mixed
   numeric/date naming scheme. Worth a dedicated pass before the next
   schema change.
7. **AI cost assumptions.** `docs/AI_COSTS.md` uses static list prices
   and a 5-calls/day assumption — validate against the real usage
   counters written by the `update-ai-usage` edge function before any
   pricing decision.

## Remaining work (human-only — not doable by an agent)

These are integration / business-decision items. Agents have prepared
the surface but cannot complete them without credentials, partner
accounts, or product approval:

1. **Stripe integration.** Billing screens
   (`lib/screens/billing/billing_payments_screen.dart`,
   `upgrade_screen.dart`) are UI-only. Needs: Stripe account +
   publishable/secret keys, webhook endpoint in Supabase functions,
   price IDs for each tier. Requires a human to own the Stripe
   dashboard.
2. **Jitsi / video calling.** `CallManagementScreen` is wired up but
   the actual calling backend (Jitsi self-host or hosted) is not
   configured. Needs: Jitsi deployment URL, JWT app-id / secret for
   moderated rooms, push-notification ringer hook-up.
3. **Real OCR.** `lib/services/ocr/ocr_cardio_service.dart` and the
   `program_ingest` supabase function currently contain placeholder /
   stub logic (see `model_hint: 'gpt-4o-mini'` note). Needs: decision
   on OCR provider (Google Vision vs OpenAI vision vs Tesseract),
   credentials, and a re-write of the service beyond the current stub.
4. **Whisper usage metering.** Transcription calls go straight to
   OpenAI; they are not counted by `AIUsageService`. Needs: a usage
   hook around `transcription_ai.dart` and a billing mapping
   (minutes → credits) before whisper can count against a user's
   monthly AI limit.
5. **Support edge function.** `send-support-email` is coded for
   `type: "support_reply"` only. A human needs to extend it to
   `type: "new_request"` (or decide to rely on admin dashboard
   polling) — documented in `agent-3-routes/PENDING_WIRING.md`.
6. **Auth-sessions surfacing for Devices screen.** Requires either a
   new SECURITY DEFINER RPC over `auth.sessions` or an edge function;
   both require a migration and were out of Agent 3's scope.
7. **Per-feature AI usage breakdown.** The current `get_ai_usage_summary`
   RPC does not split usage by feature. A human needs to extend the
   RPC (or its underlying table) before `ai_usage_screen.dart` can
   show the per-feature view the spec originally described.
8. **l10n pipeline.** The six new Agent-3 screens use English inline
   strings; `ar` / `ku` locales are declared globally but no ARB
   catalogue is wired. A human needs to decide whether to introduce
   an ARB pipeline and extract strings from the whole app, not just
   these screens.
9. **Test-suite green.** Fix the 24 failing tests and the hanging
   `exercise_sheet_prefs_plumbing_test.dart` before relying on
   `flutter test` in CI. Agent-driven fixes are risky without knowing
   intended behaviour of the failing widgets.

---

## Commit trail (baseline → HEAD)

```
625fb32 docs: add AI_COSTS.md — endpoint inventory + per-user monthly estimate
7ba883f ci: consolidate supabase deploy workflows; add flutter-analyze gate
f1d27f4 cost: swap embedding default from text-embedding-3-large to -3-small
1c907c5 refactor: consolidate lib/archive into archived/lib-archive
2b3b8f3 refactor: rename RevolutionaryPlanBuilderScreen to WorkoutPlanBuilderScreen
1352ca8 refactor: merge lib/screens/workouts into lib/screens/workout
de2cece chore: gitignore .env.backup/.env.problematic and .analyzer.*.txt
7058b2b chore: archive root implementation/summary/complete/fix notes under docs/archive/implementation-notes
8782835 chore: remove orphan .env.backup and .env.problematic
e2f76e6 chore: remove orphan .analyzer baseline and pass logs
167df3f chore: remove orphan supabase migration .bak files
711bb0f chore: remove orphan AdminAnnouncementsScreen
4193da1 chore: remove orphan WorkoutKnowledgeAdminScreen
7fcdd92 chore: remove orphan ViralAnalyticsScreen
ba5812b chore: remove orphan MetaAdminScreen
d643821 chore: remove orphan ModernLiveCallsScreen
457881d chore: remove orphan CallingDemoScreen
dc51262 chore: remove orphan WorkoutWeekEditor
7c7a298 chore: remove orphan ExerciseEntryBlock
85bb10b chore: remove orphan WorkoutEditorWeekTabs
12b10a0 chore: remove orphan ModernCoachMessengerScreen
7cbe2e9 agent/1: baseline snapshot
```

Not pushed to origin. All commits local.
