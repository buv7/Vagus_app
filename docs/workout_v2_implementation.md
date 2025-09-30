# Workout v2 Implementation Documentation

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Database Schema](#database-schema)
4. [API Documentation](#api-documentation)
5. [Services](#services)
6. [Usage Examples](#usage-examples)
7. [Troubleshooting](#troubleshooting)

---

## Overview

### What's New in Workout v2

Workout v2 is a complete redesign of the workout management system, introducing a hierarchical structure, advanced tracking, AI-powered generation, comprehensive analytics, and OneSignal notifications.

**Key Changes:**
- **Hierarchical Structure**: Plans → Weeks → Days → Exercises
- **Exercise Grouping**: Supersets, circuits, drop sets, and giant sets
- **AI Generation**: Intelligent workout plan creation based on user profile
- **Advanced Tracking**: RPE, tempo, rest times, form videos
- **Progression Algorithms**: Linear, DUP, wave periodization
- **Analytics**: Volume tracking, PR detection, muscle group distribution
- **Export Functionality**: PDF and image export for sharing
- **Notifications**: Workout reminders, PR celebrations, weekly summaries

### Version Comparison

| Feature | v1 | v2 |
|---------|----|----|
| Structure | Flat exercise list | Hierarchical (Plan→Week→Day→Exercise) |
| Exercise Groups | ❌ | ✅ (Superset, Circuit, Drop Set, Giant Set) |
| AI Generation | ❌ | ✅ |
| Progression | Manual | Automated algorithms |
| Analytics | Basic | Comprehensive (Volume, PRs, Muscle Groups) |
| Export | ❌ | ✅ (PDF, Image) |
| Notifications | ❌ | ✅ (8 types with OneSignal) |
| Tracking | Sets/Reps/Weight | Sets/Reps/Weight/RPE/Tempo/Rest/Notes |
| Rest Timer | ❌ | ✅ |
| Form Videos | ❌ | ✅ |
| History | Limited | Comprehensive with graphs |

---

## Architecture

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                       │
├─────────────────────────────────────────────────────────────┤
│  Coach Screens           │         Client Screens           │
│  - WorkoutPlanBuilder    │  - WorkoutPlanViewer            │
│  - WorkoutDayEditor      │  - WorkoutSessionTracker        │
│  - ExercisePicker        │  - WorkoutHistory               │
│  - PlanTemplateLibrary   │  - ExerciseFormVideos           │
│  - ClientPlanManager     │  - ProgressCharts               │
└──────────────┬───────────┴────────────┬────────────────────┘
               │                        │
┌──────────────┴────────────────────────┴────────────────────┐
│                      Service Layer                          │
├─────────────────────────────────────────────────────────────┤
│  WorkoutService    │  WorkoutAIService                      │
│  - CRUD operations │  - generateWorkoutPlan()               │
│  - Plan management │  - suggestExercises()                  │
│  - Exercise search │  - applyPeriodization()                │
│                    │                                         │
│  ProgressionService│  WorkoutAnalyticsService               │
│  - Linear          │  - calculateVolume()                   │
│  - DUP             │  - detectPRs()                         │
│  - Wave            │  - getMuscleGroupDistribution()        │
│  - Autoregulation  │  - getProgressionTrends()              │
│                    │                                         │
│  WorkoutExportService  │  OneSignalService                  │
│  - exportToPDF()       │  - sendWorkoutReminder()           │
│  - exportToImage()     │  - sendPRCelebration()             │
│                        │  - scheduleWorkoutReminders()       │
└──────────────┬─────────┴────────────┬─────────────────────┘
               │                      │
┌──────────────┴──────────────────────┴─────────────────────┐
│                     Data Layer                             │
├────────────────────────────────────────────────────────────┤
│  Supabase Database   │  Edge Functions                     │
│  - workout_plans     │  - schedule-workout-reminders       │
│  - workout_weeks     │  - send-workout-notification        │
│  - workout_days      │  - cancel-workout-reminders         │
│  - exercises         │  - generate-workout-ai (future)     │
│  - workout_sessions  │                                     │
│  - exercise_logs     │                                     │
│  - workout_comments  │                                     │
└────────────────────────────────────────────────────────────┘
```

### Data Flow Diagrams

#### Coach Creates Workout Plan Flow
```
┌──────────┐      ┌──────────────┐      ┌──────────┐      ┌──────────┐
│  Coach   │─────>│ PlanBuilder  │─────>│ Workout  │─────>│ Supabase │
│  Screen  │      │   Screen     │      │ Service  │      │    DB    │
└──────────┘      └──────────────┘      └──────────┘      └──────────┘
                         │                     │
                         │                     v
                         │              ┌──────────────┐
                         │              │ OneSignal    │
                         │              │ Schedule     │
                         │              │ Notifications│
                         │              └──────────────┘
                         v
                  ┌──────────────┐
                  │ AI Service   │
                  │ (Optional)   │
                  └──────────────┘
```

#### Client Tracks Workout Flow
```
┌──────────┐      ┌──────────────┐      ┌──────────┐      ┌──────────┐
│  Client  │─────>│  Session     │─────>│ Workout  │─────>│ Supabase │
│  Screen  │      │  Tracker     │      │ Service  │      │    DB    │
└──────────┘      └──────────────┘      └──────────┘      └──────────┘
                         │                     │
                         │                     v
                         │              ┌──────────────┐
                         │              │ Analytics    │
                         │              │ Service      │
                         │              │ - Detect PRs │
                         │              │ - Calculate  │
                         │              │   Volume     │
                         │              └──────────────┘
                         v
                  ┌──────────────┐
                  │ OneSignal    │
                  │ PR Celebrate │
                  └──────────────┘
```

### Component Architecture

```
lib/
├── models/
│   ├── workout/
│   │   ├── workout_plan.dart           # Core data model
│   │   ├── workout_week.dart
│   │   ├── workout_day.dart
│   │   ├── exercise.dart
│   │   ├── exercise_group.dart         # Superset, Circuit, etc.
│   │   └── workout_session.dart
│   ├── analytics/
│   │   ├── workout_analytics_data.dart
│   │   ├── volume_data.dart
│   │   ├── pr_record.dart
│   │   └── progression_data.dart
│   └── notifications/
│       └── workout_notification_types.dart
│
├── services/
│   ├── workout/
│   │   ├── workout_service.dart        # Core CRUD operations
│   │   ├── workout_ai_service.dart     # AI generation
│   │   ├── progression_service.dart    # Progression algorithms
│   │   ├── workout_analytics_service.dart
│   │   └── workout_export_service.dart
│   └── notifications/
│       └── onesignal_service.dart      # Workout notifications
│
├── screens/
│   ├── workout/
│   │   ├── coach/
│   │   │   ├── workout_plan_builder.dart
│   │   │   ├── workout_day_editor.dart
│   │   │   ├── exercise_picker_screen.dart
│   │   │   └── plan_template_library.dart
│   │   ├── client/
│   │   │   ├── workout_plan_viewer.dart
│   │   │   ├── workout_session_tracker.dart
│   │   │   ├── workout_history_screen.dart
│   │   │   └── exercise_form_video_screen.dart
│   │   └── shared/
│   │       ├── workout_analytics_screen.dart
│   │       └── exercise_detail_screen.dart
│   └── settings/
│       └── notification_preferences_screen.dart
│
└── widgets/
    └── workout/
        ├── exercise_card.dart
        ├── workout_summary_card.dart
        ├── rest_timer.dart
        ├── set_tracker.dart
        └── analytics_charts/
            ├── volume_chart.dart
            ├── muscle_group_pie_chart.dart
            └── progression_line_chart.dart
```

---

## Database Schema

### Entity-Relationship Diagram

```
┌─────────────────┐
│   auth.users    │
└────────┬────────┘
         │
         │ 1:N
         v
┌─────────────────────────────┐
│     workout_plans           │
│─────────────────────────────│
│ id (PK)                     │
│ user_id (FK → auth.users)   │
│ name                        │
│ goal (enum)                 │
│ total_weeks                 │
│ current_week                │
│ status                      │
│ created_at                  │
│ updated_at                  │
└──────────┬──────────────────┘
           │
           │ 1:N
           v
┌─────────────────────────────┐
│     workout_weeks           │
│─────────────────────────────│
│ id (PK)                     │
│ plan_id (FK)                │
│ week_number                 │
│ start_date                  │
│ end_date                    │
│ notes                       │
└──────────┬──────────────────┘
           │
           │ 1:N
           v
┌─────────────────────────────┐
│     workout_days            │
│─────────────────────────────│
│ id (PK)                     │
│ week_id (FK)                │
│ day_label                   │
│ date                        │
│ notes                       │
│ estimated_duration          │
└──────────┬──────────────────┘
           │
           │ 1:N
           v
┌─────────────────────────────┐
│       exercises             │
│─────────────────────────────│
│ id (PK)                     │
│ day_id (FK)                 │
│ group_id (FK, nullable)     │
│ name                        │
│ muscle_group                │
│ sets                        │
│ target_reps_min             │
│ target_reps_max             │
│ target_weight               │
│ target_rpe_min              │
│ target_rpe_max              │
│ rest_seconds                │
│ tempo                       │
│ notes                       │
│ order_index                 │
│ video_url                   │
└─────────────────────────────┘

┌─────────────────────────────┐
│    exercise_groups          │
│─────────────────────────────│
│ id (PK)                     │
│ day_id (FK)                 │
│ type (superset/circuit/etc) │
│ rest_between_rounds         │
│ order_index                 │
└─────────────────────────────┘

┌─────────────────────────────┐
│    workout_sessions         │
│─────────────────────────────│
│ id (PK)                     │
│ user_id (FK)                │
│ day_id (FK)                 │
│ started_at                  │
│ completed_at                │
│ total_volume                │
│ notes                       │
└──────────┬──────────────────┘
           │
           │ 1:N
           v
┌─────────────────────────────┐
│     exercise_logs           │
│─────────────────────────────│
│ id (PK)                     │
│ session_id (FK)             │
│ exercise_id (FK)            │
│ set_number                  │
│ reps                        │
│ weight                      │
│ rpe                         │
│ tempo                       │
│ notes                       │
│ completed_at                │
└─────────────────────────────┘
```

### Table Specifications

#### workout_plans

**Purpose:** Top-level container for a complete workout program.

```sql
CREATE TABLE workout_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  goal TEXT CHECK (goal IN ('strength', 'hypertrophy', 'endurance', 'powerlifting', 'general_fitness')),
  total_weeks INTEGER NOT NULL CHECK (total_weeks > 0 AND total_weeks <= 52),
  current_week INTEGER DEFAULT 1 CHECK (current_week > 0),
  status TEXT DEFAULT 'active' CHECK (status IN ('draft', 'active', 'completed', 'archived')),
  is_template BOOLEAN DEFAULT FALSE,
  template_category TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_workout_plans_user_id ON workout_plans(user_id);
CREATE INDEX idx_workout_plans_status ON workout_plans(status) WHERE status = 'active';
CREATE INDEX idx_workout_plans_template ON workout_plans(is_template) WHERE is_template = TRUE;
```

**RLS Policies:**
```sql
-- Users can view their own plans OR plans assigned to them
CREATE POLICY "Users can view own plans"
  ON workout_plans FOR SELECT
  USING (auth.uid() = user_id);

-- Coaches can view client plans
CREATE POLICY "Coaches can view client plans"
  ON workout_plans FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM coach_client_relationships
      WHERE coach_id = auth.uid() AND client_id = workout_plans.user_id
    )
  );

-- Users can insert their own plans
CREATE POLICY "Users can insert own plans"
  ON workout_plans FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own plans
CREATE POLICY "Users can update own plans"
  ON workout_plans FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can delete their own plans
CREATE POLICY "Users can delete own plans"
  ON workout_plans FOR DELETE
  USING (auth.uid() = user_id);
```

#### workout_weeks

**Purpose:** Week divisions within a plan for periodization.

```sql
CREATE TABLE workout_weeks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  plan_id UUID NOT NULL REFERENCES workout_plans(id) ON DELETE CASCADE,
  week_number INTEGER NOT NULL CHECK (week_number > 0),
  start_date DATE,
  end_date DATE,
  notes TEXT,
  deload BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(plan_id, week_number)
);

CREATE INDEX idx_workout_weeks_plan_id ON workout_weeks(plan_id);
CREATE INDEX idx_workout_weeks_dates ON workout_weeks(start_date, end_date);
```

#### workout_days

**Purpose:** Individual training days within a week.

```sql
CREATE TABLE workout_days (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  week_id UUID NOT NULL REFERENCES workout_weeks(id) ON DELETE CASCADE,
  day_label TEXT NOT NULL, -- e.g., "Push Day", "Leg Day", "Upper Body"
  date DATE,
  notes TEXT,
  estimated_duration INTEGER, -- minutes
  muscle_groups TEXT[], -- ['chest', 'shoulders', 'triceps']
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_workout_days_week_id ON workout_days(week_id);
CREATE INDEX idx_workout_days_date ON workout_days(date);
CREATE INDEX idx_workout_days_muscle_groups ON workout_days USING GIN(muscle_groups);
```

#### exercise_groups

**Purpose:** Group exercises into supersets, circuits, etc.

```sql
CREATE TABLE exercise_groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  day_id UUID NOT NULL REFERENCES workout_days(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('superset', 'triset', 'giant_set', 'circuit', 'drop_set')),
  rest_between_rounds INTEGER DEFAULT 90, -- seconds
  rounds INTEGER DEFAULT 1,
  order_index INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_exercise_groups_day_id ON exercise_groups(day_id);
```

#### exercises

**Purpose:** Individual exercises within a workout day.

```sql
CREATE TABLE exercises (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  day_id UUID NOT NULL REFERENCES workout_days(id) ON DELETE CASCADE,
  group_id UUID REFERENCES exercise_groups(id) ON DELETE SET NULL,

  -- Exercise identification
  name TEXT NOT NULL,
  muscle_group TEXT NOT NULL,
  equipment TEXT,

  -- Prescription
  sets INTEGER NOT NULL CHECK (sets > 0),
  target_reps_min INTEGER CHECK (target_reps_min > 0),
  target_reps_max INTEGER CHECK (target_reps_max >= target_reps_min),
  target_reps_avg INTEGER GENERATED ALWAYS AS ((target_reps_min + target_reps_max) / 2) STORED,
  target_weight DECIMAL(6,2),
  target_rpe_min DECIMAL(3,1) CHECK (target_rpe_min >= 1 AND target_rpe_min <= 10),
  target_rpe_max DECIMAL(3,1) CHECK (target_rpe_max >= target_rpe_min AND target_rpe_max <= 10),

  -- Timing
  rest_seconds INTEGER DEFAULT 90 CHECK (rest_seconds >= 0),
  tempo TEXT, -- e.g., "3-0-1-0" (eccentric-pause-concentric-pause)

  -- Additional info
  notes TEXT,
  video_url TEXT,
  order_index INTEGER NOT NULL,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_exercises_day_id ON exercises(day_id);
CREATE INDEX idx_exercises_group_id ON exercises(group_id) WHERE group_id IS NOT NULL;
CREATE INDEX idx_exercises_muscle_group ON exercises(muscle_group);
CREATE INDEX idx_exercises_name ON exercises(name);
```

#### workout_sessions

**Purpose:** Track actual workout completion and performance.

```sql
CREATE TABLE workout_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  day_id UUID NOT NULL REFERENCES workout_days(id) ON DELETE CASCADE,

  started_at TIMESTAMPTZ NOT NULL,
  completed_at TIMESTAMPTZ,

  -- Calculated metrics
  total_volume DECIMAL(10,2), -- sum of (weight * reps) for all exercises
  total_sets INTEGER,
  average_rpe DECIMAL(3,1),

  -- Session feedback
  notes TEXT,
  energy_level INTEGER CHECK (energy_level >= 1 AND energy_level <= 5),

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_workout_sessions_user_id ON workout_sessions(user_id);
CREATE INDEX idx_workout_sessions_day_id ON workout_sessions(day_id);
CREATE INDEX idx_workout_sessions_started_at ON workout_sessions(started_at);
CREATE INDEX idx_workout_sessions_completed ON workout_sessions(completed_at) WHERE completed_at IS NOT NULL;
```

#### exercise_logs

**Purpose:** Track individual set performance within a session.

```sql
CREATE TABLE exercise_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id UUID NOT NULL REFERENCES workout_sessions(id) ON DELETE CASCADE,
  exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,

  set_number INTEGER NOT NULL CHECK (set_number > 0),
  reps INTEGER NOT NULL CHECK (reps >= 0),
  weight DECIMAL(6,2) NOT NULL CHECK (weight >= 0),
  rpe DECIMAL(3,1) CHECK (rpe >= 1 AND rpe <= 10),
  tempo TEXT,
  rest_seconds INTEGER,

  notes TEXT,
  form_rating INTEGER CHECK (form_rating >= 1 AND form_rating <= 5),
  completed_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(session_id, exercise_id, set_number)
);

CREATE INDEX idx_exercise_logs_session_id ON exercise_logs(session_id);
CREATE INDEX idx_exercise_logs_exercise_id ON exercise_logs(exercise_id);
CREATE INDEX idx_exercise_logs_completed_at ON exercise_logs(completed_at);
```

### Database Functions

#### calculate_plan_volume(plan_id UUID)

Calculates total training volume for an entire plan.

```sql
CREATE OR REPLACE FUNCTION calculate_plan_volume(p_plan_id UUID)
RETURNS DECIMAL(10,2) AS $$
DECLARE
  total_volume DECIMAL(10,2);
BEGIN
  SELECT COALESCE(SUM(e.sets * e.target_reps_avg * e.target_weight), 0)
  INTO total_volume
  FROM exercises e
  JOIN workout_days d ON e.day_id = d.id
  JOIN workout_weeks w ON d.week_id = w.id
  WHERE w.plan_id = p_plan_id;

  RETURN total_volume;
END;
$$ LANGUAGE plpgsql;
```

#### detect_prs(user_id UUID, exercise_name TEXT)

Detects personal records for a user and exercise.

```sql
CREATE OR REPLACE FUNCTION detect_prs(p_user_id UUID, p_exercise_name TEXT)
RETURNS TABLE(
  pr_type TEXT,
  value DECIMAL,
  achieved_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  -- Max weight for any rep range
  SELECT
    'max_weight' as pr_type,
    MAX(el.weight) as value,
    MAX(el.completed_at) as achieved_at
  FROM exercise_logs el
  JOIN workout_sessions ws ON el.session_id = ws.id
  JOIN exercises e ON el.exercise_id = e.id
  WHERE ws.user_id = p_user_id
    AND e.name = p_exercise_name

  UNION ALL

  -- Max reps at any weight
  SELECT
    'max_reps' as pr_type,
    MAX(el.reps)::DECIMAL as value,
    MAX(el.completed_at) as achieved_at
  FROM exercise_logs el
  JOIN workout_sessions ws ON el.session_id = ws.id
  JOIN exercises e ON el.exercise_id = e.id
  WHERE ws.user_id = p_user_id
    AND e.name = p_exercise_name

  UNION ALL

  -- Max volume (weight * reps) for a single set
  SELECT
    'max_volume_single_set' as pr_type,
    MAX(el.weight * el.reps) as value,
    MAX(el.completed_at) as achieved_at
  FROM exercise_logs el
  JOIN workout_sessions ws ON el.session_id = ws.id
  JOIN exercises e ON el.exercise_id = e.id
  WHERE ws.user_id = p_user_id
    AND e.name = p_exercise_name;
END;
$$ LANGUAGE plpgsql;
```

#### get_muscle_group_volume(user_id UUID, start_date DATE, end_date DATE)

Get training volume distribution by muscle group.

```sql
CREATE OR REPLACE FUNCTION get_muscle_group_volume(
  p_user_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE(
  muscle_group TEXT,
  total_volume DECIMAL,
  total_sets INTEGER,
  session_count INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    e.muscle_group,
    SUM(el.weight * el.reps) as total_volume,
    COUNT(el.*)::INTEGER as total_sets,
    COUNT(DISTINCT ws.id)::INTEGER as session_count
  FROM exercise_logs el
  JOIN workout_sessions ws ON el.session_id = ws.id
  JOIN exercises e ON el.exercise_id = e.id
  WHERE ws.user_id = p_user_id
    AND DATE(ws.started_at) BETWEEN p_start_date AND p_end_date
    AND ws.completed_at IS NOT NULL
  GROUP BY e.muscle_group
  ORDER BY total_volume DESC;
END;
$$ LANGUAGE plpgsql;
```

### Triggers

#### auto_update_timestamp

Automatically updates the `updated_at` column.

```sql
CREATE OR REPLACE FUNCTION auto_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_workout_plans_timestamp
  BEFORE UPDATE ON workout_plans
  FOR EACH ROW
  EXECUTE FUNCTION auto_update_timestamp();

CREATE TRIGGER update_workout_weeks_timestamp
  BEFORE UPDATE ON workout_weeks
  FOR EACH ROW
  EXECUTE FUNCTION auto_update_timestamp();

CREATE TRIGGER update_workout_days_timestamp
  BEFORE UPDATE ON workout_days
  FOR EACH ROW
  EXECUTE FUNCTION auto_update_timestamp();

CREATE TRIGGER update_exercises_timestamp
  BEFORE UPDATE ON exercises
  FOR EACH ROW
  EXECUTE FUNCTION auto_update_timestamp();
```

---

## API Documentation

### WorkoutService

Core service for workout CRUD operations.

#### `createWorkoutPlan()`

Creates a new workout plan with weeks structure.

**Signature:**
```dart
Future<String> createWorkoutPlan({
  required String name,
  required String goal,
  required int totalWeeks,
  String? description,
  String? userId,
  bool isTemplate = false,
}) async
```

**Parameters:**
- `name`: Plan name (e.g., "8-Week Hypertrophy")
- `goal`: Training goal - `strength`, `hypertrophy`, `endurance`, `powerlifting`, `general_fitness`
- `totalWeeks`: Number of weeks (1-52)
- `description`: Optional plan description
- `userId`: Target user ID (defaults to current user, coaches can specify client)
- `isTemplate`: Whether this is a reusable template

**Returns:** Plan ID (UUID)

**Example:**
```dart
final workoutService = WorkoutService();

final planId = await workoutService.createWorkoutPlan(
  name: '8-Week Hypertrophy Block',
  goal: 'hypertrophy',
  totalWeeks: 8,
  description: 'Focus on chest, back, and legs with progressive overload',
  isTemplate: false,
);

print('Created plan: $planId');
```

**Database Operations:**
1. Inserts into `workout_plans` table
2. Automatically creates `workout_weeks` records (1 per week)
3. Sets up initial structure with empty weeks

#### `addWorkoutDay()`

Adds a training day to a week.

**Signature:**
```dart
Future<String> addWorkoutDay({
  required String weekId,
  required String dayLabel,
  DateTime? date,
  String? notes,
  int? estimatedDuration,
  List<String>? muscleGroups,
}) async
```

**Parameters:**
- `weekId`: Parent week UUID
- `dayLabel`: Day name (e.g., "Push Day", "Leg Day")
- `date`: Scheduled date (optional for templates)
- `notes`: Optional day notes
- `estimatedDuration`: Estimated minutes
- `muscleGroups`: List of muscle groups (e.g., `['chest', 'shoulders', 'triceps']`)

**Returns:** Day ID (UUID)

**Example:**
```dart
final dayId = await workoutService.addWorkoutDay(
  weekId: weekId,
  dayLabel: 'Upper Body Push',
  date: DateTime.now().add(Duration(days: 1)),
  estimatedDuration: 75,
  muscleGroups: ['chest', 'shoulders', 'triceps'],
  notes: 'Focus on progressive overload on compound movements',
);
```

#### `addExercise()`

Adds an exercise to a workout day.

**Signature:**
```dart
Future<String> addExercise({
  required String dayId,
  String? groupId,
  required String name,
  required String muscleGroup,
  String? equipment,
  required int sets,
  int? targetRepsMin,
  int? targetRepsMax,
  double? targetWeight,
  double? targetRpeMin,
  double? targetRpeMax,
  int? restSeconds,
  String? tempo,
  String? notes,
  String? videoUrl,
  required int orderIndex,
}) async
```

**Parameters:**
- `dayId`: Parent day UUID
- `groupId`: Optional group ID (for supersets, circuits, etc.)
- `name`: Exercise name
- `muscleGroup`: Primary muscle group
- `equipment`: Required equipment
- `sets`: Number of sets
- `targetRepsMin`/`targetRepsMax`: Rep range
- `targetWeight`: Target weight in kg
- `targetRpeMin`/`targetRpeMax`: RPE range (1-10)
- `restSeconds`: Rest between sets
- `tempo`: Tempo notation (e.g., "3-0-1-0")
- `notes`: Exercise notes
- `videoUrl`: Form video URL
- `orderIndex`: Position in workout

**Returns:** Exercise ID (UUID)

**Example:**
```dart
final exerciseId = await workoutService.addExercise(
  dayId: dayId,
  name: 'Barbell Bench Press',
  muscleGroup: 'chest',
  equipment: 'barbell',
  sets: 4,
  targetRepsMin: 8,
  targetRepsMax: 12,
  targetWeight: 80.0,
  targetRpeMin: 7.0,
  targetRpeMax: 9.0,
  restSeconds: 120,
  tempo: '3-0-1-0', // 3sec down, 0sec pause, 1sec up, 0sec pause
  notes: 'Warm up with bar and build to working weight',
  orderIndex: 0,
);
```

#### `createExerciseGroup()`

Creates a group for supersets, circuits, etc.

**Signature:**
```dart
Future<String> createExerciseGroup({
  required String dayId,
  required String type, // 'superset', 'triset', 'giant_set', 'circuit', 'drop_set'
  int restBetweenRounds = 90,
  int rounds = 1,
  required int orderIndex,
}) async
```

**Example:**
```dart
// Create superset
final groupId = await workoutService.createExerciseGroup(
  dayId: dayId,
  type: 'superset',
  restBetweenRounds: 60,
  rounds: 3,
  orderIndex: 1,
);

// Add exercises to the superset
await workoutService.addExercise(
  dayId: dayId,
  groupId: groupId,
  name: 'Dumbbell Flyes',
  muscleGroup: 'chest',
  sets: 3,
  targetRepsMin: 12,
  targetRepsMax: 15,
  orderIndex: 0,
);

await workoutService.addExercise(
  dayId: dayId,
  groupId: groupId,
  name: 'Cable Crossover',
  muscleGroup: 'chest',
  sets: 3,
  targetRepsMin: 12,
  targetRepsMax: 15,
  orderIndex: 1,
);
```

#### `getWorkoutPlan()`

Retrieves a complete workout plan with all nested data.

**Signature:**
```dart
Future<WorkoutPlan> getWorkoutPlan(String planId) async
```

**Returns:** `WorkoutPlan` object with nested weeks, days, exercises

**Example:**
```dart
final plan = await workoutService.getWorkoutPlan(planId);

print('Plan: ${plan.name}');
print('Weeks: ${plan.weeks.length}');
print('Status: ${plan.status}');

for (final week in plan.weeks) {
  print('Week ${week.weekNumber}: ${week.days.length} days');
  for (final day in week.days) {
    print('  ${day.dayLabel}: ${day.exercises.length} exercises');
  }
}
```

#### `startWorkoutSession()`

Starts tracking a workout session.

**Signature:**
```dart
Future<String> startWorkoutSession({
  required String dayId,
  String? userId,
}) async
```

**Returns:** Session ID (UUID)

**Example:**
```dart
final sessionId = await workoutService.startWorkoutSession(dayId: dayId);

// Track sets...
await workoutService.logExerciseSet(
  sessionId: sessionId,
  exerciseId: exerciseId,
  setNumber: 1,
  reps: 10,
  weight: 80.0,
  rpe: 7.5,
);

// Complete session
await workoutService.completeWorkoutSession(
  sessionId: sessionId,
  notes: 'Great session!',
  energyLevel: 4,
);
```

#### `logExerciseSet()`

Logs a completed set during a workout session.

**Signature:**
```dart
Future<void> logExerciseSet({
  required String sessionId,
  required String exerciseId,
  required int setNumber,
  required int reps,
  required double weight,
  double? rpe,
  String? tempo,
  int? restSeconds,
  String? notes,
  int? formRating,
}) async
```

#### `completeWorkoutSession()`

Completes a workout session and calculates metrics.

**Signature:**
```dart
Future<void> completeWorkoutSession({
  required String sessionId,
  String? notes,
  int? energyLevel, // 1-5
}) async
```

**Post-completion Actions:**
1. Sets `completed_at` timestamp
2. Calculates `total_volume` (sum of weight * reps)
3. Calculates `average_rpe`
4. Detects PRs
5. Triggers `sendPRCelebration()` notifications if PRs detected

### WorkoutAIService

AI-powered workout generation service.

#### `generateWorkoutPlan()`

Generates a complete workout plan based on user profile and preferences.

**Signature:**
```dart
Future<WorkoutPlan> generateWorkoutPlan({
  required String userId,
  required String goal,
  required int totalWeeks,
  required int daysPerWeek,
  required String experienceLevel, // 'beginner', 'intermediate', 'advanced'
  List<String>? availableEquipment,
  List<String>? focusMuscleGroups,
  int? sessionDuration, // minutes
  List<String>? injuries,
}) async
```

**Algorithm:**
1. Analyzes user profile (age, experience, injuries)
2. Selects appropriate split (Full Body, Push/Pull/Legs, Arnold Split, Bro Split)
3. Selects exercises based on equipment and goals
4. Calculates volume based on experience and goal
5. Applies periodization scheme
6. Inserts generated plan into database

**Example:**
```dart
final aiService = WorkoutAIService();

final generatedPlan = await aiService.generateWorkoutPlan(
  userId: currentUserId,
  goal: 'hypertrophy',
  totalWeeks: 12,
  daysPerWeek: 4,
  experienceLevel: 'intermediate',
  availableEquipment: ['barbell', 'dumbbell', 'cables', 'machines'],
  focusMuscleGroups: ['chest', 'back'],
  sessionDuration: 75,
  injuries: ['lower_back'],
);

print('Generated ${generatedPlan.weeks.length} weeks');
print('Plan ID: ${generatedPlan.id}');
```

#### `suggestExerciseSubstitution()`

Suggests alternative exercises for equipment or injury constraints.

**Signature:**
```dart
Future<List<Exercise>> suggestExerciseSubstitution({
  required String exerciseName,
  required String muscleGroup,
  List<String>? availableEquipment,
  List<String>? injuries,
  int limit = 5,
}) async
```

**Example:**
```dart
// User can't do barbell squats due to knee injury
final alternatives = await aiService.suggestExerciseSubstitution(
  exerciseName: 'Barbell Squat',
  muscleGroup: 'legs',
  injuries: ['knee'],
  availableEquipment: ['dumbbell', 'machines'],
  limit: 3,
);

// Returns: [Leg Press, Goblet Squat, Bulgarian Split Squat]
```

### ProgressionService

Applies progression algorithms to workout plans.

#### `applyLinearProgression()`

Applies linear progression to a plan.

**Signature:**
```dart
Future<void> applyLinearProgression({
  required String planId,
  double weightIncreasePercentage = 2.5, // % increase per week
  bool includeDeload = true,
  int deloadFrequency = 4, // every 4 weeks
}) async
```

**Example:**
```dart
final progressionService = ProgressionService();

await progressionService.applyLinearProgression(
  planId: planId,
  weightIncreasePercentage: 2.5,
  includeDeload: true,
  deloadFrequency: 4,
);
```

**Algorithm:**
- Week 1: 100% of starting weight
- Week 2: 102.5%
- Week 3: 105%
- Week 4: 107.5%
- Week 5: 70% (deload)
- Week 6: 110%
- ...

#### `applyDUPProgression()`

Applies Daily Undulating Periodization.

**Signature:**
```dart
Future<void> applyDUPProgression({
  required String planId,
}) async
```

**Algorithm:**
- Day 1: Heavy (3-5 reps, 85-90% 1RM)
- Day 2: Moderate (8-12 reps, 70-80% 1RM)
- Day 3: Light (15-20 reps, 60-70% 1RM)

#### `applyWaveProgression()`

Applies wave periodization.

**Signature:**
```dart
Future<void> applyWaveProgression({
  required String planId,
  int waveLength = 3, // weeks per wave
}) async
```

**Algorithm:**
- Week 1: 75% intensity
- Week 2: 85% intensity
- Week 3: 95% intensity (peak)
- Week 4: 80% intensity (start new wave)
- ...

### WorkoutAnalyticsService

Comprehensive analytics for workout tracking.

#### `getWeeklyVolume()`

Get total training volume for a week.

**Signature:**
```dart
Future<double> getWeeklyVolume({
  required String userId,
  required DateTime weekStart,
}) async
```

**Returns:** Total volume in kg (sum of weight * reps for all exercises)

#### `detectPRs()`

Detects personal records.

**Signature:**
```dart
Future<List<PRRecord>> detectPRs({
  required String userId,
  String? exerciseName,
  DateTime? since,
}) async
```

**Returns:** List of PR records with types:
- `max_weight`: Heaviest weight lifted
- `max_reps`: Most reps at any weight
- `max_volume_single_set`: Highest weight * reps
- `estimated_1rm`: Highest estimated 1RM

**Example:**
```dart
final analyticsService = WorkoutAnalyticsService();

final prs = await analyticsService.detectPRs(
  userId: currentUserId,
  exerciseName: 'Barbell Bench Press',
  since: DateTime.now().subtract(Duration(days: 30)),
);

for (final pr in prs) {
  print('${pr.prType}: ${pr.value} kg on ${pr.achievedAt}');
}
```

#### `getMuscleGroupDistribution()`

Get volume distribution by muscle group.

**Signature:**
```dart
Future<Map<String, MuscleGroupData>> getMuscleGroupDistribution({
  required String userId,
  required DateTime startDate,
  required DateTime endDate,
}) async
```

**Returns:** Map of muscle group → data (volume, sets, session count)

**Example:**
```dart
final distribution = await analyticsService.getMuscleGroupDistribution(
  userId: currentUserId,
  startDate: DateTime.now().subtract(Duration(days: 7)),
  endDate: DateTime.now(),
);

// Returns:
// {
//   'chest': MuscleGroupData(volume: 2500, sets: 15, sessionCount: 2),
//   'back': MuscleGroupData(volume: 3000, sets: 18, sessionCount: 2),
//   ...
// }
```

#### `getProgressionTrend()`

Get progression trend for an exercise over time.

**Signature:**
```dart
Future<List<ProgressionDataPoint>> getProgressionTrend({
  required String userId,
  required String exerciseName,
  String metric = 'estimated_1rm', // or 'max_weight', 'average_weight', 'volume'
  DateTime? startDate,
  DateTime? endDate,
}) async
```

**Example:**
```dart
final trend = await analyticsService.getProgressionTrend(
  userId: currentUserId,
  exerciseName: 'Barbell Squat',
  metric: 'estimated_1rm',
  startDate: DateTime.now().subtract(Duration(days: 90)),
);

// Plot trend line
for (final point in trend) {
  print('${point.date}: ${point.value} kg');
}
```

### WorkoutExportService

Export workout plans and sessions.

#### `exportPlanToPDF()`

Exports a workout plan to PDF.

**Signature:**
```dart
Future<Uint8List> exportPlanToPDF({
  required String planId,
  bool includeNotes = true,
  bool includeVideoLinks = false,
}) async
```

**Returns:** PDF bytes

**Example:**
```dart
final exportService = WorkoutExportService();

final pdfBytes = await exportService.exportPlanToPDF(
  planId: planId,
  includeNotes: true,
  includeVideoLinks: true,
);

// Save or share
final file = File('workout_plan.pdf');
await file.writeAsBytes(pdfBytes);

// Or share
await Share.file('Workout Plan', 'workout_plan.pdf', pdfBytes, 'application/pdf');
```

#### `exportSessionSummaryToImage()`

Exports a session summary as an image (for social sharing).

**Signature:**
```dart
Future<Uint8List> exportSessionSummaryToImage({
  required String sessionId,
  String theme = 'dark', // or 'light'
}) async
```

**Example:**
```dart
final imageBytes = await exportService.exportSessionSummaryToImage(
  sessionId: sessionId,
  theme: 'dark',
);

await Share.file('Workout Complete', 'workout_summary.png', imageBytes, 'image/png');
```

---

## Services

### Service Architecture

All workout services follow a consistent pattern:

```dart
class WorkoutService {
  final SupabaseClient _supabase;

  WorkoutService([SupabaseClient? supabase])
      : _supabase = supabase ?? Supabase.instance.client;

  // CRUD operations
  Future<T> create(...) async { }
  Future<T> read(...) async { }
  Future<void> update(...) async { }
  Future<void> delete(...) async { }

  // Utility methods
  Future<T> calculate(...) async { }
}
```

### Error Handling

All services throw typed exceptions:

```dart
class WorkoutException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  WorkoutException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'WorkoutException: $message';
}

// Usage
try {
  await workoutService.createWorkoutPlan(...);
} on WorkoutException catch (e) {
  if (e.code == 'PLAN_LIMIT_REACHED') {
    showDialog(...);
  } else {
    showSnackBar(e.message);
  }
} catch (e) {
  showSnackBar('Unexpected error: $e');
}
```

### Service Dependencies

```
WorkoutService (base)
    ↓
WorkoutAIService → uses WorkoutService for saving generated plans
    ↓
ProgressionService → uses WorkoutService for reading/updating plans
    ↓
WorkoutAnalyticsService → uses WorkoutService for querying sessions
    ↓
WorkoutExportService → uses WorkoutService + AnalyticsService
```

---

## Usage Examples

### Complete Coach Workflow

```dart
// 1. Create plan
final workoutService = WorkoutService();

final planId = await workoutService.createWorkoutPlan(
  name: '12-Week Powerlifting Prep',
  goal: 'powerlifting',
  totalWeeks: 12,
  userId: clientId, // Assign to client
);

// 2. Get week 1
final plan = await workoutService.getWorkoutPlan(planId);
final week1Id = plan.weeks.first.id;

// 3. Add day 1: Squat Focus
final day1Id = await workoutService.addWorkoutDay(
  weekId: week1Id,
  dayLabel: 'Squat Day',
  estimatedDuration: 90,
  muscleGroups: ['legs', 'glutes', 'core'],
);

// 4. Add squat exercise
await workoutService.addExercise(
  dayId: day1Id,
  name: 'Barbell Back Squat',
  muscleGroup: 'legs',
  equipment: 'barbell',
  sets: 5,
  targetRepsMin: 3,
  targetRepsMax: 5,
  targetWeight: 140.0,
  restSeconds: 180,
  notes: 'Competition stance, hit depth',
  orderIndex: 0,
);

// 5. Add accessory superset
final supersetId = await workoutService.createExerciseGroup(
  dayId: day1Id,
  type: 'superset',
  restBetweenRounds: 90,
  orderIndex: 1,
);

await workoutService.addExercise(
  dayId: day1Id,
  groupId: supersetId,
  name: 'Bulgarian Split Squat',
  muscleGroup: 'legs',
  sets: 3,
  targetRepsMin: 8,
  targetRepsMax: 10,
  orderIndex: 0,
);

await workoutService.addExercise(
  dayId: day1Id,
  groupId: supersetId,
  name: 'Leg Curl',
  muscleGroup: 'hamstrings',
  sets: 3,
  targetRepsMin: 10,
  targetRepsMax: 12,
  orderIndex: 1,
);

// 6. Duplicate for remaining weeks
for (int weekNum = 2; weekNum <= 12; weekNum++) {
  await workoutService.duplicateWeek(
    sourceWeekId: week1Id,
    targetWeekNumber: weekNum,
  );
}

// 7. Apply progression
final progressionService = ProgressionService();
await progressionService.applyLinearProgression(
  planId: planId,
  weightIncreasePercentage: 2.5,
  includeDeload: true,
  deloadFrequency: 4,
);

// 8. Send notification to client
final oneSignalService = OneSignalService();
await oneSignalService.sendPlanAssignedNotification(
  clientId,
  '12-Week Powerlifting Prep',
  'Coach Mike',
  planId: planId,
  totalWeeks: 12,
  startDate: DateTime.now().add(Duration(days: 7)),
);
```

### Complete Client Workflow

```dart
// 1. View assigned plan
final workoutService = WorkoutService();
final plans = await workoutService.getUserWorkoutPlans(currentUserId);
final activePlan = plans.firstWhere((p) => p.status == 'active');

print('Current plan: ${activePlan.name}');
print('Week ${activePlan.currentWeek} of ${activePlan.totalWeeks}');

// 2. Get today's workout
final today = DateTime.now();
final todayWorkout = await workoutService.getWorkoutForDate(
  planId: activePlan.id,
  date: today,
);

if (todayWorkout == null) {
  print('Rest day!');
  return;
}

print('Today: ${todayWorkout.dayLabel}');
print('Estimated time: ${todayWorkout.estimatedDuration} minutes');
print('Exercises: ${todayWorkout.exercises.length}');

// 3. Start workout session
final sessionId = await workoutService.startWorkoutSession(
  dayId: todayWorkout.id,
);

// 4. Complete first exercise
final firstExercise = todayWorkout.exercises.first;
print('Exercise 1: ${firstExercise.name}');
print('Target: ${firstExercise.sets}x${firstExercise.targetRepsMin}-${firstExercise.targetRepsMax} @ ${firstExercise.targetWeight}kg');

// Log sets
for (int setNum = 1; setNum <= firstExercise.sets; setNum++) {
  // User completes set
  await workoutService.logExerciseSet(
    sessionId: sessionId,
    exerciseId: firstExercise.id,
    setNumber: setNum,
    reps: 10,
    weight: firstExercise.targetWeight!,
    rpe: 7.5,
  );

  print('Set $setNum complete');

  // Rest timer
  if (setNum < firstExercise.sets) {
    await Future.delayed(Duration(seconds: firstExercise.restSeconds ?? 90));
  }
}

// 5. Complete remaining exercises...

// 6. Complete session
await workoutService.completeWorkoutSession(
  sessionId: sessionId,
  notes: 'Felt strong today!',
  energyLevel: 4,
);

// 7. Check for PRs
final analyticsService = WorkoutAnalyticsService();
final recentPRs = await analyticsService.detectPRs(
  userId: currentUserId,
  since: DateTime.now().subtract(Duration(hours: 1)),
);

if (recentPRs.isNotEmpty) {
  for (final pr in recentPRs) {
    print('🎉 NEW PR: ${pr.exerciseName} - ${pr.prType}: ${pr.value}kg');
  }
}
```

### AI Generation Workflow

```dart
final aiService = WorkoutAIService();

// 1. Generate plan from user profile
final generatedPlan = await aiService.generateWorkoutPlan(
  userId: currentUserId,
  goal: 'hypertrophy',
  totalWeeks: 8,
  daysPerWeek: 4,
  experienceLevel: 'intermediate',
  availableEquipment: ['barbell', 'dumbbell', 'cables', 'machines'],
  sessionDuration: 75,
  injuries: ['shoulder'],
);

print('Generated plan: ${generatedPlan.name}');
print('Split type: ${generatedPlan.description}'); // e.g., "Upper/Lower Split"

// 2. Review and customize
// (User reviews in UI)

// 3. Accept and save
// Plan is already saved from generateWorkoutPlan()

// 4. Schedule notifications
final oneSignalService = OneSignalService();
await oneSignalService.scheduleWorkoutReminders(
  generatedPlan.id,
  {
    'reminder_time': '18:00',
    'timezone': 'America/New_York',
  },
);
```

### Analytics Workflow

```dart
final analyticsService = WorkoutAnalyticsService();

// 1. Get this week's volume
final thisWeekVolume = await analyticsService.getWeeklyVolume(
  userId: currentUserId,
  weekStart: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)),
);

print('This week: ${thisWeekVolume}kg');

// 2. Compare to last week
final lastWeekVolume = await analyticsService.getWeeklyVolume(
  userId: currentUserId,
  weekStart: DateTime.now().subtract(Duration(days: DateTime.now().weekday + 6)),
);

final volumeChange = ((thisWeekVolume - lastWeekVolume) / lastWeekVolume * 100);
print('Change: ${volumeChange.toStringAsFixed(1)}%');

// 3. Get muscle group distribution
final distribution = await analyticsService.getMuscleGroupDistribution(
  userId: currentUserId,
  startDate: DateTime.now().subtract(Duration(days: 7)),
  endDate: DateTime.now(),
);

print('Muscle Group Distribution:');
for (final entry in distribution.entries) {
  final percentage = (entry.value.volume / thisWeekVolume * 100);
  print('${entry.key}: ${percentage.toStringAsFixed(1)}% (${entry.value.sets} sets)');
}

// 4. Get progression trend
final benchPressTrend = await analyticsService.getProgressionTrend(
  userId: currentUserId,
  exerciseName: 'Barbell Bench Press',
  metric: 'estimated_1rm',
  startDate: DateTime.now().subtract(Duration(days: 90)),
);

print('Bench Press 1RM Progression (Last 90 days):');
for (final point in benchPressTrend) {
  print('${point.date.toString().split(' ')[0]}: ${point.value}kg');
}

// 5. Export session summary
final exportService = WorkoutExportService();
final imageBytes = await exportService.exportSessionSummaryToImage(
  sessionId: lastSessionId,
  theme: 'dark',
);

// Share to social media
await Share.file(
  'Workout Complete 💪',
  'workout_${DateTime.now().millisecondsSinceEpoch}.png',
  imageBytes,
  'image/png',
);
```

---

## Troubleshooting

### Common Issues and Solutions

#### Issue: RLS Policy Blocks Query

**Symptom:** `new row violates row-level security policy` or queries return empty results

**Cause:** User doesn't have permission to access the data

**Solution:**
```dart
// Check if user is authenticated
final session = Supabase.instance.client.auth.currentSession;
if (session == null) {
  throw WorkoutException('User not authenticated');
}

// Verify userId matches
final userId = session.user.id;
print('Current user: $userId');

// For coaches accessing client data, verify relationship exists
final relationship = await supabase
  .from('coach_client_relationships')
  .select()
  .eq('coach_id', userId)
  .eq('client_id', clientId)
  .maybeSingle();

if (relationship == null) {
  throw WorkoutException('No coach-client relationship found');
}
```

#### Issue: Cascade Deletes Not Working

**Symptom:** Child records remain after parent is deleted

**Cause:** Foreign key constraints not properly set

**Solution:**
```sql
-- Verify foreign key has ON DELETE CASCADE
SELECT
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name,
  rc.delete_rule
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
JOIN information_schema.referential_constraints AS rc
  ON rc.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name = 'workout_weeks';

-- If delete_rule is not 'CASCADE', recreate constraint
ALTER TABLE workout_weeks
  DROP CONSTRAINT workout_weeks_plan_id_fkey;

ALTER TABLE workout_weeks
  ADD CONSTRAINT workout_weeks_plan_id_fkey
  FOREIGN KEY (plan_id)
  REFERENCES workout_plans(id)
  ON DELETE CASCADE;
```

#### Issue: Notifications Not Sending

**Symptom:** `scheduleWorkoutReminders()` succeeds but no notifications received

**Debugging:**
```dart
// 1. Verify OneSignal player ID is synced
final playerId = await OneSignal.User.getOnesignalId();
print('Player ID: $playerId');

if (playerId == null) {
  print('ERROR: Player ID is null. User may not have granted permission.');
  await OneSignal.Notifications.requestPermission(true);
  return;
}

// 2. Verify player ID is stored in database
final userRecord = await supabase
  .from('profiles')
  .select('onesignal_player_id')
  .eq('id', userId)
  .single();

print('DB Player ID: ${userRecord['onesignal_player_id']}');

if (userRecord['onesignal_player_id'] != playerId) {
  print('Player ID mismatch! Syncing...');
  await supabase
    .from('profiles')
    .update({'onesignal_player_id': playerId})
    .eq('id', userId);
}

// 3. Check scheduled_notifications table
final scheduled = await supabase
  .from('scheduled_notifications')
  .select()
  .eq('user_id', userId)
  .eq('status', 'scheduled')
  .order('send_at');

print('Scheduled notifications: ${scheduled.length}');
for (final notif in scheduled) {
  print('  - ${notif['notification_type']} at ${notif['send_at']}');
}

// 4. Test immediate notification
await OneSignalService().sendWorkoutReminder(
  userId,
  'Test Workout',
  DateTime.now(),
);
print('Test notification sent');
```

#### Issue: PR Detection Not Working

**Symptom:** `detectPRs()` returns empty list despite completing heavier sets

**Cause:** Session not properly completed or exercise names don't match

**Solution:**
```dart
// 1. Verify session is completed
final session = await supabase
  .from('workout_sessions')
  .select('*, exercise_logs(*)')
  .eq('id', sessionId)
  .single();

if (session['completed_at'] == null) {
  print('Session not completed!');
  await workoutService.completeWorkoutSession(sessionId: sessionId);
}

// 2. Verify exercise logs exist
if (session['exercise_logs'].isEmpty) {
  print('No exercise logs found!');
  // Check if logs were saved with correct session_id
}

// 3. Check exercise name matching
final exerciseLogs = await supabase
  .from('exercise_logs')
  .select('exercises(name)')
  .eq('session_id', sessionId);

print('Exercises logged:');
for (final log in exerciseLogs) {
  print('  - ${log['exercises']['name']}');
}

// 4. Run PR detection manually
final prs = await supabase.rpc('detect_prs', {
  'p_user_id': userId,
  'p_exercise_name': 'Barbell Bench Press', // Exact match required!
});

print('PRs found: ${prs.length}');
```

#### Issue: Volume Calculation Incorrect

**Symptom:** Analytics show wrong volume numbers

**Cause:** Null weights or reps, incomplete sessions included

**Solution:**
```sql
-- Check for null values
SELECT
  el.id,
  el.reps,
  el.weight,
  (el.reps * el.weight) as set_volume
FROM exercise_logs el
JOIN workout_sessions ws ON el.session_id = ws.id
WHERE ws.user_id = '<user_id>'
  AND ws.completed_at >= NOW() - INTERVAL '7 days'
  AND (el.reps IS NULL OR el.weight IS NULL);

-- If nulls found, set defaults
UPDATE exercise_logs
SET weight = 0
WHERE weight IS NULL;

-- Exclude incomplete sessions from analytics
SELECT
  SUM(el.weight * el.reps) as total_volume
FROM exercise_logs el
JOIN workout_sessions ws ON el.session_id = ws.id
WHERE ws.user_id = '<user_id>'
  AND ws.completed_at IS NOT NULL  -- Only completed sessions
  AND ws.completed_at >= NOW() - INTERVAL '7 days';
```

#### Issue: AI Generation Takes Too Long

**Symptom:** `generateWorkoutPlan()` times out or takes >30 seconds

**Optimization:**
```dart
// 1. Use cached exercise database instead of API calls
final exerciseDb = await _loadCachedExerciseDatabase();

// 2. Reduce plan complexity
final generatedPlan = await aiService.generateWorkoutPlan(
  userId: currentUserId,
  goal: 'hypertrophy',
  totalWeeks: 4, // Start with 4 weeks, duplicate after
  daysPerWeek: 3, // Reduce days
  experienceLevel: 'intermediate',
);

// 3. Show loading indicator
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => AlertDialog(
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Generating your perfect workout plan...'),
        Text('This may take 10-30 seconds'),
      ],
    ),
  ),
);

// 4. Use timeout with retry
try {
  final plan = await aiService.generateWorkoutPlan(...)
    .timeout(Duration(seconds: 30));
} on TimeoutException {
  print('Generation timed out, retrying with simpler parameters...');
  final plan = await aiService.generateWorkoutPlan(
    ...
    totalWeeks: 2, // Minimal plan
  );
}
```

#### Issue: Duplicate Week Creates Too Many Records

**Symptom:** Database has thousands of records after duplication

**Cause:** Accidentally duplicated with wrong parameters

**Solution:**
```dart
// Safe duplication with transaction
try {
  await supabase.rpc('duplicate_week_safe', {
    'p_source_week_id': sourceWeekId,
    'p_target_week_number': targetWeekNumber,
    'p_target_plan_id': planId,
  });
} catch (e) {
  print('Duplication failed: $e');
  // Transaction will rollback automatically
}

// Create database function with safety checks
CREATE OR REPLACE FUNCTION duplicate_week_safe(
  p_source_week_id UUID,
  p_target_week_number INTEGER,
  p_target_plan_id UUID
) RETURNS UUID AS $
DECLARE
  v_new_week_id UUID;
  v_existing_count INTEGER;
BEGIN
  -- Check if target week already exists
  SELECT COUNT(*) INTO v_existing_count
  FROM workout_weeks
  WHERE plan_id = p_target_plan_id
    AND week_number = p_target_week_number;

  IF v_existing_count > 0 THEN
    RAISE EXCEPTION 'Week % already exists for plan %', p_target_week_number, p_target_plan_id;
  END IF;

  -- Insert new week
  INSERT INTO workout_weeks (plan_id, week_number, notes, deload)
  SELECT p_target_plan_id, p_target_week_number, notes, deload
  FROM workout_weeks
  WHERE id = p_source_week_id
  RETURNING id INTO v_new_week_id;

  -- Copy days
  INSERT INTO workout_days (week_id, day_label, notes, estimated_duration, muscle_groups)
  SELECT v_new_week_id, day_label, notes, estimated_duration, muscle_groups
  FROM workout_days
  WHERE week_id = p_source_week_id;

  -- Copy exercises (via trigger or another function)

  RETURN v_new_week_id;
END;
$ LANGUAGE plpgsql;
```

### Performance Optimization

#### Query Optimization

```dart
// BAD: N+1 queries
final plan = await supabase.from('workout_plans').select().eq('id', planId).single();
for (final weekId in plan['week_ids']) {
  final week = await supabase.from('workout_weeks').select().eq('id', weekId).single();
  // ...
}

// GOOD: Single query with joins
final plan = await supabase
  .from('workout_plans')
  .select('''
    *,
    workout_weeks!inner(
      *,
      workout_days!inner(
        *,
        exercises(*)
      )
    )
  ''')
  .eq('id', planId)
  .single();
```

#### Caching Strategy

```dart
class WorkoutService {
  final Map<String, WorkoutPlan> _planCache = {};

  Future<WorkoutPlan> getWorkoutPlan(String planId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _planCache.containsKey(planId)) {
      print('Returning cached plan');
      return _planCache[planId]!;
    }

    final plan = await _fetchPlanFromDatabase(planId);
    _planCache[planId] = plan;

    return plan;
  }

  void clearCache() {
    _planCache.clear();
  }
}
```

#### Index Usage

```sql
-- Create covering indexes for common queries

-- Get user's active plans
CREATE INDEX idx_workout_plans_user_status ON workout_plans(user_id, status)
  WHERE status = 'active';

-- Get today's workout
CREATE INDEX idx_workout_days_plan_date ON workout_days(week_id, date);

-- Exercise search
CREATE INDEX idx_exercises_name_trgm ON exercises USING gin(name gin_trgm_ops);
CREATE EXTENSION IF NOT EXISTS pg_trgm; -- For fuzzy search

-- Analytics queries
CREATE INDEX idx_exercise_logs_user_completed ON exercise_logs(
  session_id,
  exercise_id,
  completed_at
) WHERE completed_at IS NOT NULL;
```

---

## Appendix

### Glossary

- **1RM**: One-rep max, the maximum weight you can lift for one rep
- **RPE**: Rate of Perceived Exertion (1-10 scale)
- **Tempo**: Speed of exercise phases (eccentric-pause-concentric-pause)
- **Superset**: Two exercises performed back-to-back with no rest
- **Drop Set**: Performing a set to failure, reducing weight, continuing
- **Giant Set**: 4+ exercises performed back-to-back
- **Deload**: Recovery week with reduced volume/intensity
- **DUP**: Daily Undulating Periodization
- **Periodization**: Structured variation of training variables

### References

- [Supabase Documentation](https://supabase.com/docs)
- [OneSignal Flutter SDK](https://documentation.onesignal.com/docs/flutter-sdk-setup)
- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Brzycki 1RM Formula](https://en.wikipedia.org/wiki/One-repetition_maximum)

### Support

For questions or issues:
1. Check this documentation first
2. Search existing GitHub issues
3. Create new issue with workout v2 label
4. Contact dev team: dev@vagushealth.com

---

**Document Version:** 1.0
**Last Updated:** 2025-09-30
**Author:** Claude AI (Vagus Development Team)
**Status:** ✅ Complete
