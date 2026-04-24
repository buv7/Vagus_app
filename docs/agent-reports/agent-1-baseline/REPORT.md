# Agent 1 — Baseline & Safety-Net Report

**Repo:** vagus_app (Flutter + Supabase)
**Branch at baseline:** `21-1-2026-mr-universe`
**Head commit:** `9383fdd last update to messages screen settings`
**Generated:** 2026-04-24

This is a read-only snapshot of the repo. No source files were modified.
All raw artifacts live alongside this report under
`docs/agent-reports/agent-1-baseline/`.

---

## 1. `flutter analyze` results

- **Command:** `flutter analyze` (81.4 s)
- **Exit code:** 0 (no blocker errors — analyzer finished cleanly)
- **Total issues reported:** **302**
- **Raw output:** `analyze.txt`

### Severity breakdown

| severity | count |
|----------|-------|
| error    |   0   |
| warning  |  29   |
| info     | 273   |

### Top lint rules

| count | rule |
|-------|------|
| 209 | `prefer_const_constructors` |
|  27 | `prefer_final_locals` |
|  16 | `unawaited_futures` |
|  12 | `unused_import` |
|   7 | `unused_local_variable` |
|   6 | `use_build_context_synchronously` |
|   6 | `unnecessary_import` |
|   6 | `prefer_final_fields` |
|   4 | `unused_element` |
|   3 | `unused_field` |
|   3 | `unnecessary_null_comparison` |
|   2 | `prefer_const_constructors_in_immutables` |
|   1 | `deprecated_member_use` |

**Take:** zero errors, zero deprecation blockers to speak of. ~70 % of
the analyzer noise is `prefer_const_constructors` — low-value churn if
automated. The 16 `unawaited_futures` and 6
`use_build_context_synchronously` warnings are the ones worth a human
eye before any refactor.

---

## 2. `flutter test` results

- **Command:** `flutter test`
- **Raw output:** `tests.txt`
- **Progress at stall:** 174 passing, 24 failing, stuck looping on
  `test/exercise_sheet_prefs_plumbing_test.dart`
  ("ExerciseDetailSheet Preferences Plumbing loads preferences on
  initialization").
- **Status:** test runner did **not** reach clean completion within
  the monitoring window; the reporter kept re-emitting the same line
  for the same test with no state change. This is itself a finding —
  the suite cannot currently be executed to green end-to-end in CI.
- **Confirmed failures before stall:** 24 (see `tests.txt` for
  individual `[E]` markers; the last concrete failure recorded is
  `test/widgets/nutrition/macro_progress_bar_test.dart` —
  "includes semantic label for accessibility").

**Take:** before any safety-net refactor, the test infrastructure
needs a pass: (a) 24 genuine failures, and (b) at least one test that
appears to hang the runner. Treat test green-ness as a prerequisite,
not a checkbox, for downstream agents.

---

## 3. File inventory

Full details in `file-inventory.txt`.

- **Total `.dart` files under `lib/`:** 650
- **`lib/` size on disk:** 9.7 MB
- **Top-level lib/ folders:** 10 (screens, services, widgets,
  components, models, utils, theme, data, archive, config)
- **Supabase migrations (`supabase/migrations/`):** 171 files

### Lib folder sizes

| files | size | folder |
|------:|-----:|--------|
| 216 | 4524 K | `lib/screens/` |
| 159 | 2058 K | `lib/services/` |
| 147 | 1820 K | `lib/widgets/` |
|  51 |  468 K | `lib/components/` |
|  50 |  450 K | `lib/models/` |
|  13 |   96 K | `lib/utils/` |
|   8 |   93 K | `lib/theme/` |
|   3 |   24 K | `lib/data/` |
|   1 |  316 K | `lib/archive/` (mostly `.disabled`/`.old` files) |
|   1 |    8 K | `lib/config/` |

### Screen folders (33 subfolders + 1 root file, 216 files total)

Top five:
- `nutrition/` — 42
- `admin/` — 38
- `coach/` — 18
- `workout/` — 17
- `settings/` — 12

**Eighteen screen folders contain exactly one `.dart` file.** Combined
with the route redirects (below), many of these look like
placeholders.

---

## 4. TODO / FIXME / stubbed / mock markers

- **Raw output:** `todos.txt` (638 matching lines, `file:line` format,
  case-insensitive).
- **Inside `lib/archive/`:** 61 occurrences (legacy/disabled code —
  expected).
- **Everywhere else in `lib/`:** 578 occurrences across live code.

**Take:** ~580 live TODO-class markers is substantial for a 650-file
codebase. The density and the word "mock" being a common match mean a
chunk of business logic is almost certainly still placeholder code.

---

## 5. Route map (`lib/main.dart`)

Full map in `routes.txt`. Headline numbers:

- **Static routes declared:** 20
- **Dynamic routes (`onGenerateRoute`):** 1 (`/workout-editor`)
- **Distinct destination widgets:** 12
- **Redirect / placeholder routes (multiple names, one screen):** 8

### Dead-redirect clusters

- **`UserSettingsScreen` is the target of 5 routes:**
  `/settings`, `/profile/edit`, `/devices`, `/export`, `/support`.
  The last four are stub redirects to the settings page — they need
  dedicated screens or the route entries should be removed.

- **`AdminScreen` is the target of 3 routes:**
  `/admin`, `/ai-usage`, `/apply-coach`. `/ai-usage` and
  `/apply-coach` are placeholder redirects, not admin concerns.

- **`ClientThreadsScreen` is the target of 2 routes:**
  `/messages/client` and `/messages`. The comment in `main.dart`
  flags this as "Default to client view" — a coach hitting
  `/messages` will land on the wrong screen.

---

## 6. Orphan screen candidates

Full analysis in `orphan-candidates.txt`.

**Method:** for each of the 216 files under `lib/screens/`, grep the
rest of `lib/` (excluding `lib/archive/`) for `import` statements
referencing either its relative path or its basename.

| external-import count | screen files |
|----------------------:|-------------:|
| 0 | 61 |
| 1 | 95 |
| 2 | 33 |
| 3 | 16 |
| 4 |  5 |
| 5 |  4 |
| 8 |  1 |
| 10 | 1 |

**156 of 216 screens (72 %) have ≤1 external import.** Several of
those will be referenced by dynamic navigation or tests, so this is a
candidate list, not a hit list. Notable duplications flagged in
`orphan-candidates.txt`:

- Two QR-scanner screens in `screens/coaches/` with 0 refs each.
- `screens/dashboard/home_screen.dart` (0 refs) — the real home is
  `AuthGate → AnimatedSplashScreen`.
- Several `modern_*` screens (menu, messenger, live calls) with 0 refs
  — an unfinished redesign that was never wired into routing.
- Two parallel profile-editor trees (`screens/coach/widgets/` and
  `screens/coach_profile/widgets/`) both at 0 refs.

---

## Overall baseline summary

| metric | value |
|--------|------:|
| `.dart` files in `lib/` | 650 |
| `lib/` size | 9.7 MB |
| Screen files | 216 (across 33 folders) |
| Supabase migrations | 171 |
| Analyzer issues | 302 (0 error / 29 warn / 273 info) |
| Tests passing / failing (at stall) | 174 / 24 |
| Test suite reaches completion | **no** (hangs on exercise_sheet_prefs_plumbing_test) |
| TODO/FIXME/mock lines (live code) | 578 |
| Routes (static) | 20, of which 8 are redirects to 3 screens |
| Zero-ref screen candidates | 61 |
| ≤1-ref screen candidates | 156 (72 %) |

### Risks / watch-items for downstream agents

1. **Test suite is not currently green or stable.** Fix failures and
   the hanging test before using `flutter test` as a safety net.
2. **High orphan-candidate count.** Manual verification required per
   file (Navigator.pushNamed strings, tests) before deletion.
3. **Route table encodes stubs as redirects.** Cleaning `main.dart`
   and building real screens for `/profile/edit`, `/devices`,
   `/export`, `/support`, `/ai-usage`, `/apply-coach` is a discrete
   workstream.
4. **Archive folder** (`lib/archive/`) contains 316 KB of
   `.disabled`/`.old` code not compiled — safe to ignore for now,
   review for deletion separately.
5. **Migration count (171)** is high and mixes numeric and
   date-prefixed filenames; there is at least one duplicate numeric
   prefix in play (two `0004_*` and two `0006_*` files — one is
   `.bak`). Worth auditing separately before any schema work.

---

## Deliverables created under `docs/agent-reports/agent-1-baseline/`

- `REPORT.md` — this file
- `analyze.txt` — full `flutter analyze` output (exit 0, 302 issues)
- `tests.txt` — full `flutter test` output up to the hang point
- `todos.txt` — all TODO/FIXME/stubbed/mock hits with `file:line`
- `routes.txt` — route map with duplicate-target annotations
- `file-inventory.txt` — per-folder `.dart` counts and sizes
- `orphan-candidates.txt` — screens with ≤1 external import
