# Revolutionary Plan Builder - Quick Start Guide

## 🚀 Create Your First Plan in 3 Minutes

### Step 1: Plan Basics (30 seconds)
1. **Plan Name**: Tap the plan name field at the top and enter a descriptive name (e.g., "8-Week Strength Builder")
2. **Client**: Tap the client selector and choose from your client list
3. **Duration**: Select how many weeks (1-52)
4. **Start Date**: Pick the program start date

### Step 2: Add Exercises (2 minutes)
1. **Navigate**: Select a week from the left sidebar, then tap a day (Mon-Sun)
2. **Add Exercise**: Tap the green "Add Exercise" button (bottom-right)
3. **Search**: Find your exercise in the library
4. **Edit Details**: Tap the edit icon to set:
   - Sets, Reps, Weight
   - Rest periods
   - Advanced: %1RM, RIR, Tempo
   - Training Method: Superset, Circuit, etc.

### Step 3: Save & Review (30 seconds)
1. **Auto-Save**: Plan saves every 30 seconds automatically
2. **Manual Save**: Tap the green "Save" button (top-right) anytime
3. **View Analytics**: Tap the purple analytics button (bottom-right) to see weekly stats

---

## 💪 Key Features Overview

### Exercises
- **Full Editor**: Sets, reps, weight, rest, %1RM, RIR, tempo, notes
- **Training Methods**: Color-coded supersets (blue), circuits (orange), giant sets (purple), drop sets (pink)
- **Visual Indicators**: Bordered cards with glow effects show exercise grouping
- **Quick Actions**: Edit or delete any exercise with one tap

### Cardio
- **Add Cardio**: Orange button above "Add Exercise"
- **5 Types**: LISS, MISS, HIIT, Intervals, Sprints
- **5 Machines**: Treadmill, Bike, Rower, Elliptical, Stairmaster
- **Machine Settings**: Speed, resistance, incline, RPM, stroke rate, etc.
- **Intervals**: Program work/rest intervals for HIIT

### Day Management
- **Stats Panel**: Auto-calculated duration, exercise count, cardio count
- **Day Notes**: Add coaching instructions or client reminders
- **Rest Days**: Automatically detected when no exercises/cardio added

### Analytics
- **Weekly Volume**: Bar chart showing volume per day
- **Muscle Groups**: Distribution of exercises by muscle group
- **Tonnage**: Total weight moved across all exercises
- **Time**: Total hours, sessions/week, average duration

### Smart Features
- **Auto-Save**: Never lose work (saves every 30 seconds)
- **Undo/Redo**: Made a mistake? Undo instantly (50-step history)
- **Real-Time Calculations**: Volume, tonnage, duration update live
- **Confirmations**: Delete actions require confirmation to prevent accidents
- **Validation**: Input validation prevents invalid data

---

## 📱 Mobile vs Desktop Tips

### Mobile (Phone/Tablet)
- **Sidebars Auto-Hide**: Exercise library and week list hide on small screens
- **Stacked Buttons**: FABs stack vertically for easy thumb access
- **Analytics**: Swipe down to close the analytics panel
- **SafeArea**: Content never gets cut off by notches or home indicators
- **Touch Targets**: All buttons are 48px+ for easy tapping

### Desktop
- **Sidebars**: Week overview (left) and exercise library (right) always visible
- **Analytics**: Fixed height panel at bottom
- **More Options**: All secondary actions in overflow menu (top-right)
- **Keyboard**: Ctrl+S to save (when Flutter 3.19+ available)

---

## 🔥 Common Workflows

### Create a Push/Pull/Legs Split
1. Create plan with 1 week duration
2. **Day 1 (Monday)**: Add push exercises (bench, shoulder press, triceps)
3. **Day 2 (Tuesday)**: Add pull exercises (rows, pull-ups, biceps)
4. **Day 3 (Wednesday)**: Rest day (leave empty)
5. **Day 4 (Thursday)**: Add leg exercises (squat, leg press, lunges)
6. Duplicate week for remaining weeks

### Program a Superset
1. Add first exercise (e.g., Bench Press)
2. Tap edit → Advanced tab → Select "Superset"
3. Add second exercise (e.g., Bent-Over Row)
4. Tap edit → Advanced tab → Select "Superset"
5. Both exercises now show blue borders and "Superset" badge

### Add HIIT Cardio
1. Tap orange "Add Cardio" button
2. Select cardio type: "HIIT"
3. Choose machine: "Treadmill"
4. Set duration: 20 minutes
5. Set intensity: "High"
6. **Interval Settings**:
   - Work: 30 seconds
   - Rest: 30 seconds
   - Rounds: 20
7. Add notes: "10% incline during work intervals"

### Copy a Week
1. Navigate to the week you want to duplicate
2. Tap the "..." menu on the week card
3. Select "Duplicate"
4. New week appears at the end with all exercises/cardio copied

---

## ⚡ Pro Tips

1. **Day Notes**: Use for warm-up protocols, mobility work, or client-specific modifications
2. **Exercise Notes**: Add form cues, tempo instructions, or substitution options
3. **Analytics Panel**: Review after building to ensure balanced volume across muscle groups
4. **Duration Estimates**: Help clients plan their schedule (includes rest periods)
5. **Intensity Indicators**: Use cardio intensity colors to quickly see recovery days
6. **Training Methods**: Visual indicators help clients understand workout structure
7. **Mobile First**: Build on desktop, review/adjust on mobile for client-facing polish
8. **Auto-Save**: Watch for the green checkmark (top-right) confirming saves
9. **Undo**: Made changes you don't like? Undo button (top-right) reverses up to 50 steps
10. **Validation**: Red error banners prevent you from saving incomplete data

---

## 🎯 Best Practices

### Program Design
- **Progressive Overload**: Use %1RM fields to plan progression week-to-week
- **Volume Landmarks**: Check analytics to ensure 10-20 sets per muscle group per week
- **Recovery**: Balance high-intensity days with lower-volume or rest days
- **Variety**: Mix training methods (straight sets, supersets, circuits) for engagement

### Client Communication
- **Day Notes**: Explain the "why" behind each training day
- **Exercise Notes**: Pre-empt form questions with detailed cues
- **Intensity**: Use RIR and %1RM to guide effort levels
- **Cardio Instructions**: Specify exact machine settings for consistency

### Workflow Efficiency
- **Templates** (Coming Soon): Save your favorite splits and protocols
- **Duplicate Weeks**: Use for linear periodization (same structure, increasing weight)
- **Bulk Planning**: Build all weeks first, then go back to fine-tune details
- **Mobile Review**: Final check on mobile to ensure client-facing UX is perfect

---

## 🐛 Troubleshooting

**Plan won't save?**
- Check for red error messages
- Ensure plan has a name
- Verify all exercises have required fields (name is minimum)

**Analytics showing 0?**
- Add weight values to exercises for volume/tonnage calculations
- Ensure exercises have sets and reps entered
- Cardio requires duration for time calculations

**Buttons not accessible on mobile?**
- Try landscape orientation for more space
- Use the overflow menu (⋮) for secondary actions
- Pinch to zoom if needed

**Changes not showing?**
- Check for "Unsaved" indicator (orange dot, top-right)
- Tap Save button to force manual save
- Refresh if auto-save isn't working

---

## 📞 Support

**Coming Soon:**
- Plan Templates
- PDF Export
- Exercise Reordering (Drag & Drop)
- AI Exercise Suggestions

**Current Limitations:**
- Keyboard shortcuts require Flutter 3.19+ (coming in future update)
- Templates feature in development
- PDF export in development

**Need Help?**
- Feature requests and bug reports: GitHub Issues
- Documentation: Check the release notes for detailed feature descriptions

---

## 🎉 You're Ready!

The Revolutionary Plan Builder gives you professional-grade tools to create comprehensive workout plans that rival $200-500/month platforms. Start building and transform how you deliver training programs to clients!

**Happy Planning! 💪**
