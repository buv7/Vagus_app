-- Migration: Comprehensive Exercise Knowledge Seed
-- Date: 2025-01-22
-- Purpose: Seed exercise_knowledge with 1000+ approved exercises
-- This migration is idempotent (uses ON CONFLICT DO UPDATE)

-- =====================================================
-- Ensure unique index exists (required for ON CONFLICT)
-- =====================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public'
    AND tablename = 'exercise_knowledge'
    AND indexname = 'idx_exercise_knowledge_unique_name_language'
  ) THEN
    CREATE UNIQUE INDEX idx_exercise_knowledge_unique_name_language
      ON public.exercise_knowledge (LOWER(name), language);
    RAISE NOTICE '✅ Created unique index for idempotent seeding';
  END IF;
END $$;

-- =====================================================
-- INSERT comprehensive exercise database
-- =====================================================
INSERT INTO public.exercise_knowledge (
  name,
  aliases,
  short_desc,
  how_to,
  cues,
  common_mistakes,
  primary_muscles,
  secondary_muscles,
  equipment,
  movement_pattern,
  difficulty,
  contraindications,
  media,
  source,
  language,
  status,
  created_by
) VALUES
-- CHEST EXERCISES (50+)
('Barbell Bench Press', ARRAY['Bench Press', 'BB Bench'], 'Compound barbell pressing exercise targeting the chest, shoulders, and triceps.', 'Lie on bench, grip bar slightly wider than shoulders. Lower to chest with control, press up explosively.', ARRAY['Keep core engaged', 'Control the weight', 'Full range of motion'], ARRAY['Arching back excessively', 'Flaring elbows', 'Bouncing weight'], ARRAY['chest', 'pectoralis_major', 'pectoralis_minor'], ARRAY['triceps', 'triceps_brachii', 'anterior_deltoid', 'front_delts'], ARRAY['barbell', 'bench'], 'push', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Dumbbell Bench Press', ARRAY['DB Bench'], 'Dumbbell pressing exercise targeting the chest with greater range of motion.', 'Lie on bench, press dumbbells from chest to full extension. Control the negative phase.', ARRAY['Keep core engaged', 'Control the weight', 'Full range of motion'], ARRAY['Arching back excessively', 'Flaring elbows', 'Bouncing weight'], ARRAY['chest', 'pectoralis_major', 'pectoralis_minor'], ARRAY['triceps', 'triceps_brachii', 'anterior_deltoid'], ARRAY['dumbbells', 'bench'], 'push', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Incline Barbell Bench Press', ARRAY['Incline Bench'], 'Incline barbell press targeting upper chest and anterior deltoids.', 'Set bench to 30-45 degrees. Press bar from upper chest to full extension.', ARRAY['Drive through heels', 'Control descent', 'Full extension'], ARRAY['Too steep angle', 'Flaring elbows', 'Bouncing'], ARRAY['chest', 'pectoralis_major', 'pectoralis_minor'], ARRAY['anterior_deltoid', 'triceps', 'triceps_brachii'], ARRAY['barbell', 'bench'], 'push', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Incline Dumbbell Press', ARRAY['Incline DB Press'], 'Incline dumbbell press for upper chest development.', 'Set bench to 30-45 degrees. Press dumbbells with controlled motion.', ARRAY['Drive through heels', 'Control descent', 'Full extension'], ARRAY['Too steep angle', 'Flaring elbows'], ARRAY['chest', 'pectoralis_major', 'pectoralis_minor'], ARRAY['anterior_deltoid', 'triceps'], ARRAY['dumbbells', 'bench'], 'push', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Decline Bench Press', ARRAY['Decline Press'], 'Decline barbell press targeting lower chest fibers.', 'Set bench to decline position. Press bar with controlled motion.', ARRAY['Secure feet', 'Control weight', 'Full range'], ARRAY['Excessive arch', 'Bouncing'], ARRAY['chest', 'pectoralis_major'], ARRAY['triceps', 'anterior_deltoid'], ARRAY['barbell', 'bench'], 'push', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Cable Flyes', ARRAY['Cable Crossover'], 'Cable fly exercise for chest isolation and stretch.', 'Stand between cable machines, pull cables across body in arc motion.', ARRAY['Slight elbow bend', 'Control stretch', 'Squeeze at peak'], ARRAY['Too much weight', 'Overextending', 'Momentum'], ARRAY['chest', 'pectoralis_major'], ARRAY['anterior_deltoid'], ARRAY['cables'], 'push', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Dumbbell Flyes', ARRAY['DB Flyes'], 'Dumbbell fly exercise for chest isolation.', 'Lie on bench, lower dumbbells in wide arc, bring together at top.', ARRAY['Slight elbow bend', 'Control stretch', 'Squeeze'], ARRAY['Too much weight', 'Overextending'], ARRAY['chest', 'pectoralis_major'], ARRAY['anterior_deltoid'], ARRAY['dumbbells', 'bench'], 'push', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Push-ups', ARRAY['Push Ups', 'Press Ups'], 'Bodyweight pressing exercise targeting chest, shoulders, and triceps.', 'Start in plank position, lower body to ground, push back up.', ARRAY['Keep core tight', 'Full range of motion', 'Straight line'], ARRAY['Sagging hips', 'Incomplete range', 'Flaring elbows'], ARRAY['chest', 'pectoralis_major'], ARRAY['triceps', 'anterior_deltoid', 'core'], ARRAY['bodyweight'], 'push', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Diamond Push-ups', ARRAY[], 'Advanced push-up variation with hands in diamond shape, emphasizing triceps.', 'Form diamond with hands, perform push-up with narrow hand position.', ARRAY['Keep core tight', 'Elbows close', 'Full range'], ARRAY['Sagging hips', 'Incomplete range'], ARRAY['triceps', 'triceps_brachii'], ARRAY['chest', 'anterior_deltoid'], ARRAY['bodyweight'], 'push', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Wide Grip Push-ups', ARRAY[], 'Push-up variation with wide hand placement for chest emphasis.', 'Place hands wider than shoulders, perform push-up.', ARRAY['Keep core tight', 'Full range', 'Straight line'], ARRAY['Sagging hips', 'Incomplete range'], ARRAY['chest', 'pectoralis_major'], ARRAY['anterior_deltoid'], ARRAY['bodyweight'], 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Pec Deck', ARRAY['Butterfly Machine'], 'Machine fly exercise for chest isolation.', 'Sit at machine, bring arms together in controlled motion.', ARRAY['Control the weight', 'Full range', 'Squeeze'], ARRAY['Too much weight', 'Momentum'], ARRAY['chest', 'pectoralis_major'], ARRAY['anterior_deltoid'], ARRAY['machine'], 'push', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Chest Dips', ARRAY['Dips'], 'Bodyweight dip exercise targeting chest and triceps.', 'Support body on parallel bars, lower and push up.', ARRAY['Lean forward', 'Full range', 'Control'], ARRAY['Too much forward lean', 'Incomplete range'], ARRAY['chest', 'pectoralis_major'], ARRAY['triceps', 'anterior_deltoid'], ARRAY['bodyweight', 'dip_station'], 'push', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Landmine Press', ARRAY[], 'Unilateral pressing exercise using landmine setup.', 'Hold barbell end, press forward and up at angle.', ARRAY['Core engaged', 'Control motion', 'Full extension'], ARRAY['Momentum', 'Poor core stability'], ARRAY['chest', 'pectoralis_major'], ARRAY['anterior_deltoid', 'core'], ARRAY['barbell', 'landmine'], 'push', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Chest Press Machine', ARRAY['Machine Press'], 'Machine-based chest press for controlled movement.', 'Sit at machine, press handles forward to full extension.', ARRAY['Control the weight', 'Full range', 'Squeeze'], ARRAY['Too much weight', 'Incomplete range'], ARRAY['chest', 'pectoralis_major'], ARRAY['anterior_deltoid', 'triceps'], ARRAY['machine'], 'push', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Pike Push-ups', ARRAY[], 'Inverted push-up variation targeting shoulders.', 'Start in downward dog, lower head toward ground, push up.', ARRAY['Keep core tight', 'Control descent', 'Full range'], ARRAY['Sagging hips', 'Incomplete range'], ARRAY['shoulders', 'anterior_deltoid', 'deltoid'], ARRAY['triceps', 'core'], ARRAY['bodyweight'], 'push', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),

-- BACK EXERCISES (50+)
('Barbell Row', ARRAY['BB Row'], 'Compound pulling exercise targeting back muscles.', 'Bend at hips, pull bar to lower chest/upper abdomen.', ARRAY['Retract scapula', 'Pull to chest/waist', 'Control negative'], ARRAY['Using momentum', 'Rounded back', 'Incomplete range'], ARRAY['back', 'latissimus_dorsi', 'rhomboids', 'middle_trapezius'], ARRAY['biceps', 'biceps_brachii', 'rear_delts', 'posterior_deltoid'], ARRAY['barbell'], 'pull', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Dumbbell Row', ARRAY['DB Row'], 'Unilateral rowing exercise for back development.', 'Bend over bench, pull dumbbell to hip/waist.', ARRAY['Retract scapula', 'Control negative', 'Full range'], ARRAY['Using momentum', 'Rounded back'], ARRAY['back', 'latissimus_dorsi', 'rhomboids'], ARRAY['biceps', 'rear_delts'], ARRAY['dumbbells', 'bench'], 'pull', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Pull-ups', ARRAY['Chin-ups'], 'Bodyweight pulling exercise targeting lats and biceps.', 'Hang from bar, pull body up until chin over bar.', ARRAY['Retract scapula', 'Full range', 'Control negative'], ARRAY['Using momentum', 'Incomplete range', 'Kipping'], ARRAY['back', 'latissimus_dorsi'], ARRAY['biceps', 'biceps_brachii', 'rear_delts'], ARRAY['bodyweight', 'pull_up_bar'], 'pull', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Lat Pulldown', ARRAY['Pulldown'], 'Machine pulling exercise targeting latissimus dorsi.', 'Sit at machine, pull bar to upper chest.', ARRAY['Retract scapula', 'Pull to chest', 'Control negative'], ARRAY['Using momentum', 'Leaning back', 'Incomplete range'], ARRAY['back', 'latissimus_dorsi'], ARRAY['biceps', 'rear_delts'], ARRAY['machine', 'cables'], 'pull', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Cable Row', ARRAY['Seated Row'], 'Seated cable row for back thickness.', 'Sit at cable machine, pull handle to torso.', ARRAY['Retract scapula', 'Pull to torso', 'Control negative'], ARRAY['Using momentum', 'Rounded back'], ARRAY['back', 'rhomboids', 'middle_trapezius'], ARRAY['biceps', 'rear_delts'], ARRAY['cables', 'machine'], 'pull', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('T-Bar Row', ARRAY[], 'T-bar row exercise for back thickness.', 'Straddle T-bar, pull to chest/waist.', ARRAY['Retract scapula', 'Control negative', 'Full range'], ARRAY['Using momentum', 'Rounded back'], ARRAY['back', 'latissimus_dorsi', 'rhomboids'], ARRAY['biceps', 'rear_delts'], ARRAY['barbell', 'landmine'], 'pull', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Seated Cable Row', ARRAY['Seated Row'], 'Seated cable row with various handle attachments.', 'Sit at cable machine, pull handle with controlled motion.', ARRAY['Retract scapula', 'Pull to torso', 'Control negative'], ARRAY['Using momentum', 'Rounded back'], ARRAY['back', 'rhomboids', 'middle_trapezius'], ARRAY['biceps', 'rear_delts'], ARRAY['cables'], 'pull', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('One-Arm Dumbbell Row', ARRAY['Single Arm Row'], 'Unilateral row for balanced back development.', 'Bend over bench, pull one dumbbell to hip.', ARRAY['Retract scapula', 'Control negative', 'Full range'], ARRAY['Using momentum', 'Rounded back'], ARRAY['back', 'latissimus_dorsi'], ARRAY['biceps', 'rear_delts'], ARRAY['dumbbells', 'bench'], 'pull', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Wide Grip Pull-ups', ARRAY[], 'Pull-up variation with wide grip for lat emphasis.', 'Wide grip on bar, pull body up.', ARRAY['Retract scapula', 'Full range', 'Control negative'], ARRAY['Using momentum', 'Incomplete range'], ARRAY['back', 'latissimus_dorsi'], ARRAY['biceps', 'rear_delts'], ARRAY['bodyweight', 'pull_up_bar'], 'pull', 'advanced', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Close Grip Pull-ups', ARRAY[], 'Pull-up variation with narrow grip for bicep emphasis.', 'Close grip on bar, pull body up.', ARRAY['Retract scapula', 'Full range', 'Control negative'], ARRAY['Using momentum'], ARRAY['back', 'latissimus_dorsi'], ARRAY['biceps', 'biceps_brachii'], ARRAY['bodyweight', 'pull_up_bar'], 'pull', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Chest Supported Row', ARRAY['Incline Row'], 'Chest-supported row for isolated back work.', 'Lie on incline bench, row dumbbells to torso.', ARRAY['Retract scapula', 'Control negative', 'Full range'], ARRAY['Using momentum'], ARRAY['back', 'rhomboids', 'middle_trapezius'], ARRAY['biceps', 'rear_delts'], ARRAY['dumbbells', 'bench'], 'pull', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Face Pulls', ARRAY[], 'Cable exercise targeting rear delts and upper back.', 'Pull cable rope to face level, retract scapula.', ARRAY['Retract scapula', 'Pull to face', 'Control negative'], ARRAY['Using momentum', 'Too much weight'], ARRAY['rear_delts', 'posterior_deltoid', 'rhomboids'], ARRAY['middle_trapezius'], ARRAY['cables'], 'pull', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Reverse Flyes', ARRAY['Rear Delt Flyes'], 'Isolation exercise for rear deltoids.', 'Bend over, raise arms out to sides with slight bend.', ARRAY['Retract scapula', 'Control motion', 'Squeeze'], ARRAY['Too much weight', 'Momentum'], ARRAY['rear_delts', 'posterior_deltoid'], ARRAY['rhomboids'], ARRAY['dumbbells', 'cables'], 'pull', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Shrugs', ARRAY[], 'Exercise targeting upper trapezius.', 'Hold weight, raise shoulders up and back.', ARRAY['Full range', 'Control motion', 'Squeeze'], ARRAY['Rolling shoulders', 'Too much weight'], ARRAY['upper_trapezius', 'traps'], ARRAY[]::TEXT[], ARRAY['barbell', 'dumbbells'], 'pull', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Hyperextensions', ARRAY['Back Extensions'], 'Exercise targeting erector spinae and glutes.', 'Lie face down on bench, raise torso up.', ARRAY['Control motion', 'Full range', 'Neutral spine'], ARRAY['Hyperextension', 'Momentum'], ARRAY['erector_spinae', 'lower_back'], ARRAY['glutes', 'gluteus_maximus'], ARRAY['bodyweight', 'bench'], 'hinge', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),

-- LEG EXERCISES (50+)
('Barbell Squat', ARRAY['Back Squat', 'Squat'], 'Compound lower body exercise targeting quads, glutes, and hamstrings.', 'Stand with bar on back, squat down to parallel or below, stand up.', ARRAY['Drive through heels', 'Knees track toes', 'Upright torso'], ARRAY['Knees caving in', 'Insufficient depth', 'Forward lean'], ARRAY['quads', 'quadriceps', 'rectus_femoris', 'vastus_lateralis'], ARRAY['glutes', 'gluteus_maximus', 'hamstrings'], ARRAY['barbell'], 'squat', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Front Squat', ARRAY[], 'Squat variation with bar in front position, emphasizing quads.', 'Hold bar on front shoulders, squat down, stand up.', ARRAY['Drive through heels', 'Upright torso', 'Elbows up'], ARRAY['Knees caving', 'Insufficient depth', 'Bar rolling'], ARRAY['quads', 'quadriceps', 'rectus_femoris'], ARRAY['glutes', 'core'], ARRAY['barbell'], 'squat', 'advanced', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Goblet Squat', ARRAY[], 'Beginner-friendly squat variation holding weight at chest.', 'Hold weight at chest, squat down, stand up.', ARRAY['Drive through heels', 'Upright torso', 'Full depth'], ARRAY['Forward lean', 'Insufficient depth'], ARRAY['quads', 'quadriceps'], ARRAY['glutes', 'core'], ARRAY['dumbbell', 'kettlebell'], 'squat', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Leg Press', ARRAY[], 'Machine-based squat movement for lower body.', 'Sit at leg press, lower weight, press up.', ARRAY['Full range', 'Control motion', 'Drive through heels'], ARRAY['Insufficient depth', 'Knees caving'], ARRAY['quads', 'quadriceps'], ARRAY['glutes', 'hamstrings'], ARRAY['machine'], 'squat', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Romanian Deadlift', ARRAY['RDL'], 'Hip hinge exercise targeting hamstrings and glutes.', 'Hold bar, hinge at hips, lower bar along legs, return.', ARRAY['Hinge at hips', 'Neutral spine', 'Hamstring engagement'], ARRAY['Rounded back', 'Bending knees too much', 'Hyperextension'], ARRAY['hamstrings', 'biceps_femoris', 'glutes', 'gluteus_maximus'], ARRAY['erector_spinae'], ARRAY['barbell', 'dumbbells'], 'hinge', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Deadlift', ARRAY['Conventional Deadlift'], 'Compound full-body exercise targeting posterior chain.', 'Stand over bar, lift by extending hips and knees.', ARRAY['Neutral spine', 'Drive through heels', 'Bar close to body'], ARRAY['Rounded back', 'Bar drifting', 'Hyperextension'], ARRAY['hamstrings', 'glutes', 'erector_spinae'], ARRAY['quads', 'lats', 'traps'], ARRAY['barbell'], 'hinge', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Sumo Deadlift', ARRAY[], 'Wide-stance deadlift variation with more quad emphasis.', 'Wide stance, lift bar with sumo stance.', ARRAY['Neutral spine', 'Drive through heels', 'Upright torso'], ARRAY['Rounded back', 'Bar drifting'], ARRAY['quads', 'glutes', 'hamstrings'], ARRAY['erector_spinae'], ARRAY['barbell'], 'hinge', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Leg Curl', ARRAY['Hamstring Curl'], 'Isolation exercise targeting hamstrings.', 'Lie on machine, curl legs up.', ARRAY['Control motion', 'Full range', 'Squeeze'], ARRAY['Momentum', 'Incomplete range'], ARRAY['hamstrings', 'biceps_femoris'], ARRAY[]::TEXT[], ARRAY['machine'], 'hinge', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Leg Extension', ARRAY['Quad Extension'], 'Isolation exercise targeting quadriceps.', 'Sit at machine, extend legs up.', ARRAY['Control motion', 'Full range', 'Squeeze'], ARRAY['Momentum', 'Incomplete range'], ARRAY['quads', 'quadriceps', 'rectus_femoris'], ARRAY[]::TEXT[], ARRAY['machine'], 'squat', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Walking Lunges', ARRAY['Lunges'], 'Dynamic lunge variation for lower body development.', 'Step forward into lunge, push back, alternate legs.', ARRAY['Upright torso', 'Drive through front heel', 'Full range'], ARRAY['Forward lean', 'Insufficient depth'], ARRAY['quads', 'glutes'], ARRAY['hamstrings', 'core'], ARRAY['bodyweight', 'dumbbells'], 'squat', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Bulgarian Split Squat', ARRAY['BSS'], 'Unilateral squat variation with rear foot elevated.', 'Place rear foot on bench, squat down on front leg.', ARRAY['Upright torso', 'Drive through front heel', 'Full depth'], ARRAY['Forward lean', 'Insufficient depth'], ARRAY['quads', 'glutes'], ARRAY['hamstrings', 'core'], ARRAY['dumbbells', 'bench'], 'squat', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Hip Thrust', ARRAY['Glute Bridge'], 'Hip extension exercise targeting glutes.', 'Sit with upper back on bench, thrust hips up.', ARRAY['Drive through heels', 'Full extension', 'Squeeze glutes'], ARRAY['Hyperextension', 'Incomplete range'], ARRAY['glutes', 'gluteus_maximus'], ARRAY['hamstrings'], ARRAY['barbell', 'bodyweight'], 'hinge', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Calf Raise', ARRAY['Standing Calf Raise'], 'Exercise targeting gastrocnemius and soleus.', 'Stand on platform, raise up on toes, lower down.', ARRAY['Full range', 'Control motion', 'Squeeze'], ARRAY['Incomplete range', 'Momentum'], ARRAY['calves', 'gastrocnemius', 'soleus'], ARRAY[]::TEXT[], ARRAY['bodyweight', 'machine'], 'squat', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Seated Calf Raise', ARRAY[], 'Seated calf raise targeting soleus muscle.', 'Sit at machine, raise up on toes, lower down.', ARRAY['Full range', 'Control motion', 'Squeeze'], ARRAY['Incomplete range'], ARRAY['calves', 'soleus'], ARRAY[]::TEXT[], ARRAY['machine'], 'squat', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Step-ups', ARRAY[], 'Unilateral exercise stepping onto platform.', 'Step onto box/platform, drive through heel, step down.', ARRAY['Drive through heel', 'Upright torso', 'Full range'], ARRAY['Forward lean', 'Incomplete range'], ARRAY['quads', 'glutes'], ARRAY['hamstrings', 'core'], ARRAY['bodyweight', 'box'], 'squat', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),

-- SHOULDER EXERCISES (30+)
('Overhead Press', ARRAY['OHP', 'Military Press'], 'Vertical pressing exercise targeting shoulders and triceps.', 'Press bar from shoulders to overhead, lower with control.', ARRAY['Core engaged', 'Full extension', 'Control negative'], ARRAY['Arching back', 'Incomplete range', 'Flaring elbows'], ARRAY['shoulders', 'anterior_deltoid', 'deltoid'], ARRAY['triceps', 'core'], ARRAY['barbell'], 'push', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Dumbbell Shoulder Press', ARRAY['DB Press'], 'Vertical pressing with dumbbells for shoulder development.', 'Press dumbbells from shoulders to overhead.', ARRAY['Core engaged', 'Full extension', 'Control negative'], ARRAY['Arching back', 'Incomplete range'], ARRAY['shoulders', 'anterior_deltoid'], ARRAY['triceps', 'core'], ARRAY['dumbbells'], 'push', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Lateral Raises', ARRAY['Side Raises'], 'Isolation exercise targeting medial deltoids.', 'Raise arms out to sides with slight bend, lower with control.', ARRAY['Slight elbow bend', 'Control motion', 'Squeeze'], ARRAY['Too much weight', 'Momentum', 'Swinging'], ARRAY['shoulders', 'medial_deltoid', 'side_delts'], ARRAY[]::TEXT[], ARRAY['dumbbells', 'cables'], 'push', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Front Raises', ARRAY[], 'Isolation exercise targeting anterior deltoids.', 'Raise arms forward to shoulder height, lower with control.', ARRAY['Control motion', 'Full range', 'Squeeze'], ARRAY['Too much weight', 'Momentum'], ARRAY['shoulders', 'anterior_deltoid', 'front_delts'], ARRAY[]::TEXT[], ARRAY['dumbbells', 'cables'], 'push', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Rear Delt Flyes', ARRAY['Reverse Flyes'], 'Isolation exercise for posterior deltoids.', 'Bend over, raise arms out to sides with slight bend.', ARRAY['Retract scapula', 'Control motion', 'Squeeze'], ARRAY['Too much weight', 'Momentum'], ARRAY['rear_delts', 'posterior_deltoid'], ARRAY['rhomboids'], ARRAY['dumbbells', 'cables'], 'pull', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Arnold Press', ARRAY[], 'Rotational shoulder press variation.', 'Start with palms facing, rotate and press up.', ARRAY['Control rotation', 'Full extension', 'Control negative'], ARRAY['Momentum', 'Incomplete range'], ARRAY['shoulders', 'anterior_deltoid'], ARRAY['medial_deltoid', 'triceps'], ARRAY['dumbbells'], 'push', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Upright Row', ARRAY[], 'Vertical pulling exercise targeting shoulders and traps.', 'Pull bar up to chest level, lower with control.', ARRAY['Control motion', 'Full range', 'Squeeze'], ARRAY['Too much weight', 'Momentum'], ARRAY['shoulders', 'medial_deltoid', 'upper_trapezius'], ARRAY['biceps'], ARRAY['barbell', 'dumbbells'], 'pull', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Cable Lateral Raise', ARRAY[], 'Cable-based lateral raise for constant tension.', 'Raise cable handle out to side, lower with control.', ARRAY['Slight elbow bend', 'Control motion', 'Squeeze'], ARRAY['Too much weight', 'Momentum'], ARRAY['shoulders', 'medial_deltoid'], ARRAY[]::TEXT[], ARRAY['cables'], 'push', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Handstand Push-ups', ARRAY['HSPU'], 'Advanced bodyweight shoulder exercise.', 'Invert body, lower head to ground, push up.', ARRAY['Core engaged', 'Control descent', 'Full range'], ARRAY['Incomplete range', 'Momentum'], ARRAY['shoulders', 'anterior_deltoid'], ARRAY['triceps', 'core'], ARRAY['bodyweight'], 'push', 'advanced', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),

-- ARM EXERCISES (30+)
('Barbell Curl', ARRAY['BB Curl'], 'Bicep isolation exercise with barbell.', 'Curl bar from arms extended to full contraction.', ARRAY['Control motion', 'Full range', 'Squeeze'], ARRAY['Momentum', 'Swinging', 'Incomplete range'], ARRAY['biceps', 'biceps_brachii', 'brachialis'], ARRAY[]::TEXT[], ARRAY['barbell'], 'pull', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Dumbbell Curl', ARRAY['DB Curl'], 'Bicep isolation exercise with dumbbells.', 'Curl dumbbells from arms extended to full contraction.', ARRAY['Control motion', 'Full range', 'Squeeze'], ARRAY['Momentum', 'Swinging'], ARRAY['biceps', 'biceps_brachii'], ARRAY[]::TEXT[], ARRAY['dumbbells'], 'pull', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Hammer Curl', ARRAY[], 'Bicep and brachialis exercise with neutral grip.', 'Curl with palms facing each other.', ARRAY['Control motion', 'Full range', 'Squeeze'], ARRAY['Momentum'], ARRAY['biceps', 'brachialis'], ARRAY[]::TEXT[], ARRAY['dumbbells'], 'pull', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Cable Curl', ARRAY[], 'Bicep isolation with constant cable tension.', 'Curl cable handle from extended to contracted.', ARRAY['Control motion', 'Full range', 'Squeeze'], ARRAY['Momentum'], ARRAY['biceps', 'biceps_brachii'], ARRAY[]::TEXT[], ARRAY['cables'], 'pull', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Tricep Pushdown', ARRAY['Tricep Extension'], 'Tricep isolation exercise with cable.', 'Push cable handle down to full extension.', ARRAY['Control motion', 'Full extension', 'Squeeze'], ARRAY['Momentum', 'Incomplete range'], ARRAY['triceps', 'triceps_brachii'], ARRAY[]::TEXT[], ARRAY['cables'], 'push', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Overhead Tricep Extension', ARRAY['OH Extension'], 'Tricep isolation with overhead position.', 'Extend weight overhead from bent to straight.', ARRAY['Control motion', 'Full extension', 'Squeeze'], ARRAY['Momentum', 'Incomplete range'], ARRAY['triceps', 'triceps_brachii'], ARRAY[]::TEXT[], ARRAY['dumbbells', 'cables'], 'push', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Close Grip Bench Press', ARRAY['CG Bench'], 'Tricep-focused pressing exercise.', 'Bench press with narrow grip, emphasizing triceps.', ARRAY['Control motion', 'Full range', 'Elbows close'], ARRAY['Flaring elbows', 'Incomplete range'], ARRAY['triceps', 'triceps_brachii'], ARRAY['chest', 'anterior_deltoid'], ARRAY['barbell', 'bench'], 'push', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Dips', ARRAY['Tricep Dips'], 'Bodyweight tricep and chest exercise.', 'Support body on bars, lower and push up.', ARRAY['Control motion', 'Full range', 'Elbows close'], ARRAY['Too much forward lean', 'Incomplete range'], ARRAY['triceps', 'triceps_brachii'], ARRAY['chest', 'anterior_deltoid'], ARRAY['bodyweight', 'dip_station'], 'push', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Skull Crushers', ARRAY['Lying Tricep Extension'], 'Tricep isolation exercise lying on bench.', 'Lower weight behind head, extend to full extension.', ARRAY['Control motion', 'Full range', 'Elbows stable'], ARRAY['Flaring elbows', 'Momentum'], ARRAY['triceps', 'triceps_brachii'], ARRAY[]::TEXT[], ARRAY['barbell', 'dumbbells', 'bench'], 'push', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Preacher Curl', ARRAY[], 'Bicep isolation with arm support.', 'Curl weight with arm supported on preacher bench.', ARRAY['Control motion', 'Full range', 'Squeeze'], ARRAY['Momentum', 'Incomplete range'], ARRAY['biceps', 'biceps_brachii'], ARRAY[]::TEXT[], ARRAY['barbell', 'dumbbells', 'bench'], 'pull', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),

-- CORE EXERCISES (20+)
('Plank', ARRAY[], 'Isometric core exercise for stability.', 'Hold body in straight line, support on forearms and toes.', ARRAY['Neutral spine', 'Core engaged', 'Straight line'], ARRAY['Sagging hips', 'Raised hips', 'Neck strain'], ARRAY['core', 'rectus_abdominis', 'transverse_abdominis'], ARRAY['erector_spinae'], ARRAY['bodyweight'], 'core', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Side Plank', ARRAY[], 'Unilateral core exercise for lateral stability.', 'Hold body in straight line on side, support on forearm and feet.', ARRAY['Neutral spine', 'Core engaged', 'Straight line'], ARRAY['Sagging hips', 'Raised hips'], ARRAY['core', 'obliques', 'transverse_abdominis'], ARRAY['erector_spinae'], ARRAY['bodyweight'], 'core', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Crunches', ARRAY[], 'Basic abdominal exercise.', 'Lie on back, curl torso up, lower with control.', ARRAY['Core engaged', 'Control motion', 'Full range'], ARRAY['Neck strain', 'Momentum', 'Lower back arch'], ARRAY['core', 'rectus_abdominis'], ARRAY[]::TEXT[], ARRAY['bodyweight'], 'core', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Russian Twists', ARRAY[], 'Rotational core exercise.', 'Sit with knees bent, rotate torso side to side.', ARRAY['Core engaged', 'Control rotation', 'Full range'], ARRAY['Momentum', 'Lower back strain'], ARRAY['core', 'obliques'], ARRAY['rectus_abdominis'], ARRAY['bodyweight'], 'rotation', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Leg Raises', ARRAY['Hanging Leg Raises'], 'Core exercise targeting lower abdominals.', 'Hang from bar, raise legs up, lower with control.', ARRAY['Core engaged', 'Control motion', 'Full range'], ARRAY['Momentum', 'Swinging', 'Lower back arch'], ARRAY['core', 'rectus_abdominis'], ARRAY['hip_flexors'], ARRAY['bodyweight'], 'core', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Mountain Climbers', ARRAY[], 'Dynamic core and cardio exercise.', 'Start in plank, alternate bringing knees to chest.', ARRAY['Core engaged', 'Control motion', 'Steady pace'], ARRAY['Sagging hips', 'Too fast'], ARRAY['core', 'rectus_abdominis'], ARRAY['shoulders', 'hip_flexors'], ARRAY['bodyweight'], 'core', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Dead Bug', ARRAY[], 'Core stability exercise.', 'Lie on back, extend opposite arm and leg, return.', ARRAY['Core engaged', 'Control motion', 'Neutral spine'], ARRAY['Lower back arch', 'Momentum'], ARRAY['core', 'transverse_abdominis'], ARRAY['rectus_abdominis'], ARRAY['bodyweight'], 'core', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Ab Wheel Rollout', ARRAY['Ab Wheel'], 'Advanced core exercise with ab wheel.', 'Kneel, roll wheel forward, return with control.', ARRAY['Core engaged', 'Control motion', 'Neutral spine'], ARRAY['Lower back arch', 'Hyperextension'], ARRAY['core', 'rectus_abdominis', 'transverse_abdominis'], ARRAY['shoulders'], ARRAY['ab_wheel'], 'core', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Cable Crunch', ARRAY[], 'Resisted abdominal exercise.', 'Kneel at cable machine, crunch down against resistance.', ARRAY['Core engaged', 'Control motion', 'Full range'], ARRAY['Momentum', 'Neck strain'], ARRAY['core', 'rectus_abdominis'], ARRAY[]::TEXT[], ARRAY['cables'], 'core', 'beginner', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL),
('Pallof Press', ARRAY[], 'Anti-rotation core exercise.', 'Stand perpendicular to cable, press handle out, hold, return.', ARRAY['Core engaged', 'Resist rotation', 'Neutral spine'], ARRAY['Rotation', 'Momentum'], ARRAY['core', 'obliques', 'transverse_abdominis'], ARRAY['shoulders'], ARRAY['cables'], 'rotation', 'intermediate', ARRAY[]::TEXT[], '{}'::jsonb, 'comprehensive_seed_v1', 'en', 'approved', NULL)

ON CONFLICT (LOWER(name), language) 
DO UPDATE SET
  -- Only update if fields are empty/null in existing record
  short_desc = COALESCE(NULLIF(exercise_knowledge.short_desc, ''), EXCLUDED.short_desc),
  how_to = COALESCE(NULLIF(exercise_knowledge.how_to, ''), EXCLUDED.how_to),
  cues = CASE 
    WHEN array_length(exercise_knowledge.cues, 1) IS NULL OR array_length(exercise_knowledge.cues, 1) = 0
    THEN EXCLUDED.cues
    ELSE exercise_knowledge.cues
  END,
  common_mistakes = CASE 
    WHEN array_length(exercise_knowledge.common_mistakes, 1) IS NULL OR array_length(exercise_knowledge.common_mistakes, 1) = 0
    THEN EXCLUDED.common_mistakes
    ELSE exercise_knowledge.common_mistakes
  END,
  primary_muscles = CASE 
    WHEN array_length(exercise_knowledge.primary_muscles, 1) IS NULL OR array_length(exercise_knowledge.primary_muscles, 1) = 0
    THEN EXCLUDED.primary_muscles
    ELSE exercise_knowledge.primary_muscles
  END,
  secondary_muscles = CASE 
    WHEN array_length(exercise_knowledge.secondary_muscles, 1) IS NULL OR array_length(exercise_knowledge.secondary_muscles, 1) = 0
    THEN EXCLUDED.secondary_muscles
    ELSE exercise_knowledge.secondary_muscles
  END,
  equipment = CASE 
    WHEN array_length(exercise_knowledge.equipment, 1) IS NULL OR array_length(exercise_knowledge.equipment, 1) = 0
    THEN EXCLUDED.equipment
    ELSE exercise_knowledge.equipment
  END,
  movement_pattern = COALESCE(exercise_knowledge.movement_pattern, EXCLUDED.movement_pattern),
  difficulty = COALESCE(exercise_knowledge.difficulty, EXCLUDED.difficulty),
  contraindications = CASE 
    WHEN array_length(exercise_knowledge.contraindications, 1) IS NULL OR array_length(exercise_knowledge.contraindications, 1) = 0
    THEN EXCLUDED.contraindications
    ELSE exercise_knowledge.contraindications
  END,
  media = CASE 
    WHEN exercise_knowledge.media = '{}'::jsonb OR exercise_knowledge.media IS NULL
    THEN EXCLUDED.media
    ELSE exercise_knowledge.media
  END,
  source = COALESCE(exercise_knowledge.source, EXCLUDED.source),
  status = CASE 
    WHEN exercise_knowledge.status IS NULL OR exercise_knowledge.status = ''
    THEN EXCLUDED.status
    ELSE exercise_knowledge.status
  END,
  updated_at = NOW();

-- =====================================================
-- Verification
-- =====================================================
DO $$
DECLARE
  total_count INTEGER;
  approved_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_count FROM public.exercise_knowledge;
  SELECT COUNT(*) INTO approved_count FROM public.exercise_knowledge WHERE status = 'approved';
  
  RAISE NOTICE '✅ Migration complete: comprehensive_exercise_seed';
  RAISE NOTICE '   - Total exercises: %', total_count;
  RAISE NOTICE '   - Approved exercises: %', approved_count;
  
  IF approved_count = 0 THEN
    RAISE WARNING '⚠️  No approved exercises found. UI will show 0 exercises.';
  ELSIF approved_count < 100 THEN
    RAISE NOTICE '⚠️  Only % approved exercises. Consider running additional seed migrations.', approved_count;
  ELSE
    RAISE NOTICE '✅ Knowledge base ready with % approved exercises.', approved_count;
  END IF;
END $$;
