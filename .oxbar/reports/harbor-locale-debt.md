# HARBOR — Locale Debt Report

**Generated:** 2026-04-28  
**Mode:** Bootstrap (TONGUE PENDING — app_en.arb does not yet exist)  
**Scope:** All open PRs as of 2026-04-28  
**PRs scanned:** #7, #8, #14, #17, #21, #22, #24, #27, #28

---

## Summary

| PR | Agent | UI strings hardcoded | Severity | Advisory posted |
|----|-------|---------------------|----------|-----------------|
| #22 | TRIAL | ~15 | High | ✅ #issuecomment-4335877487 |
| #24 | DANGERZONE | ~15 | High (safety-critical) | ✅ #issuecomment-4335880102 |
| #27 | UX-ADAPT | ~14 | High | ✅ #issuecomment-4335881751 |
| #28 | TIER v2 | ~8 | Medium | ✅ #issuecomment-4335883431 |
| #17 | SIGNAL v2 | ~9 | Medium | ✅ #issuecomment-4335884995 |
| #14 | EX-MEDIA | ~2 (error msgs) | Low | — |
| #21 | IAP-GOOGLE | ~0 (server-side only) | None | — |
| #8 | GUARDIAN | ~1 (snackbar) | Low | — |
| #7 | MUSIC-PURGE | ~1 | Low | — |

**Total estimated ARB keys needed across open PRs: ~65**

---

## Catalogued keys by PR

### PR #22 — TRIAL
```
trialStartedTitle
trialStartedBody
trialEndedTitle
trialEndedBody
trialChoosePlanCta
trialMoveToFreeCta
trialReleaseClientsFirst
trialReleaseClientsCta          (pluralised: "Release N client(s) & continue")
trialDowngradingLabel
trialNowOnFreeTitle
trialNowOnFreeBody
trialExitSurveyTitle
trialExitSurveySubtitle
trialExitReasonPrice
trialExitReasonFeatures
trialExitReasonFit
trialExitReasonOther
trialExitSurveyFeedbackHint     ("What feature would change your mind?")
trialExitSurveyOtherHint        ("Any other feedback?")
trialBannerCta                  ("Your trial ends in N days — choose a plan")  ← plural-aware
generalGotIt
generalSubmitAndContinue
generalSkip
```

### PR #24 — DANGERZONE ⚠️ safety-critical
```
dangerZoneDeactivateTitle
dangerZoneDeactivateBody
dangerZoneDeactivateGracePeriod
dangerZoneDeletionScheduled
dangerZoneDeleteTitle
dangerZoneDeleteBody
dangerZoneDeleteGracePeriod
dangerZoneTypeDeleteLabel       ("Type DELETE to confirm")
dangerZoneAccountRestored
dangerZoneEnterPassword
dangerZoneWrongPassword
dangerZoneDataProfile
dangerZoneDataMessages
dangerZoneDataPosts
dangerZoneDataLab
dangerZoneDataPhotos
dangerZoneDataFiles
dangerZonePermanentlyDeleted
generalSomethingWentWrong
generalCancel
```

### PR #27 — UX-ADAPT
```
uxModeSimple
uxModeDefault
uxModeInsane
uxModeSimpleDesc
uxModeDefaultDesc
uxModeInsaneDesc
uxInterfaceModeLabel
uxInterfaceComplexityLabel
uxManualOverrideActive
uxAutoMode                      ("Auto ({mode}) — based on {hours}")  ← placeholders
uxResetToAuto
uxSimplifyDialogTitle
uxSimplifyDialogBody
uxSimplifyKeep
uxSimplifySwitch
uxProgressMsgBeginner
uxProgressMsgPower
uxProgressMsgUpdate
uxShareCardGenerated
generalMaybeLater
```

### PR #28 — TIER v2
```
tierFree
tierPro
tierUltimate
tierClientLimitReached          (placeholders: {limit}, {plan})
tierFeatureLabWorkUpsell
tierFeaturePoseUpsell
tierFeatureWearableUpsell
tierUpgradeCta                  (placeholder: {plan})
generalMaybeLater               (shared with UX-ADAPT)
```

### PR #17 — SIGNAL v2
```
settingsNotificationsTitle
notifSectionActivityTraining
notifWorkoutReminders
notifWorkoutRemindersSubtitle
notifStreakReminders
notifStreakRemindersSubtitle
generalPreferencesSaved
notifTestPushSent
notifTestPushFailed
generalSave
```

---

## Actions for TONGUE

When you extract strings from the codebase, these PRs are the highest-priority source files:

1. `lib/features/trial/` — TRIAL PR #22
2. `lib/features/account/` (deactivate/delete screens) — DANGERZONE PR #24
3. `lib/features/ux_adapt/` — UX-ADAPT PR #27
4. `lib/features/tier/` — TIER PR #28
5. `lib/features/notifications/settings_screen.dart` — SIGNAL PR #17

All advisory comments link to this report. TONGUE should reference the suggested key names above for consistency.

---

## Actions for POLYGLOT-AR and POLYGLOT-KU

- **DANGERZONE strings are safety-critical** — deletion and deactivation warnings must be reviewed by a native speaker. Do not use machine translation without human validation for these.
- **Plural-aware strings** (e.g. `trialBannerCta`, `trialReleaseClientsCta`) require ICU plural syntax in ARB.
- **Interpolated strings** (e.g. `tierClientLimitReached`, `uxAutoMode`) require placeholder syntax — translate the surrounding text, preserve `{param}` tokens unchanged.

---

## Status

HARBOR will re-scan on each PR merge. Once TONGUE's PR merges (`app_en.arb` appears in `main`), advisory mode ends and enforce mode begins — all future PRs will be blocked if they add untranslated strings.
