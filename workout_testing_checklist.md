# Workout System - Manual Testing Checklist

Comprehensive manual testing checklist for all workout features.

**Version:** 1.0
**Last Updated:** 2024-01-15

---

## Table of Contents

1. [Setup & Authentication](#setup--authentication)
2. [Coach Features](#coach-features)
3. [Client Features](#client-features)
4. [AI Features](#ai-features)
5. [Analytics & Reports](#analytics--reports)
6. [Notifications](#notifications)
7. [Edge Cases](#edge-cases)
8. [Accessibility](#accessibility)
9. [Performance](#performance)
10. [Cross-Platform](#cross-platform)

---

## Setup & Authentication

### Pre-Testing Setup
- [ ] Fresh database with test data loaded
- [ ] Test accounts created (coach + 2 clients)
- [ ] All environment variables set
- [ ] OneSignal configured
- [ ] AI service credentials valid

### Login & Permissions
- [ ] Coach can log in
- [ ] Client can log in
- [ ] Coach sees coach-specific features
- [ ] Client sees client-specific features
- [ ] Proper role-based access control

---

## Coach Features

### 1. Plan Creation

#### Basic Plan Creation
- [ ] Navigate to "Create Workout Plan"
- [ ] Enter plan name: "8-Week Hypertrophy Test"
- [ ] Select goal: Hypertrophy
- [ ] Set total weeks: 8
- [ ] Assign to test client
- [ ] Save plan
- [ ] **Verify:** Plan appears in coach's plan list
- [ ] **Verify:** Plan appears in client's dashboard

#### Week Management
- [ ] Open created plan
- [ ] Click "Add Week"
- [ ] **Verify:** Week 1 is created with correct dates
- [ ] Click "Duplicate Week"
- [ ] **Verify:** Week 2 is created with same structure
- [ ] Edit week 2 name to "Deload Week"
- [ ] Mark week 2 as deload
- [ ] **Verify:** Deload indicator shows

#### Day Management
- [ ] Open Week 1
- [ ] Click "Add Day"
- [ ] Enter day label: "Push Day"
- [ ] Set date: Tomorrow
- [ ] Save day
- [ ] **Verify:** Day appears in week
- [ ] Add 4 more days (Pull, Legs, Upper, Lower)
- [ ] **Verify:** All 5 days listed
- [ ] Reorder days by drag-and-drop
- [ ] **Verify:** Order persists after reload
- [ ] Mark one day as rest day
- [ ] **Verify:** Rest day has special styling

#### Exercise Management
- [ ] Open "Push Day"
- [ ] Click "Add Exercise"
- [ ] Search for "Bench Press"
- [ ] **Verify:** Autocomplete shows exercises
- [ ] Select "Barbell Bench Press"
- [ ] Set:
  - Sets: 4
  - Reps: 8-12
  - Weight: 80kg
  - RPE: 7-8
  - Rest: 120s
  - Tempo: 3-1-1-0
- [ ] Save exercise
- [ ] **Verify:** Exercise appears in list
- [ ] Add 5 more exercises
- [ ] **Verify:** All exercises listed
- [ ] Reorder exercises
- [ ] **Verify:** Order saved
- [ ] Edit first exercise
- [ ] Change weight to 85kg
- [ ] **Verify:** Change persists
- [ ] Delete last exercise
- [ ] **Verify:** Exercise removed

#### Exercise Grouping
- [ ] Select exercises 2 and 3 (checkboxes)
- [ ] Click "Group Exercises"
- [ ] Select "Superset"
- [ ] **Verify:** Superset badge appears
- [ ] **Verify:** Exercises have colored border
- [ ] Expand superset
- [ ] **Verify:** Rest period shows between
- [ ] Select exercises 4 and 5
- [ ] Group as "Giant Set"
- [ ] **Verify:** Different color
- [ ] Ungroup superset
- [ ] **Verify:** Badges removed

### 2. Plan Templates

#### Save as Template
- [ ] Open existing plan
- [ ] Click "Save as Template"
- [ ] Enter template name: "PPL Template"
- [ ] Set visibility: Public
- [ ] Add tags: "push-pull-legs", "intermediate"
- [ ] Save template
- [ ] **Verify:** Template appears in library

#### Load from Template
- [ ] Click "Create from Template"
- [ ] Browse templates
- [ ] **Verify:** PPL Template shows
- [ ] Select template
- [ ] **Verify:** Preview loads
- [ ] Customize client and start date
- [ ] Create plan
- [ ] **Verify:** New plan created with template structure

### 3. Progression System

#### Apply Linear Progression
- [ ] Open plan
- [ ] Select Week 1
- [ ] Click "Apply Progression"
- [ ] Choose "Linear"
- [ ] Set percentage: 2.5%
- [ ] Apply to all weeks
- [ ] **Verify:** Weights increase across weeks
- [ ] **Verify:** Deload week has 50% reduction
- [ ] Check Week 8
- [ ] **Verify:** Weight = original × (1.025^7)

#### Apply Wave Periodization
- [ ] Create new plan
- [ ] Add base week
- [ ] Apply "Undulating" periodization
- [ ] **Verify:** Week 1 = 100%, Week 2 = 90%, Week 3 = 105%, Week 4 = 85%
- [ ] **Verify:** Pattern repeats

### 4. Coach Feedback

#### Comment on Exercise
- [ ] View client's completed workout
- [ ] Open exercise with video
- [ ] Watch form video
- [ ] Click "Add Comment"
- [ ] Enter: "Great depth! Keep knees out more."
- [ ] Save comment
- [ ] **Verify:** Comment shows with timestamp
- [ ] **Verify:** Client receives notification

#### Comment on Session
- [ ] View completed session
- [ ] Click "Add Session Feedback"
- [ ] Enter overall feedback
- [ ] Rate session: 4/5 stars
- [ ] Save feedback
- [ ] **Verify:** Feedback visible to client

### 5. Plan Export

#### Export as PDF
- [ ] Open plan
- [ ] Click "Export"
- [ ] Select "PDF"
- [ ] **Verify:** PDF generation starts
- [ ] **Verify:** PDF downloads
- [ ] Open PDF
- [ ] **Verify:** All weeks, days, exercises included
- [ ] **Verify:** Formatting correct
- [ ] **Verify:** Coach branding present

#### Share Plan
- [ ] Click "Share Plan"
- [ ] Generate share link
- [ ] Copy link
- [ ] Open in incognito window
- [ ] **Verify:** Plan preview loads
- [ ] **Verify:** "Add to My Plans" button shows

---

## Client Features

### 1. View Assigned Plan

#### Dashboard
- [ ] Login as client
- [ ] Navigate to Workouts
- [ ] **Verify:** Current plan shows
- [ ] **Verify:** Week progress bar shows
- [ ] **Verify:** Today's workout highlighted
- [ ] **Verify:** Upcoming workouts listed
- [ ] View plan details
- [ ] **Verify:** Coach name shows
- [ ] **Verify:** Goal shows
- [ ] **Verify:** All weeks accessible

### 2. Track Workout

#### Start Session
- [ ] Click "Today's Workout"
- [ ] **Verify:** Exercise list loads
- [ ] Click "Start Workout"
- [ ] **Verify:** Timer starts
- [ ] **Verify:** First exercise highlighted
- [ ] **Verify:** Set tracker shows (1/4 completed)

#### Complete Sets
- [ ] Tap "Set 1"
- [ ] Enter weight: 80kg
- [ ] Enter reps: 12
- [ ] Enter RPE: 7
- [ ] Tap "Complete Set"
- [ ] **Verify:** Set marked with checkmark
- [ ] **Verify:** Rest timer starts (120s)
- [ ] **Verify:** Can skip rest timer
- [ ] Complete sets 2-4
- [ ] **Verify:** All sets marked complete
- [ ] **Verify:** Exercise progress shows

#### Add Notes
- [ ] Click "Add Note" on exercise
- [ ] Enter: "Felt strong today!"
- [ ] Save note
- [ ] **Verify:** Note icon shows
- [ ] Click note icon
- [ ] **Verify:** Note text displays

#### Skip Exercise
- [ ] Long press on exercise 3
- [ ] Select "Skip"
- [ ] Confirm
- [ ] **Verify:** Exercise grayed out
- [ ] **Verify:** Skipped badge shows

#### Substitute Exercise
- [ ] Long press on exercise 4
- [ ] Select "Substitute"
- [ ] Search "Dumbbell"
- [ ] Select "Dumbbell Bench Press"
- [ ] **Verify:** Exercise replaced
- [ ] **Verify:** Original suggested as alternative

### 3. Complete Workout

#### Finish Session
- [ ] Complete all exercises
- [ ] Click "Complete Workout"
- [ ] **Verify:** Summary screen shows
- [ ] **Verify:** Total duration correct
- [ ] **Verify:** Total volume calculated
- [ ] **Verify:** PR badges show if any
- [ ] Add session comment
- [ ] Rate workout: 4/5 stars
- [ ] Save session
- [ ] **Verify:** Workout marked complete on calendar

#### PR Celebration
- [ ] Complete workout with PR
- [ ] **Verify:** PR celebration animation
- [ ] **Verify:** Confetti effect
- [ ] **Verify:** PR details shown
- [ ] Share PR
- [ ] **Verify:** Share dialog opens

### 4. History & Progress

#### View History
- [ ] Navigate to "History"
- [ ] **Verify:** Calendar view shows completed days
- [ ] **Verify:** Streak counter shows
- [ ] Select past workout
- [ ] **Verify:** Session details load
- [ ] **Verify:** All sets/reps/weights shown
- [ ] **Verify:** Notes preserved

#### Exercise History
- [ ] Open exercise
- [ ] Click "History"
- [ ] **Verify:** Chart shows progression
- [ ] **Verify:** All past sessions listed
- [ ] **Verify:** PRs highlighted
- [ ] **Verify:** Can filter by date range

---

## AI Features

### 1. AI Plan Generation

#### Generate from Profile
- [ ] Click "AI Generate Plan"
- [ ] **Verify:** Profile wizard shows
- [ ] Enter:
  - Goal: Hypertrophy
  - Experience: Intermediate
  - Days/week: 4
  - Duration: 8 weeks
  - Equipment: Barbell, Dumbbell, Cables
  - Limitations: None
- [ ] Click "Generate"
- [ ] **Verify:** Loading indicator shows
- [ ] Wait for generation (10-30s)
- [ ] **Verify:** Plan preview loads
- [ ] Review exercises
- [ ] **Verify:** Exercises match equipment
- [ ] **Verify:** Volume appropriate for level
- [ ] **Verify:** Balanced muscle groups

#### Customize AI Plan
- [ ] Click "Customize"
- [ ] Change exercise
- [ ] Adjust sets/reps
- [ ] Save changes
- [ ] **Verify:** Changes persist
- [ ] Regenerate section
- [ ] **Verify:** Only selected section changes

#### Accept Plan
- [ ] Click "Accept Plan"
- [ ] Enter plan name
- [ ] Set start date
- [ ] Save plan
- [ ] **Verify:** Plan saved to library
- [ ] **Verify:** Plan assigned to client

### 2. AI Exercise Suggestions

#### Get Alternatives
- [ ] Open exercise
- [ ] Click "Suggest Alternatives"
- [ ] **Verify:** AI suggests 3-5 alternatives
- [ ] **Verify:** Alternatives target same muscle
- [ ] **Verify:** Alternatives match equipment
- [ ] Select alternative
- [ ] **Verify:** Exercise replaced

#### Smart Substitutions
- [ ] Report injury: "Lower back pain"
- [ ] **Verify:** AI suggests safer alternatives
- [ ] **Verify:** Deadlifts flagged
- [ ] **Verify:** Alternatives suggested
- [ ] Accept suggestions
- [ ] **Verify:** Plan updated

---

## Analytics & Reports

### 1. Progress Analytics

#### Volume Tracking
- [ ] Navigate to Analytics
- [ ] View "Volume Trend" chart
- [ ] **Verify:** Chart shows last 12 weeks
- [ ] **Verify:** Data accurate
- [ ] **Verify:** Trend line shows
- [ ] Change timeframe to 6 months
- [ ] **Verify:** Chart updates
- [ ] Export chart as image
- [ ] **Verify:** PNG downloads

#### Muscle Distribution
- [ ] View "Muscle Balance" pie chart
- [ ] **Verify:** All muscle groups shown
- [ ] **Verify:** Percentages sum to 100%
- [ ] **Verify:** Overdeveloped groups flagged
- [ ] **Verify:** Recommendations shown
- [ ] Click muscle group
- [ ] **Verify:** Exercise list filtered

#### Strength Gains
- [ ] View "Strength Progress" table
- [ ] **Verify:** All exercises listed
- [ ] **Verify:** Starting/current weights shown
- [ ] **Verify:** Gain % calculated
- [ ] **Verify:** Trend indicators (↑↓→)
- [ ] Sort by gain %
- [ ] **Verify:** Sorted correctly
- [ ] Click exercise
- [ ] **Verify:** Detail chart opens

### 2. Generate Report

#### Weekly Summary
- [ ] Click "Generate Report"
- [ ] Select "Weekly Summary"
- [ ] **Verify:** Report generates
- [ ] **Verify:** Shows:
  - Completed workouts
  - Total volume
  - PRs achieved
  - Consistency score
  - Summary text
- [ ] Export as PDF
- [ ] **Verify:** PDF correct

#### Monthly Report
- [ ] Generate "Monthly Report"
- [ ] **Verify:** 4-5 weeks included
- [ ] **Verify:** Month-over-month comparison
- [ ] **Verify:** Recommendations included
- [ ] Email report
- [ ] **Verify:** Email sent

---

## Notifications

### 1. Notification Setup

#### Configure Preferences
- [ ] Navigate to Settings → Notifications
- [ ] Toggle "Workout Reminders" ON
- [ ] Set reminder time: 7:00 AM
- [ ] Set minutes before: 30
- [ ] Toggle "PR Celebrations" ON
- [ ] Toggle "Coach Feedback" ON
- [ ] Toggle "Weekly Summary" ON
- [ ] Set summary day: Sunday
- [ ] Set summary time: 6:00 PM
- [ ] Save preferences
- [ ] **Verify:** Preferences saved

### 2. Receive Notifications

#### Workout Reminder
- [ ] Wait for scheduled reminder OR send test
- [ ] **Verify:** Notification received
- [ ] **Verify:** Title: "Time for [Day Label]"
- [ ] **Verify:** Body shows exercise count
- [ ] **Verify:** Actions: "Start Workout", "Snooze"
- [ ] Tap notification
- [ ] **Verify:** App opens to workout
- [ ] OR tap "Snooze"
- [ ] **Verify:** Reminder rescheduled 15min

#### PR Celebration
- [ ] Complete workout with PR
- [ ] **Verify:** Notification sent within 1 min
- [ ] **Verify:** Trophy icon shows
- [ ] **Verify:** PR details in body
- [ ] Tap notification
- [ ] **Verify:** Opens PR details/analytics

#### Coach Feedback
- [ ] Coach adds comment (other device/account)
- [ ] **Verify:** Client receives notification
- [ ] **Verify:** Shows coach name + exercise
- [ ] Tap notification
- [ ] **Verify:** Opens exercise with comment
- [ ] **Verify:** "Reply" button shows

### 3. Deep Links

#### Test All Deep Links
- [ ] Test plan assigned → opens plan
- [ ] Test workout reminder → opens workout
- [ ] Test PR celebration → opens PRs
- [ ] Test coach feedback → opens exercise
- [ ] Test weekly summary → opens analytics
- [ ] **Verify:** All deep links work
- [ ] **Verify:** Back navigation correct

---

## Edge Cases

### 1. Network Issues

#### Offline Mode
- [ ] Enable airplane mode
- [ ] Open app
- [ ] **Verify:** Cached data shows
- [ ] Try to start workout
- [ ] **Verify:** Warning shows OR works offline
- [ ] Complete sets offline
- [ ] Re-enable network
- [ ] **Verify:** Data syncs automatically
- [ ] **Verify:** No data loss

#### Slow Connection
- [ ] Throttle network to 3G
- [ ] Load large plan (52 weeks)
- [ ] **Verify:** Loading indicator shows
- [ ] **Verify:** Loads within 10 seconds
- [ ] **Verify:** No timeout errors

### 2. Data Edge Cases

#### Empty States
- [ ] New user with no plans
- [ ] **Verify:** Empty state message
- [ ] **Verify:** "Create Plan" CTA shows
- [ ] Plan with 0 weeks
- [ ] **Verify:** Error message OR prevented
- [ ] Week with 0 days
- [ ] **Verify:** Empty state shows
- [ ] Day with 0 exercises
- [ ] **Verify:** "Add Exercise" CTA

#### Extreme Values
- [ ] Create plan with 100 weeks
- [ ] **Verify:** Accepts OR reasonable limit enforced
- [ ] Add exercise with 999kg weight
- [ ] **Verify:** Accepts OR validates
- [ ] Add exercise with 100 sets
- [ ] **Verify:** Warning shows OR limit enforced
- [ ] Complete 100 rep set
- [ ] **Verify:** Saves correctly

### 3. Concurrent Edits

#### Two Coaches Edit Same Plan
- [ ] Coach A opens plan
- [ ] Coach B opens same plan
- [ ] Coach A edits exercise
- [ ] Coach B edits same exercise
- [ ] Both save
- [ ] **Verify:** Conflict resolution OR last-write-wins
- [ ] **Verify:** No data corruption

#### Client Starts During Coach Edit
- [ ] Coach editing plan
- [ ] Client starts workout from same plan
- [ ] Coach saves changes
- [ ] **Verify:** Client's session unaffected
- [ ] Client completes workout
- [ ] **Verify:** Both changes persist

### 4. Delete Scenarios

#### Delete Plan with Active Session
- [ ] Client starts workout
- [ ] Coach deletes plan
- [ ] **Verify:** Client can finish session
- [ ] **Verify:** Session saves to history
- [ ] **Verify:** Plan properly deleted after

#### Delete Exercise Mid-Workout
- [ ] Client tracking workout
- [ ] Coach deletes future exercise
- [ ] **Verify:** No effect on current session
- [ ] Client moves to deleted exercise
- [ ] **Verify:** Graceful handling

---

## Accessibility

### 1. Screen Reader

#### iOS VoiceOver
- [ ] Enable VoiceOver
- [ ] Navigate to workout plan
- [ ] **Verify:** Plan name announced
- [ ] Swipe through exercises
- [ ] **Verify:** Each exercise announced
- [ ] **Verify:** Sets/reps/weight announced
- [ ] Start workout
- [ ] **Verify:** Timer announced
- [ ] Complete set
- [ ] **Verify:** Completion announced

#### Android TalkBack
- [ ] Enable TalkBack
- [ ] Repeat iOS tests
- [ ] **Verify:** All elements accessible
- [ ] **Verify:** Proper focus order
- [ ] **Verify:** Buttons labeled correctly

### 2. Font Scaling

#### Large Text
- [ ] Set device text size to MAX
- [ ] Open app
- [ ] **Verify:** Text scales appropriately
- [ ] **Verify:** No truncation
- [ ] **Verify:** Buttons still tappable
- [ ] **Verify:** Charts readable

#### Small Text
- [ ] Set device text size to MIN
- [ ] **Verify:** Text still readable
- [ ] **Verify:** Layout not broken

### 3. Color Contrast

#### High Contrast Mode
- [ ] Enable high contrast
- [ ] **Verify:** All text meets WCAG AA
- [ ] **Verify:** Icons distinguishable
- [ ] **Verify:** Charts readable

#### Color Blind Mode
- [ ] Test with color blind simulator
- [ ] **Verify:** Muscle groups distinguishable
- [ ] **Verify:** Charts use patterns, not just color
- [ ] **Verify:** Status indicators have icons

### 4. Keyboard Navigation

#### Web/Desktop
- [ ] Use only keyboard
- [ ] Tab through form
- [ ] **Verify:** Focus visible
- [ ] **Verify:** Logical tab order
- [ ] Press Space/Enter to activate
- [ ] **Verify:** Buttons respond
- [ ] Use arrow keys in lists
- [ ] **Verify:** Navigation works

---

## Performance

### 1. Load Times

#### Initial Load
- [ ] Clear app data
- [ ] Launch app
- [ ] Time to first screen
- [ ] **Target:** < 3 seconds
- [ ] **Verify:** Splash screen shows

#### Plan Loading
- [ ] Load small plan (4 weeks)
- [ ] **Target:** < 1 second
- [ ] Load large plan (52 weeks)
- [ ] **Target:** < 3 seconds
- [ ] **Verify:** Progressive loading OR loading indicator

### 2. Memory Usage

#### Monitor RAM
- [ ] Open DevTools/Xcode Instruments
- [ ] Navigate through app
- [ ] **Verify:** Memory stays < 200MB
- [ ] Load multiple plans
- [ ] **Verify:** No memory leaks
- [ ] **Verify:** Old data garbage collected

### 3. Battery Usage

#### Background Tracking
- [ ] Start workout
- [ ] Lock screen
- [ ] Complete workout in background
- [ ] **Verify:** Battery drain reasonable
- [ ] **Verify:** Location services off if not needed

---

## Cross-Platform

### 1. iOS Testing

#### iPhone
- [ ] Test on iPhone 13
- [ ] Test on iPhone SE (small screen)
- [ ] **Verify:** Layout adapts
- [ ] Test notched screen handling
- [ ] Test safe area insets
- [ ] Test dark mode
- [ ] Test landscape orientation

#### iPad
- [ ] Test on iPad Pro
- [ ] **Verify:** Uses tablet layout
- [ ] **Verify:** Split view works
- [ ] Test multitasking
- [ ] **Verify:** Keyboard shortcuts work

### 2. Android Testing

#### Various Devices
- [ ] Test on Pixel 7
- [ ] Test on Samsung S23
- [ ] Test on budget device
- [ ] **Verify:** Performance acceptable on all
- [ ] Test various screen sizes
- [ ] **Verify:** Layout responsive

### 3. Web Testing (if applicable)

#### Browsers
- [ ] Test on Chrome
- [ ] Test on Firefox
- [ ] Test on Safari
- [ ] **Verify:** Feature parity
- [ ] **Verify:** Responsive design
- [ ] Test mobile browser
- [ ] **Verify:** Touch interactions work

---

## RTL (Right-to-Left) Layout

### Arabic/Kurdish Support

#### Text Direction
- [ ] Change app language to Arabic
- [ ] **Verify:** All text flows RTL
- [ ] **Verify:** Numbers still LTR
- [ ] **Verify:** Icons mirrored appropriately
- [ ] Open workout plan
- [ ] **Verify:** Layout flipped
- [ ] **Verify:** Drag handles on correct side
- [ ] **Verify:** Charts readable

#### Form Inputs
- [ ] Fill out plan creation form in Arabic
- [ ] **Verify:** Text aligns right
- [ ] **Verify:** Placeholders RTL
- [ ] **Verify:** Validation messages RTL

---

## Sign-Off

### Test Summary

**Date:** _______________
**Tester:** _______________
**Build:** _______________
**Platform:** ☐ iOS  ☐ Android  ☐ Web

**Results:**
- Total Tests: _____
- Passed: _____
- Failed: _____
- Blocked: _____

### Critical Issues Found

1. _______________________________________________
2. _______________________________________________
3. _______________________________________________

### Recommendation

☐ **PASS** - Ready for release
☐ **PASS WITH NOTES** - Minor issues, can release
☐ **FAIL** - Critical issues, must fix before release

**Signature:** _______________

---

## Appendix

### Test Data

#### Coach Account
- Email: coach@test.com
- Password: Test1234!

#### Client Accounts
- Email: client1@test.com / client2@test.com
- Password: Test1234!

### Test Plans

#### Plan 1: "8-Week Hypertrophy"
- Goal: Hypertrophy
- Duration: 8 weeks
- Days/week: 4
- Exercises: 24

#### Plan 2: "Strength Builder"
- Goal: Strength
- Duration: 12 weeks
- Days/week: 3
- Exercises: 15

### Quick Links

- Database: http://localhost:54323
- OneSignal: https://dashboard.onesignal.com
- Supabase: https://app.supabase.com

---

**End of Checklist**
