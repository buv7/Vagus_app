-- Migration: Seed Additional Intensifiers (80-120 total) (Idempotent)
-- Date: 2025-12-21
-- Purpose: Add 50-90 more training intensifiers to reach 80-120 total
--
-- Rules:
--   - Uses ON CONFLICT to prevent duplicates (idempotent)
--   - Only fills missing fields, preserves existing content
--   - Sets status='approved', language='en', created_by=NULL

-- =====================================================
-- INSERT additional intensifiers
-- =====================================================
INSERT INTO public.intensifier_knowledge (
  name,
  aliases,
  short_desc,
  how_to,
  fatigue_cost,
  best_for,
  intensity_rules,
  examples,
  language,
  status,
  created_by
) VALUES
-- ACCUMULATION SETS
(
  'Accumulation Sets',
  ARRAY['accumulation', 'volume accumulation'],
  'Gradually increase reps across sets while maintaining same weight, accumulating total volume.',
  '1) Set 1: Lower reps (e.g., 8 reps). 2) Set 2: Increase reps (e.g., 10 reps). 3) Set 3: More reps (e.g., 12 reps). 4) Same weight throughout. Best for: hypertrophy, volume accumulation, progressive overload without weight increase.',
  'medium',
  ARRAY['hypertrophy', 'volume', 'progressive_overload'],
  '{"accumulation": {"sets": 3, "rep_progression": [8, 10, 12], "same_weight": true}}'::jsonb,
  ARRAY['Bench press: 8, 10, 12 reps at 80kg'],
  'en',
  'approved',
  NULL
),

-- ASCENDING SETS
(
  'Ascending Sets',
  ARRAY['ascending', 'pyramid up', 'ramp up'],
  'Increase weight each set while decreasing reps (e.g., 12@60kg, 10@70kg, 8@80kg).',
  '1) Start with lighter weight, higher reps. 2) Increase weight each set. 3) Decrease reps to maintain intensity. 4) Typically 3-5 sets. Best for: strength, warm-up progression, volume with increasing intensity.',
  'medium',
  ARRAY['strength', 'warm_up', 'volume'],
  '{"ascending": {"sets": 4, "weight_increase_percent": 10, "rep_decrease": 2}}'::jsonb,
  ARRAY['Squat: 12@60kg, 10@70kg, 8@80kg, 6@90kg'],
  'en',
  'approved',
  NULL
),

-- DESCENDING SETS
(
  'Descending Sets',
  ARRAY['descending', 'reverse pyramid', 'pyramid down'],
  'Decrease weight each set while increasing reps (e.g., 6@90kg, 8@80kg, 10@70kg).',
  '1) Start with heaviest weight, lowest reps. 2) Decrease weight each set. 3) Increase reps. 4) Maintain intensity throughout. Best for: strength, volume accumulation, fatigue management.',
  'medium',
  ARRAY['strength', 'volume', 'fatigue_management'],
  '{"descending": {"sets": 4, "weight_decrease_percent": 10, "rep_increase": 2}}'::jsonb,
  ARRAY['Deadlift: 6@140kg, 8@130kg, 10@120kg, 12@110kg'],
  'en',
  'approved',
  NULL
),

-- PYRAMID SETS (FULL)
(
  'Pyramid Sets',
  ARRAY['full pyramid', 'triangle', 'up and down'],
  'Ascend then descend: increase weight/decrease reps, then decrease weight/increase reps.',
  '1) Ascend: 12@60kg, 10@70kg, 8@80kg. 2) Descend: 10@70kg, 12@60kg. 3) Peak at middle set. Best for: volume, strength, comprehensive stimulus.',
  'high',
  ARRAY['volume', 'strength', 'comprehensive'],
  '{"pyramid": {"ascending_sets": 3, "descending_sets": 2, "peak_set": 3}}'::jsonb,
  ARRAY['Bench: 12@60, 10@70, 8@80, 10@70, 12@60'],
  'en',
  'approved',
  NULL
),

-- REVERSE PYRAMID
(
  'Reverse Pyramid',
  ARRAY['reverse pyramid', 'inverted pyramid'],
  'Start heavy, decrease weight each set (opposite of ascending).',
  '1) Set 1: Heaviest weight, lowest reps. 2) Each set: lighter weight, more reps. 3) Maintain intensity. Best for: strength when fresh, volume accumulation.',
  'medium',
  ARRAY['strength', 'volume', 'fresh_strength'],
  '{"reverse_pyramid": {"sets": 4, "start_heavy": true, "weight_decrease": 10}}'::jsonb,
  ARRAY['Squat: 5@100kg, 8@90kg, 10@80kg, 12@70kg'],
  'en',
  'approved',
  NULL
),

-- STAGGERED SETS
(
  'Staggered Sets',
  ARRAY['staggered', 'alternating', 'interleaved'],
  'Alternate between two exercises with minimal rest, completing all sets of one before moving to next.',
  '1) Exercise A, set 1. 2) Exercise B, set 1. 3) Exercise A, set 2. 4) Exercise B, set 2. 5) Continue. Best for: time efficiency, volume, opposing muscle groups.',
  'low',
  ARRAY['time_efficient', 'volume', 'opposing_muscles'],
  '{"staggered": {"exercises": 2, "rest_between_alternating": 30}}'::jsonb,
  ARRAY['Bench press + Rows: alternate sets'],
  'en',
  'approved',
  NULL
),

-- COMPOUND SETS
(
  'Compound Sets',
  ARRAY['compound set', 'same muscle compound'],
  'Two exercises for same muscle group back-to-back with minimal rest (0-30s).',
  '1) Exercise A for target muscle (e.g., bench press). 2) Rest 0-30s. 3) Exercise B for same muscle (e.g., flyes). 4) Rest 60-120s. 5) Repeat. Best for: hypertrophy, volume, muscle targeting.',
  'high',
  ARRAY['hypertrophy', 'volume', 'targeting'],
  '{"compound_set": {"rest_between_exercises": 15, "rest_after_pair": 90}}'::jsonb,
  ARRAY['Bench press + Flyes, Squat + Leg press'],
  'en',
  'approved',
  NULL
),

-- EXTENDED SETS
(
  'Extended Sets',
  ARRAY['extended', 'continuous', 'non-stop'],
  'Perform multiple exercises in sequence without rest, targeting same muscle group.',
  '1) Exercise A to near-failure. 2) Immediately switch to Exercise B (same muscle). 3) Continue to Exercise C if applicable. 4) Rest after all exercises complete. Best for: hypertrophy, extreme volume, time efficiency.',
  'very_high',
  ARRAY['hypertrophy', 'volume', 'time_efficient'],
  '{"extended": {"exercises": 3, "rest_between": 0, "rest_after": 120}}'::jsonb,
  ARRAY['Chest: Bench + Flyes + Push-ups, no rest'],
  'en',
  'approved',
  NULL
),

-- FST-7 (FASCIA STRETCH TRAINING)
(
  'FST-7',
  ARRAY['fst7', 'fascia stretch', '7 sets'],
  'Perform 7 sets of 8-12 reps with 30-45s rest, focusing on stretch position.',
  '1) 7 sets of 8-12 reps. 2) 30-45 seconds rest between sets. 3) Focus on stretch position (full ROM). 4) Moderate weight (60-70% 1RM). Best for: hypertrophy, fascia stretching, muscle growth.',
  'high',
  ARRAY['hypertrophy', 'fascia', 'muscle_growth'],
  '{"fst7": {"sets": 7, "reps": 10, "rest_seconds": 35, "load_percent": 65}}'::jsonb,
  ARRAY['Cable flyes: 7x10 with 35s rest, full stretch'],
  'en',
  'approved',
  NULL
),

-- GERMAN VOLUME TRAINING (GVT)
(
  'German Volume Training',
  ARRAY['gvt', '10x10', 'german volume'],
  'Perform 10 sets of 10 reps with 60-90s rest, using 60% 1RM.',
  '1) 10 sets of 10 reps. 2) 60-90 seconds rest. 3) Weight: 60% 1RM. 4) Same exercise for all sets. Best for: hypertrophy, volume, muscle mass.',
  'very_high',
  ARRAY['hypertrophy', 'volume', 'mass'],
  '{"gvt": {"sets": 10, "reps": 10, "rest_seconds": 75, "load_percent_1rm": 60}}'::jsonb,
  ARRAY['Squat: 10x10 @ 60% 1RM, 75s rest'],
  'en',
  'approved',
  NULL
),

-- DENSITY TRAINING
(
  'Density Training',
  ARRAY['density', 'time density', 'volume density'],
  'Perform maximum volume in fixed time period, tracking total reps/weight.',
  '1) Set time limit (e.g., 15 minutes). 2) Perform sets with minimal rest. 3) Track total volume. 4) Goal: beat previous session. Best for: conditioning, volume, time efficiency.',
  'medium',
  ARRAY['conditioning', 'volume', 'time_efficient'],
  '{"density": {"time_minutes": 15, "target_volume": 200, "minimal_rest": true}}'::jsonb,
  ARRAY['15-min density: max pull-ups in time limit'],
  'en',
  'approved',
  NULL
),

-- REST-PAUSE VARIATIONS
(
  'Rest-Pause (Extended)',
  ARRAY['extended rest pause', 'multi rest pause'],
  'Rest-pause with more mini-sets (4-6) and longer total duration.',
  '1) Initial set to failure. 2) Rest 15-20s. 3) Perform 4-6 mini-sets of 2-3 reps. 4) Rest 15-20s between each. Best for: extreme volume, hypertrophy, time under tension.',
  'very_high',
  ARRAY['volume', 'hypertrophy', 'time_under_tension'],
  '{"rest_pause_extended": {"rest_seconds": 18, "mini_sets": 5, "reps_per_mini": 2}}'::jsonb,
  ARRAY['Bench: failure set, then 5x2 with 18s rest'],
  'en',
  'approved',
  NULL
),

-- CLUSTER REST VARIATIONS
(
  'Cluster Rest (10-20s)',
  ARRAY['short cluster', 'micro cluster', 'cluster 10s'],
  'Cluster sets with very short rest (10-20s) between clusters.',
  '1) Cluster 1: 3-5 reps. 2) Rest 10-20 seconds. 3) Cluster 2: 3-5 reps. 4) Repeat for 4-6 clusters. Best for: volume with heavy loads, strength-endurance.',
  'medium',
  ARRAY['volume', 'strength_endurance', 'heavy_loads'],
  '{"cluster_short": {"reps_per_cluster": 4, "clusters": 5, "rest_seconds": 15}}'::jsonb,
  ARRAY['Squat: 4 reps, 15s rest, repeat 5x'],
  'en',
  'approved',
  NULL
),

-- ISO-TENSION
(
  'Iso-Tension',
  ARRAY['iso tension', 'static tension', 'isometric tension'],
  'Hold isometric contraction at various joint angles for time.',
  '1) Move to target angle (e.g., 90 degrees). 2) Hold contraction for 10-30 seconds. 3) Move to different angle. 4) Repeat. Best for: strength, stability, joint angle specificity.',
  'medium',
  ARRAY['strength', 'stability', 'joint_specificity'],
  '{"iso_tension": {"hold_seconds": 20, "angles": [90, 135, 180]}}'::jsonb,
  ARRAY['Squat: hold at 90°, 135°, full extension'],
  'en',
  'approved',
  NULL
),

-- PARTIAL REPS (MID-RANGE)
(
  'Partial Reps (Mid-Range)',
  ARRAY['mid partial', 'middle rom', 'mid range'],
  'Perform only the middle portion of ROM, avoiding full extension and full contraction.',
  '1) Start at midpoint. 2) Move through middle 50% of ROM. 3) Avoid full stretch and full contraction. 4) Repeat. Best for: hypertrophy, constant tension, weak point training.',
  'medium',
  ARRAY['hypertrophy', 'constant_tension', 'weak_point'],
  '{"partial_mid": {"rom_percent": 50, "position": "middle"}}'::jsonb,
  ARRAY['Bench: middle 50% only, no lockout or chest touch'],
  'en',
  'approved',
  NULL
),

-- BANDED REPS
(
  'Banded Reps',
  ARRAY['banded', 'resistance band', 'band tension'],
  'Add resistance bands to increase tension at top of movement (accommodating resistance).',
  '1) Attach bands to bar/equipment. 2) Bands provide more resistance at top (stretched). 3) Less resistance at bottom. 4) Maintains tension throughout. Best for: strength, lockout strength, constant tension.',
  'medium',
  ARRAY['strength', 'lockout', 'constant_tension'],
  '{"banded": {"band_resistance": "accommodating", "tension_curve": "increasing"}}'::jsonb,
  ARRAY['Banded bench press, Banded squat'],
  'en',
  'approved',
  NULL
),

-- CHAIN REPS
(
  'Chain Reps',
  ARRAY['chains', 'chain resistance', 'accommodating chains'],
  'Add chains to bar for accommodating resistance (more weight as chains lift off ground).',
  '1) Attach chains to bar. 2) More chains lift off ground as you rise = more resistance. 3) Less resistance at bottom. 4) Maintains tension. Best for: strength, lockout strength, power.',
  'low',
  ARRAY['strength', 'lockout', 'power'],
  '{"chains": {"accommodating": true, "tension_increases": true}}'::jsonb,
  ARRAY['Chain bench press, Chain squat'],
  'en',
  'approved',
  NULL
),

-- PAUSE VARIATIONS
(
  'Paused Reps (Top)',
  ARRAY['top pause', 'lockout pause', 'top hold'],
  'Pause at top/lockout position for 1-3 seconds before lowering.',
  '1) Perform rep to top position. 2) Pause 1-3 seconds at lockout. 3) Lower under control. 4) Repeat. Best for: strength, lockout strength, stability.',
  'low',
  ARRAY['strength', 'lockout', 'stability'],
  '{"paused_top": {"pause_seconds": 2, "position": "top"}}'::jsonb,
  ARRAY['Bench: pause 2s at lockout, Squat: pause at top'],
  'en',
  'approved',
  NULL
),

-- ECCENTRIC OVERLOAD
(
  'Eccentric Overload',
  ARRAY['eccentric', 'negative overload', 'lowering phase'],
  'Use 110-130% of concentric max for eccentric phase only, with assistance on concentric.',
  '1) Load 110-130% of concentric max. 2) Lower slowly (3-6 seconds) under control. 3) Use assistance (spotter/machine) to return to start. 4) Repeat. Best for: strength, hypertrophy, muscle damage, weak point training.',
  'high',
  ARRAY['strength', 'hypertrophy', 'muscle_damage'],
  '{"eccentric_overload": {"load_percent": 120, "eccentric_seconds": 4, "assisted_concentric": true}}'::jsonb,
  ARRAY['Bench: 120% 1RM, 4s down, spotter helps up'],
  'en',
  'approved',
  NULL
),

-- CONCENTRIC ONLY
(
  'Concentric Only',
  ARRAY['concentric', 'positive only', 'lifting phase'],
  'Focus only on concentric/lifting phase, using assistance to return to start position.',
  '1) Start at bottom position (with assistance). 2) Perform concentric phase explosively. 3) Use assistance to return to start. 4) Repeat. Best for: power, speed, neural drive.',
  'low',
  ARRAY['power', 'speed', 'neural'],
  '{"concentric_only": {"explosive": true, "assisted_eccentric": true}}'::jsonb,
  ARRAY['Squat: explosive up, assisted down'],
  'en',
  'approved',
  NULL
),

-- ISO-HOLDS (MULTIPLE POSITIONS)
(
  'Iso-Holds (Multiple Positions)',
  ARRAY['multi iso', 'position holds', 'angle holds'],
  'Hold isometric contraction at multiple joint angles within same set.',
  '1) Hold position 1 (e.g., 90°) for 10-20s. 2) Move to position 2 (e.g., 135°) for 10-20s. 3) Continue through 3-4 positions. Best for: strength, stability, comprehensive stimulus.',
  'medium',
  ARRAY['strength', 'stability', 'comprehensive'],
  '{"multi_iso": {"positions": 4, "hold_seconds_per_position": 15}}'::jsonb,
  ARRAY['Squat: hold at 90°, 120°, 150°, full extension'],
  'en',
  'approved',
  NULL
),

-- BREATHING SQUATS
(
  'Breathing Squats',
  ARRAY['breathing', '20 rep squats', 'breathing pause'],
  'Perform 20 reps with 3-5 deep breaths between each rep after initial 10 reps.',
  '1) Perform 10 normal reps. 2) After rep 10, take 3-5 deep breaths. 3) Continue with remaining 10 reps, breathing between each. 4) Same weight throughout. Best for: hypertrophy, mental toughness, volume.',
  'very_high',
  ARRAY['hypertrophy', 'mental_toughness', 'volume'],
  '{"breathing": {"total_reps": 20, "breathing_starts_at": 10, "breaths_per_rep": 4}}'::jsonb,
  ARRAY['Squat: 20 reps, breathing after rep 10'],
  'en',
  'approved',
  NULL
),

-- WIDOWMAKER SETS
(
  'Widowmaker Sets',
  ARRAY['widowmaker', '20 rep set', 'high rep single'],
  'Single set of 20 reps with weight you can normally do for 10 reps.',
  '1) Load weight you can do for 10 reps. 2) Perform single set of 20 reps. 3) Rest as needed (but try to complete). 4) Extreme intensity. Best for: hypertrophy, mental toughness, volume.',
  'very_high',
  ARRAY['hypertrophy', 'mental_toughness', 'volume'],
  '{"widowmaker": {"reps": 20, "load_percent_of_10rm": 100}}'::jsonb,
  ARRAY['Squat: 1x20 @ 10RM weight'],
  'en',
  'approved',
  NULL
),

-- DROP SET (TRIPLE)
(
  'Triple Drop Set',
  ARRAY['triple drop', '3 drop', 'triple strip'],
  'Drop weight three times in sequence with minimal rest (0-5s between drops).',
  '1) Set to failure at weight 1. 2) Drop 20-30%, continue to failure. 3) Drop again 20-30%, continue to failure. 4) Drop third time 20-30%, continue to failure. Best for: extreme hypertrophy, muscle pump, finishing.',
  'very_high',
  ARRAY['hypertrophy', 'pump', 'finishing'],
  '{"triple_drop": {"drops": 3, "weight_reduction_percent": 25, "rest_seconds": 2}}'::jsonb,
  ARRAY['Curls: 12kg x 10, 9kg x 8, 7kg x 6, 5kg x 5'],
  'en',
  'approved',
  NULL
),

-- STATIC HOLDS (PROGRESSIVE)
(
  'Progressive Static Holds',
  ARRAY['progressive iso', 'increasing hold', 'progressive static'],
  'Increase hold time each set (e.g., 10s, 15s, 20s, 25s).',
  '1) Set 1: Hold for 10 seconds. 2) Set 2: Hold for 15 seconds. 3) Set 3: Hold for 20 seconds. 4) Continue increasing. Best for: strength, endurance, progressive overload.',
  'medium',
  ARRAY['strength', 'endurance', 'progressive_overload'],
  '{"progressive_static": {"sets": 4, "hold_progression": [10, 15, 20, 25]}}'::jsonb,
  ARRAY['Pull-up hold: 10s, 15s, 20s, 25s'],
  'en',
  'approved',
  NULL
),

-- TIME UNDER TENSION (TUT) FOCUS
(
  'Time Under Tension Focus',
  ARRAY['TUT', 'time under tension', 'slow tempo focus'],
  'Extend time under tension by slowing all phases (e.g., 5-2-5-2 tempo).',
  '1) Eccentric: 5 seconds. 2) Pause bottom: 2 seconds. 3) Concentric: 5 seconds. 4) Pause top: 2 seconds. 5) Repeat. Best for: hypertrophy, muscle damage, time under tension.',
  'high',
  ARRAY['hypertrophy', 'muscle_damage', 'time_under_tension'],
  '{"tut_focus": {"eccentric": 5, "pause_bottom": 2, "concentric": 5, "pause_top": 2}}'::jsonb,
  ARRAY['Squat: 5-2-5-2 tempo, Bench: 4-1-4-1 tempo'],
  'en',
  'approved',
  NULL
),

-- SPEED REPS
(
  'Speed Reps',
  ARRAY['speed', 'dynamic effort', 'compensatory acceleration'],
  'Perform reps explosively with 50-60% 1RM, focusing on bar speed.',
  '1) Load 50-60% 1RM. 2) Perform reps as explosively as possible. 3) Focus on bar speed, not weight. 4) 3-5 sets of 3-5 reps. Best for: power, speed, neural drive.',
  'low',
  ARRAY['power', 'speed', 'neural'],
  '{"speed": {"load_percent_1rm": 55, "reps": 3, "sets": 5, "explosive": true}}'::jsonb,
  ARRAY['Bench: 5x3 @ 55% 1RM, explosive'],
  'en',
  'approved',
  NULL
),

-- COMPLEX SETS
(
  'Complex Sets',
  ARRAY['complex', 'movement complex', 'exercise complex'],
  'Perform multiple exercises in sequence with same weight, no rest between exercises.',
  '1) Exercise A (e.g., clean). 2) Immediately Exercise B (e.g., front squat). 3) Immediately Exercise C (e.g., push press). 4) Rest after all exercises. Best for: conditioning, power, movement efficiency.',
  'high',
  ARRAY['conditioning', 'power', 'movement_efficiency'],
  '{"complex": {"exercises": 3, "rest_between": 0, "same_weight": true}}'::jsonb,
  ARRAY['Clean + Front Squat + Push Press complex'],
  'en',
  'approved',
  NULL
),

-- CONTRAST SETS
(
  'Contrast Sets',
  ARRAY['contrast', 'post-activation potentiation', 'PAP'],
  'Heavy set followed immediately by lighter explosive set (same movement pattern).',
  '1) Heavy set: 85-95% 1RM, 1-3 reps. 2) Rest 30-60s. 3) Light explosive set: 50-60% 1RM, 3-5 reps. 4) Repeat. Best for: power, speed, post-activation potentiation.',
  'low',
  ARRAY['power', 'speed', 'PAP'],
  '{"contrast": {"heavy_percent": 90, "heavy_reps": 2, "light_percent": 55, "light_reps": 4, "rest_seconds": 45}}'::jsonb,
  ARRAY['Squat: 2@90%, then 4@55% explosive'],
  'en',
  'approved',
  NULL
),

-- CLUSTER DROP SETS
(
  'Cluster Drop Sets',
  ARRAY['cluster drop', 'drop cluster', 'hybrid cluster'],
  'Combine cluster sets with drop sets: clusters at weight 1, then drop and cluster at weight 2.',
  '1) Cluster 1-3 at weight 1. 2) Drop weight 20-30%. 3) Cluster 1-3 at weight 2. 4) Continue if desired. Best for: extreme volume, hypertrophy, time efficiency.',
  'very_high',
  ARRAY['volume', 'hypertrophy', 'time_efficient'],
  '{"cluster_drop": {"clusters_per_weight": 3, "weight_drop_percent": 25, "reps_per_cluster": 4}}'::jsonb,
  ARRAY['Bench: 3 clusters @ 80kg, drop to 60kg, 3 clusters'],
  'en',
  'approved',
  NULL
),

-- ISO-DYNAMIC
(
  'Iso-Dynamic',
  ARRAY['iso dynamic', 'static dynamic', 'hold and move'],
  'Hold isometric position, then perform dynamic reps, alternating.',
  '1) Hold isometric for 5-10 seconds. 2) Perform 2-3 dynamic reps. 3) Hold isometric again. 4) Repeat. Best for: strength, stability, comprehensive stimulus.',
  'medium',
  ARRAY['strength', 'stability', 'comprehensive'],
  '{"iso_dynamic": {"iso_seconds": 7, "dynamic_reps": 3, "alternating": true}}'::jsonb,
  ARRAY['Squat: hold 7s, 3 reps, hold 7s, repeat'],
  'en',
  'approved',
  NULL
),

-- REST-PAUSE DROP SET
(
  'Rest-Pause Drop Set',
  ARRAY['rest pause drop', 'hybrid rest pause'],
  'Rest-pause set, then drop weight and perform another rest-pause set.',
  '1) Rest-pause set at weight 1 (initial + mini-sets). 2) Drop weight 20-30%. 3) Rest-pause set at weight 2. Best for: extreme volume, hypertrophy, time efficiency.',
  'very_high',
  ARRAY['volume', 'hypertrophy', 'time_efficient'],
  '{"rest_pause_drop": {"rest_pause_sets": 2, "weight_drop_percent": 25}}'::jsonb,
  ARRAY['Bench: rest-pause @ 80kg, drop to 60kg, rest-pause'],
  'en',
  'approved',
  NULL
),

-- DENSITY WAVES
(
  'Density Waves',
  ARRAY['density wave', 'volume wave', 'time wave'],
  'Alternate between high-density and low-density periods within same session.',
  '1) High density: 5 minutes, minimal rest. 2) Low density: 5 minutes, normal rest. 3) Repeat waves. Best for: conditioning, volume, recovery management.',
  'medium',
  ARRAY['conditioning', 'volume', 'recovery'],
  '{"density_waves": {"high_density_minutes": 5, "low_density_minutes": 5, "waves": 3}}'::jsonb,
  ARRAY['Alternating 5-min high/low density blocks'],
  'en',
  'approved',
  NULL
),

-- ACCELERATED REPS
(
  'Accelerated Reps',
  ARRAY['accelerated', 'progressive speed', 'ramping speed'],
  'Start slow, accelerate through ROM, finishing explosively.',
  '1) Start rep slowly. 2) Gradually accelerate. 3) Finish explosively at top. 4) Control eccentric. Best for: power, speed, neural drive.',
  'low',
  ARRAY['power', 'speed', 'neural'],
  '{"accelerated": {"start_slow": true, "finish_explosive": true}}'::jsonb,
  ARRAY['Squat: slow start, explosive finish'],
  'en',
  'approved',
  NULL
),

-- DECELERATED REPS
(
  'Decelerated Reps',
  ARRAY['decelerated', 'controlled speed', 'braking'],
  'Start explosively, then decelerate through ROM, controlling the movement.',
  '1) Start rep explosively. 2) Gradually decelerate. 3) Finish with control. 4) Focus on control throughout. Best for: technique, stability, control.',
  'low',
  ARRAY['technique', 'stability', 'control'],
  '{"decelerated": {"start_explosive": true, "finish_controlled": true}}'::jsonb,
  ARRAY['Squat: explosive start, controlled finish'],
  'en',
  'approved',
  NULL
),

-- PARTIAL + FULL REPS
(
  'Partial + Full Reps',
  ARRAY['partial full', 'combo reps', 'mixed rom'],
  'Alternate between partial and full reps within same set.',
  '1) Partial rep (e.g., top 50%). 2) Full rep. 3) Partial rep. 4) Full rep. 5) Continue alternating. Best for: volume, comprehensive stimulus, time under tension.',
  'medium',
  ARRAY['volume', 'comprehensive', 'time_under_tension'],
  '{"partial_full": {"alternating": true, "partial_rom_percent": 50}}'::jsonb,
  ARRAY['Bench: partial, full, partial, full'],
  'en',
  'approved',
  NULL
),

-- ISO-SQUEEZE
(
  'Iso-Squeeze',
  ARRAY['iso squeeze', 'squeeze hold', 'contraction hold'],
  'Hold maximum voluntary contraction at peak of movement for time.',
  '1) Perform rep to peak/contracted position. 2) Squeeze maximally. 3) Hold squeeze for 2-5 seconds. 4) Release and repeat. Best for: hypertrophy, mind-muscle connection, peak contraction.',
  'low',
  ARRAY['hypertrophy', 'mind_muscle', 'peak_contraction'],
  '{"iso_squeeze": {"squeeze_seconds": 3, "position": "peak"}}'::jsonb,
  ARRAY['Curl: squeeze at top 3s, Lat pulldown: squeeze at bottom 3s'],
  'en',
  'approved',
  NULL
),

-- REVERSE TEMPO
(
  'Reverse Tempo',
  ARRAY['reverse tempo', 'inverted tempo', 'opposite tempo'],
  'Fast eccentric, slow concentric (opposite of normal tempo).',
  '1) Lower quickly (1 second). 2) Pause briefly. 3) Lift slowly (4-5 seconds). 4) Repeat. Best for: hypertrophy, time under tension, control.',
  'medium',
  ARRAY['hypertrophy', 'time_under_tension', 'control'],
  '{"reverse_tempo": {"eccentric": 1, "concentric": 4}}'::jsonb,
  ARRAY['Squat: 1s down, 4s up'],
  'en',
  'approved',
  NULL
),

-- PAUSE VARIATIONS (MID-RANGE)
(
  'Paused Reps (Mid-Range)',
  ARRAY['mid pause', 'middle pause', 'mid range pause'],
  'Pause at midpoint of movement for 1-3 seconds.',
  '1) Perform rep to midpoint. 2) Pause 1-3 seconds. 3) Complete rep. 4) Repeat. Best for: strength, control, weak point training.',
  'medium',
  ARRAY['strength', 'control', 'weak_point'],
  '{"paused_mid": {"pause_seconds": 2, "position": "midpoint"}}'::jsonb,
  ARRAY['Bench: pause at midpoint 2s'],
  'en',
  'approved',
  NULL
),

-- CONTINUOUS TENSION
(
  'Continuous Tension',
  ARRAY['continuous', 'no lockout', 'constant tension'],
  'Avoid lockout/rest positions, maintaining constant tension throughout set.',
  '1) Perform reps without full lockout. 2) Maintain tension at top. 3) Don''t rest at bottom. 4) Continuous movement. Best for: hypertrophy, time under tension, muscle pump.',
  'high',
  ARRAY['hypertrophy', 'time_under_tension', 'pump'],
  '{"continuous_tension": {"no_lockout": true, "no_rest": true}}'::jsonb,
  ARRAY['Bench: no lockout, Squat: no full extension'],
  'en',
  'approved',
  NULL
),

-- PULSE REPS
(
  'Pulse Reps',
  ARRAY['pulse', 'mini pulses', 'micro movements'],
  'Perform small pulses at end range of motion (e.g., top of leg extension).',
  '1) Perform full rep. 2) At end range, perform 3-5 small pulses. 3) Return to start. 4) Repeat. Best for: hypertrophy, end-range strength, muscle pump.',
  'medium',
  ARRAY['hypertrophy', 'end_range', 'pump'],
  '{"pulse": {"pulses_per_rep": 4, "position": "end_range"}}'::jsonb,
  ARRAY['Leg extension: full rep + 4 pulses at top'],
  'en',
  'approved',
  NULL
),

-- BOTTOM-UP REPS
(
  'Bottom-Up Reps',
  ARRAY['bottom up', 'start from bottom', 'dead start'],
  'Start each rep from dead stop at bottom position (no stretch reflex).',
  '1) Lower to bottom. 2) Pause 1-2 seconds (eliminate stretch reflex). 3) Explode up. 4) Repeat. Best for: strength, starting strength, weak point training.',
  'high',
  ARRAY['strength', 'starting_strength', 'weak_point'],
  '{"bottom_up": {"pause_seconds": 1.5, "dead_start": true}}'::jsonb,
  ARRAY['Squat: dead stop at bottom, explode up'],
  'en',
  'approved',
  NULL
),

-- TOP-DOWN REPS
(
  'Top-Down Reps',
  ARRAY['top down', 'start from top', 'negative start'],
  'Start each rep from top position, focusing on controlled negative.',
  '1) Start at top position. 2) Lower slowly and controlled. 3) Explode or control up. 4) Repeat. Best for: eccentric strength, control, technique.',
  'medium',
  ARRAY['eccentric_strength', 'control', 'technique'],
  '{"top_down": {"start_position": "top", "focus": "eccentric"}}'::jsonb,
  ARRAY['Pull-up: start at top, controlled negative'],
  'en',
  'approved',
  NULL
),

-- RACK PULLS (PARTIAL ROM)
(
  'Rack Pulls',
  ARRAY['rack pull', 'partial deadlift', 'block pull'],
  'Perform deadlift from elevated position (blocks/rack), reducing ROM.',
  '1) Set bar at knee height or higher. 2) Perform deadlift from elevated position. 3) Full lockout. 4) Can use heavier weight. Best for: strength, lockout strength, weak point training.',
  'low',
  ARRAY['strength', 'lockout', 'weak_point'],
  '{"rack_pull": {"height": "knee", "rom_reduced": true}}'::jsonb,
  ARRAY['Deadlift from knee height, Bench from pins at chest'],
  'en',
  'approved',
  NULL
),

-- PIN PRESSES
(
  'Pin Presses',
  ARRAY['pin press', 'rack press', 'partial press'],
  'Perform press from pins at various heights, starting from dead stop.',
  '1) Set pins at target height (e.g., chest, mid-range, lockout). 2) Start from dead stop on pins. 3) Press explosively. 4) Return to pins. Best for: strength, power, weak point training.',
  'medium',
  ARRAY['strength', 'power', 'weak_point'],
  '{"pin_press": {"height": "variable", "dead_start": true}}'::jsonb,
  ARRAY['Bench from pins at chest, Squat from pins at parallel'],
  'en',
  'approved',
  NULL
),

-- BOARD PRESSES
(
  'Board Presses',
  ARRAY['board press', 'reduced rom bench', 'board bench'],
  'Perform bench press with boards on chest, reducing ROM.',
  '1) Place 1-4 boards on chest. 2) Lower bar to boards. 3) Press from boards. 4) Reduced ROM allows heavier weight. Best for: strength, lockout strength, overload.',
  'low',
  ARRAY['strength', 'lockout', 'overload'],
  '{"board_press": {"boards": 2, "rom_reduced": true}}'::jsonb,
  ARRAY['Bench with 2 boards, Bench with 4 boards'],
  'en',
  'approved',
  NULL
),

-- DEFICIT REPS
(
  'Deficit Reps',
  ARRAY['deficit', 'elevated', 'increased rom'],
  'Stand on platform/plates to increase ROM (e.g., deficit deadlift).',
  '1) Stand on 2-4 inch platform. 2) Perform movement with increased ROM. 3) More stretch at bottom. 4) Can use same or slightly lighter weight. Best for: strength, flexibility, ROM improvement.',
  'medium',
  ARRAY['strength', 'flexibility', 'rom_improvement'],
  '{"deficit": {"platform_height_inches": 3, "rom_increased": true}}'::jsonb,
  ARRAY['Deficit deadlift from 3" platform'],
  'en',
  'approved',
  NULL
),

-- PAUSE-SQUEEZE-PAUSE
(
  'Pause-Squeeze-Pause',
  ARRAY['pause squeeze', 'triple pause', 'PSP'],
  'Pause at bottom, squeeze at top, pause again (e.g., 2s-2s-2s).',
  '1) Lower to bottom. 2) Pause 2 seconds. 3) Lift to top. 4) Squeeze 2 seconds. 5) Pause 2 seconds. 6) Repeat. Best for: hypertrophy, time under tension, control.',
  'high',
  ARRAY['hypertrophy', 'time_under_tension', 'control'],
  '{"pause_squeeze_pause": {"pause_bottom": 2, "squeeze_top": 2, "pause_top": 2}}'::jsonb,
  ARRAY['Squat: 2s bottom, 2s squeeze top, 2s pause top'],
  'en',
  'approved',
  NULL
),

-- REVERSE BAND
(
  'Reverse Band',
  ARRAY['reverse band', 'band assistance', 'accommodating assistance'],
  'Use bands to assist at bottom (most stretch), less assistance at top.',
  '1) Attach bands to provide assistance at bottom. 2) Less assistance as bands relax. 3) Allows heavier weight or more reps. Best for: overload, volume, strength.',
  'low',
  ARRAY['overload', 'volume', 'strength'],
  '{"reverse_band": {"assistance_at_bottom": true, "decreasing_assistance": true}}'::jsonb,
  ARRAY['Reverse band squat, Reverse band bench'],
  'en',
  'approved',
  NULL
),

-- CLUSTER REST-PAUSE
(
  'Cluster Rest-Pause',
  ARRAY['cluster rest pause', 'hybrid cluster', 'CRP'],
  'Combine cluster sets with rest-pause: clusters with 15-20s rest between.',
  '1) Cluster 1: 3-5 reps. 2) Rest 15-20s. 3) Cluster 2: 3-5 reps. 4) Continue for 4-6 clusters. 5) Similar to rest-pause but with clusters. Best for: volume, strength, time efficiency.',
  'medium',
  ARRAY['volume', 'strength', 'time_efficient'],
  '{"cluster_rest_pause": {"reps_per_cluster": 4, "clusters": 5, "rest_seconds": 18}}'::jsonb,
  ARRAY['Bench: 5 clusters of 4 reps, 18s rest'],
  'en',
  'approved',
  NULL
),

-- ISO-STRETCH
(
  'Iso-Stretch',
  ARRAY['iso stretch', 'stretch hold', 'lengthened hold'],
  'Hold stretch position under load for extended time (20-60s).',
  '1) Move to maximum stretch position. 2) Hold position for 20-60 seconds. 3) Maintain tension. 4) Return to start. Best for: flexibility, stretch-mediated growth, mobility.',
  'low',
  ARRAY['flexibility', 'stretch_mediated', 'mobility'],
  '{"iso_stretch": {"hold_seconds": 30, "position": "maximum_stretch"}}'::jsonb,
  ARRAY['RDL: hold bottom 30s, Calf raise: hold bottom 30s'],
  'en',
  'approved',
  NULL
),

-- PARTIAL REPS (PROGRESSIVE)
(
  'Progressive Partials',
  ARRAY['progressive partial', 'increasing rom', 'ramping partial'],
  'Start with small ROM, gradually increase ROM each set.',
  '1) Set 1: 25% ROM. 2) Set 2: 50% ROM. 3) Set 3: 75% ROM. 4) Set 4: 100% ROM. Best for: warm-up, progressive overload, ROM improvement.',
  'low',
  ARRAY['warm_up', 'progressive_overload', 'rom_improvement'],
  '{"progressive_partials": {"rom_progression": [25, 50, 75, 100]}}'::jsonb,
  ARRAY['Squat: 25%, 50%, 75%, 100% ROM'],
  'en',
  'approved',
  NULL
),

-- TIME-BASED SETS
(
  'Time-Based Sets',
  ARRAY['time based', 'duration sets', 'timed sets'],
  'Perform reps for fixed time period (e.g., 30 seconds), counting total reps.',
  '1) Set timer for target duration (e.g., 30s). 2) Perform as many reps as possible. 3) Count total reps. 4) Goal: beat previous session. Best for: conditioning, volume, time efficiency.',
  'medium',
  ARRAY['conditioning', 'volume', 'time_efficient'],
  '{"time_based": {"duration_seconds": 30, "target_reps": 15}}'::jsonb,
  ARRAY['30-second set: max push-ups, max pull-ups'],
  'en',
  'approved',
  NULL
),

-- REP-BASED DROPS
(
  'Rep-Based Drops',
  ARRAY['rep drop', 'reps drop set', 'rep reduction'],
  'Drop weight when you can''t complete target reps, continue with lower reps.',
  '1) Start with target reps (e.g., 12). 2) When you can''t complete 12, drop weight. 3) Continue with lower target (e.g., 10). 4) Drop again if needed. Best for: volume, hypertrophy, fatigue management.',
  'high',
  ARRAY['volume', 'hypertrophy', 'fatigue_management'],
  '{"rep_drop": {"initial_reps": 12, "drop_reps": 10, "weight_drop_percent": 20}}'::jsonb,
  ARRAY['Curls: 12 reps, drop weight when can''t complete, continue with 10'],
  'en',
  'approved',
  NULL
),

-- ISO-CONCENTRIC
(
  'Iso-Concentric',
  ARRAY['iso concentric', 'static concentric', 'hold and press'],
  'Hold isometric at start, then perform concentric phase explosively.',
  '1) Hold isometric position (e.g., bottom of squat). 2) Hold for 3-5 seconds. 3) Explode concentrically. 4) Return and repeat. Best for: strength, power, starting strength.',
  'medium',
  ARRAY['strength', 'power', 'starting_strength'],
  '{"iso_concentric": {"iso_seconds": 4, "explosive_concentric": true}}'::jsonb,
  ARRAY['Squat: hold bottom 4s, explode up'],
  'en',
  'approved',
  NULL
),

-- VARIABLE TEMPO
(
  'Variable Tempo',
  ARRAY['variable tempo', 'changing tempo', 'mixed tempo'],
  'Change tempo each rep or set (e.g., slow, medium, fast).',
  '1) Rep 1: Slow tempo (4-1-2-1). 2) Rep 2: Medium tempo (2-1-1-0). 3) Rep 3: Fast tempo (1-0-1-0). 4) Repeat pattern. Best for: comprehensive stimulus, variety, adaptation.',
  'medium',
  ARRAY['comprehensive', 'variety', 'adaptation'],
  '{"variable_tempo": {"tempos": ["slow", "medium", "fast"], "pattern": "alternating"}}'::jsonb,
  ARRAY['Squat: slow, medium, fast, repeat'],
  'en',
  'approved',
  NULL
),

-- DOUBLE PAUSE
(
  'Double Pause',
  ARRAY['double pause', 'two pauses', 'pause pause'],
  'Pause at two positions in same rep (e.g., bottom and midpoint).',
  '1) Lower to bottom. 2) Pause 1-2 seconds. 3) Lift to midpoint. 4) Pause 1-2 seconds. 5) Complete rep. Best for: strength, control, time under tension.',
  'high',
  ARRAY['strength', 'control', 'time_under_tension'],
  '{"double_pause": {"pause_positions": ["bottom", "midpoint"], "pause_seconds": 1.5}}'::jsonb,
  ARRAY['Squat: pause bottom 1.5s, pause midpoint 1.5s'],
  'en',
  'approved',
  NULL
),

-- TRIPLE PAUSE
(
  'Triple Pause',
  ARRAY['triple pause', 'three pauses', 'pause pause pause'],
  'Pause at three positions: bottom, midpoint, top.',
  '1) Lower to bottom, pause 1s. 2) Lift to midpoint, pause 1s. 3) Lift to top, pause 1s. 4) Return. Best for: extreme time under tension, control, strength.',
  'very_high',
  ARRAY['time_under_tension', 'control', 'strength'],
  '{"triple_pause": {"pause_positions": ["bottom", "midpoint", "top"], "pause_seconds": 1}}'::jsonb,
  ARRAY['Squat: pause at bottom, midpoint, top (1s each)'],
  'en',
  'approved',
  NULL
),

-- ACCELERATING CLUSTERS
(
  'Accelerating Clusters',
  ARRAY['accelerating cluster', 'speed cluster', 'fast cluster'],
  'Increase rep speed each cluster, starting controlled, finishing explosively.',
  '1) Cluster 1: Controlled speed. 2) Cluster 2: Medium speed. 3) Cluster 3: Fast speed. 4) Cluster 4: Explosive. Best for: power, speed, progressive acceleration.',
  'low',
  ARRAY['power', 'speed', 'progressive_acceleration'],
  '{"accelerating_clusters": {"clusters": 4, "speed_progression": ["controlled", "medium", "fast", "explosive"]}}'::jsonb,
  ARRAY['Squat: 4 clusters, increasing speed each cluster'],
  'en',
  'approved',
  NULL
),

-- DECELERATING CLUSTERS
(
  'Decelerating Clusters',
  ARRAY['decelerating cluster', 'slow cluster', 'controlled cluster'],
  'Decrease rep speed each cluster, starting fast, finishing controlled.',
  '1) Cluster 1: Explosive. 2) Cluster 2: Fast. 3) Cluster 3: Medium. 4) Cluster 4: Controlled. Best for: control, technique, fatigue management.',
  'low',
  ARRAY['control', 'technique', 'fatigue_management'],
  '{"decelerating_clusters": {"clusters": 4, "speed_progression": ["explosive", "fast", "medium", "controlled"]}}'::jsonb,
  ARRAY['Squat: 4 clusters, decreasing speed each cluster'],
  'en',
  'approved',
  NULL
),

-- ISO-REP COMBINATION
(
  'Iso-Rep Combination',
  ARRAY['iso rep combo', 'hold and rep', 'static dynamic combo'],
  'Hold isometric, then perform reps, alternating pattern.',
  '1) Hold isometric 5-10 seconds. 2) Perform 3-5 reps. 3) Hold isometric again. 4) Perform reps. 5) Repeat. Best for: strength, volume, comprehensive stimulus.',
  'medium',
  ARRAY['strength', 'volume', 'comprehensive'],
  '{"iso_rep_combo": {"iso_seconds": 7, "reps": 4, "alternating": true}}'::jsonb,
  ARRAY['Squat: hold 7s, 4 reps, hold 7s, 4 reps'],
  'en',
  'approved',
  NULL
),

-- WAVE CLUSTERS
(
  'Wave Clusters',
  ARRAY['wave cluster', 'undulating cluster', 'wave pattern'],
  'Vary cluster intensity in wave pattern (high, medium, high, medium).',
  '1) Cluster 1: High intensity (heavy, low reps). 2) Cluster 2: Medium intensity. 3) Cluster 3: High intensity. 4) Cluster 4: Medium intensity. Best for: volume, strength, recovery management.',
  'medium',
  ARRAY['volume', 'strength', 'recovery'],
  '{"wave_clusters": {"clusters": 4, "pattern": ["high", "medium", "high", "medium"]}}'::jsonb,
  ARRAY['Squat: wave pattern clusters (high-med-high-med)'],
  'en',
  'approved',
  NULL
),

-- ECCENTRIC CLUSTERS
(
  'Eccentric Clusters',
  ARRAY['eccentric cluster', 'negative cluster', 'lowering cluster'],
  'Focus on slow, controlled eccentric phase in clusters.',
  '1) Cluster 1: 3-5 reps with 4-6s eccentric. 2) Rest 20s. 3) Cluster 2: Repeat. 4) Continue. Best for: hypertrophy, muscle damage, eccentric strength.',
  'high',
  ARRAY['hypertrophy', 'muscle_damage', 'eccentric_strength'],
  '{"eccentric_clusters": {"reps_per_cluster": 4, "eccentric_seconds": 5, "clusters": 4}}'::jsonb,
  ARRAY['Squat: 4 clusters, 5s eccentric each rep'],
  'en',
  'approved',
  NULL
),

-- CONCENTRIC CLUSTERS
(
  'Concentric Clusters',
  ARRAY['concentric cluster', 'positive cluster', 'lifting cluster'],
  'Focus on explosive concentric phase in clusters.',
  '1) Cluster 1: 3-5 explosive reps. 2) Rest 20s. 3) Cluster 2: Repeat. 4) Continue. Best for: power, speed, neural drive.',
  'low',
  ARRAY['power', 'speed', 'neural'],
  '{"concentric_clusters": {"reps_per_cluster": 4, "explosive": true, "clusters": 4}}'::jsonb,
  ARRAY['Squat: 4 clusters, explosive concentric each rep'],
  'en',
  'approved',
  NULL
),

-- ISO-WAVE
(
  'Iso-Wave',
  ARRAY['iso wave', 'wave iso', 'undulating iso'],
  'Vary isometric hold intensity in wave pattern.',
  '1) Hold 1: Maximum intensity (10s). 2) Hold 2: Medium intensity (15s). 3) Hold 3: Maximum intensity (10s). 4) Hold 4: Medium intensity (15s). Best for: strength, endurance, recovery.',
  'medium',
  ARRAY['strength', 'endurance', 'recovery'],
  '{"iso_wave": {"holds": 4, "pattern": [10, 15, 10, 15]}}'::jsonb,
  ARRAY['Squat: wave pattern holds (10s-15s-10s-15s)'],
  'en',
  'approved',
  NULL
),

-- PARTIAL WAVE
(
  'Partial Wave',
  ARRAY['partial wave', 'rom wave', 'undulating partial'],
  'Vary ROM in wave pattern (full, partial, full, partial).',
  '1) Rep 1: Full ROM. 2) Rep 2: Partial ROM (50%). 3) Rep 3: Full ROM. 4) Rep 4: Partial ROM. Best for: volume, comprehensive stimulus, variety.',
  'medium',
  ARRAY['volume', 'comprehensive', 'variety'],
  '{"partial_wave": {"pattern": ["full", "partial", "full", "partial"], "partial_rom_percent": 50}}'::jsonb,
  ARRAY['Squat: full, partial, full, partial'],
  'en',
  'approved',
  NULL
),

-- TEMPO WAVE
(
  'Tempo Wave',
  ARRAY['tempo wave', 'speed wave', 'undulating tempo'],
  'Vary tempo in wave pattern (slow, fast, slow, fast).',
  '1) Rep 1: Slow tempo (4-1-2-1). 2) Rep 2: Fast tempo (1-0-1-0). 3) Rep 3: Slow. 4) Rep 4: Fast. Best for: comprehensive stimulus, adaptation, variety.',
  'medium',
  ARRAY['comprehensive', 'adaptation', 'variety'],
  '{"tempo_wave": {"pattern": ["slow", "fast", "slow", "fast"]}}'::jsonb,
  ARRAY['Squat: slow, fast, slow, fast tempo'],
  'en',
  'approved',
  NULL
),

-- REST WAVE
(
  'Rest Wave',
  ARRAY['rest wave', 'undulating rest', 'variable rest'],
  'Vary rest periods in wave pattern (short, long, short, long).',
  '1) Set 1: Short rest (30s). 2) Set 2: Long rest (120s). 3) Set 3: Short rest. 4) Set 4: Long rest. Best for: volume, recovery management, adaptation.',
  'low',
  ARRAY['volume', 'recovery', 'adaptation'],
  '{"rest_wave": {"pattern": [30, 120, 30, 120]}}'::jsonb,
  ARRAY['Squat: 30s rest, 120s rest, alternating'],
  'en',
  'approved',
  NULL
),

-- LOAD WAVE
(
  'Load Wave',
  ARRAY['load wave', 'weight wave', 'undulating load'],
  'Vary load in wave pattern (light, heavy, light, heavy).',
  '1) Set 1: Light load (70% 1RM). 2) Set 2: Heavy load (90% 1RM). 3) Set 3: Light. 4) Set 4: Heavy. Best for: strength, volume, recovery management.',
  'medium',
  ARRAY['strength', 'volume', 'recovery'],
  '{"load_wave": {"pattern": [70, 90, 70, 90], "unit": "percent_1rm"}}'::jsonb,
  ARRAY['Squat: 70%, 90%, 70%, 90% 1RM'],
  'en',
  'approved',
  NULL
),

-- REP WAVE
(
  'Rep Wave',
  ARRAY['rep wave', 'undulating reps', 'variable reps'],
  'Vary reps in wave pattern (high, low, high, low).',
  '1) Set 1: High reps (12). 2) Set 2: Low reps (5). 3) Set 3: High reps. 4) Set 4: Low reps. Best for: volume, strength, comprehensive stimulus.',
  'medium',
  ARRAY['volume', 'strength', 'comprehensive'],
  '{"rep_wave": {"pattern": [12, 5, 12, 5]}}'::jsonb,
  ARRAY['Squat: 12 reps, 5 reps, 12 reps, 5 reps'],
  'en',
  'approved',
  NULL
),

-- COMPLEX WAVE
(
  'Complex Wave',
  ARRAY['complex wave', 'multi wave', 'undulating complex'],
  'Vary multiple parameters in wave pattern (load, reps, tempo, rest).',
  '1) Set 1: Light, high reps, fast, short rest. 2) Set 2: Heavy, low reps, slow, long rest. 3) Repeat pattern. Best for: comprehensive stimulus, adaptation, periodization.',
  'medium',
  ARRAY['comprehensive', 'adaptation', 'periodization'],
  '{"complex_wave": {"parameters": ["load", "reps", "tempo", "rest"], "pattern": "alternating"}}'::jsonb,
  ARRAY['Squat: alternating light/heavy, high/low reps, fast/slow'],
  'en',
  'approved',
  NULL
)

ON CONFLICT (LOWER(name), language)
DO UPDATE SET
  -- Only update fields that are NULL or empty
  short_desc = COALESCE(
    NULLIF(intensifier_knowledge.short_desc, ''),
    EXCLUDED.short_desc
  ),
  how_to = COALESCE(
    NULLIF(intensifier_knowledge.how_to, ''),
    EXCLUDED.how_to
  ),
  aliases = CASE 
    WHEN array_length(intensifier_knowledge.aliases, 1) IS NULL 
      OR array_length(intensifier_knowledge.aliases, 1) = 0
    THEN EXCLUDED.aliases
    ELSE intensifier_knowledge.aliases
  END,
  fatigue_cost = COALESCE(intensifier_knowledge.fatigue_cost, EXCLUDED.fatigue_cost),
  best_for = CASE 
    WHEN array_length(intensifier_knowledge.best_for, 1) IS NULL 
      OR array_length(intensifier_knowledge.best_for, 1) = 0
    THEN EXCLUDED.best_for
    ELSE intensifier_knowledge.best_for
  END,
  intensity_rules = CASE 
    WHEN intensifier_knowledge.intensity_rules = '{}'::jsonb 
      OR intensifier_knowledge.intensity_rules IS NULL
    THEN EXCLUDED.intensity_rules
    ELSE intensifier_knowledge.intensity_rules
  END,
  examples = CASE 
    WHEN array_length(intensifier_knowledge.examples, 1) IS NULL 
      OR array_length(intensifier_knowledge.examples, 1) = 0
    THEN EXCLUDED.examples
    ELSE intensifier_knowledge.examples
  END,
  updated_at = NOW();

-- =====================================================
-- Verification
-- =====================================================
DO $$
DECLARE
  total_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_count
  FROM public.intensifier_knowledge
  WHERE status = 'approved' AND language = 'en';
  
  RAISE NOTICE '✅ Migration complete: seed_more_intensifiers';
  RAISE NOTICE '   - Total intensifiers (approved, en): %', total_count;
END $$;
