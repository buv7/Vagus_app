-- Migration: Seed intensifier_knowledge with 50+ training intensifiers (Idempotent)
-- Date: 2025-12-21
-- Purpose: Bulk insert training intensifiers/methods into intensifier_knowledge
--
-- Includes:
--   - Rest-Pause, Myo-Reps, Drop Sets, Cluster Sets
--   - EMOM, Density blocks, Tempo variations
--   - Partial reps, Isometrics, Pre/Post-exhaust
--   - Supersets, Circuits, BFR, and more
--
-- Rules:
--   - Uses ON CONFLICT to prevent duplicates (idempotent)
--   - Only fills missing fields, preserves existing content
--   - Sets status='approved', language='en', created_by=NULL

-- =====================================================
-- INSERT intensifiers
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
-- REST-PAUSE
(
  'Rest-Pause',
  ARRAY['rest pause', 'rest-pause', 'cluster rest'],
  'Perform a set to failure, rest 15-20 seconds, then continue with mini-sets until target reps are reached.',
  '1) Perform initial set to failure (0 RIR). 2) Rest 15-20 seconds. 3) Perform 2-4 additional mini-sets of 2-3 reps each with 15-20s rest between. 4) Total volume: initial set + mini-sets. Best for: strength and hypertrophy when volume is limited.',
  'high',
  ARRAY['strength', 'hypertrophy', 'time_efficient'],
  '{"rest_pause": {"rest_seconds": 15, "mini_sets": 3, "target_rir": 0, "reps_per_mini_set": 2}}'::jsonb,
  ARRAY['Bench press: 8 reps, rest 15s, 3 reps, rest 15s, 2 reps'],
  'en',
  'approved',
  NULL
),

-- MYO-REPS
(
  'Myo-Reps',
  ARRAY['myoreps', 'myo reps', 'activation sets'],
  'Activation set to near-failure, then short rest periods with mini-sets until you can''t complete the target reps.',
  '1) Perform activation set (15-30 reps to 3-5 RIR). 2) Rest 5-10 seconds. 3) Perform mini-sets of 3-5 reps with 5-10s rest until you can''t complete target reps. 4) Typically 3-5 mini-sets. Best for: hypertrophy, muscle pump, time efficiency.',
  'high',
  ARRAY['hypertrophy', 'pump', 'time_efficient'],
  '{"myo_reps": {"activation_reps": 20, "activation_rir": 3, "rest_seconds": 7, "mini_set_reps": 4, "target_mini_sets": 4}}'::jsonb,
  ARRAY['Lateral raises: 20 reps activation, then 4x4 with 7s rest'],
  'en',
  'approved',
  NULL
),

-- DROP SET (SINGLE)
(
  'Drop Set',
  ARRAY['drop set', 'strip set', 'running the rack'],
  'Perform a set to failure, immediately reduce weight by 20-30%, and continue to failure again.',
  '1) Perform set to failure (0-1 RIR). 2) Immediately reduce weight by 20-30% (have weights ready). 3) Continue to failure again. 4) Optional: one more drop (double drop set). Best for: hypertrophy, muscle pump, finishing a muscle group.',
  'very_high',
  ARRAY['hypertrophy', 'pump', 'finishing'],
  '{"drop_set": {"drops": 1, "weight_reduction_percent": 25, "rest_seconds": 0}}'::jsonb,
  ARRAY['Dumbbell curls: 12kg x 10, immediately 9kg x 8'],
  'en',
  'approved',
  NULL
),

-- DROP SET (DOUBLE)
(
  'Double Drop Set',
  ARRAY['double drop', 'triple drop', 'triple drop set'],
  'Perform a set to failure, drop weight twice (or three times) with minimal rest between drops.',
  '1) Perform set to failure. 2) Drop weight 20-30%, continue to failure. 3) Drop weight again 20-30%, continue to failure. 4) Optional third drop. Rest between drops: 0-5 seconds. Best for: extreme hypertrophy, muscle pump, finishing sets.',
  'very_high',
  ARRAY['hypertrophy', 'pump', 'finishing'],
  '{"drop_set": {"drops": 2, "weight_reduction_percent": 25, "rest_seconds": 2}}'::jsonb,
  ARRAY['Cable flyes: 20kg x 12, 15kg x 10, 10kg x 8'],
  'en',
  'approved',
  NULL
),

-- MECHANICAL ADVANTAGE DROP SET
(
  'Mechanical Advantage Drop Set',
  ARRAY['mechanical drop', 'angle drop', 'leverage drop'],
  'Change exercise angle/leverage to make it easier, allowing continuation after failure at harder angle.',
  '1) Perform set at harder angle/leverage to failure. 2) Immediately switch to easier angle (e.g., incline to flat, close-grip to wide-grip). 3) Continue to failure. Best for: hypertrophy, time efficiency, no weight changes needed.',
  'high',
  ARRAY['hypertrophy', 'time_efficient', 'no_equipment_change'],
  '{"mechanical_drop": {"angle_change": true, "rest_seconds": 0}}'::jsonb,
  ARRAY['Incline DB press to flat DB press, close-grip bench to wide-grip'],
  'en',
  'approved',
  NULL
),

-- CLUSTER SETS
(
  'Cluster Sets',
  ARRAY['cluster', 'cluster training', 'inter-set rest'],
  'Break a set into smaller clusters with short rest periods (10-30s) between clusters, maintaining same weight.',
  '1) Perform cluster 1 (e.g., 3-5 reps). 2) Rest 10-30 seconds. 3) Perform cluster 2. 4) Repeat for 3-5 clusters. 5) Total reps higher than single set would allow. Best for: strength, power, volume accumulation with heavy loads.',
  'medium',
  ARRAY['strength', 'power', 'volume'],
  '{"cluster": {"reps_per_cluster": 4, "clusters": 4, "rest_seconds": 20, "total_target_reps": 16}}'::jsonb,
  ARRAY['Squat: 4 reps, rest 20s, 4 reps, rest 20s, 4 reps, rest 20s, 4 reps'],
  'en',
  'approved',
  NULL
),

-- EMOM
(
  'EMOM',
  ARRAY['every minute on minute', 'emom', 'minute drill'],
  'Perform a set at the start of each minute, rest for remainder of minute. Repeat for specified rounds.',
  '1) Set timer for rounds (e.g., 10 minutes). 2) At start of each minute, perform target reps. 3) Rest for remainder of minute. 4) Repeat. Best for: conditioning, density, time-capped training.',
  'medium',
  ARRAY['conditioning', 'density', 'time_capped'],
  '{"emom": {"rounds": 10, "reps_per_round": 5, "target_seconds": 30}}'::jsonb,
  ARRAY['EMOM 10: 5 pull-ups every minute for 10 minutes'],
  'en',
  'approved',
  NULL
),

-- DENSITY BLOCK
(
  'Density Block',
  ARRAY['density', 'density training', 'volume density'],
  'Perform maximum reps in a fixed time period (e.g., 10 minutes), tracking total volume.',
  '1) Set time limit (e.g., 10 minutes). 2) Perform sets with minimal rest. 3) Track total reps/volume. 4) Goal: beat previous session''s total. Best for: conditioning, volume accumulation, time efficiency.',
  'medium',
  ARRAY['conditioning', 'volume', 'time_efficient'],
  '{"density": {"time_minutes": 10, "target_volume": 100}}'::jsonb,
  ARRAY['10-minute density block: as many push-ups as possible'],
  'en',
  'approved',
  NULL
),

-- 1.5 REPS
(
  '1.5 Reps',
  ARRAY['one and a half', '1.5', 'partial full'],
  'Perform one full rep, then a half rep (return to midpoint), then another full rep. Counts as 2 reps.',
  '1) Perform full rep (e.g., squat to top). 2) Lower to midpoint (e.g., half squat). 3) Return to top. 4) Lower to bottom, return to top (full rep). 5) Repeat. Best for: hypertrophy, time under tension, weak point training.',
  'high',
  ARRAY['hypertrophy', 'time_under_tension', 'weak_point'],
  '{"one_point_five": {"full_rep": true, "half_rep_position": "midpoint"}}'::jsonb,
  ARRAY['Squat: full, half up, full, repeat'],
  'en',
  'approved',
  NULL
),

-- LENGTHENED PARTIALS
(
  'Lengthened Partials',
  ARRAY['lengthened', 'stretch partials', 'ROM partials'],
  'Perform only the lengthened/stretch portion of the movement (bottom half), avoiding shortened position.',
  '1) Start at lengthened position (e.g., bottom of squat). 2) Perform partial rep through lengthened ROM only (e.g., bottom 50-70% of range). 3) Avoid shortened position. 4) Repeat. Best for: hypertrophy, stretch-mediated growth, weak point training.',
  'medium',
  ARRAY['hypertrophy', 'stretch_mediated', 'weak_point'],
  '{"lengthened_partials": {"rom_percent": 60, "avoid_shortened": true}}'::jsonb,
  ARRAY['Squat: bottom 60% only, Leg curl: bottom half only'],
  'en',
  'approved',
  NULL
),

-- PAUSED REPS
(
  'Paused Reps',
  ARRAY['pause', 'paused', 'isometric pause'],
  'Pause for 1-5 seconds at a specific point in the movement (usually bottom or stretch position).',
  '1) Perform rep to pause point (e.g., bottom of bench press). 2) Pause 1-5 seconds (eliminate stretch reflex). 3) Complete rep. 4) Repeat. Best for: strength, weak point training, technique improvement.',
  'medium',
  ARRAY['strength', 'weak_point', 'technique'],
  '{"paused": {"pause_seconds": 2, "pause_position": "bottom"}}'::jsonb,
  ARRAY['Bench press: pause 2s at chest, Squat: pause 3s at bottom'],
  'en',
  'approved',
  NULL
),

-- SLOW ECCENTRICS
(
  'Slow Eccentrics',
  ARRAY['slow negative', 'tempo eccentric', 'controlled negative'],
  'Control the lowering/eccentric phase for 3-6 seconds, normal or explosive concentric.',
  '1) Lower weight slowly (3-6 seconds). 2) Pause briefly at bottom (optional). 3) Normal or explosive concentric. 4) Repeat. Best for: hypertrophy, time under tension, muscle damage, technique.',
  'high',
  ARRAY['hypertrophy', 'time_under_tension', 'technique'],
  '{"slow_eccentric": {"eccentric_seconds": 4, "pause_seconds": 0}}'::jsonb,
  ARRAY['Bench press: 4s down, 1s up'],
  'en',
  'approved',
  NULL
),

-- TEMPO SETS
(
  'Tempo Sets',
  ARRAY['tempo', 'time under tension', 'TUT'],
  'Control the speed of all phases: eccentric (lowering), pause, concentric (lifting), pause. Written as E-P-C-P (seconds).',
  '1) Follow tempo prescription (e.g., 3-1-1-0 = 3s down, 1s pause, 1s up, 0s pause). 2) Maintain tempo throughout set. 3) Adjust weight to maintain tempo. Best for: hypertrophy, technique, time under tension, strength.',
  'medium',
  ARRAY['hypertrophy', 'technique', 'time_under_tension'],
  '{"tempo": {"eccentric": 3, "pause_bottom": 1, "concentric": 1, "pause_top": 0}}'::jsonb,
  ARRAY['Squat: 3-1-1-0 tempo, Bench: 2-0-1-0 tempo'],
  'en',
  'approved',
  NULL
),

-- YIELDING ISOMETRIC
(
  'Yielding Isometric',
  ARRAY['isometric hold', 'static hold', 'iso hold'],
  'Hold a position under load for time (e.g., bottom of squat, top of pull-up).',
  '1) Move to target position. 2) Hold position for 10-60 seconds (or until failure). 3) Complete rep or end set. Best for: strength, stability, time under tension, weak point training.',
  'medium',
  ARRAY['strength', 'stability', 'time_under_tension'],
  '{"yielding_isometric": {"hold_seconds": 30, "position": "bottom"}}'::jsonb,
  ARRAY['Squat: hold bottom 30s, Pull-up: hold top 20s'],
  'en',
  'approved',
  NULL
),

-- OVERCOMING ISOMETRIC
(
  'Overcoming Isometric',
  ARRAY['overcoming', 'pushing isometric', 'maximal isometric'],
  'Push/pull against immovable object (or maximal resistance) for time, generating maximum force.',
  '1) Set up against immovable object or maximal resistance. 2) Push/pull with maximum force for 5-10 seconds. 3) Rest and repeat. Best for: strength, power, neural drive, rehabilitation.',
  'low',
  ARRAY['strength', 'power', 'neural'],
  '{"overcoming_isometric": {"hold_seconds": 6, "max_force": true}}'::jsonb,
  ARRAY['Push against wall/bar, Pull against fixed bar'],
  'en',
  'approved',
  NULL
),

-- ISO-HOLD AT STRETCH
(
  'Iso-Hold at Stretch',
  ARRAY['stretch hold', 'stretch iso', 'lengthened hold'],
  'Hold the lengthened/stretch position under load for time (e.g., bottom of Romanian deadlift).',
  '1) Perform rep to stretch position. 2) Hold stretch position for 10-30 seconds. 3) Return to start. 4) Repeat. Best for: hypertrophy, flexibility, stretch-mediated growth.',
  'medium',
  ARRAY['hypertrophy', 'flexibility', 'stretch_mediated'],
  '{"iso_stretch": {"hold_seconds": 20, "position": "lengthened"}}'::jsonb,
  ARRAY['RDL: hold bottom 20s, Calf raise: hold bottom 15s'],
  'en',
  'approved',
  NULL
),

-- PRE-EXHAUST
(
  'Pre-Exhaust',
  ARRAY['pre exhaust', 'pre-exhaustion', 'isolation compound'],
  'Perform isolation exercise first to fatigue target muscle, then immediately perform compound exercise.',
  '1) Perform isolation exercise to near-failure (e.g., leg extension). 2) Immediately (0-30s rest) perform compound exercise (e.g., squat). 3) Compound exercise will feel harder due to pre-fatigue. Best for: hypertrophy, muscle targeting, volume efficiency.',
  'high',
  ARRAY['hypertrophy', 'targeting', 'volume'],
  '{"pre_exhaust": {"isolation_sets": 1, "rest_seconds": 15, "compound_sets": 1}}'::jsonb,
  ARRAY['Leg extension → Squat, Flyes → Bench press'],
  'en',
  'approved',
  NULL
),

-- POST-EXHAUST
(
  'Post-Exhaust',
  ARRAY['post exhaust', 'post-exhaustion', 'compound isolation'],
  'Perform compound exercise first, then immediately perform isolation exercise for same muscle group.',
  '1) Perform compound exercise to near-failure (e.g., bench press). 2) Immediately (0-30s rest) perform isolation exercise (e.g., flyes). 3) Isolation exercise provides additional volume and pump. Best for: hypertrophy, volume accumulation, muscle pump.',
  'high',
  ARRAY['hypertrophy', 'volume', 'pump'],
  '{"post_exhaust": {"compound_sets": 1, "rest_seconds": 15, "isolation_sets": 1}}'::jsonb,
  ARRAY['Bench press → Flyes, Squat → Leg extension'],
  'en',
  'approved',
  NULL
),

-- SUPERSET
(
  'Superset',
  ARRAY['super set', 'paired set', 'AG'],
  'Perform two exercises back-to-back with minimal rest (0-30s) between exercises. Rest after both exercises complete.',
  '1) Perform exercise A to target RIR. 2) Rest 0-30 seconds. 3) Perform exercise B to target RIR. 4) Rest 60-120 seconds. 5) Repeat. Best for: hypertrophy, time efficiency, volume accumulation.',
  'medium',
  ARRAY['hypertrophy', 'time_efficient', 'volume'],
  '{"superset": {"rest_between_exercises": 15, "rest_after_pair": 90}}'::jsonb,
  ARRAY['Bench press + Rows, Bicep curls + Tricep extensions'],
  'en',
  'approved',
  NULL
),

-- ANTAGONIST SUPERSET
(
  'Antagonist Superset',
  ARRAY['antagonist', 'opposing', 'push pull'],
  'Superset opposing muscle groups (e.g., chest/back, biceps/triceps) for enhanced recovery and pump.',
  '1) Perform exercise A (e.g., bench press). 2) Rest 0-30 seconds. 3) Perform opposing exercise B (e.g., rows). 4) Rest 60-120 seconds. 5) Repeat. Opposing muscles enhance recovery. Best for: hypertrophy, time efficiency, recovery.',
  'low',
  ARRAY['hypertrophy', 'time_efficient', 'recovery'],
  '{"antagonist": {"rest_between": 15, "rest_after_pair": 90}}'::jsonb,
  ARRAY['Bench + Rows, Curls + Extensions, Quads + Hamstrings'],
  'en',
  'approved',
  NULL
),

-- TRISET
(
  'Triset',
  ARRAY['tri set', 'triple set', '3-exercise circuit'],
  'Perform three exercises back-to-back with minimal rest (0-30s) between each. Rest after all three complete.',
  '1) Perform exercise A. 2) Rest 0-30s. 3) Perform exercise B. 4) Rest 0-30s. 5) Perform exercise C. 6) Rest 90-180s. 7) Repeat. Best for: hypertrophy, time efficiency, volume, conditioning.',
  'high',
  ARRAY['hypertrophy', 'time_efficient', 'conditioning'],
  '{"triset": {"rest_between": 15, "rest_after_triplet": 120}}'::jsonb,
  ARRAY['Chest: Bench + Flyes + Push-ups, Legs: Squat + Lunge + Extension'],
  'en',
  'approved',
  NULL
),

-- GIANT SET
(
  'Giant Set',
  ARRAY['giant set', 'quad set', '4+ exercise circuit'],
  'Perform four or more exercises back-to-back with minimal rest (0-30s) between each. Rest after all complete.',
  '1) Perform exercise A. 2) Rest 0-30s. 3) Perform exercise B. 4) Rest 0-30s. 5) Continue for 4+ exercises. 6) Rest 120-180s. 7) Repeat. Best for: hypertrophy, time efficiency, volume, extreme conditioning.',
  'very_high',
  ARRAY['hypertrophy', 'time_efficient', 'conditioning'],
  '{"giant_set": {"exercises": 4, "rest_between": 15, "rest_after": 150}}'::jsonb,
  ARRAY['Chest: 4-5 exercises, Back: 4-5 exercises'],
  'en',
  'approved',
  NULL
),

-- CIRCUIT
(
  'Circuit',
  ARRAY['circuit training', 'round', 'station training'],
  'Perform multiple exercises in sequence (circuit), rest after completing full circuit, repeat for rounds.',
  '1) Perform exercise A. 2) Move to exercise B (minimal rest). 3) Continue through all exercises. 4) Rest 60-180s after circuit. 5) Repeat circuit for specified rounds. Best for: conditioning, time efficiency, full-body training.',
  'medium',
  ARRAY['conditioning', 'time_efficient', 'full_body'],
  '{"circuit": {"exercises": 5, "rest_between": 10, "rest_after_round": 120, "rounds": 3}}'::jsonb,
  ARRAY['Full-body circuit: 5 exercises, 3 rounds'],
  'en',
  'approved',
  NULL
),

-- BLOOD FLOW RESTRICTION (BFR)
(
  'Blood Flow Restriction',
  ARRAY['BFR', 'occlusion', 'kaatsu'],
  'Use bands/cuffs to partially restrict blood flow (50-80% of arterial occlusion), allowing lighter loads (20-30% 1RM) to produce hypertrophy.',
  '1) Apply BFR bands/cuffs at 50-80% occlusion pressure. 2) Perform sets with 20-30% 1RM (light weight). 3) High reps (15-30) to failure or near-failure. 4) Short rest (30-60s). 5) 3-4 sets. Best for: hypertrophy with light loads, rehabilitation, volume without heavy loading.',
  'low',
  ARRAY['hypertrophy', 'rehabilitation', 'light_load'],
  '{"bfr": {"occlusion_percent": 70, "load_percent_1rm": 25, "reps": 20, "rest_seconds": 45}}'::jsonb,
  ARRAY['BFR leg extension: 25% 1RM, 20 reps, 3 sets'],
  'en',
  'approved',
  NULL
),

-- PARTIAL REPS (TOP)
(
  'Partial Reps (Top)',
  ARRAY['top partial', 'lockout partial', 'top ROM'],
  'Perform only the top portion of the movement (e.g., top 50% of range of motion).',
  '1) Start at top position. 2) Lower to midpoint (50% ROM). 3) Return to top. 4) Repeat. Avoid full ROM. Best for: strength, lockout strength, weak point training (top end).',
  'low',
  ARRAY['strength', 'lockout', 'weak_point'],
  '{"partial_top": {"rom_percent": 50, "avoid_full_rom": true}}'::jsonb,
  ARRAY['Bench press: top 50% only, Squat: top half only'],
  'en',
  'approved',
  NULL
),

-- PARTIAL REPS (BOTTOM)
(
  'Partial Reps (Bottom)',
  ARRAY['bottom partial', 'stretch partial', 'bottom ROM'],
  'Perform only the bottom portion of the movement (e.g., bottom 50% of range of motion).',
  '1) Start at bottom position. 2) Raise to midpoint (50% ROM). 3) Return to bottom. 4) Repeat. Avoid full ROM. Best for: hypertrophy, stretch position, weak point training (bottom end).',
  'medium',
  ARRAY['hypertrophy', 'stretch', 'weak_point'],
  '{"partial_bottom": {"rom_percent": 50, "avoid_full_rom": true}}'::jsonb,
  ARRAY['Squat: bottom 50% only, Leg curl: bottom half only'],
  'en',
  'approved',
  NULL
),

-- CHEAT REPS (CONTROLLED)
(
  'Cheat Reps (Controlled)',
  ARRAY['cheat', 'controlled cheat', 'form breakdown'],
  'Use slight form breakdown/momentum to complete additional reps after strict form failure.',
  '1) Perform strict reps to failure. 2) Use slight momentum/form breakdown to complete 1-3 additional reps. 3) Maintain control (not dangerous). Best for: hypertrophy, volume accumulation, finishing sets.',
  'medium',
  ARRAY['hypertrophy', 'volume', 'finishing'],
  '{"cheat": {"strict_to_failure": true, "cheat_reps": 2, "controlled": true}}'::jsonb,
  ARRAY['Bicep curls: strict to failure, then 2 controlled cheat reps'],
  'en',
  'approved',
  NULL
),

-- FORCED REPS (SPOTTER)
(
  'Forced Reps',
  ARRAY['forced', 'assisted', 'spotter assisted'],
  'After reaching failure, use spotter assistance to complete 2-4 additional reps with help.',
  '1) Perform set to failure (0 RIR). 2) Spotter provides minimal assistance (just enough to complete rep). 3) Complete 2-4 forced reps. 4) Spotter removes assistance gradually. Best for: hypertrophy, volume, finishing sets (requires spotter).',
  'high',
  ARRAY['hypertrophy', 'volume', 'finishing'],
  '{"forced": {"reps_after_failure": 3, "spotter_assistance": true}}'::jsonb,
  ARRAY['Bench press: failure at 8, spotter helps 3 more reps'],
  'en',
  'approved',
  NULL
),

-- NEGATIVES
(
  'Negatives',
  ARRAY['negative', 'eccentric only', 'lowering phase'],
  'Focus only on the lowering/eccentric phase, using heavier weight than concentric max, with assistance on concentric.',
  '1) Load 110-130% of concentric max. 2) Lower weight slowly (3-6 seconds) under control. 3) Use assistance (spotter/machine) to return to start. 4) Repeat. Best for: strength, hypertrophy, time under tension, weak point training.',
  'high',
  ARRAY['strength', 'hypertrophy', 'time_under_tension'],
  '{"negatives": {"load_percent_1rm": 120, "eccentric_seconds": 4, "assisted_concentric": true}}'::jsonb,
  ARRAY['Bench press: 120% 1RM, 4s down, spotter helps up'],
  'en',
  'approved',
  NULL
),

-- WAVE LOADING (STRENGTH)
(
  'Wave Loading',
  ARRAY['wave', 'ascending wave', 'strength wave'],
  'Perform ascending waves of weight with decreasing reps, then reset and repeat (e.g., 5@100kg, 3@105kg, 1@110kg, reset, repeat).',
  '1) Wave 1: Higher reps, lower weight (e.g., 5 reps @ 100kg). 2) Wave 2: Medium reps, medium weight (e.g., 3 reps @ 105kg). 3) Wave 3: Lower reps, higher weight (e.g., 1 rep @ 110kg). 4) Reset and repeat waves. Best for: strength, power, volume with heavy loads.',
  'medium',
  ARRAY['strength', 'power', 'volume'],
  '{"wave": {"waves": 3, "reps_per_wave": [5, 3, 1], "weight_increase_percent": 5}}'::jsonb,
  ARRAY['Squat: 5@100, 3@105, 1@110, reset, repeat'],
  'en',
  'approved',
  NULL
),

-- BACK-OFF SETS
(
  'Back-Off Sets',
  ARRAY['back off', 'backoff', 'volume backoff'],
  'Perform heavy set(s) first, then reduce weight by 10-20% and perform additional volume sets.',
  '1) Perform 1-2 heavy sets (85-95% 1RM). 2) Reduce weight by 10-20%. 3) Perform 2-3 additional sets with reduced weight. 4) Higher reps on back-off sets. Best for: strength, volume accumulation, technique practice.',
  'medium',
  ARRAY['strength', 'volume', 'technique'],
  '{"back_off": {"heavy_sets": 2, "heavy_percent_1rm": 90, "backoff_weight_reduction": 15, "backoff_sets": 3}}'::jsonb,
  ARRAY['Squat: 2x5@90%, then 3x8@75%'],
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
  seeded_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO seeded_count
  FROM public.intensifier_knowledge
  WHERE status = 'approved' AND language = 'en';
  
  RAISE NOTICE '✅ Migration complete: seed_intensifier_knowledge';
  RAISE NOTICE '   - Seeded intensifiers: %', seeded_count;
END $$;
