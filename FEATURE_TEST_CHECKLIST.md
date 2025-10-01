# VAGUS App - Feature Test Checklist
**Generated**: October 1, 2025
**Purpose**: Manual testing checklist for all features
**Status Legend**:
- ✅ Working perfectly
- ⚠️ Partially working (see notes)
- ❌ Broken (see error)
- 🔲 Not tested yet
- 🚫 Not implemented

---

## Authentication & Onboarding

### Sign Up Flow
- 🔲 Email/password signup
- 🔲 Google sign-in
- 🔲 Apple sign-in
- 🔲 Email verification flow
- 🔲 Profile setup wizard
- 🔲 Biometric enrollment prompt

**Test Path**: `modern_login_screen.dart` → `signup_screen.dart`

### Sign In Flow
- 🔲 Email/password login
- 🔲 Google login
- 🔲 Apple login
- 🔲 Remember me functionality
- 🔲 Biometric login (fingerprint/face)
- 🔲 Auto-login on app restart

**Test Path**: `modern_login_screen.dart` → `auth_gate.dart`

### Password Management
- 🔲 Password reset request
- 🔲 Password reset email received
- 🔲 Set new password flow
- 🔲 Password strength validation
- 🔲 Password visibility toggle

**Test Path**: `password_reset_screen.dart` → `set_new_password_screen.dart`

### Role Selection
- 🔲 Select "I'm a client" role
- 🔲 Select "I'm a coach" role
- 🔲 Role persists across sessions
- 🔲 Become coach flow
- 🔲 Coach approval process

**Test Path**: `auth_gate.dart` → `become_coach_screen.dart`

---

## Client Features

### Client Dashboard
- 🔲 Dashboard loads without errors
- 🔲 Today's workout displayed
- 🔲 Nutrition summary shows macros
- 🔲 Progress photos visible
- 🔲 Quick actions work (check-in, message coach)
- 🔲 Streak counter displays
- 🔲 Recent activity feed loads

**Test Path**: `main_nav.dart` → `modern_client_dashboard.dart`

**Known Issues**:
- ⚠️ Heavy debug logging (non-blocking)
- ⚠️ Timeout handling on slow connections

### Workout Viewing
- 🔲 View active workout plan
- 🔲 See all weeks in plan
- 🔲 Expand/collapse weeks
- 🔲 View exercises for each day
- 🔲 See sets/reps/weight targets
- 🔲 Exercise descriptions load
- 🔲 Progression notes visible
- 🔲 Attachments (videos/images) open

**Test Path**: `main_nav.dart` → `modern_workout_plan_viewer.dart`

**Known Issues**:
- ❌ **CRITICAL**: PDF export broken (Windows path issue)

### Workout Logging
- 🔲 Start workout session
- 🔲 Log sets and reps
- 🔲 Enter weight used
- 🔲 Record RPE (Rate of Perceived Exertion)
- 🔲 Add exercise notes
- 🔲 Mark exercises complete
- 🔲 Rest timer works
- 🔲 Session summary displays
- 🔲 Complete workout and save

**Test Path**: `workout_plan_viewer_screen_refactored.dart` (session mode)

**Known Issues**:
- ⚠️ Session mode UI incomplete (basic functionality works)
- 🚫 Exercise demo player not implemented
- 🚫 Workout history screen missing

### Nutrition Tracking

#### Meal Logging
- 🔲 Log breakfast
- 🔲 Log lunch
- 🔲 Log dinner
- 🔲 Log snacks
- 🔲 View daily macro totals
- 🔲 See macro breakdown chart
- 🔲 Check remaining calories

**Test Path**: `nutrition_hub_screen.dart`

**Known Issues**:
- ⚠️ Meal model missing fields (id, timestamps, mealType, photo_url)
- ⚠️ Macro calculations may be incomplete

#### Barcode Scanner
- 🔲 Open barcode scanner
- 🔲 Scan food barcode
- 🔲 Food details populate
- 🔲 Adjust serving size
- 🔲 Add to meal log
- 🔲 View nutrition info

**Test Path**: `barcode_scanner_tab.dart` → `smart_barcode_scanner.dart`

#### Food Snap (OCR)
- 🔲 Open camera for food photo
- 🔲 Take photo of meal
- 🔲 OCR processes image
- 🔲 Food items detected
- 🔲 Macros estimated
- 🔲 Edit detected items
- 🔲 Save to meal log

**Test Path**: `nutrition_hub_screen.dart` (Food Snap button)

**Known Issues**:
- ⚠️ OCR accuracy depends on image quality
- ⚠️ May require API credits

#### Manual Food Entry
- 🔲 Search food database
- 🔲 Select food from results
- 🔲 Adjust serving size
- 🔲 Add to meal
- 🔲 Create custom food
- 🔲 Save custom food to library

**Test Path**: `custom_foods_tab.dart`

**Known Issues**:
- ⚠️ Recipe navigation incomplete (TODO)

#### Grocery List
- 🔲 View auto-generated grocery list
- 🔲 Check off items
- 🔲 Add custom items
- 🔲 Remove items
- 🔲 Clear completed items
- 🔲 Share list via text/email

**Test Path**: `grocery_list_screen.dart`

### Progress Tracking

#### Photo Check-ins
- 🔲 Upload progress photo
- 🔲 Take photo with camera
- 🔲 Add notes to photo
- 🔲 View photo timeline
- 🔲 Compare photos side-by-side
- 🔲 Delete photos
- 🔲 Share photos with coach

**Test Path**: `upload_photos_screen.dart` → `check_ins_screen.dart`

**Known Issues**:
- ⚠️ File preview navigation incomplete (8 instances)
- 🚫 Photo comparison feature not implemented

#### Weight Tracking
- 🔲 Log daily weight
- 🔲 View weight trend chart
- 🔲 See weight change over time
- 🔲 Edit past entries
- 🔲 Delete entries

**Test Path**: `weight_screen.dart`

#### Body Measurements
- 🔲 Log measurements (chest, waist, hips, etc.)
- 🔲 View measurement history
- 🔲 See progress charts
- 🔲 Edit past measurements

**Test Path**: `measurements_screen.dart`

#### Quick Check-ins
- 🔲 Quick check-in from dashboard
- 🔲 Rate energy level
- 🔲 Rate sleep quality
- 🔲 Rate mood
- 🔲 Add quick notes
- 🔲 Submit check-in

**Test Path**: `quick_check_in_screen.dart`

### Messaging
- 🔲 View message threads
- 🔲 Send text message to coach
- 🔲 Send photo/video attachment
- 🔲 Send voice message
- 🔲 View message history
- 🔲 Receive push notifications for new messages
- 🔲 Mark messages as read

**Test Path**: `main_nav.dart` → `modern_messenger_screen.dart`

### Calendar
- 🔲 View workout schedule
- 🔲 View meal plan schedule
- 🔲 See upcoming events
- 🔲 View past completed workouts
- 🔲 Navigate between months
- 🔲 Tap date to see details

**Test Path**: `main_nav.dart` → `modern_calendar_viewer.dart`

### Profile & Settings
- 🔲 Edit profile information
- 🔲 Change profile photo
- 🔲 Update goals
- 🔲 Change notification preferences
- 🔲 Enable/disable push notifications
- 🔲 Change theme (light/dark)
- 🔲 Manage connected devices
- 🔲 View AI usage quotas
- 🔲 Logout

**Test Path**: `profile_screen.dart` → `edit_profile_screen.dart` → `settings_screen.dart`

### Supplements
- 🔲 Log daily supplements
- 🔲 Track supplement timing
- 🔲 View supplement history
- 🔲 Set reminders for supplements

**Test Path**: `supplements_hub_screen.dart`

**Known Issues**:
- 🚫 Supplement edit screen not implemented

---

## Coach Features

### Coach Dashboard
- 🔲 Dashboard loads without errors
- 🔲 Client inbox displays
- 🔲 Flagged clients show alerts
- 🔲 AI insights visible
- 🔲 Quick actions work (message, create plan)
- 🔲 Recent activity feed loads
- 🔲 Analytics overview displays

**Test Path**: `main_nav.dart` → `modern_coach_dashboard.dart`

**Known Issues**:
- ⚠️ Debug logging present (non-blocking)

### Client Management

#### Client List
- 🔲 View all active clients
- 🔲 Search clients by name
- 🔲 Filter clients (active, inactive, flagged)
- 🔲 Sort clients (alphabetical, recent, status)
- 🔲 View client quick stats (adherence, progress)
- 🔲 Tap client to view profile

**Test Path**: `main_nav.dart` → `modern_client_management_screen.dart`

#### Client Profile
- 🔲 View client details
- 🔲 See client goals
- 🔲 View progress photos timeline
- 🔲 Check workout adherence
- 🔲 Review nutrition compliance
- 🔲 Read client notes
- 🔲 View weekly summaries
- 🔲 Access client files

**Test Path**: `coach_client_profile_screen.dart`

#### Client Onboarding
- 🔲 Send client invitation
- 🔲 Create intake form
- 🔲 Assign intake form to client
- 🔲 View client responses
- 🔲 Review submitted intake forms

**Test Path**: `coach_forms_screen.dart`

**Known Issues**:
- ❌ **CRITICAL**: Intake form response viewer not implemented

### Workout Plan Builder

#### Plan Creation
- 🔲 Create new workout plan
- 🔲 Set plan name and description
- 🔲 Define number of weeks
- 🔲 Add workout weeks
- 🔲 Add workout days
- 🔲 Set day labels (e.g., Push, Pull, Legs)
- 🔲 Add exercises to days
- 🔲 Search exercise library
- 🔲 Set sets, reps, and rest
- 🔲 Add progression notes
- 🔲 Attach videos/images

**Test Path**: `coach_plan_builder_screen_refactored.dart`

**Known Issues**:
- ⚠️ 15+ TODOs in refactored version
- 🚫 10 missing widgets (per README)

#### Exercise Library
- 🔲 Browse exercise database
- 🔲 Search exercises by name
- 🔲 Filter by muscle group
- 🔲 Filter by equipment
- 🔲 View exercise details
- 🔲 See exercise demos
- 🔲 Create custom exercises
- 🔲 Add exercises to library

**Test Path**: Exercise library integration in plan builder

**Known Issues**:
- 🚫 Exercise demo player not implemented

#### Plan Templates
- 🔲 Create plan from template
- 🔲 Save plan as template
- 🔲 Browse template library
- 🔲 Edit templates
- 🔲 Share templates

**Test Path**: Template management in plan builder

#### Plan Assignment
- 🔲 Assign plan to client
- 🔲 Set plan start date
- 🔲 Customize plan for client
- 🔲 Send notification to client
- 🔲 Client receives plan

**Test Path**: Plan assignment flow

#### Program Ingestion (PDF Import)
- 🔲 Upload PDF workout program
- 🔲 AI processes PDF
- 🔲 Review extracted exercises
- 🔲 Edit extracted data
- 🔲 Import to plan builder
- 🔲 Convert to digital plan

**Test Path**: `program_ingest_upload_sheet.dart` → `program_ingest_preview_screen.dart`

**Known Issues**:
- ⚠️ Some features stubbed

### Nutrition Plan Builder
- 🔲 Create nutrition plan
- 🔲 Set macro targets (protein, carbs, fats)
- 🔲 Set calorie target
- 🔲 Create meal templates
- 🔲 Add recipes
- 🔲 Assign meal plan to client
- 🔲 Auto-generate grocery list
- 🔲 Schedule meals

**Test Path**: Nutrition plan builder

### Coach Messaging
- 🔲 View all client conversations
- 🔲 Filter by client status
- 🔲 See unread message count
- 🔲 Send message to client
- 🔲 Send bulk messages
- 🔲 Use message templates
- 🔲 Attach files to messages

**Test Path**: `main_nav.dart` → `modern_client_messages_screen.dart`

### Coach Notes
- 🔲 Add notes to client profile
- 🔲 Tag notes (workout, nutrition, general)
- 🔲 Search notes
- 🔲 View note history
- 🔲 Edit/delete notes
- 🔲 Pin important notes

**Test Path**: `coach_notes_screen.dart`

### Weekly Reviews
- 🔲 Generate weekly client report
- 🔲 Review workout adherence
- 🔲 Review nutrition compliance
- 🔲 See weight changes
- 🔲 View progress photos
- 🔲 Add coach comments
- 🔲 Send review to client

**Test Path**: `client_weekly_review_screen.dart`

### Coach Inbox
- 🔲 View flagged clients
- 🔲 See clients needing attention
- 🔲 Check skipped sessions alerts
- 🔲 Review low adherence warnings
- 🔲 Respond to client questions
- 🔲 Clear inbox items

**Test Path**: Coach inbox in dashboard

**Known Issues**:
- ⚠️ Skipped sessions check disabled (workout_sessions table not deployed)

### Coach Portfolio
- 🔲 Edit coach bio
- 🔲 Upload profile photo
- 🔲 Add specialties/certifications
- 🔲 Set coaching prices
- 🔲 Upload before/after photos
- 🔲 Add client testimonials
- 🔲 Publish portfolio
- 🔲 View public profile

**Test Path**: `unified_coach_profile_screen.dart` → `portfolio_edit_screen.dart`

### Coach Marketplace
- 🔲 Browse coach marketplace
- 🔲 Filter by specialty
- 🔲 Search coaches
- 🔲 View coach profiles
- 🔲 Book consultation
- 🔲 Send coach message

**Test Path**: `coach_marketplace_screen.dart` → `coach_portfolio_marketplace_screen.dart`

### Affiliates
- 🔲 View affiliate dashboard
- 🔲 Generate referral link
- 🔲 Share referral code
- 🔲 Track referrals
- 🔲 See earnings
- 🔲 View payout history

**Test Path**: `coach_affiliates_screen.dart`

---

## Calendar Features

### Event Management
- 🔲 Create calendar event
- 🔲 Edit event details
- 🔲 Set event reminders
- 🔲 Invite participants
- 🔲 Delete events
- 🔲 Recurring events

**Test Path**: `event_editor.dart`

### Availability Publishing
- 🔲 Set availability hours
- 🔲 Block unavailable times
- 🔲 Publish availability
- 🔲 Share booking link
- 🔲 Receive booking notifications

**Test Path**: `availability_publisher.dart`

### Booking Flow
- 🔲 View coach availability
- 🔲 Select time slot
- 🔲 Fill booking form
- 🔲 Confirm booking
- 🔲 Receive confirmation
- 🔲 Add to calendar

**Test Path**: `booking_form.dart`

---

## Calling Features

### Video/Audio Calls
- 🔲 Initiate call to coach
- 🔲 Receive incoming call
- 🔲 Accept call
- 🔲 Decline call
- 🔲 Mute/unmute microphone
- 🔲 Enable/disable video
- 🔲 Switch camera (front/back)
- 🔲 Speaker mode toggle
- 🔲 End call
- 🔲 Call duration display

**Test Path**: `simple_call_screen.dart` → `call_management_screen.dart`

**Known Issues**:
- 🚫 Speaker toggle not implemented
- 🚫 Camera switch not implemented
- 🚫 Call settings dialog missing

### Live Sessions
- 🔲 Start live session
- 🔲 Join live session
- 🔲 Screen sharing
- 🔲 Session recording
- 🔲 View participants
- 🔲 Chat during session

**Test Path**: `modern_live_calls_screen.dart`

---

## Files & Media

### File Upload
- 🔲 Upload document
- 🔲 Upload photo
- 🔲 Upload video
- 🔲 Select from gallery
- 🔲 Take photo with camera
- 🔲 Record video

**Test Path**: `upload_photos_screen.dart` → `file_manager_screen.dart`

**Known Issues**:
- 🚫 Video recording not implemented
- 🚫 Photo capture not implemented (uses system camera)

### File Management
- 🔲 View all files
- 🔲 Filter files (photos, videos, documents)
- 🔲 Search files
- 🔲 Preview files
- 🔲 Download files
- 🔲 Share files
- 🔲 Delete files

**Test Path**: `file_manager_screen.dart`

**Known Issues**:
- ❌ File preview navigation missing (8 instances)
- 🚫 File download not implemented
- 🚫 Share functionality not implemented

### Coach File Feedback
- 🔲 Coach views client files
- 🔲 Add comments to files
- 🔲 Request specific files
- 🔲 Mark files as reviewed

**Test Path**: `coach_file_feedback_screen.dart`

---

## Admin Features

### Admin Dashboard
- 🔲 View system overview
- 🔲 Monitor active users
- 🔲 Check system health
- 🔲 View recent incidents
- 🔲 Access admin tools

**Test Path**: `admin_hub_screen.dart` → `admin_screen.dart`

### User Management
- 🔲 View all users
- 🔲 Search users
- 🔲 Edit user details
- 🔲 Ban/suspend users
- 🔲 Change user roles
- 🔲 Reset user passwords
- 🔲 View user activity logs

**Test Path**: `user_manager_panel.dart`

### Coach Approval
- 🔲 View coach applications
- 🔲 Review coach credentials
- 🔲 Approve coach applications
- 🔲 Reject with feedback
- 🔲 Request additional info

**Test Path**: `coach_approval_panel.dart`

### Support Ticket System

#### Ticket Management
- 🔲 View all tickets
- 🔲 Filter by status (open, in progress, closed)
- 🔲 Filter by priority
- 🔲 Search tickets
- 🔲 Assign tickets to agents
- 🔲 View ticket details
- 🔲 Reply to tickets
- 🔲 Close tickets
- 🔲 Reopen tickets

**Test Path**: `support_inbox_screen.dart`

#### Ticket Board (Kanban)
- 🔲 View ticket board
- 🔲 Drag tickets between columns
- 🔲 Filter board view
- 🔲 Quick assign from board

**Test Path**: `admin_ticket_board_screen.dart`

#### Ticket Queue
- 🔲 View ticket queue
- 🔲 Prioritize tickets
- 🔲 Auto-routing based on rules
- 🔲 Load balancing

**Test Path**: `admin_ticket_queue_screen.dart`

#### SLA Policies
- 🔲 Create SLA policy
- 🔲 Set response time targets
- 🔲 Set resolution time targets
- 🔲 Apply policies to ticket types
- 🔲 View SLA compliance reports

**Test Path**: `admin_sla_policies_screen.dart` → `support_sla_editor_screen.dart`

#### Canned Replies
- 🔲 Create canned reply templates
- 🔲 Categorize templates
- 🔲 Use templates in tickets
- 🔲 Edit templates
- 🔲 Share templates with team

**Test Path**: `support_canned_replies_screen.dart`

#### Triage Rules
- 🔲 Create auto-triage rules
- 🔲 Set rule conditions
- 🔲 Define rule actions
- 🔲 Test rules
- 🔲 Enable/disable rules

**Test Path**: `admin_triage_rules_screen.dart` → `support_rules_editor_screen.dart`

### Incidents & Operations

#### Incident Management
- 🔲 View active incidents
- 🔲 Create incident report
- 🔲 Assign incident owner
- 🔲 Track incident status
- 🔲 View incident timeline
- 🔲 Resolve incidents
- 🔲 Post-mortem analysis

**Test Path**: `admin_incidents_screen.dart`

#### Root Cause Analysis
- 🔲 Perform RCA
- 🔲 Document findings
- 🔲 Link to incidents
- 🔲 Create action items

**Test Path**: `admin_root_cause_screen.dart`

#### Escalation Matrix
- 🔲 Define escalation paths
- 🔲 Set escalation thresholds
- 🔲 Assign escalation contacts
- 🔲 Test escalation flow

**Test Path**: `admin_escalation_matrix_screen.dart`

#### Playbooks
- 🔲 Create operational playbooks
- 🔲 Document procedures
- 🔲 Link to incidents
- 🔲 Version control playbooks

**Test Path**: `admin_playbooks_screen.dart`

#### Macros
- 🔲 Create automation macros
- 🔲 Define macro actions
- 🔲 Run macros on tickets
- 🔲 Schedule macros

**Test Path**: `admin_macros_screen.dart`

### Analytics & Reports

#### Analytics Dashboard
- 🔲 View user growth metrics
- 🔲 Track engagement stats
- 🔲 Monitor revenue
- 🔲 Export reports
- 🔲 Custom date ranges

**Test Path**: `admin_analytics_screen.dart` → `analytics_reports_screen.dart`

#### Agent Workload
- 🔲 View agent assignments
- 🔲 Track ticket load
- 🔲 Monitor response times
- 🔲 Capacity planning

**Test Path**: `admin_agent_workload_screen.dart`

### Ads & Banners
- 🔲 Create ad banner
- 🔲 Upload banner image
- 🔲 Set display rules (user type, location)
- 🔲 Schedule ad campaigns
- 🔲 Track banner clicks
- 🔲 A/B test banners

**Test Path**: `admin_ads_screen.dart`

### Knowledge Base
- 🔲 Create knowledge articles
- 🔲 Categorize articles
- 🔲 Search knowledge base
- 🔲 Link articles to tickets
- 🔲 Publish articles

**Test Path**: `admin_knowledge_screen.dart`

### Announcements
- 🔲 Create announcement
- 🔲 Target user segments
- 🔲 Schedule announcements
- 🔲 View announcement analytics

**Test Path**: `admin_announcements_screen.dart`

### AI Configuration
- 🔲 Configure AI models
- 🔲 Set usage quotas
- 🔲 Monitor AI usage
- 🔲 View AI costs
- 🔲 Adjust rate limits

**Test Path**: `ai_config_panel.dart`

### Audit Logs
- 🔲 View audit trail
- 🔲 Filter by user
- 🔲 Filter by action type
- 🔲 Export audit logs
- 🔲 Compliance reporting

**Test Path**: `audit_log_screen.dart`

### Global Settings
- 🔲 App-wide settings
- 🔲 Feature flags
- 🔲 Maintenance mode
- 🔲 API configurations

**Test Path**: `global_settings_panel.dart`

### Pricing Editor
- 🔲 Edit coaching prices
- 🔲 Set package prices
- 🔲 Configure discounts
- 🔲 Currency settings

**Test Path**: `price_editor_screen.dart`

### Diagnostics
- 🔲 Nutrition system diagnostics
- 🔲 Database health check
- 🔲 API status
- 🔲 Error logs

**Test Path**: `nutrition_diagnostics_screen.dart`

---

## Billing Features

### Payments
- 🔲 Add payment method
- 🔲 Update payment method
- 🔲 View payment history
- 🔲 Download receipts
- 🔲 Refund requests

**Test Path**: `billing_payments_screen.dart`

### Invoices
- 🔲 View invoice history
- 🔲 Download invoices
- 🔲 Print invoices
- 🔲 Email invoices

**Test Path**: `invoice_history_viewer.dart`

### Billing Settings
- 🔲 Update billing address
- 🔲 Change billing email
- 🔲 Auto-renewal settings
- 🔲 Cancel subscription

**Test Path**: `billing_settings.dart`

### Upgrade Flow
- 🔲 View subscription tiers
- 🔲 Compare plans
- 🔲 Select upgrade tier
- 🔲 Enter payment info
- 🔲 Confirm upgrade
- 🔲 Receive confirmation

**Test Path**: `upgrade_screen.dart`

---

## Additional Features

### Streaks
- 🔲 View current streak
- 🔲 Streak calendar visualization
- 🔲 Streak history
- 🔲 Streak milestones

**Test Path**: `streaks_screen.dart`

### Rank/Leaderboard
- 🔲 View personal rank
- 🔲 See leaderboard
- 🔲 Compare with friends
- 🔲 Rank badges

**Test Path**: `rank_screen.dart`

### Voice Commands
- 🔲 Enable voice assistant
- 🔲 Voice log workout
- 🔲 Voice log meal
- 🔲 Voice search

**Test Path**: `voice_command_screen.dart`

**Known Issues**:
- 🚫 Voice interface service archived (disabled)

### Integrations
- 🔲 Connect health apps (Apple Health, Google Fit)
- 🔲 Sync wearable data
- 🔲 Import workout data
- 🔲 Export data

**Test Path**: Integration settings

### Business Profile
- 🔲 Create business profile
- 🔲 Add business details
- 🔲 Team management
- 🔲 Business analytics

**Test Path**: `business_profile_screen.dart`

---

## Cross-Cutting Concerns

### Performance
- 🔲 App launches in <3 seconds
- 🔲 Screen transitions smooth (60fps)
- 🔲 Images load quickly
- 🔲 No janky scrolling
- 🔲 Offline functionality

### Error Handling
- 🔲 Network errors shown gracefully
- 🔲 Validation errors clear
- 🔲 Form errors highlighted
- 🔲 Retry mechanisms work

### Notifications

#### Push Notifications
- 🔲 Receive workout reminders
- 🔲 Receive message notifications
- 🔲 Receive coach alerts
- 🔲 Notification settings work
- 🔲 Notification deep-linking works

#### In-App Notifications
- 🔲 Notification bell icon shows count
- 🔲 Notification list displays
- 🔲 Mark as read
- 🔲 Clear all notifications

### Accessibility
- 🔲 Screen reader support
- 🔲 Font scaling works
- 🔲 High contrast mode
- 🔲 Keyboard navigation

### Security
- 🔲 Sensitive data encrypted
- 🔲 Secure API communication (HTTPS)
- 🔲 Biometric protection works
- 🔲 Session timeout
- 🔲 Auto-logout on inactivity

---

## Testing Notes

### How to Use This Checklist

1. **Systematic Testing**: Test one section at a time
2. **Update Status**: Mark each item as you test
3. **Document Issues**: Add notes for broken/partial features
4. **Priority**: Focus on critical user flows first
5. **Regression**: Re-test after fixes

### Priority Testing Order

1. **P0 (Critical)**: Auth, Dashboard, Core Workout/Nutrition
2. **P1 (High)**: Messaging, Calendar, Progress Tracking
3. **P2 (Medium)**: Coach Tools, File Management
4. **P3 (Low)**: Admin Features, Advanced Analytics

### Test Environments

- [ ] Development (local)
- [ ] Staging
- [ ] Production

### Test Devices

- [ ] iOS (iPhone)
- [ ] Android (Pixel/Samsung)
- [ ] iOS Tablet
- [ ] Android Tablet

### Test Users

- [ ] Client role
- [ ] Coach role
- [ ] Admin role

---

## Known Critical Issues (Do Not Test - Already Documented)

1. ❌ **PDF Export**: Broken (Windows path resolution)
2. ❌ **Intake Form Responses**: Not implemented (coach cannot view)
3. ⚠️ **File Preview Navigation**: Incomplete (8 instances)
4. ⚠️ **Workout Session Mode**: Basic UI incomplete
5. ⚠️ **Meal Model**: Missing fields (id, timestamps, mealType, photo_url)
6. ⚠️ **Skipped Sessions Check**: Disabled (workout_sessions table not deployed)

---

**Total Features to Test**: 350+
**Estimated Testing Time**: 40-60 hours
**Last Updated**: October 1, 2025
