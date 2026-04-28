# PRISM status: IN-PROGRESS

**Started:** 2026-04-28
**Last update:** 2026-04-28
**Branch:** agent/prism-init
**Mission:** Visual diff CI + golden tests + token enforcement lint

## Current state
Bootstrap complete. PR open for review.

## Progress
- [x] Survey repo: theme tokens at lib/theme/design_tokens.dart (PALETTE pending)
- [x] Add golden_toolkit ^0.15.0 (MIT confirmed) to dev_dependencies
- [x] Author test/golden/prism_harness.dart — PrismTestApp + screenGoldens helper
- [x] Author test/golden/golden_test.dart — 30 screens × 3 locales = 90 goldens
      - 27 mapped to real screen classes (with stub args where needed)
      - 3 PlaceholderScreens: periods_log, lab_work, sleep_view (pending those agents)
- [x] Author .github/workflows/prism.yml — golden_diff + token_lint + rtl_check jobs
- [x] Add PRISM token enforcement docs to analysis_options.yaml
- [ ] Goldens baseline committed (requires first --update-goldens run in CI)
- [ ] PALETTE merges tokens.dart → tighten token_lint to reference tokens.dart paths
- [ ] RTL pass (waiting on HARBOR translations via .oxbar/handoffs/HARBOR-to-PRISM.md)

## Files touched
- pubspec.yaml (added golden_toolkit)
- test/golden/prism_harness.dart (new)
- test/golden/golden_test.dart (new)
- .github/workflows/prism.yml (new)
- analysis_options.yaml (PRISM token docs added)
- .oxbar/agent-status/PRISM.md (this file)

## Blockers
- Golden baseline images must be generated with `flutter test --update-goldens`
  on a macOS/Linux runner before the golden_diff job can compare. Expected to be
  done as part of the PR merge workflow.
- PALETTE (tokens.dart) is still PENDING — token_lint currently targets DesignTokens.
  When PALETTE merges, update the grep exclusion path in prism.yml token_lint jobs.

## Questions for OXBAR
- Should the golden_diff job be a required status check (blocking merge) from day 1,
  or start as advisory until the baseline is established?
- Confirm: periods_log / lab_work / sleep_view screens — which agent owns them
  and when do they land? PRISM will update PlaceholderScreens on handoff.

## Next step
Merge PR [PRISM] Visual diff CI + golden tests + token enforcement lint.
Then: watch all incoming PRs and enforce token + RTL policy.
