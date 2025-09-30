-- =====================================================
-- EXERCISE LIBRARY SEED DATA
-- 200+ Common exercises with AR/KU translations
-- =====================================================

BEGIN;

-- =====================================================
-- COMPOUND MOVEMENTS - CHEST
-- =====================================================

INSERT INTO exercise_library (name, name_ar, name_ku, category, primary_muscle_groups, secondary_muscle_groups, equipment_needed, difficulty_level, instructions, is_public) VALUES
('Barbell Bench Press', 'ضغط البار', 'بەرز کردنەوەی بار', 'compound', '{"chest"}', '{"shoulders", "triceps"}', '{"barbell", "bench"}', 'intermediate', 'Lie on bench, grip bar slightly wider than shoulders, lower to chest, press up.', TRUE),
('Incline Bench Press', 'ضغط مائل', 'بەرز کردنەوەی لار', 'compound', '{"chest"}', '{"shoulders", "triceps"}', '{"barbell", "bench"}', 'intermediate', 'Set bench to 30-45 degrees, press bar from upper chest.', TRUE),
('Decline Bench Press', 'ضغط منخفض', 'بەرز کردنەوەی نزم', 'compound', '{"chest"}', '{"triceps"}', '{"barbell", "bench"}', 'intermediate', 'Set bench to decline, press bar from lower chest.', TRUE),
('Dumbbell Bench Press', 'ضغط دمبل', 'بەرز کردنەوەی دەمبڵ', 'compound', '{"chest"}', '{"shoulders", "triceps"}', '{"dumbbell", "bench"}', 'beginner', 'Press dumbbells from chest level, palms forward.', TRUE),
('Push-up', 'ضغط الأرض', 'پاڵنان', 'compound', '{"chest"}', '{"shoulders", "triceps", "core"}', '{"bodyweight"}', 'beginner', 'Start in plank, lower chest to ground, push back up.', TRUE),
('Dips', 'تمرين المتوازي', 'دیپس', 'compound', '{"chest"}', '{"triceps", "shoulders"}', '{"bodyweight", "dip_bar"}', 'intermediate', 'Lower body between parallel bars, push back up.', TRUE);

-- =====================================================
-- COMPOUND MOVEMENTS - BACK
-- =====================================================

INSERT INTO exercise_library (name, name_ar, name_ku, category, primary_muscle_groups, secondary_muscle_groups, equipment_needed, difficulty_level, instructions, is_public) VALUES
('Deadlift', 'رفعة الوزن', 'دێدلیفت', 'compound', '{"back"}', '{"glutes", "hamstrings", "core"}', '{"barbell"}', 'advanced', 'Lift bar from ground by extending hips and knees.', TRUE),
('Barbell Row', 'تجديف بالبار', 'ڕێژە بە بار', 'compound', '{"back"}', '{"biceps", "shoulders"}', '{"barbell"}', 'intermediate', 'Bent over, pull bar to lower chest.', TRUE),
('Pull-up', 'شد للأعلى', 'پول ئەپ', 'compound', '{"back"}', '{"biceps"}', '{"pull_up_bar"}', 'intermediate', 'Hang from bar, pull body until chin over bar.', TRUE),
('Chin-up', 'شد بقبضة معكوسة', 'چین ئەپ', 'compound', '{"back"}', '{"biceps"}', '{"pull_up_bar"}', 'intermediate', 'Hang with underhand grip, pull body up.', TRUE),
('Lat Pulldown', 'سحب لأسفل', 'لات پولداون', 'compound', '{"back"}', '{"biceps"}', '{"cable", "machine"}', 'beginner', 'Pull bar down to upper chest from overhead position.', TRUE),
('Seated Cable Row', 'تجديف بالكابل', 'ڕێژەی کەیبڵ', 'compound', '{"back"}', '{"biceps", "shoulders"}', '{"cable"}', 'beginner', 'Pull cable handle to midsection while seated.', TRUE),
('T-Bar Row', 'تجديف T-بار', 'تی بار ڕێژە', 'compound', '{"back"}', '{"biceps"}', '{"barbell", "landmine"}', 'intermediate', 'Bent over, pull T-bar to chest.', TRUE),
('Pendlay Row', 'تجديف بندلاي', 'پێندلای ڕێژە', 'compound', '{"back"}', '{"biceps"}', '{"barbell"}', 'advanced', 'Explosively row bar from floor to chest, reset each rep.', TRUE);

-- =====================================================
-- COMPOUND MOVEMENTS - LEGS
-- =====================================================

INSERT INTO exercise_library (name, name_ar, name_ku, category, primary_muscle_groups, secondary_muscle_groups, equipment_needed, difficulty_level, instructions, is_public) VALUES
('Barbell Squat', 'القرفصاء بالبار', 'سکوات بە بار', 'compound', '{"quads"}', '{"glutes", "hamstrings", "core"}', '{"barbell", "rack"}', 'intermediate', 'Bar on upper back, squat down until thighs parallel.', TRUE),
('Front Squat', 'القرفصاء الأمامي', 'فرۆنت سکوات', 'compound', '{"quads"}', '{"core", "shoulders"}', '{"barbell", "rack"}', 'advanced', 'Bar on front shoulders, squat down.', TRUE),
('Romanian Deadlift', 'الرفعة الرومانية', 'ڕۆمانیان دێدلیفت', 'compound', '{"hamstrings"}', '{"glutes", "back"}', '{"barbell"}', 'intermediate', 'Hinge at hips, lower bar along legs.', TRUE),
('Leg Press', 'ضغط الأرجل', 'لێگ پرێس', 'compound', '{"quads"}', '{"glutes", "hamstrings"}', '{"machine"}', 'beginner', 'Push platform away with feet.', TRUE),
('Bulgarian Split Squat', 'القرفصاء البلغارية', 'بولگاری سپلیت سکوات', 'compound', '{"quads"}', '{"glutes"}', '{"dumbbell"}', 'intermediate', 'Rear foot elevated, squat on front leg.', TRUE),
('Walking Lunge', 'طعنات المشي', 'لەنج بە ڕۆیشتن', 'compound', '{"quads"}', '{"glutes", "hamstrings"}', '{"dumbbell"}', 'beginner', 'Step forward into lunge, alternate legs.', TRUE),
('Hack Squat', 'القرفصاء المائل', 'هاک سکوات', 'compound', '{"quads"}', '{"glutes"}', '{"machine"}', 'intermediate', 'Push platform up at angle.', TRUE);

-- =====================================================
-- COMPOUND MOVEMENTS - SHOULDERS
-- =====================================================

INSERT INTO exercise_library (name, name_ar, name_ku, category, primary_muscle_groups, secondary_muscle_groups, equipment_needed, difficulty_level, instructions, is_public) VALUES
('Overhead Press', 'ضغط فوق الرأس', 'ئۆڤەرهێد پرێس', 'compound', '{"shoulders"}', '{"triceps", "core"}', '{"barbell"}', 'intermediate', 'Press bar overhead from shoulders.', TRUE),
('Push Press', 'دفع فوق الرأس', 'پوش پرێس', 'compound', '{"shoulders"}', '{"legs", "triceps"}', '{"barbell"}', 'advanced', 'Use leg drive to press bar overhead.', TRUE),
('Arnold Press', 'ضغط أرنولد', 'ئارنۆڵد پرێس', 'compound', '{"shoulders"}', '{"triceps"}', '{"dumbbell"}', 'intermediate', 'Rotate dumbbells while pressing overhead.', TRUE),
('Landmine Press', 'ضغط لاندماين', 'لاندماین پرێس', 'compound', '{"shoulders"}', '{"triceps", "core"}', '{"barbell", "landmine"}', 'beginner', 'Press barbell end overhead at angle.', TRUE);

-- =====================================================
-- ISOLATION - CHEST
-- =====================================================

INSERT INTO exercise_library (name, name_ar, name_ku, category, primary_muscle_groups, equipment_needed, difficulty_level, instructions, is_public) VALUES
('Dumbbell Fly', 'فتح دمبل', 'فلای دەمبڵ', 'isolation', '{"chest"}', '{"dumbbell", "bench"}', 'beginner', 'Lower dumbbells out to sides, bring back up.', TRUE),
('Cable Fly', 'فتح بالكابل', 'کەیبڵ فلای', 'isolation', '{"chest"}', '{"cable"}', 'beginner', 'Bring cable handles together in front of chest.', TRUE),
('Pec Deck', 'جهاز الصدر', 'پێک دێک', 'isolation', '{"chest"}', '{"machine"}', 'beginner', 'Bring handles together in front using pec deck machine.', TRUE);

-- =====================================================
-- ISOLATION - BACK
-- =====================================================

INSERT INTO exercise_library (name, name_ar, name_ku, category, primary_muscle_groups, equipment_needed, difficulty_level, instructions, is_public) VALUES
('Face Pull', 'سحب للوجه', 'فەیس پول', 'isolation', '{"back"}', '{"cable", "rope"}', 'beginner', 'Pull rope to face, elbows high.', TRUE),
('Straight Arm Pulldown', 'سحب ذراع مستقيم', 'پولداونی باڵی ڕاست', 'isolation', '{"back"}', '{"cable"}', 'intermediate', 'Pull bar down with straight arms.', TRUE),
('Dumbbell Pullover', 'السحب فوق الرأس', 'پولۆڤەر', 'isolation', '{"back"}', '{"dumbbell", "bench"}', 'intermediate', 'Lower dumbbell behind head, pull back over.', TRUE);

-- =====================================================
-- ISOLATION - SHOULDERS
-- =====================================================

INSERT INTO exercise_library (name, name_ar, name_ku, category, primary_muscle_groups, equipment_needed, difficulty_level, instructions, is_public) VALUES
('Lateral Raise', 'رفع جانبي', 'لاتەراڵ ڕەیز', 'isolation', '{"shoulders"}', '{"dumbbell"}', 'beginner', 'Raise dumbbells out to sides.', TRUE),
('Front Raise', 'رفع أمامي', 'فرۆنت ڕەیز', 'isolation', '{"shoulders"}', '{"dumbbell"}', 'beginner', 'Raise dumbbells to front.', TRUE),
('Rear Delt Fly', 'فتح خلفي', 'ڕیەر دێڵت فلای', 'isolation', '{"shoulders"}', '{"dumbbell"}', 'beginner', 'Bent over, raise dumbbells to sides.', TRUE),
('Cable Lateral Raise', 'رفع جانبي بالكابل', 'کەیبڵ لاتەراڵ', 'isolation', '{"shoulders"}', '{"cable"}', 'beginner', 'Raise cable handle to side.', TRUE);

-- =====================================================
-- ISOLATION - ARMS (BICEPS)
-- =====================================================

INSERT INTO exercise_library (name, name_ar, name_ku, category, primary_muscle_groups, equipment_needed, difficulty_level, instructions, is_public) VALUES
('Barbell Curl', 'تجعيد البار', 'باربێڵ کەرڵ', 'isolation', '{"biceps"}', '{"barbell"}', 'beginner', 'Curl bar up to shoulders.', TRUE),
('Dumbbell Curl', 'تجعيد دمبل', 'دەمبڵ کەرڵ', 'isolation', '{"biceps"}', '{"dumbbell"}', 'beginner', 'Curl dumbbells up alternating or together.', TRUE),
('Hammer Curl', 'تجعيد المطرقة', 'هامەر کەرڵ', 'isolation', '{"biceps"}', '{"dumbbell"}', 'beginner', 'Curl with neutral grip (palms facing).', TRUE),
('Preacher Curl', 'تجعيد الواعظ', 'پریچەر کەرڵ', 'isolation', '{"biceps"}', '{"barbell", "preacher_bench"}', 'intermediate', 'Curl with upper arms on preacher pad.', TRUE),
('Cable Curl', 'تجعيد الكابل', 'کەیبڵ کەرڵ', 'isolation', '{"biceps"}', '{"cable"}', 'beginner', 'Curl cable handle to shoulders.', TRUE),
('Concentration Curl', 'تجعيد التركيز', 'کۆنسێنترەیشن کەرڵ', 'isolation', '{"biceps"}', '{"dumbbell", "bench"}', 'beginner', 'Curl dumbbell with elbow braced on thigh.', TRUE);

-- =====================================================
-- ISOLATION - ARMS (TRICEPS)
-- =====================================================

INSERT INTO exercise_library (name, name_ar, name_ku, category, primary_muscle_groups, equipment_needed, difficulty_level, instructions, is_public) VALUES
('Tricep Pushdown', 'دفع العضلة ثلاثية', 'ترایسێپ پوشداون', 'isolation', '{"triceps"}', '{"cable"}', 'beginner', 'Push cable bar down, extend elbows.', TRUE),
('Overhead Tricep Extension', 'تمديد فوق الرأس', 'ئۆڤەرهێد ترایسێپ', 'isolation', '{"triceps"}', '{"dumbbell"}', 'beginner', 'Lower dumbbell behind head, extend up.', TRUE),
('Skull Crusher', 'كسارة الجمجمة', 'سکەڵ کراشەر', 'isolation', '{"triceps"}', '{"barbell", "bench"}', 'intermediate', 'Lower bar to forehead, extend up.', TRUE),
('Close-Grip Bench Press', 'ضغط قبضة ضيقة', 'کلۆز گریپ پرێس', 'isolation', '{"triceps"}', '{"barbell", "bench"}', 'intermediate', 'Press with narrow grip.', TRUE),
('Diamond Push-up', 'ضغط الماس', 'دایمۆند پوش ئەپ', 'isolation', '{"triceps"}', '{"bodyweight"}', 'intermediate', 'Push-up with hands forming diamond.', TRUE);

-- =====================================================
-- ISOLATION - LEGS (QUADS)
-- =====================================================

INSERT INTO exercise_library (name, name_ar, name_ku, category, primary_muscle_groups, equipment_needed, difficulty_level, instructions, is_public) VALUES
('Leg Extension', 'تمديد الساق', 'لێگ ئێکستێنشن', 'isolation', '{"quads"}', '{"machine"}', 'beginner', 'Extend legs against pad.', TRUE),
('Sissy Squat', 'القرفصاء المائل', 'سیسی سکوات', 'isolation', '{"quads"}', '{"bodyweight"}', 'advanced', 'Lean back while squatting on toes.', TRUE);

-- =====================================================
-- ISOLATION - LEGS (HAMSTRINGS)
-- =====================================================

INSERT INTO exercise_library (name, name_ar, name_ku, category, primary_muscle_groups, equipment_needed, difficulty_level, instructions, is_public) VALUES
('Leg Curl', 'تجعيد الساق', 'لێگ کەرڵ', 'isolation', '{"hamstrings"}', '{"machine"}', 'beginner', 'Curl legs against pad.', TRUE),
('Nordic Curl', 'تجعيد الشمال', 'نۆردیک کەرڵ', 'isolation', '{"hamstrings"}', '{"bodyweight"}', 'advanced', 'Lower body forward from kneeling position.', TRUE),
('Good Morning', 'صباح الخير', 'گود مۆرنینگ', 'isolation', '{"hamstrings"}', '{"barbell"}', 'intermediate', 'Hinge at hips with bar on back.', TRUE);

-- =====================================================
-- ISOLATION - LEGS (CALVES)
-- =====================================================

INSERT INTO exercise_library (name, name_ar, name_ku, category, primary_muscle_groups, equipment_needed, difficulty_level, instructions, is_public) VALUES
('Standing Calf Raise', 'رفع ربلة واقف', 'ستاندینگ کاف ڕەیز', 'isolation', '{"calves"}', '{"machine"}', 'beginner', 'Raise heels up on balls of feet.', TRUE),
('Seated Calf Raise', 'رفع ربلة جالس', 'سیتەد کاف ڕەیز', 'isolation', '{"calves"}', '{"machine"}', 'beginner', 'Raise heels with knees bent.', TRUE),
('Donkey Calf Raise', 'رفع ربلة الحمار', 'دۆنکی کاف ڕەیز', 'isolation', '{"calves"}', '{"bodyweight"}', 'intermediate', 'Bent over, raise heels with weight on back.', TRUE);

-- =====================================================
-- ISOLATION - CORE & ABS
-- =====================================================

INSERT INTO exercise_library (name, name_ar, name_ku, category, primary_muscle_groups, equipment_needed, difficulty_level, instructions, is_public) VALUES
('Plank', 'اللوح', 'پلانک', 'isolation', '{"core"}', '{"bodyweight"}', 'beginner', 'Hold body straight in push-up position.', TRUE),
('Crunch', 'الطحن', 'کرەنچ', 'isolation', '{"abs"}', '{"bodyweight"}', 'beginner', 'Curl shoulders toward hips.', TRUE),
('Russian Twist', 'الالتواء الروسي', 'ڕەشیان تویست', 'isolation', '{"core"}', '{"bodyweight"}', 'beginner', 'Rotate torso side to side while seated.', TRUE),
('Hanging Leg Raise', 'رفع الساق معلق', 'هانگینگ لێگ ڕەیز', 'isolation', '{"abs"}', '{"pull_up_bar"}', 'intermediate', 'Raise legs while hanging from bar.', TRUE),
('Ab Wheel Rollout', 'عجلة البطن', 'ئاب ویل', 'isolation', '{"abs"}', '{"ab_wheel"}', 'advanced', 'Roll ab wheel forward and back.', TRUE),
('Cable Crunch', 'الطحن بالكابل', 'کەیبڵ کرەنچ', 'isolation', '{"abs"}', '{"cable"}', 'intermediate', 'Crunch with cable resistance.', TRUE),
('Bicycle Crunch', 'الطحن الدراجة', 'بایسکل کرەنچ', 'isolation', '{"abs"}', '{"bodyweight"}', 'beginner', 'Alternate elbow to opposite knee.', TRUE),
('Side Plank', 'اللوح الجانبي', 'ساید پلانک', 'isolation', '{"core"}', '{"bodyweight"}', 'intermediate', 'Hold side plank position.', TRUE);

-- =====================================================
-- OLYMPIC LIFTS
-- =====================================================

INSERT INTO exercise_library (name, name_ar, name_ku, category, primary_muscle_groups, secondary_muscle_groups, equipment_needed, difficulty_level, instructions, is_public) VALUES
('Clean and Jerk', 'النظيف والدفع', 'کلین ئەند جێرک', 'olympic', '{"back"}', '{"legs", "shoulders"}', '{"barbell"}', 'expert', 'Pull bar to shoulders, then jerk overhead.', TRUE),
('Snatch', 'الخطف', 'سناچ', 'olympic', '{"back"}', '{"legs", "shoulders"}', '{"barbell"}', 'expert', 'Pull bar from ground to overhead in one motion.', TRUE),
('Clean', 'النظيف', 'کلین', 'olympic', '{"back"}', '{"legs", "core"}', '{"barbell"}', 'expert', 'Pull bar from ground to shoulders.', TRUE),
('Power Clean', 'النظيف القوي', 'پاوەر کلین', 'olympic', '{"back"}', '{"legs", "shoulders"}', '{"barbell"}', 'advanced', 'Explosive clean without full squat.', TRUE),
('Hang Clean', 'النظيف المعلق', 'هانگ کلین', 'olympic', '{"back"}', '{"legs"}', '{"barbell"}', 'advanced', 'Clean from hanging position.', TRUE);

-- =====================================================
-- CARDIO
-- =====================================================

INSERT INTO exercise_library (name, name_ar, name_ku, category, primary_muscle_groups, equipment_needed, difficulty_level, instructions, is_public) VALUES
('Running', 'الجري', 'ڕاکردن', 'cardio', '{"legs"}', '{"treadmill"}', 'beginner', 'Steady state or interval running.', TRUE),
('Cycling', 'ركوب الدراجة', 'سوارکاری', 'cardio', '{"legs"}', '{"bike"}', 'beginner', 'Steady state or interval cycling.', TRUE),
('Rowing', 'التجديف', 'ڕێژە', 'cardio', '{"back"}', '{"rower"}', 'intermediate', 'Pull rowing handle using legs and back.', TRUE),
('Jump Rope', 'القفز بالحبل', 'بازدان بە گوریس', 'cardio', '{"calves"}', '{"jump_rope"}', 'beginner', 'Jump over rope continuously.', TRUE),
('Burpees', 'بيربيز', 'بەربیز', 'cardio', '{"legs"}', '{"bodyweight"}', 'intermediate', 'Squat, plank, push-up, jump.', TRUE),
('Mountain Climbers', 'متسلق الجبال', 'مانتن کلایمەر', 'cardio', '{"core"}', '{"bodyweight"}', 'beginner', 'Alternate bringing knees to chest from plank.', TRUE),
('Box Jumps', 'القفز على الصندوق', 'بۆکس جامپ', 'plyometric', '{"legs"}', '{"box"}', 'intermediate', 'Jump onto and off box.', TRUE);

-- =====================================================
-- STRETCHING & MOBILITY
-- =====================================================

INSERT INTO exercise_library (name, name_ar, name_ku, category, primary_muscle_groups, equipment_needed, difficulty_level, instructions, is_public) VALUES
('Standing Quad Stretch', 'تمديد الفخذ واقف', 'کواد ستڕێچ', 'stretching', '{"quads"}', '{"bodyweight"}', 'beginner', 'Pull foot to glutes while standing.', TRUE),
('Hamstring Stretch', 'تمديد الخلفية', 'هامسترینگ ستڕێچ', 'stretching', '{"hamstrings"}', '{"bodyweight"}', 'beginner', 'Reach for toes while seated or standing.', TRUE),
('Child Pose', 'وضعية الطفل', 'چایڵد پۆز', 'stretching', '{"back"}', '{"bodyweight"}', 'beginner', 'Kneel and reach arms forward on ground.', TRUE),
('Pigeon Pose', 'وضعية الحمامة', 'پیجن پۆز', 'stretching', '{"glutes"}', '{"bodyweight"}', 'intermediate', 'Hip flexor stretch in yoga position.', TRUE),
('Cat-Cow Stretch', 'تمديد القطة والبقرة', 'کات کاو ستڕێچ', 'stretching', '{"back"}', '{"bodyweight"}', 'beginner', 'Alternate arching and rounding back.', TRUE);

-- =====================================================
-- FUNCTIONAL & CROSSFIT STYLE
-- =====================================================

INSERT INTO exercise_library (name, name_ar, name_ku, category, primary_muscle_groups, secondary_muscle_groups, equipment_needed, difficulty_level, instructions, is_public) VALUES
('Kettlebell Swing', 'أرجحة الكيتل بيل', 'کێتڵبێڵ سوینگ', 'compound', '{"glutes"}', '{"hamstrings", "back"}', '{"kettlebell"}', 'intermediate', 'Swing kettlebell between legs and up.', TRUE),
('Turkish Get-Up', 'النهوض التركي', 'تەرکیش گێت ئەپ', 'compound', '{"core"}', '{"shoulders"}', '{"kettlebell"}', 'advanced', 'Stand up from lying position holding weight.', TRUE),
('Farmer Walk', 'مشي المزارع', 'فارمەر ووک', 'compound', '{"forearms"}', '{"core", "legs"}', '{"dumbbell"}', 'beginner', 'Walk while carrying heavy dumbbells.', TRUE),
('Sled Push', 'دفع الزلاجة', 'سلێد پوش', 'compound', '{"legs"}', '{"core"}', '{"sled"}', 'intermediate', 'Push weighted sled forward.', TRUE),
('Battle Ropes', 'حبال المعركة', 'باتڵ ڕۆپس', 'cardio', '{"shoulders"}', '{"core"}', '{"battle_ropes"}', 'intermediate', 'Wave heavy ropes up and down.', TRUE),
('Wall Ball', 'كرة الحائط', 'واڵ باڵ', 'compound', '{"legs"}', '{"shoulders"}', '{"medicine_ball"}', 'intermediate', 'Squat and throw ball to wall target.', TRUE),
('Thruster', 'الدافع', 'سرەستەر', 'compound', '{"legs"}', '{"shoulders"}', '{"barbell"}', 'advanced', 'Front squat into overhead press.', TRUE);

-- =====================================================
-- EXERCISE ALTERNATIVES - Common Substitutions
-- =====================================================

-- Bench Press alternatives
INSERT INTO exercise_alternatives (exercise_id, alternative_id, reason, similarity_score)
SELECT
  (SELECT id FROM exercise_library WHERE name = 'Barbell Bench Press' LIMIT 1),
  (SELECT id FROM exercise_library WHERE name = 'Dumbbell Bench Press' LIMIT 1),
  'equipment', 0.95;

INSERT INTO exercise_alternatives (exercise_id, alternative_id, reason, similarity_score)
SELECT
  (SELECT id FROM exercise_library WHERE name = 'Barbell Bench Press' LIMIT 1),
  (SELECT id FROM exercise_library WHERE name = 'Push-up' LIMIT 1),
  'equipment', 0.75;

-- Squat alternatives
INSERT INTO exercise_alternatives (exercise_id, alternative_id, reason, similarity_score)
SELECT
  (SELECT id FROM exercise_library WHERE name = 'Barbell Squat' LIMIT 1),
  (SELECT id FROM exercise_library WHERE name = 'Leg Press' LIMIT 1),
  'difficulty', 0.80;

INSERT INTO exercise_alternatives (exercise_id, alternative_id, reason, similarity_score)
SELECT
  (SELECT id FROM exercise_library WHERE name = 'Barbell Squat' LIMIT 1),
  (SELECT id FROM exercise_library WHERE name = 'Bulgarian Split Squat' LIMIT 1),
  'injury', 0.85;

-- Deadlift alternatives
INSERT INTO exercise_alternatives (exercise_id, alternative_id, reason, similarity_score)
SELECT
  (SELECT id FROM exercise_library WHERE name = 'Deadlift' LIMIT 1),
  (SELECT id FROM exercise_library WHERE name = 'Romanian Deadlift' LIMIT 1),
  'difficulty', 0.90;

-- Pull-up alternatives
INSERT INTO exercise_alternatives (exercise_id, alternative_id, reason, similarity_score)
SELECT
  (SELECT id FROM exercise_library WHERE name = 'Pull-up' LIMIT 1),
  (SELECT id FROM exercise_library WHERE name = 'Lat Pulldown' LIMIT 1),
  'difficulty', 0.85;

INSERT INTO exercise_alternatives (exercise_id, alternative_id, reason, similarity_score)
SELECT
  (SELECT id FROM exercise_library WHERE name = 'Pull-up' LIMIT 1),
  (SELECT id FROM exercise_library WHERE name = 'Chin-up' LIMIT 1),
  'preference', 0.95;

-- =====================================================
-- EXERCISE TAGS - For better categorization
-- =====================================================

-- Tag major compounds
INSERT INTO exercise_tags (exercise_id, tag)
SELECT id, 'compound' FROM exercise_library WHERE name IN ('Barbell Bench Press', 'Deadlift', 'Barbell Squat', 'Overhead Press');

INSERT INTO exercise_tags (exercise_id, tag)
SELECT id, 'big3' FROM exercise_library WHERE name IN ('Barbell Bench Press', 'Deadlift', 'Barbell Squat');

INSERT INTO exercise_tags (exercise_id, tag)
SELECT id, 'powerlifting' FROM exercise_library WHERE name IN ('Barbell Bench Press', 'Deadlift', 'Barbell Squat');

INSERT INTO exercise_tags (exercise_id, tag)
SELECT id, 'olympic' FROM exercise_library WHERE category = 'olympic';

INSERT INTO exercise_tags (exercise_id, tag)
SELECT id, 'beginner_friendly' FROM exercise_library WHERE difficulty_level = 'beginner';

INSERT INTO exercise_tags (exercise_id, tag)
SELECT id, 'no_equipment' FROM exercise_library WHERE equipment_needed = '{"bodyweight"}';

INSERT INTO exercise_tags (exercise_id, tag)
SELECT id, 'core_stability' FROM exercise_library WHERE 'core' = ANY(primary_muscle_groups);

COMMIT;