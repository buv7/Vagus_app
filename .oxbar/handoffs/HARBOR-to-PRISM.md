# Handoff from HARBOR to PRISM

**Date:** 2026-04-28
**PR:** (pending — HARBOR bootstrap PR)
**Trigger:** This handoff becomes active once POLYGLOT-AR or POLYGLOT-KU marks their PR merged (AR/KU translations land in `lib/l10n/app_ar.arb` or `lib/l10n/app_ku.arb`).

---

## What's now available

- `lib/l10n/app_ar.arb` — Arabic translations (once POLYGLOT-AR merges)
- `lib/l10n/app_ku.arb` — Kurdish-Sorani translations (once POLYGLOT-KU merges)
- `lib/l10n/glossary.json` — 200 fitness terms with EN/AR/KU equivalents (seeded by HARBOR, reviewed by POLYGLOT agents)

## Your task: RTL screenshot pass

When either `app_ar.arb` or `app_ku.arb` lands on `main`, PRISM must:

1. Build the app with the new locale active.
2. Screenshot **every screen listed below** in both AR and KU locales.
3. Flag any RTL layout bug in a GitHub issue tagged `rtl-bug`, assigned to PRISM for fix.
4. Write your issue list to `.oxbar/reports/prism-rtl-pass-<date>.md`.

---

## Top 30 screens to screenshot (AR + KU locales)

Screenshot order follows user journey — highest-traffic screens first.

| # | Screen | Route / file hint | RTL risks |
|---|--------|-------------------|-----------|
| 1 | Onboarding splash | `onboarding/` | Text alignment, logo position |
| 2 | Login / Sign-up | `auth/login` | Email field direction, button labels |
| 3 | Home / Dashboard | `home/` | Card layout, stat tiles, greeting text |
| 4 | Workout list | `workout/list` | List item text, badges, icons |
| 5 | Workout detail | `workout/detail` | Exercise order, set/rep labels |
| 6 | Active workout timer | `workout/active` | Timer direction, rest countdown |
| 7 | Exercise library | `exercise/library` | Grid/list alignment, search bar |
| 8 | Exercise detail | `exercise/detail` | Video overlay text, muscle diagram labels |
| 9 | Nutrition tracker | `nutrition/tracker` | Macro bars (LTR progress bars need mirroring), labels |
| 10 | Meal planning | `nutrition/plan` | Day headers, meal cards |
| 11 | Body measurements | `measurements/` | Chart axis labels, unit suffix placement |
| 12 | Progress charts | `progress/charts` | X-axis date direction, legend alignment |
| 13 | Coach messaging | `messaging/` | Chat bubbles (sender/receiver sides must flip for RTL) |
| 14 | Session booking | `booking/` | Calendar grid (weekday order, Today marker) |
| 15 | Profile | `profile/` | Avatar placement, bio text |
| 16 | Settings | `settings/` | List tile arrow direction, toggle alignment |
| 17 | Locale / language picker | `settings/locale` | Checkmark position, language name rendering |
| 18 | Goal setting | `goals/` | Input fields, slider |
| 19 | Notifications | `notifications/` | Timestamp alignment, action button side |
| 20 | Photo progress | `progress/photos` | Gallery grid, comparison overlay |
| 21 | Body weight log | `progress/weight` | Chart, entry form |
| 22 | Check-in form | `check_in/` | Multi-field form field order |
| 23 | Subscription / pricing | `subscription/` | Price display (currency symbol position), plan cards |
| 24 | Workout history | `history/` | Date group headers, duration labels |
| 25 | Rest timer overlay | (modal) | Countdown digits, skip button |
| 26 | Exercise tutorial (video) | (modal/overlay) | Caption text, progress bar |
| 27 | Leaderboard | `leaderboard/` | Rank numbers, name alignment |
| 28 | Community / feed | `feed/` | Post cards, like/comment row |
| 29 | Media library | `media/` | Grid, filename truncation |
| 30 | Subscription management | `subscription/manage` | Renewal date, cancel button placement |

---

## RTL layout checklist (for each screen)

Check every item below. If any fail, open a GitHub issue:

- [ ] **Text alignment** — all body text is right-aligned in AR/KU, not hardcoded `textAlign: TextAlign.left`
- [ ] **Input fields** — text direction is RTL; cursor starts at right
- [ ] **List tiles** — leading/trailing widgets are swapped (icon on right, chevron on left)
- [ ] **Icons** — directional icons (back arrow, chevron, play/forward) are mirrored via `Directionality` or `Transform.scale(scaleX: -1)`
- [ ] **Progress bars** — fill direction is left-to-right visually (NOT reversed in RTL — progress bars are not mirrored per BIDI spec)
- [ ] **Charts** — X-axis runs left-to-right (time always flows L→R regardless of locale)
- [ ] **Chat bubbles** — sender on LEFT for RTL (sender's message originates from the right side of the conversation in LTR; flip logically, not spatially)
- [ ] **Numeric values** — displayed in Western Arabic numerals (٠١٢ / ۰۱۲ NOT required unless explicitly requested)
- [ ] **Text overflow** — Arabic/Kurdish strings are typically longer than EN; no overflow/clipping at screen edges
- [ ] **Padding / margin** — no hardcoded `EdgeInsets.only(left: …)` where `EdgeInsetsDirectional.only(start: …)` should be used
- [ ] **Scaffold / drawer** — drawer opens from right side in RTL
- [ ] **BottomNavigationBar** — item order mirrors for RTL (first item on right)

---

## How to build in a locale

```bash
# Run in AR locale on a connected device or emulator
flutter run --dart-define=FORCE_LOCALE=ar

# Run in KU locale
flutter run --dart-define=FORCE_LOCALE=ku
```

If `FORCE_LOCALE` is not wired up yet, ask TONGUE for the locale-override mechanism.

## Severity guide for issues

| Severity | Example | Action |
|----------|---------|--------|
| **P0 — blocker** | Text cut off, overlapping, unreadable | Block the locale PR from merging until fixed |
| **P1 — high** | Wrong icon direction, drawer on wrong side | Fix before launch |
| **P2 — medium** | Minor padding asymmetry, icon not mirrored | Fix in next sprint |
| **P3 — low** | Cosmetic preference, debate on mirroring | Log and defer |

## Caveats

- HARBOR authors this handoff but does NOT perform the screenshots — that is PRISM's domain.
- If `flutter gen-l10n` fails after translations land, ping HARBOR (check `.oxbar/agent-status/HARBOR.md`).
- Screenshots should use a standard device profile: Pixel 5 (Android) and iPhone 14 (iOS) equivalents in the emulator.
- If a screen does not yet exist (feature not implemented), mark it as `N/A — not yet built` in your report.
