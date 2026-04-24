# Agent 4: Duplicate Consolidator — Report

Branch: `21-1-2026-mr-universe`
Baseline HEAD: `de2cece`
Build verification: `flutter analyze` only (no Android SDK on this
host, so `flutter build apk --debug` returns
`No Android SDK found. Try setting the ANDROID_HOME environment
variable.` — this affects every phase, not just one.) Pre-existing
analyzer issues on baseline: **191 info/warning, 0 error**. My
changes kept that count stable and unchanged.

---

## Phase 1 — workouts/ → workout/ merge

**Commit:** `1352ca8`

**Before**
- `lib/screens/workouts/` — 1 file (`modern_workout_plan_viewer.dart`)
- `lib/screens/workout/`  — 8 files + `widgets/` subdir

**After**
- `lib/screens/workouts/` — **deleted**
- `lib/screens/workout/`  — 9 files + `widgets/` subdir

No filename collision (only one file to move).

**Imports updated (5):**
1. `lib/widgets/fab/simple_glassmorphism_fab.dart`
2. `lib/screens/workout/coach_workout_dashboard_screen.dart`
3. `lib/screens/workout/client_workout_dashboard_screen.dart`
4. `lib/screens/nav/main_nav.dart`
5. `lib/screens/dashboard/modern_client_dashboard.dart`

Documentation references in markdown/txt (audit docs,
`screens_by_module.txt`) were intentionally **not** touched — those
are historical audit artifacts and rewriting them changes reporting,
not behavior.

`flutter analyze`: 191 issues, 0 errors.

---

## Phase 2 — RevolutionaryPlanBuilderScreen → WorkoutPlanBuilderScreen

**Commit:** `2b3b8f3`

**File rename (git mv):**
- `lib/screens/workout/revolutionary_plan_builder_screen.dart`
  → `lib/screens/workout/workout_plan_builder_screen.dart`

**Class rename inside the file (6 occurrences — class, ctor, State
binding, private state class, State parameter):**
- `RevolutionaryPlanBuilderScreen` → `WorkoutPlanBuilderScreen`
- `_RevolutionaryPlanBuilderScreenState` →
  `_WorkoutPlanBuilderScreenState`

**Callers updated (4 files, 5 instantiations):**
| File | Import | Instantiation(s) |
| --- | --- | --- |
| `lib/main.dart` | ✓ | `/workout-editor` route in `onGenerateRoute` |
| `lib/widgets/fab/simple_glassmorphism_fab.dart` | ✓ | 1 |
| `lib/widgets/fab/glassmorphism_fab.dart` | ✓ | 1 |
| `lib/screens/plans/plans_dashboard_screen.dart` | ✓ | 2 |

Found 4 imports (not 3 as the prompt estimated) because
`glassmorphism_fab.dart` also imports the builder alongside its
`simple_` sibling.

Doc references in `*.md` and `docs/agent-reports/agent-1-baseline/`
audit artifacts were intentionally left alone.

`flutter analyze`: 191 issues, 0 errors.

Note: `lib/main.dart` also had uncommitted edits from Agent 3
(route-table wiring). Isolated via `git stash push -- lib/main.dart`,
applied just my 2 rename hunks, committed, then `git stash pop`ed
Agent 3's work back. `2b3b8f3` contains only my rename changes.

---

## Phase 3 — Coach messaging screens review

**Decision: KEEP BOTH — they are NOT duplicates.**

They form a standard list/detail pair:

| Screen | Role | External refs |
| --- | --- | --- |
| `coach_threads_screen.dart` (`CoachThreadsScreen`) | Inbox: list of threads, per-client previews, unread counts, search. | `lib/main.dart` (`/messages/coach` route), `lib/widgets/coach/quick_actions_grid.dart`. |
| `coach_messenger_screen.dart` (`CoachMessengerScreen`) | Single-thread chat: messages, AI draft reply, QuickBook, attachments, voice, pin panel, in-thread search. Takes `client: Map<String,dynamic>`. | Only `coach_threads_screen.dart` (tapping a thread opens it). |

Removing either would break a distinct user flow:
- Dropping `CoachThreadsScreen` leaves no entry point / inbox.
- Dropping `CoachMessengerScreen` leaves the inbox with nowhere to
  navigate on tap and loses ~900 lines of chat functionality.

**No changes made in Phase 3; no commit.**

Potential future consolidation (out of scope here): the *client*
side has three near-parallel screens
(`client_messenger_screen`, `client_threads_screen`,
`client_chat_list_screen`, `modern_client_messages_screen`,
`modern_messenger_screen`) that likely *do* overlap. Flagging for a
future cleanup pass — do not bundle into this agent's scope.

---

## Phase 4 — Archive folder consolidation

**Commit:** TBD (see log below).

**Before**
- `lib/archive/`      — `backup/`, `disabled/`, `unused_cache/`, `README.md`
- `archived/`         — `coach_profile_old_20251011/`, `disconnected/`, `documentation/`, `shims/`, `stubs/`, `tests/`, `README.md`

**After**
- `lib/archive/`        — **deleted**
- `archived/lib-archive/` — contains `backup/`, `disabled/`, `unused_cache/`, `README.md` from the old `lib/archive/`

Stale-import check: `grep -r "lib/archive/\|from 'archive/"` under
`lib/` after the move — **no references.** Consistent with the rule
that archive content must be unreferenced.

`flutter analyze`: 191 issues, 0 errors.

---

## Deferred / out-of-scope

- Client messaging screens (see Phase 3 note) — multiple
  near-parallel implementations; warrants its own consolidation pass.
- The 191 analyzer info/warnings in the baseline (`prefer_const_constructors`,
  `deprecated_member_use` for `withOpacity`, unused locals) are
  unchanged by this work.
- `flutter build apk --debug` could not run in this environment
  (missing Android SDK). If CI runs it downstream and fails, revert
  the offending phase per the guardrail protocol.

## File counts

| Location | Before | After | Delta |
| --- | --- | --- | --- |
| `lib/screens/workouts/` | 1 | — (deleted) | −1 folder |
| `lib/screens/workout/` | 8 + widgets | 9 + widgets | +1 (moved in) / 0 net rename |
| `lib/archive/` | 3 subdirs + README | — (deleted) | −1 folder |
| `archived/lib-archive/` | — | 3 subdirs + README | +1 folder |

## Commits introduced

| SHA | Phase | Summary |
| --- | --- | --- |
| `1352ca8` | 1 | merge `lib/screens/workouts` into `lib/screens/workout` |
| `2b3b8f3` | 2 | rename `RevolutionaryPlanBuilderScreen` → `WorkoutPlanBuilderScreen` |
| phase 4 (tip of branch at time of this report) | 4 | move `lib/archive/*` to `archived/lib-archive/` |
