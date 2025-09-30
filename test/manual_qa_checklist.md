# Manual QA Checklist - Nutrition Platform Rebuild

## Test Environment Setup
- [ ] iOS Device/Simulator (iOS 13+)
- [ ] Android Device/Emulator (Android 8+)
- [ ] Tablet (iPad/Android Tablet)
- [ ] Web Browser (Chrome/Safari/Firefox)
- [ ] Test Coach Account
- [ ] Test Client Account
- [ ] Network Throttling Tool
- [ ] Screen Reader Enabled (VoiceOver/TalkBack)

## Part 1: Core Functionality Tests

### Navigation & Routing
- [ ] All navigation buttons work correctly
- [ ] Back button returns to previous screen
- [ ] Deep links work (if implemented)
- [ ] No dead-end screens
- [ ] Drawer/menu opens and closes
- [ ] Tab navigation works
- [ ] Bottom navigation switches screens

### Data Loading & Display
- [ ] Initial data loads correctly
- [ ] Loading indicators appear during fetch
- [ ] Empty states show helpful messages
- [ ] Error states show retry buttons
- [ ] Cached data loads instantly
- [ ] Pull-to-refresh works
- [ ] Pagination loads more data

### Form Validation
- [ ] Required fields show validation messages
- [ ] Email/phone formats validated
- [ ] Number inputs accept only numbers
- [ ] Text length limits enforced
- [ ] Duplicate prevention works
- [ ] Form submits successfully
- [ ] Success message appears after submit

## Part 2: Nutrition-Specific Features

### Plan Creation (Coach)
- [ ] Create new plan button works
- [ ] Client selection dropdown populates
- [ ] Plan name field accepts input
- [ ] Length type selection works (Daily/Weekly/Program)
- [ ] AI generation button triggers correctly
- [ ] AI generation shows progress
- [ ] Add meal button works
- [ ] Meal name is editable
- [ ] Save plan button works
- [ ] Success message appears
- [ ] Plan appears in list after save

### Food Picker 2.0
**Search Tab:**
- [ ] Search input accepts text
- [ ] Debouncing delays search (300ms)
- [ ] Results update as you type
- [ ] Quick filters work (High Protein, Low Carb, etc.)
- [ ] Food cards display nutrition info
- [ ] Favorite toggle works
- [ ] Add to meal button works
- [ ] Multi-select mode enables
- [ ] Selected count updates
- [ ] Bulk add works

**Barcode Scanner Tab:**
- [ ] Camera permission requested
- [ ] Camera view displays
- [ ] Scanning overlay animates
- [ ] Manual entry field works
- [ ] Scan history shows
- [ ] Food recognition displays results
- [ ] Add scanned food works

**Recent Foods Tab:**
- [ ] Recent foods load
- [ ] Time grouping correct (Today, Yesterday, etc.)
- [ ] Tap to add works
- [ ] Most recent foods appear first

**Favorites Tab:**
- [ ] Favorites load correctly
- [ ] Categories display (Proteins, Carbs, etc.)
- [ ] Search within favorites works
- [ ] Remove from favorites works
- [ ] Category chips filter correctly

**Custom Foods Tab:**
- [ ] Photo upload button works
- [ ] Camera capture works
- [ ] Name field accepts text
- [ ] All macro fields accept numbers
- [ ] Micronutrient fields work
- [ ] Serving size field works
- [ ] Share with coach toggle works
- [ ] Create button saves food
- [ ] Custom food appears in list

### Meal Editing
- [ ] Add food to meal works
- [ ] Food quantity editable
- [ ] Unit selector works (g, serv)
- [ ] Remove food from meal works
- [ ] Meal summary updates correctly
- [ ] Drag to reorder foods works
- [ ] Meal detail modal opens
- [ ] Coach notes editable (coach mode)
- [ ] Client comments editable (client mode)
- [ ] File attachment works
- [ ] Photo attachment works

### Plan Viewing (Client)
- [ ] Plan loads correctly
- [ ] Macro progress bars display
- [ ] Meal cards show correct info
- [ ] Tap meal opens detail
- [ ] Check-off button works
- [ ] Check-off updates count
- [ ] Hydration tracker works
- [ ] Day insights display
- [ ] Supplement section shows
- [ ] Request changes button works

## Part 3: Role-Based Features

### Coach Mode
- [ ] Edit button visible
- [ ] Add meal button visible
- [ ] Macro target editor accessible
- [ ] Coach notes input visible
- [ ] Delete meal button works
- [ ] Reorder meals works
- [ ] Duplicate plan works
- [ ] Save as template works
- [ ] Export PDF works
- [ ] Switch to view mode works

### Client Mode
- [ ] Edit button hidden
- [ ] Add meal button hidden
- [ ] Macro targets read-only
- [ ] Check-off buttons visible
- [ ] Client comment box visible
- [ ] Request changes button visible
- [ ] Can't delete meals
- [ ] Can't reorder meals
- [ ] Can export PDF
- [ ] Can generate grocery list

## Part 4: Technical Excellence Tests

### Offline Support
- [ ] Enable airplane mode
- [ ] Create/edit plan works offline
- [ ] Offline banner appears
- [ ] Pending changes indicator shows
- [ ] Disable airplane mode
- [ ] Auto-sync triggers
- [ ] Sync success notification shows
- [ ] All changes persisted

### Error Handling
- [ ] Network error shows helpful message
- [ ] Retry button works
- [ ] Database error shows message
- [ ] Validation errors are clear
- [ ] Permission denied errors handled
- [ ] Timeout errors handled
- [ ] No crashes occur

### Performance
- [ ] App loads in < 2 seconds
- [ ] Screen transitions smooth
- [ ] No janky animations
- [ ] Scrolling is smooth
- [ ] Images load progressively
- [ ] Search is responsive
- [ ] No memory leaks
- [ ] Battery drain acceptable

### Caching
- [ ] Data loads from cache instantly
- [ ] Cache updates after fetch
- [ ] Stale cache refreshes
- [ ] Cache survives app restart
- [ ] Cache size reasonable
- [ ] Clear cache works

## Part 5: UI/UX Tests

### Animations
- [ ] All animations smooth (60fps)
- [ ] Micro-interactions work
- [ ] Loading animations display
- [ ] Success animations play
- [ ] Error animations play
- [ ] Reduce motion respected

### Images
- [ ] All images load correctly
- [ ] Placeholder shows while loading
- [ ] Error image shows on failure
- [ ] Tap to retry works
- [ ] Image caching works
- [ ] No broken image links

### Empty States
- [ ] Show helpful message
- [ ] Include relevant icon
- [ ] Provide call-to-action
- [ ] CTA button works
- [ ] No confusing empty screens

### Loading States
- [ ] Skeleton loaders appear
- [ ] Spinners show for long operations
- [ ] Progress bars show percentage
- [ ] "Loading..." text clear
- [ ] Cancel button works (if applicable)

### Error States
- [ ] Clear error message
- [ ] Retry button visible
- [ ] Error icon displayed
- [ ] Technical details hidden (but logged)
- [ ] User knows what to do

## Part 6: Internationalization Tests

### English (EN)
- [ ] All text in English
- [ ] No translation keys visible
- [ ] LTR layout correct
- [ ] Numbers formatted correctly
- [ ] Dates formatted correctly

### Arabic (AR)
- [ ] All text in Arabic
- [ ] RTL layout applied
- [ ] Icons flipped correctly
- [ ] Numbers in Western digits
- [ ] Text aligned right
- [ ] Scrolling direction correct

### Kurdish (KU)
- [ ] All text in Kurdish
- [ ] RTL layout applied
- [ ] All translations present
- [ ] Numbers formatted correctly

### Language Switching
- [ ] Switch language updates UI immediately
- [ ] All screens update
- [ ] No mixed languages
- [ ] Language persists after restart

## Part 7: Accessibility Tests

### Screen Reader (VoiceOver/TalkBack)
- [ ] Enable VoiceOver/TalkBack
- [ ] All buttons announced correctly
- [ ] Semantic labels clear
- [ ] Hints provided where needed
- [ ] Navigation order logical
- [ ] State changes announced
- [ ] Progress updates announced
- [ ] Error messages announced

### Keyboard Navigation
- [ ] Tab through all controls
- [ ] Focus visible
- [ ] Enter/Space activates
- [ ] Escape closes modals
- [ ] Arrow keys navigate lists
- [ ] No keyboard traps

### Visual Accessibility
- [ ] Contrast ratios meet WCAG AA
- [ ] Text readable at 200% zoom
- [ ] Touch targets 44x44 minimum
- [ ] Focus indicators visible
- [ ] Color not sole indicator
- [ ] High contrast mode works

### Motion & Animation
- [ ] Reduce motion setting detected
- [ ] Animations disabled when set
- [ ] No vestibular triggers
- [ ] No rapid flashing

## Part 8: Platform-Specific Tests

### iOS
- [ ] Works on iPhone SE (small screen)
- [ ] Works on iPhone 14 Pro Max (large screen)
- [ ] Works on iPad (tablet)
- [ ] Safe area insets respected
- [ ] Status bar appearance correct
- [ ] Notch accommodated
- [ ] Home indicator accommodated
- [ ] Pull-to-refresh iOS style

### Android
- [ ] Works on small phone (5")
- [ ] Works on large phone (6.7")
- [ ] Works on tablet (10")
- [ ] System navigation handled
- [ ] Back button works correctly
- [ ] Material design consistent
- [ ] Swipe gestures work

### Web
- [ ] Desktop layout responsive
- [ ] Mobile layout responsive
- [ ] Mouse interactions work
- [ ] Touch interactions work
- [ ] Keyboard shortcuts work
- [ ] Browser back button works
- [ ] Deep links work
- [ ] No console errors

### Tablet
- [ ] Uses split-screen layouts
- [ ] Master-detail pattern works
- [ ] Landscape orientation good
- [ ] Portrait orientation good
- [ ] No wasted space
- [ ] Touch targets appropriate size

## Part 9: Edge Cases & Stress Tests

### Data Edge Cases
- [ ] Empty plan displays correctly
- [ ] Plan with 100+ meals handles well
- [ ] Very long meal names truncate
- [ ] Very large numbers format correctly
- [ ] Zero values display correctly
- [ ] Negative values prevented
- [ ] Decimal precision correct

### Network Edge Cases
- [ ] Slow 3G connection works
- [ ] Intermittent connection handled
- [ ] Connection lost during save
- [ ] Duplicate requests prevented
- [ ] Stale data detected
- [ ] Token refresh works

### User Edge Cases
- [ ] User logs out during operation
- [ ] User switches accounts
- [ ] Session expires gracefully
- [ ] Permission revoked handled
- [ ] Account deleted handled

## Part 10: Regression Tests

### After Each Change
- [ ] No new crashes introduced
- [ ] Existing features still work
- [ ] Performance not degraded
- [ ] No visual regressions
- [ ] Accessibility not broken
- [ ] Tests still pass

## Test Results Summary

**Date:** __________
**Tester:** __________
**Platform:** __________
**Build:** __________

**Total Tests:** ___ / ___
**Passed:** ___
**Failed:** ___
**Blocked:** ___

**Critical Issues:**
1.
2.
3.

**Medium Issues:**
1.
2.
3.

**Minor Issues:**
1.
2.
3.

**Notes:**


**Sign-off:**
- [ ] All critical issues resolved
- [ ] Ready for production deployment

---

**QA Lead:** ________________
**Date:** ________________