# VAGUS App - UI/Feature Restoration Roadmap
**Generated**: October 1, 2025
**Purpose**: Phased plan to restore and complete UI features
**Timeline**: 12-13 weeks to production readiness
**Current Status**: Post-audit, pre-restoration

---

## Executive Summary

This roadmap guides the restoration of the VAGUS app from current state (post-refactor, 80+ TODOs) to production-ready. The app has solid foundations (security, database, architecture) but needs feature completion, bug fixes, and polish.

**Key Goals**:
1. ✅ Fix 2 critical broken features (Week 1-2)
2. ✅ Complete 6 high-value incomplete features (Week 3-5)
3. ✅ Build 10 missing workout widgets (Week 6-8)
4. ✅ Polish secondary features (Week 9-10)
5. ✅ Production readiness (Week 11-12)
6. 🔍 Evaluate archived features (Week 13+)

**Success Criteria**:
- Zero critical bugs
- All core user flows functional
- Professional UX polish
- Performance optimized
- Security reviewed
- Ready for beta users

---

## Current State Assessment

### Strengths ✅
- Well-structured codebase with 207 screens
- Comprehensive feature coverage (15+ modules)
- Modern architecture (Workout v2, Nutrition v2)
- Strong admin/support system (38+ screens)
- Security-hardened (credentials removed)
- Clear role-based navigation (Client/Coach/Admin)

### Weaknesses ⚠️
- 80+ TODO markers (incomplete features)
- 2 critical broken features
- 10 missing workout widgets
- Heavy debug logging needs cleanup
- Some data models incomplete
- File management flows incomplete

### Risk Areas 🔴
- **CRITICAL**: PDF export broken (user-facing)
- **CRITICAL**: Intake form responses not viewable (coach workflow)
- **HIGH**: File preview navigation incomplete
- **MEDIUM**: Workout session mode UI partial
- **MEDIUM**: Nutrition macro calculations stubbed

---

## Phase 1: Critical Fixes (Week 1-2)

### Goal
Restore broken user-facing functionality that blocks core workflows.

### Tasks

#### 1.1 Fix PDF Export (Priority: CRITICAL)
**File**: `lib/screens/workout/workout_plan_viewer_screen_refactored.dart:1026`

**Problem**: Windows path resolution breaks PDF generation

**Solution Steps**:
1. Read current PDF export implementation
2. Identify path resolution issue (likely `path_provider` Windows compatibility)
3. Implement cross-platform path handling:
   ```dart
   // Use path_provider properly
   final directory = await getApplicationDocumentsDirectory();
   final filePath = '${directory.path}/workout_plan_${plan.id}.pdf';
   ```
4. Test on Windows, macOS, Linux
5. Handle permissions (storage access)
6. Add error handling and user feedback
7. Remove "temporarily disabled" message

**Estimated Effort**: 1-2 days
**Dependencies**: `pdf`, `path_provider` packages
**Testing**: Export on all platforms, verify PDF opens

---

#### 1.2 Implement Intake Form Response Viewer (Priority: CRITICAL)
**File**: `lib/screens/coach/intake/coach_forms_screen.dart:869`

**Problem**: Coaches cannot view client intake form responses (incomplete workflow)

**Solution Steps**:
1. Design UI for response viewer (modal or full screen)
2. Create data model for form responses
3. Implement Supabase query to fetch responses:
   ```dart
   final responses = await supabase
     .from('intake_form_responses')
     .select('*, intake_forms(*)')
     .eq('client_id', clientId)
     .order('created_at', ascending: false);
   ```
4. Build response detail view (show all fields)
5. Add filtering by form type
6. Add export to PDF/CSV option
7. Link from client profile and forms screen

**Estimated Effort**: 3-4 days
**Dependencies**: Supabase schema (verify `intake_form_responses` table)
**Testing**: Submit form as client, view as coach

---

#### 1.3 Complete File Preview Navigation (Priority: HIGH)
**Files**: Multiple in `lib/screens/files/` and `lib/widgets/files/` (8 instances)

**Problem**: Users can upload files but cannot preview or navigate file details

**Solution Steps**:
1. List all 8 TODO instances and affected screens
2. Create unified file preview screen:
   - Image preview (zoomable)
   - Video player
   - Document viewer (PDF, etc.)
3. Implement navigation from file lists
4. Add file metadata display (size, date, uploader)
5. Implement file actions menu (download, share, delete)
6. Add breadcrumb navigation
7. Handle file not found errors

**Estimated Effort**: 3-4 days
**Dependencies**: `flutter_pdfview`, `video_player`
**Testing**: Upload various file types, preview each

---

#### 1.4 Add Missing Meal Model Fields (Priority: HIGH)
**Files**: `lib/widgets/nutrition/meal_timeline_card.dart` + data models

**Problem**: Meal model missing critical fields (id, timestamps, mealType, photo_url)

**Solution Steps**:
1. Review current `Meal` model definition
2. Add missing fields to model:
   ```dart
   class Meal {
     final String id;
     final DateTime? checkedInAt;
     final DateTime createdAt;
     final MealType mealType; // enum: breakfast, lunch, dinner, snack
     final String? photoUrl;
     // ... existing fields
   }
   ```
3. Create database migration if needed:
   ```sql
   ALTER TABLE nutrition_meals ADD COLUMN checked_in_at TIMESTAMPTZ;
   ALTER TABLE nutrition_meals ADD COLUMN meal_type TEXT;
   ALTER TABLE nutrition_meals ADD COLUMN photo_url TEXT;
   ```
4. Update all Meal instantiations in codebase
5. Update meal_timeline_card to use new fields
6. Fix macro calculations to use correct data
7. Test nutrition tracking end-to-end

**Estimated Effort**: 2-3 days
**Dependencies**: Database migration, model updates
**Testing**: Log meals, verify data persists correctly

---

### Phase 1 Deliverables

- ✅ PDF export working on all platforms
- ✅ Coaches can view intake form responses
- ✅ File preview navigation functional
- ✅ Meal model complete with all fields
- ✅ Zero critical blockers remain

**Total Effort**: 2 weeks
**Success Metrics**:
- All critical TODOs resolved
- Core user workflows unblocked
- No P0 bugs in issue tracker

---

## Phase 2: High-Value Completions (Week 3-5)

### Goal
Complete partially implemented features that add significant user value.

### Tasks

#### 2.1 Implement Workout Session Mode UI (Priority: HIGH)
**File**: `lib/screens/workout/workout_plan_viewer_screen_refactored.dart:662`

**Problem**: Session mode exists but UI is incomplete (basic functionality only)

**Solution Steps**:
1. Design full session mode UI:
   - Current exercise highlight
   - Set-by-set logging interface
   - Timer for rest periods
   - RPE input slider
   - Quick notes field
   - Navigation to next exercise
2. Implement session state management:
   ```dart
   class WorkoutSession {
     final String id;
     final DateTime startedAt;
     Map<String, List<ExerciseSet>> completedSets;
     String? currentExerciseId;
     // ...
   }
   ```
3. Add session persistence (save progress if app closed)
4. Implement session summary screen
5. Add session history to workout viewer
6. Show session analytics (total volume, time, etc.)

**Estimated Effort**: 4-5 days
**Dependencies**: workout_sessions table (see Phase 6)
**Testing**: Complete full workout session, verify data saved

---

#### 2.2 Add Exercise Demo Player (Priority: HIGH)
**Files**: Multiple workout screens

**Problem**: No way to view exercise demonstrations (videos/animations)

**Solution Steps**:
1. Design exercise demo UI:
   - Video player with controls
   - Alternative: animated GIF or Lottie animations
   - Overlay with form cues
   - Related exercises section
2. Integrate video player:
   ```dart
   VideoPlayerController _controller = VideoPlayerController.network(
     exerciseDemo.videoUrl,
   );
   ```
3. Add demo source management:
   - Option 1: YouTube embed
   - Option 2: Hosted videos (Supabase Storage)
   - Option 3: Third-party API (e.g., JEFIT, ExRx)
4. Implement caching for offline playback
5. Add demo to exercise library
6. Link from workout viewer
7. Handle missing demos gracefully

**Estimated Effort**: 3-4 days
**Dependencies**: `video_player`, `youtube_player_flutter`
**Testing**: Play various demos, test offline behavior

---

#### 2.3 Create Workout History Screen (Priority: HIGH)
**File**: `lib/screens/workout/workout_plan_viewer_screen_refactored.dart:1053`

**Problem**: Users cannot review past workouts

**Solution Steps**:
1. Design history screen:
   - Calendar view of completed workouts
   - List view with filters (date range, exercise)
   - Detail view for each session
   - Progress charts (volume over time, PR tracking)
2. Implement data fetching:
   ```dart
   final history = await supabase
     .from('workout_sessions')
     .select('*, exercise_logs(*)')
     .eq('user_id', userId)
     .gte('completed_at', startDate)
     .order('completed_at', ascending: false);
   ```
3. Add filtering and sorting
4. Implement session replay view
5. Add export to CSV option
6. Link from workout viewer and profile
7. Show PRs (personal records) highlighted

**Estimated Effort**: 4-5 days
**Dependencies**: workout_sessions table
**Testing**: Log multiple workouts, view history

---

#### 2.4 Complete File Share/Download (Priority: MEDIUM)
**Files**: Multiple in `lib/screens/files/`

**Problem**: File management incomplete (can't share or download)

**Solution Steps**:
1. Implement file download:
   ```dart
   Future<void> downloadFile(String fileUrl) async {
     final dir = await getApplicationDocumentsDirectory();
     final file = File('${dir.path}/$fileName');
     final response = await http.get(Uri.parse(fileUrl));
     await file.writeAsBytes(response.bodyBytes);
     // Show snackbar with file path
   }
   ```
2. Implement file sharing:
   - Use `share_plus` package
   - Share file URL or download + share
   - Add share to social media
3. Add permissions handling (storage access)
4. Show download progress indicator
5. Handle network errors
6. Add "open with" functionality

**Estimated Effort**: 2-3 days
**Dependencies**: `share_plus`, `http`, `path_provider`
**Testing**: Download/share various file types

---

#### 2.5 Fix Completion Percentage Calculations (Priority: MEDIUM)
**File**: `lib/screens/workout/workout_plan_viewer_screen_refactored.dart:783, 788`

**Problem**: Using placeholder logic for workout completion

**Solution Steps**:
1. Define completion criteria:
   - % of exercises completed
   - % of sets logged
   - Weighted by difficulty/volume?
2. Implement accurate calculation:
   ```dart
   double calculateCompletion(WorkoutDay day) {
     final totalExercises = day.exercises.length;
     final completedExercises = day.exercises.where((e) => e.isCompleted).length;
     return completedExercises / totalExercises;
   }
   ```
3. Add visual progress indicators (circular, linear)
4. Show completion on workout cards
5. Track weekly completion rate
6. Display in analytics

**Estimated Effort**: 1-2 days
**Dependencies**: None
**Testing**: Log workouts, verify percentages accurate

---

#### 2.6 Fix Nutrition Macro Calculations (Priority: MEDIUM)
**Files**: Nutrition module

**Problem**: Macro calculations incomplete or stubbed

**Solution Steps**:
1. Review current calculation logic
2. Ensure formulas correct:
   ```dart
   double totalProtein = meals.fold(0, (sum, meal) =>
     sum + meal.items.fold(0, (mealSum, item) =>
       mealSum + (item.protein * item.servings)));
   ```
3. Add unit conversions (grams, oz, etc.)
4. Handle missing macro data gracefully
5. Add macro goals tracking
6. Show progress bars (protein, carbs, fats, calories)
7. Color-code based on goals (green/yellow/red)

**Estimated Effort**: 2-3 days
**Dependencies**: Complete Meal model (Phase 1)
**Testing**: Log various foods, verify totals match

---

### Phase 2 Deliverables

- ✅ Workout session mode fully functional
- ✅ Exercise demos viewable
- ✅ Workout history accessible
- ✅ Files can be shared and downloaded
- ✅ Completion percentages accurate
- ✅ Macro calculations correct

**Total Effort**: 3 weeks
**Success Metrics**:
- Core features feel complete
- User feedback positive on session tracking
- No HIGH priority issues remain

---

## Phase 3: Widget Library Completion (Week 6-8)

### Goal
Build the 10 missing workout widgets documented in README.

### Tasks

#### 3.1 Priority 1 Widgets (Week 6)

**Widget 1: workout_timer_widget.dart**
- Rest timer with countdown
- Visual progress ring
- Sound/vibration alerts
- Adjustable duration
- Pause/resume controls

**Widget 2: muscle_group_selector.dart**
- Visual body map
- Clickable muscle groups
- Multi-select support
- Filter exercises by selection

**Widget 3: exercise_history_chart.dart**
- Line chart of volume over time
- Bar chart of reps/sets
- PR indicators
- Interactive tooltips

**Estimated Effort**: 1 week (3 widgets)

---

#### 3.2 Priority 2 Widgets (Week 7)

**Widget 4: exercise_search_widget.dart**
- Search bar with autocomplete
- Filter by muscle group, equipment
- Recent exercises section
- Favorites support

**Widget 5: set_rep_input_widget.dart**
- Numeric input for sets/reps/weight
- Quick increment/decrement buttons
- Unit switching (lbs/kg)
- Previous set data display

**Widget 6: client_workout_comment_box.dart**
- Comment input field
- Mention coach with @
- Attach photos/videos
- Edit/delete comments

**Estimated Effort**: 1 week (3 widgets)

---

#### 3.3 Priority 3 Widgets (Week 8)

**Widget 7: workout_attachment_viewer.dart**
- Image carousel
- Video player
- PDF viewer
- Download button

**Widget 8: workout_version_history_viewer.dart**
- Timeline of plan changes
- Diff view (what changed)
- Restore previous version
- Export version

**Widget 9: ai_workout_generator_dialog.dart** (Complex)
- Input: goals, experience level, equipment
- AI generates workout plan
- Preview before applying
- Edit AI suggestions

**Widget 10: exercise_demo_player.dart** (Duplicate of 2.2)
- Already covered in Phase 2

**Estimated Effort**: 1 week (3-4 widgets)

---

### Phase 3 Deliverables

- ✅ 10 workout widgets implemented
- ✅ Widgets documented with examples
- ✅ Widgets integrated into workout screens
- ✅ Widget library complete

**Total Effort**: 3 weeks
**Success Metrics**:
- All widgets functional and tested
- README updated to mark widgets complete
- Workout module feels feature-rich

---

## Phase 4: UX Polish (Week 9-10)

### Goal
Smooth out rough edges, complete secondary features, and improve overall UX.

### Tasks

#### 4.1 Complete Calling Module Controls
**Files**: `lib/widgets/calling/call_controls.dart`, `call_header.dart`

**TODO Items**:
- Speaker toggle (use `flutter_sound` or native platform channels)
- Camera switch (front/back)
- Call settings dialog (volume, quality)
- Recording options (record call with consent)

**Estimated Effort**: 2-3 days

---

#### 4.2 Implement Admin Operation Handlers
**Files**: Admin incident/ops screens

**TODO Items**:
- Acknowledge operation handler
- Extend deadline handler
- Escalate to manager handler

**Estimated Effort**: 1-2 days

---

#### 4.3 Add AI Quotas Detail Screen
**Navigation**: From settings or dashboard

**Features**:
- Show AI usage by type (OCR, workout generation, chat)
- Display quota limits
- Usage history chart
- Upgrade prompt when limit reached

**Estimated Effort**: 2-3 days

---

#### 4.4 Complete Recipe Navigation
**Files**: Nutrition module

**TODO Items**:
- Recipe detail screen
- Recipe search
- Recipe favorites
- Add recipe to meal plan

**Estimated Effort**: 2-3 days

---

#### 4.5 Add Supplement Edit/Navigation
**Files**: `lib/screens/supplements/`

**TODO Items**:
- Supplement edit screen
- Add custom supplements
- Set supplement reminders
- Track supplement effectiveness

**Estimated Effort**: 2-3 days

---

#### 4.6 UI/UX Refinements

**Loading States**:
- Add shimmer loading for all data fetches
- Consistent loading indicators

**Empty States**:
- Illustrative empty state graphics
- Clear CTAs (e.g., "Add your first workout")

**Error States**:
- Friendly error messages
- Actionable retry buttons
- Contextual help

**Animations**:
- Smooth page transitions
- Micro-interactions (button presses, swipes)
- Celebrate milestones (streak achievements, PRs)

**Accessibility**:
- Semantic labels for screen readers
- Sufficient color contrast (WCAG AA)
- Focus indicators for keyboard navigation

**Estimated Effort**: 3-4 days

---

### Phase 4 Deliverables

- ✅ All calling controls functional
- ✅ Admin operations complete
- ✅ AI quotas visible and manageable
- ✅ Recipe system fully navigable
- ✅ Supplement tracking complete
- ✅ Professional UX polish throughout

**Total Effort**: 2 weeks
**Success Metrics**:
- App feels polished and professional
- No jarring transitions or inconsistencies
- Positive user testing feedback

---

## Phase 5: Production Readiness (Week 11-12)

### Goal
Prepare app for production deployment with beta users.

### Tasks

#### 5.1 Clean Up Debug Statements (Week 11, Day 1-2)

**High-Priority Files**:
- `auth_gate.dart` (18 debug statements)
- `modern_client_dashboard.dart` (10 debug statements)
- `modern_coach_dashboard.dart` (3+ statements)
- `main_nav.dart` (4 statements)
- `calendar/event_editor.dart` (6 statements)
- Workout screens (multiple)

**Approach**:
1. Replace debug statements with proper logging:
   ```dart
   // Before:
   debugPrint('User role: $role');

   // After:
   logger.info('User role detected', extra: {'role': role, 'userId': userId});
   ```
2. Use `kDebugMode` for dev-only logs:
   ```dart
   if (kDebugMode) {
     print('Debug info: $data');
   }
   ```
3. Remove sensitive data from logs
4. Add log levels (info, warning, error)
5. Configure log output (console, file, remote)

**Estimated Effort**: 1-2 days

---

#### 5.2 Remove/Document Orphaned Screens (Week 11, Day 3)

**Orphaned Screens**:
1. Old workout screens (replaced by refactored versions)
   - `workout_plan_viewer_screen.dart` (old)
   - `coach_plan_builder_screen.dart` (old)
   - `workout_plan_builder_screen.dart` (old)
2. Legacy login screen
   - `login_screen.dart` (replaced by `modern_login_screen.dart`)
3. Example/test screens
   - `unified_coach_profile_example.dart`
   - `calling_demo_screen.dart`

**Approach**:
1. Verify screens are truly unused (grep for imports)
2. Either:
   - Delete if confirmed unused
   - OR move to `lib/archive/` with `.archived` suffix
3. Document why removed (commit message)
4. Update any lingering references

**Estimated Effort**: 0.5 days

---

#### 5.3 End-to-End Testing (Week 11, Day 4-5)

**Critical User Flows**:
1. ✅ Sign up → Onboarding → Dashboard
2. ✅ Login → Dashboard → Logout
3. ✅ Client: View workout → Log session → Complete
4. ✅ Client: Log meals → Track macros → View history
5. ✅ Client: Upload progress photo → View timeline
6. ✅ Client: Message coach → Receive reply
7. ✅ Coach: View clients → Open profile → Review progress
8. ✅ Coach: Create workout plan → Assign to client
9. ✅ Coach: Create nutrition plan → Send to client
10. ✅ Admin: View support tickets → Reply → Close ticket

**Testing Checklist**:
- Test on iOS and Android
- Test with different user roles
- Test offline behavior
- Test with slow network
- Test with large datasets

**Estimated Effort**: 2 days

---

#### 5.4 Performance Audit (Week 12, Day 1-2)

**Metrics to Measure**:
- App launch time (<3 seconds)
- Screen transition time (<300ms)
- Time to first meaningful paint
- Frame rate (target: 60fps)
- Memory usage
- Battery consumption
- Network efficiency

**Optimization Tasks**:
1. Profile with Flutter DevTools
2. Identify expensive builds (widget rebuilds)
3. Add `const` constructors where possible
4. Lazy-load images with `cached_network_image`
5. Paginate long lists
6. Implement virtualized scrolling for huge lists
7. Optimize database queries (indexes)
8. Cache frequently accessed data
9. Reduce bundle size (tree shaking)

**Estimated Effort**: 2 days

---

#### 5.5 Accessibility Audit (Week 12, Day 3)

**WCAG 2.1 AA Compliance**:
- Color contrast (4.5:1 for text)
- Touch target size (minimum 44×44 pt)
- Focus indicators
- Semantic labels
- Screen reader support
- Keyboard navigation

**Tools**:
- `flutter accessibility inspector`
- iOS Accessibility Inspector
- Android Accessibility Scanner

**Estimated Effort**: 1 day

---

#### 5.6 Security Review (Week 12, Day 4-5)

**Security Checklist**:
- ✅ No hardcoded secrets (completed in previous audit)
- ✅ Environment variables used
- ✅ API keys secured
- ✅ HTTPS only
- ✅ Certificate pinning (consider)
- ✅ Input validation (SQL injection, XSS prevention)
- ✅ Secure storage (keychain/keystore for tokens)
- ✅ Session timeout configured
- ✅ Biometric auth secure
- ✅ Row-Level Security (RLS) on all tables

**Penetration Testing** (Optional):
- Hire third-party security audit
- OR use automated tools (OWASP ZAP)

**Estimated Effort**: 2 days

---

### Phase 5 Deliverables

- ✅ Zero debug statements in production
- ✅ Orphaned screens removed
- ✅ All critical user flows tested
- ✅ Performance optimized (60fps, <3s launch)
- ✅ Accessibility compliant (WCAG AA)
- ✅ Security reviewed and approved

**Total Effort**: 2 weeks
**Success Metrics**:
- Beta ready
- No P0/P1 bugs
- Performance benchmarks met
- Security sign-off

---

## Phase 6: Feature Restoration Review (Week 13+)

### Goal
Evaluate archived services and decide on restoration priority.

### Archived Services Review

#### 6.1 Voice Interface Service
**Status**: Archived (disabled)
**Location**: `lib/archive/voice_interface_service.dart.disabled`

**Evaluation Questions**:
- Is there user demand for voice commands?
- What voice features are most valuable?
  - Voice log workout
  - Voice log meal
  - Voice search
  - Voice assistant
- What's the technical lift?
  - Integration with speech-to-text API
  - Natural language processing
  - Command parsing
- What's the ROI?

**Decision**: Restore if user research shows demand

---

#### 6.2 Restaurant Service
**Status**: Archived (disabled)
**Location**: `lib/archive/restaurant_service.dart.disabled`

**Evaluation Questions**:
- Are restaurant integrations ready?
- What data sources available?
  - Yelp API
  - Google Places
  - Nutritionix restaurant database
- What features would be included?
  - Find nearby restaurants
  - View menus with macros
  - Order integration
  - Save favorite restaurants

**Decision**: Restore when partnerships established

---

#### 6.3 Sustainability Tracking
**Status**: Archived (disabled)
**Location**: `lib/archive/sustainability_service.dart.disabled`

**Evaluation Questions**:
- Is sustainability a product requirement?
- What metrics to track?
  - Carbon footprint of meals
  - Eco-friendly food choices
  - Local/organic preference
- Is this a differentiator?

**Decision**: Low priority, consider for future

---

#### 6.4 Offline Mode
**Status**: Archived (removed)
**Services**: `offline_banner.dart`, `offline_operation_queue.dart`

**Evaluation Questions**:
- How critical is offline functionality?
- What features need offline support?
  - View cached workout plans
  - Log workouts offline (sync later)
  - View cached meal plans
- What's the complexity?
  - Local database (Hive, Drift)
  - Sync queue implementation
  - Conflict resolution

**Decision**: Re-evaluate based on user feedback about connectivity issues

---

#### 6.5 Deploy workout_sessions Table

**Critical Dependency**: Multiple features depend on this table:
- Workout session mode (Phase 2)
- Workout history (Phase 2)
- Analytics (coach dashboard)
- Skipped sessions alerts (coach inbox)

**Steps**:
1. Review migration file: `supabase/migrations/migrate_workout_v1_to_v2.sql`
2. Verify schema matches code expectations:
   - Current migration has: `user_id`, `day_id`, `started_at`, `completed_at`
   - Coach inbox needs: `client_id`, `status`, `scheduled_date`
3. Decide:
   - **Option A**: Update migration to match all code needs
   - **Option B**: Update code to use migration schema + add views
4. Apply migration to database
5. Re-enable commented queries in:
   - `coach_inbox_service.dart:225-242`
   - `workout_analytics_service.dart:347-355, 839-845`
6. Test thoroughly

**Estimated Effort**: 2-3 days
**Recommended**: Do in Phase 2 (before workout session mode)

---

### Phase 6 Deliverables

- 🔍 Archived services evaluated
- 🔍 Restoration priorities set
- ✅ workout_sessions table deployed (if needed)
- 📋 Product roadmap for future features

**Total Effort**: Varies (product-driven)

---

## Risk Management

### High-Risk Areas

#### Risk 1: workout_sessions Table Deployment
**Impact**: HIGH (blocks Phase 2 features)
**Mitigation**:
- Deploy early in Phase 2 (Week 3)
- Thorough testing before dependent features
- Have rollback migration ready

#### Risk 2: Performance Degradation
**Impact**: MEDIUM (poor UX)
**Mitigation**:
- Profile early and often
- Set performance budgets
- Automated performance testing

#### Risk 3: Scope Creep
**Impact**: MEDIUM (timeline slips)
**Mitigation**:
- Stick to roadmap priorities
- Defer non-critical features to post-launch
- Use feature flags for gradual rollout

#### Risk 4: Third-Party Dependencies
**Impact**: LOW-MEDIUM (package issues)
**Mitigation**:
- Pin package versions
- Test package upgrades in isolation
- Have fallback plans for critical packages

---

## Success Metrics

### Phase-by-Phase Metrics

**Phase 1** (Week 1-2):
- ✅ 0 critical bugs
- ✅ PDF export success rate: 100%
- ✅ Intake form responses viewable

**Phase 2** (Week 3-5):
- ✅ Workout session completion rate: >80%
- ✅ File preview success rate: 100%
- ✅ Macro calculation accuracy: 100%

**Phase 3** (Week 6-8):
- ✅ All 10 widgets implemented
- ✅ Widget usage in app: >50% of users

**Phase 4** (Week 9-10):
- ✅ User satisfaction score: >4.5/5
- ✅ UX consistency score: >90%

**Phase 5** (Week 11-12):
- ✅ Crash-free rate: >99.5%
- ✅ Performance score: >90
- ✅ Accessibility score: WCAG AA compliant

**Phase 6** (Week 13+):
- 🔍 Feature prioritization complete
- 🔍 Product roadmap defined

---

## Resource Requirements

### Development Team

**Recommended**:
- 2 Flutter developers (full-time)
- 1 Backend developer (part-time, Supabase)
- 1 Designer (part-time, UX polish)
- 1 QA tester (full-time, starting Phase 4)

**Minimum**:
- 1 Full-stack Flutter developer
- 1 QA tester (part-time)

---

## Timeline Summary

| Phase | Weeks | Focus | Status |
|-------|-------|-------|--------|
| Phase 1 | 1-2 | Critical Fixes | 🔲 Not started |
| Phase 2 | 3-5 | High-Value Features | 🔲 Not started |
| Phase 3 | 6-8 | Widget Library | 🔲 Not started |
| Phase 4 | 9-10 | UX Polish | 🔲 Not started |
| Phase 5 | 11-12 | Production Readiness | 🔲 Not started |
| Phase 6 | 13+ | Feature Restoration | 🔲 Not started |

**Total Duration**: 12-13 weeks (3 months)
**Go-Live Target**: ~January 2026

---

## Rollout Strategy

### Beta Testing (Week 11-12)

**Beta Group**:
- 10-20 friendly users
- Mix of clients and coaches
- Diverse devices (iOS/Android)

**Beta Feedback**:
- Survey after 1 week
- Focus groups
- Bug reports via TestFlight/Firebase

---

### Phased Launch (Week 13+)

**Phase 1**: Soft Launch
- 100 users
- Invite-only
- Heavy monitoring

**Phase 2**: Limited Launch
- 500 users
- Referral program
- Feature flags for gradual rollout

**Phase 3**: Public Launch
- Open to all
- Marketing campaign
- Full support team ready

---

## Appendix

### Related Documents

1. **FINAL_DATABASE_AUDIT.md** - Database health report
2. **FEATURE_TEST_CHECKLIST.md** - Comprehensive testing checklist (350+ features)
3. **UI_FEATURE_AUDIT.md** - Detailed audit findings (207 screens)
4. **all_screens.txt** - Complete screen inventory
5. **screens_by_module.txt** - Categorized screens
6. **code_todos.txt** - All TODO markers catalogued

---

### Contact & Support

**Project Lead**: Development Team
**Timeline Owner**: Product Manager
**Technical Lead**: Senior Flutter Developer

**Questions?** Review audit docs or consult product roadmap.

---

**End of Restoration Roadmap**

*This roadmap is a living document. Update as priorities shift or new issues emerge.*
