# ⚡ 10-MINUTE PRODUCTION SMOKE TEST

**Test Device:** Real Android/iPhone (not emulator)  
**Test Account:** Fresh user + existing coach  
**Duration:** 10 minutes  
**Status:** 🔄 READY TO EXECUTE

---

## 🎯 **CRITICAL PATH (2 mins)**

### 1. Auth Flow (30 sec)
```
✅ Sign up with email
✅ Verify email received
✅ Sign in/out
✅ Password reset email received
```

### 2. Core Navigation (30 sec)
```
✅ Home dashboard loads
✅ Tap each nav item (Messages, Calendar, Progress, Settings)
✅ No crashes
✅ All screens render
```

### 3. Critical Edge Functions (60 sec)
```
✅ Settings → Export My Data → Opens signed URL
✅ Settings → Delete Account → Creates delete_requests row
✅ Calendar → Create booking → Conflict detection triggers (if overlap)
```

---

## 🧪 **FEATURE VERIFICATION (8 mins)**

### 1. Calendar & Booking (90 sec)
```
Test Steps:
1. Calendar → Add Event
   - Title: "Weekly Team Call"
   - Set recurring: Every Tuesday at 10am
   - Add reminder: 15 min before
   - Save

2. Verify:
   ✅ Event appears on multiple Tuesdays
   ✅ Local notification scheduled (check in 15 mins)
   
3. Create overlapping booking (same coach, same time)
   ✅ Conflict modal blocks creation
   ✅ Shows "calendar-conflicts" edge function working
```

### 2. Files & Media (90 sec)
```
Test Steps:
1. Files → Upload
   - Upload 1 image
   - Upload 1 PDF

2. Verify:
   ✅ Image preview shows
   ✅ PDF preview shows (pdfx package)
   
3. Add tag "Important"
   ✅ Tag appears
   ✅ Search by tag works

4. Add comment "Review this"
   ✅ Comment saved
   
5. Upload new version
   ✅ Version history shows
```

### 3. Progress & Check-ins (90 sec)
```
Test Steps:
1. Progress → Add Check-in
   - Weight: 75kg
   - Notes: "Feeling great"
   - Attach photo
   - Save

2. Verify:
   ✅ Check-in appears in calendar view
   ✅ Photo thumbnail shows
   ✅ Compliance score updates (if streak)
   ✅ Progress chart renders (7/30-day MA)
```

### 4. Messaging (90 sec)
```
Test Steps:
1. Messages → Open conversation with coach
   - Send text: "Hey coach"
   - Attach file
   - Send

2. Verify:
   ✅ Message sends
   ✅ File attachment shows
   ✅ Read receipt appears (if coach online)
   ✅ Typing indicator works (if coach types)
   
3. Long-press message
   ✅ "Pin Message" option works
   ✅ "Reply in Thread" creates thread
   
4. Try AI features (if enabled)
   ✅ Smart replies appear (if aiMessaging flag ON)
   ✅ Translation toggle works (if messagingTranslation ON)
```

### 5. Billing & Subscriptions (60 sec)
```
Test Steps:
1. Settings → Upgrade Plan
   ✅ Free/Premium/Coach tiers show
   ✅ Feature comparison visible
   
2. Admin panel (if admin role)
   ✅ Grant premium_client to test user
   ✅ Verify paywall disappears
   ✅ Revoke subscription
   ✅ Verify paywall re-appears
```

### 6. Settings & Account (60 sec)
```
Test Steps:
1. Settings → Export My Data
   ✅ Click button
   ✅ "Export ready - opening..." snackbar
   ✅ Browser opens signed URL
   ✅ ZIP downloads (contains JSON exports)

2. Settings → Request Account Deletion
   ✅ Dialog appears
   ✅ "Request" button upserts delete_requests row
   ✅ Confirmation snackbar shows

3. Admin panel (if admin)
   ✅ "Process Now" calls process-delete edge function
   ✅ User profile anonymized
   ✅ delete_requests.status = 'done'
```

### 7. Admin Tools (60 sec)
```
Test Steps (Admin role required):
1. Admin → User Management
   ✅ List loads
   ✅ Search works
   
2. Admin → Coach Approval
   ✅ Pending coaches list
   ✅ Approve/reject works
   
3. Admin → Ads System
   ✅ Create ad: "Spring Sale"
   ✅ Placement: home_banner
   ✅ is_active = true
   ✅ Save
   
4. Go to home screen
   ✅ Banner ad appears
   ✅ Click ad
   ✅ ad_clicks increments
```

---

## 🔍 **EDGE FUNCTION VALIDATION**

### 1. calendar-conflicts (CRITICAL)
```sql
-- Manual test in Supabase SQL editor:
SELECT * FROM calendar_events 
WHERE coach_id = 'YOUR_COACH_ID' 
AND start_at < '2025-10-12 11:00:00'::timestamp 
AND end_at > '2025-10-12 10:00:00'::timestamp;
```
✅ Returns overlapping events  
✅ Edge function blocks booking creation

### 2. export-user-data (CRITICAL)
```bash
# Expected behavior:
- User clicks "Export My Data"
- Edge function zips: profile, messages, checkins, files metadata, etc.
- Uploads to storage bucket
- Returns signed URL (60-min expiry)
- User downloads ZIP
```
✅ ZIP contains valid JSON  
✅ All user data present  
✅ No other users' data leaked

### 3. process-delete (CRITICAL)
```sql
-- After admin triggers delete:
SELECT * FROM profiles WHERE id = 'DELETED_USER_ID';
-- Should show:
-- email: deleted_XXXXX@deleted.local
-- full_name: 'Deleted User'
-- avatar_url: null

SELECT * FROM delete_requests WHERE user_id = 'DELETED_USER_ID';
-- Should show:
-- status: 'done'
-- processed_at: [timestamp]
```
✅ Profile anonymized  
✅ Storage files deleted (if flag set)  
✅ delete_requests updated

---

## ⚠️ **RED FLAGS (STOP IF YOU SEE THESE)**

### Critical Failures
```
❌ Any screen crashes on load
❌ Sign in/out fails
❌ Edge functions return 500
❌ Database connection errors
❌ Null pointer exceptions
❌ Data visible to wrong users (RLS breach)
```

### Performance Red Flags
```
⚠️ Any screen takes >3 sec to load
⚠️ Queries time out
⚠️ Index hit ratio < 80%
⚠️ Memory leaks (app slows over time)
```

### Security Red Flags
```
🔒 User A sees User B's data
🔒 Client sees coach's admin panel
🔒 Edge functions callable without auth
🔒 RLS policies disabled
```

---

## ✅ **SUCCESS CRITERIA**

### Must Pass (100%)
- ✅ Zero crashes
- ✅ Zero RLS breaches
- ✅ All 3 edge functions work
- ✅ Sign in/out works
- ✅ Calendar conflicts blocked
- ✅ Export/delete functions work

### Should Pass (90%+)
- ✅ All screens render
- ✅ All forms submit
- ✅ All uploads work
- ✅ All queries fast (<500ms)
- ✅ All notifications schedule

### Nice to Have (80%+)
- ✅ Animations smooth
- ✅ UI polish complete
- ✅ All i18n strings translated
- ✅ All images optimized

---

## 📊 **MONITORING DURING TEST**

### Supabase Dashboard
```
1. Functions → calendar-conflicts, export-user-data, process-delete
   ✅ Invocation count increases
   ✅ Error rate = 0%
   ✅ Avg duration < 2 sec

2. Database → Query Performance
   ✅ Index hit ratio > 90%
   ✅ Slow queries = 0
   ✅ Active connections < 10

3. Storage → user-files
   ✅ Files upload successfully
   ✅ Signed URLs work
```

### Flutter DevTools (If debugging)
```
1. Memory
   ✅ No memory leaks
   ✅ Heap size stable

2. Performance
   ✅ Frame render < 16ms (60fps)
   ✅ No jank on scroll
```

---

## 🚀 **POST-SMOKE TEST**

### If ALL PASS ✅
```bash
# 1. Tag release
git tag v1.0.0
git push origin v1.0.0

# 2. Build for stores
flutter build appbundle --release  # Android
flutter build ios --release         # iOS

# 3. Submit to stores
# Google Play: Upload to Play Console (staged rollout 10%)
# App Store: Archive in Xcode → submit to TestFlight → Production

# 4. Enable monitoring
# - Crashlytics alerts
# - Supabase function alerts
# - Database slow query alerts
```

### If ANY FAIL ❌
```bash
# 1. Document the issue
- Screenshot/video
- Steps to reproduce
- Expected vs actual

# 2. Fix issue
- Hotfix branch
- Test locally
- Deploy

# 3. Re-run smoke test
- Verify fix
- Check for regressions
```

---

## ⏱️ **TIMING BREAKDOWN**

| Test Section | Duration | Priority |
|--------------|----------|----------|
| Critical Path | 2 min | 🔴 MUST DO |
| Calendar & Booking | 90 sec | 🔴 MUST DO |
| Files & Media | 90 sec | 🟡 SHOULD DO |
| Progress | 90 sec | 🟡 SHOULD DO |
| Messaging | 90 sec | 🔴 MUST DO |
| Billing | 60 sec | 🟡 SHOULD DO |
| Settings & Account | 60 sec | 🔴 MUST DO |
| Admin Tools | 60 sec | 🟢 NICE TO HAVE |

**Total:** ~10 minutes (5 min critical + 5 min comprehensive)

---

## ✅ **CHECKLIST**

```
Critical (MUST PASS):
[ ] Auth sign in/out works
[ ] Export My Data works (edge function)
[ ] Account Deletion works (edge function)
[ ] Calendar Conflicts work (edge function)
[ ] No crashes on critical paths
[ ] No RLS breaches

Comprehensive (SHOULD PASS):
[ ] File upload/preview/tag/comment works
[ ] Check-in with photo works
[ ] Progress charts render
[ ] Messaging send/attach/thread works
[ ] Billing plan comparison shows
[ ] Calendar recurring events work
[ ] Reminders schedule

Optional (NICE TO HAVE):
[ ] Admin ads system works
[ ] Smart replies appear
[ ] Translation toggle works
[ ] All animations smooth
```

---

**🎯 GOAL: ALL CRITICAL ITEMS PASS**  
**⏱️ TIME LIMIT: 10 MINUTES MAX**  
**📱 TEST ON: REAL DEVICE ONLY**

**READY TO TEST!** 🚀

