-- LABKIT — lab work parser pipeline
-- Migration owner: LABKIT
-- Created: 2026-04-28 00:00 UTC
--
-- Purpose
--   Stores encrypted blood-test / lab-work records, a biomarkers reference
--   dictionary, and per-lab coach consent grants. Uses VAULT's
--   vault_encrypt_text / vault_decrypt_text / vault_audit_access primitives.
--
-- Safety contracts (NON-NEGOTIABLE):
--   1. No diagnosis stored. Only biomarker extraction data.
--   2. biomarkers_enc is always pgcrypto-encrypted (via VAULT helpers).
--   3. raw_pdf_url_enc is always encrypted.
--   4. Every read (self or coach) inserts a data_access_audit row.
--   5. Coach access requires an active lab_consent_grants row.
--   6. Hard delete on user request via delete_lab_work().
--
-- Idempotent: safe to re-apply.
-- Rollback: see bottom.

-- ============================================================================
-- lab_work
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.lab_work (
  id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  lab_date         date        NOT NULL,
  source           text        NOT NULL CHECK (source IN ('pdf', 'photo', 'manual')),
  raw_pdf_url_enc  bytea,
  parsed_at        timestamptz,
  biomarkers_enc   bytea,
  created_at       timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.lab_work IS
  'LABKIT-owned. One row per lab upload. biomarkers_enc contains pgcrypto-'
  'encrypted JSON array of extracted biomarker results. Never store '
  'diagnosis language — only values, units, reference ranges, and '
  'low/normal/high flags.';

COMMENT ON COLUMN public.lab_work.biomarkers_enc IS
  'vault_encrypt_text( json_array_text ). Decrypt via get_lab_detail() RPC only.';

COMMENT ON COLUMN public.lab_work.raw_pdf_url_enc IS
  'vault_encrypt_text( cdn_url ). Decrypt server-side; never expose raw URL to client.';

CREATE INDEX IF NOT EXISTS lab_work_user_date_idx
  ON public.lab_work (user_id, lab_date DESC);

ALTER TABLE public.lab_work ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS lab_work_select_owner ON public.lab_work;
CREATE POLICY lab_work_select_owner
  ON public.lab_work FOR SELECT
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS lab_work_insert_self ON public.lab_work;
CREATE POLICY lab_work_insert_self
  ON public.lab_work FOR INSERT
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS lab_work_delete_owner ON public.lab_work;
CREATE POLICY lab_work_delete_owner
  ON public.lab_work FOR DELETE
  USING (user_id = auth.uid());

-- ============================================================================
-- lab_consent_grants  (per-lab, per-coach)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.lab_consent_grants (
  id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  lab_work_id    uuid        NOT NULL REFERENCES public.lab_work(id) ON DELETE CASCADE,
  coach_user_id  uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  granted_by     uuid        NOT NULL REFERENCES auth.users(id),
  granted_at     timestamptz NOT NULL DEFAULT now(),
  revoked_at     timestamptz,
  UNIQUE (lab_work_id, coach_user_id)
);

COMMENT ON TABLE public.lab_consent_grants IS
  'LABKIT-owned. Client explicitly opts each lab into coach visibility. '
  'NULL revoked_at = active grant. get_lab_for_coach() checks this before decrypting.';

CREATE INDEX IF NOT EXISTS lab_consent_coach_idx
  ON public.lab_consent_grants (coach_user_id, revoked_at NULLS FIRST);

CREATE INDEX IF NOT EXISTS lab_consent_lab_idx
  ON public.lab_consent_grants (lab_work_id);

ALTER TABLE public.lab_consent_grants ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS lab_consent_select_owner ON public.lab_consent_grants;
CREATE POLICY lab_consent_select_owner
  ON public.lab_consent_grants FOR SELECT
  USING (granted_by = auth.uid() OR coach_user_id = auth.uid());

DROP POLICY IF EXISTS lab_consent_insert_owner ON public.lab_consent_grants;
CREATE POLICY lab_consent_insert_owner
  ON public.lab_consent_grants FOR INSERT
  WITH CHECK (granted_by = auth.uid());

DROP POLICY IF EXISTS lab_consent_update_owner ON public.lab_consent_grants;
CREATE POLICY lab_consent_update_owner
  ON public.lab_consent_grants FOR UPDATE
  USING (granted_by = auth.uid());

-- ============================================================================
-- biomarkers_dictionary  (~100 reference entries)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.biomarkers_dictionary (
  id                           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  name                         text        UNIQUE NOT NULL,
  name_ar                      text,
  name_ku                      text,
  category                     text        NOT NULL,
  unit                         text,
  reference_range_male         text,
  reference_range_female       text,
  reference_range_age_adjusted jsonb       NOT NULL DEFAULT '[]'::jsonb,
  optimal_range                text,
  aliases                      text[]      NOT NULL DEFAULT '{}'::text[],
  created_at                   timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.biomarkers_dictionary IS
  'LABKIT-owned. Reference data for ~100 common biomarkers. '
  'Aliases are used for fuzzy-matching extracted text to canonical names.';

CREATE INDEX IF NOT EXISTS biomarkers_dict_name_idx
  ON public.biomarkers_dictionary (lower(name));

CREATE INDEX IF NOT EXISTS biomarkers_dict_category_idx
  ON public.biomarkers_dictionary (category);

ALTER TABLE public.biomarkers_dictionary ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS biomarkers_dict_select_auth ON public.biomarkers_dictionary;
CREATE POLICY biomarkers_dict_select_auth
  ON public.biomarkers_dictionary FOR SELECT
  TO authenticated USING (true);

-- ============================================================================
-- Seed: biomarkers_dictionary  (~100 biomarkers)
-- ============================================================================

INSERT INTO public.biomarkers_dictionary
  (name, name_ar, name_ku, category, unit, reference_range_male, reference_range_female, optimal_range, aliases)
VALUES
  -- CBC
  ('WBC','كريات الدم البيضاء','گوێزی خوێنی سپی','CBC','K/uL','4.5-11.0','4.5-11.0','4.5-8.0','{"white blood cells","white blood cell count","leukocytes","wbc count"}'),
  ('RBC','كريات الدم الحمراء','گوێزی خوێنی سوور','CBC','M/uL','4.7-6.1','4.2-5.4',NULL,'{"red blood cells","red blood cell count","erythrocytes","rbc count"}'),
  ('Hemoglobin','الهيموغلوبين','هیموگلۆبین','CBC','g/dL','13.8-17.2','12.1-15.1','14.0-17.0','{"haemoglobin","hgb","hb"}'),
  ('Hematocrit','الهيماتوكريت','هیماتۆکریت','CBC','%','40.7-50.3','36.1-44.3',NULL,'{"hct","packed cell volume","pcv"}'),
  ('MCV','متوسط حجم كريات الدم الحمراء','MCV','CBC','fL','80-100','80-100',NULL,'{"mean corpuscular volume","mean cell volume"}'),
  ('MCH','متوسط هيموغلوبين كريات الدم الحمراء','MCH','CBC','pg','27-33','27-33',NULL,'{"mean corpuscular hemoglobin","mean cell hemoglobin"}'),
  ('MCHC','تركيز متوسط هيموغلوبين كريات الدم الحمراء','MCHC','CBC','g/dL','32-36','32-36',NULL,'{"mean corpuscular hemoglobin concentration"}'),
  ('RDW','توزيع عرض كريات الدم الحمراء','RDW','CBC','%','11.5-14.5','11.5-14.5',NULL,'{"red cell distribution width","rdw-cv"}'),
  ('Platelets','الصفائح الدموية','پلاکێت','CBC','K/uL','150-400','150-400','150-350','{"platelet count","thrombocytes","plt"}'),
  ('Neutrophils','العدلات','نێوتروفیل','CBC','%','40-70','40-70',NULL,'{"neutrophil count","segs","segmented neutrophils","polys"}'),
  ('Lymphocytes','الخلايا اللمفاوية','لیمفۆسایت','CBC','%','20-40','20-40',NULL,'{"lymphocyte count"}'),
  ('Monocytes','وحيدات','مۆنۆسایت','CBC','%','2-8','2-8',NULL,'{"monocyte count"}'),
  ('Eosinophils','الحمضات','ئیۆزینۆفیل','CBC','%','1-4','1-4',NULL,'{"eosinophil count","eos"}'),
  ('Basophils','القاعدات','باسۆفیل','CBC','%','0-1','0-1',NULL,'{"basophil count","baso"}'),
  ('Reticulocytes','الخلايا الشبكية','ریتیکیۆلۆسایت','CBC','%','0.5-1.5','0.5-1.5',NULL,'{"reticulocyte count","retic"}'),
  -- Lipid Panel
  ('Total Cholesterol','الكوليسترول الكلي','کۆلیستیرۆلی کۆی','Lipid','mg/dL','<200','<200','<180','{"cholesterol total","total chol","chol"}'),
  ('LDL Cholesterol','كوليسترول البروتين الدهني منخفض الكثافة','LDL','Lipid','mg/dL','<100','<100','<70','{"ldl","low density lipoprotein","ldl-c","ldl chol"}'),
  ('HDL Cholesterol','كوليسترول البروتين الدهني عالي الكثافة','HDL','Lipid','mg/dL','>40','>50','>60','{"hdl","high density lipoprotein","hdl-c","hdl chol"}'),
  ('Triglycerides','الدهون الثلاثية','تریگلیسیرید','Lipid','mg/dL','<150','<150','<100','{"trig","trigs","triglyceride"}'),
  ('Non-HDL Cholesterol','الكوليسترول غير عالي الكثافة','Non-HDL','Lipid','mg/dL','<130','<130','<100','{"non-hdl","non hdl chol"}'),
  ('VLDL','البروتين الدهني منخفض الكثافة جدا','VLDL','Lipid','mg/dL','5-40','5-40',NULL,'{"very low density lipoprotein","vldl cholesterol"}'),
  ('Lipoprotein(a)','البروتين الدهني أ','Lp(a)','Lipid','mg/dL','<30','<30','<14','{"lp(a)","lpa","lipoprotein a"}'),
  ('ApoB','البروتين الدهني B','ApoB','Lipid','mg/dL','<100','<100','<80','{"apolipoprotein b","apo b"}'),
  ('ApoA1','البروتين الدهني A1','ApoA1','Lipid','mg/dL','94-178','108-225',NULL,'{"apolipoprotein a1","apo a1","apo a-1"}'),
  -- Metabolic / CMP
  ('Glucose','الجلوكوز','گلوکۆز','Metabolic','mg/dL','70-99','70-99','72-90','{"blood glucose","fasting glucose","blood sugar","fbs","fbg"}'),
  ('BUN','نيتروجين اليوريا في الدم','BUN','Metabolic','mg/dL','6-20','6-20',NULL,'{"blood urea nitrogen","urea nitrogen","urea"}'),
  ('Creatinine','الكرياتينين','کریاتینین','Metabolic','mg/dL','0.74-1.35','0.59-1.04',NULL,'{"creat","serum creatinine","creatinine serum"}'),
  ('eGFR','معدل الترشيح الكبيبي المقدر','eGFR','Metabolic','mL/min/1.73m²','≥60','≥60','>90','{"estimated glomerular filtration rate","gfr","egfr"}'),
  ('Sodium','الصوديوم','سۆدیۆم','Metabolic','mEq/L','136-145','136-145',NULL,'{"na","serum sodium","na+"}'),
  ('Potassium','البوتاسيوم','پۆتاسیۆم','Metabolic','mEq/L','3.5-5.0','3.5-5.0','4.0-4.5','{"k","serum potassium","k+"}'),
  ('Chloride','الكلوريد','کلۆرید','Metabolic','mEq/L','98-107','98-107',NULL,'{"cl","serum chloride","cl-"}'),
  ('Bicarbonate','البيكربونات','بایکاربۆنات','Metabolic','mEq/L','22-29','22-29',NULL,'{"hco3","co2","carbon dioxide","bicarb"}'),
  ('Calcium','الكالسيوم','کالسیۆم','Metabolic','mg/dL','8.6-10.2','8.6-10.2',NULL,'{"ca","serum calcium","total calcium"}'),
  ('Phosphorus','الفوسفور','فۆسفۆر','Metabolic','mg/dL','2.5-4.5','2.5-4.5',NULL,'{"phos","phosphate","serum phosphorus"}'),
  ('Magnesium','المغنيسيوم','مگنیزیۆم','Metabolic','mg/dL','1.7-2.2','1.7-2.2','1.9-2.2','{"mg","serum magnesium","magnesium rbc"}'),
  ('Uric Acid','حمض اليوريك','ئیوریک ئاسید','Metabolic','mg/dL','3.4-7.0','2.4-6.0',NULL,'{"urate","serum uric acid","ua"}'),
  ('Albumin','الألبومين','ئەلبیومین','Metabolic','g/dL','3.4-5.4','3.4-5.4',NULL,'{"serum albumin","alb"}'),
  ('Total Protein','البروتين الكلي','پرۆتینی کۆی','Metabolic','g/dL','6.3-8.2','6.3-8.2',NULL,'{"total serum protein","tp"}'),
  -- Diabetes
  ('HbA1c','الهيموغلوبين الغليكوزيلاتي','HbA1c','Diabetes','%','<5.7','<5.7','<5.4','{"hemoglobin a1c","glycated hemoglobin","a1c","glycohemoglobin","hba1c"}'),
  ('Fasting Insulin','الأنسولين الصيامي','ئینسولینی مانگرتن','Diabetes','uIU/mL','2-25','2-25','2-8','{"insulin fasting","insulin level","insulin"}'),
  ('C-Peptide','الببتيد C','C-پپتاید','Diabetes','ng/mL','0.8-3.5','0.8-3.5',NULL,'{"c peptide","connecting peptide"}'),
  -- Liver
  ('ALT','ألانين أمينوترانسفيراز','ALT','Liver','U/L','7-56','7-45',NULL,'{"alanine aminotransferase","sgpt","alanine transaminase"}'),
  ('AST','أسبارتات أمينوترانسفيراز','AST','Liver','U/L','10-40','10-40',NULL,'{"aspartate aminotransferase","sgot","aspartate transaminase"}'),
  ('ALP','الفوسفاتاز القلوية','ALP','Liver','U/L','44-147','44-147',NULL,'{"alkaline phosphatase","alk phos","alkphos"}'),
  ('GGT','غاما غلوتاميل ترانسبيبتيداز','GGT','Liver','U/L','8-61','5-36',NULL,'{"gamma-glutamyl transferase","gamma gt","ggt"}'),
  ('Total Bilirubin','البيليروبين الكلي','بیلیرووبینی کۆی','Liver','mg/dL','0.2-1.2','0.2-1.2',NULL,'{"tbili","total bili","bilirubin total"}'),
  ('Direct Bilirubin','البيليروبين المباشر','بیلیرووبینی ڕاستەوخۆ','Liver','mg/dL','0.0-0.3','0.0-0.3',NULL,'{"direct bili","conjugated bilirubin","dbili"}'),
  -- Thyroid
  ('TSH','هرمون تحفيز الغدة الدرقية','TSH','Thyroid','mIU/L','0.4-4.0','0.4-4.0','0.5-2.5','{"thyroid stimulating hormone","thyrotropin"}'),
  ('Free T4','الثيروكسين الحر','T4ی ئازاد','Thyroid','ng/dL','0.8-1.8','0.8-1.8',NULL,'{"ft4","free thyroxine","free t4","thyroxine free"}'),
  ('Free T3','ثلاثي يودوثيرونين الحر','T3ی ئازاد','Thyroid','pg/mL','2.3-4.2','2.3-4.2','3.0-4.0','{"ft3","free triiodothyronine","free t3","t3 free"}'),
  ('Total T3','ثلاثي يودوثيرونين الكلي','T3ی کۆی','Thyroid','ng/dL','80-200','80-200',NULL,'{"t3 total","triiodothyronine total","t3"}'),
  ('Total T4','الثيروكسين الكلي','T4ی کۆی','Thyroid','ug/dL','5.0-12.0','5.0-12.0',NULL,'{"t4 total","thyroxine total","t4"}'),
  ('Anti-TPO Antibodies','أجسام مضادة لثيروكسيداز الغدة الدرقية','Anti-TPO','Thyroid','IU/mL','<35','<35',NULL,'{"anti-tpo","thyroid peroxidase antibodies","tpo antibodies","tpo ab"}'),
  ('Reverse T3','الثيروكسين العكسي','T3ی پشتگەرایی','Thyroid','ng/dL','10-24','10-24','10-15','{"rt3","reverse triiodothyronine","rt3"}'),
  -- Iron Studies
  ('Serum Iron','الحديد في الدم','ئاسنی خوێن','Iron','ug/dL','65-175','50-170',NULL,'{"iron serum","fe","iron level","iron"}'),
  ('TIBC','الطاقة الكلية لربط الحديد','TIBC','Iron','ug/dL','250-370','250-370',NULL,'{"total iron binding capacity","iron binding capacity"}'),
  ('Transferrin Saturation','تشبع الترانسفيرين','تراسفیرین','Iron','%','20-50','20-50','25-45','{"tsat","iron saturation","transferrin sat","% saturation"}'),
  ('Ferritin','الفيريتين','فیریتین','Iron','ng/mL','12-300','12-150','50-150','{"serum ferritin","ferritin level"}'),
  -- Vitamins & Minerals
  ('Vitamin D','فيتامين د','ڤیتامینی D','Vitamins','ng/mL','20-50','20-50','40-60','{"25-oh vitamin d","vitamin d 25-oh","25-hydroxyvitamin d","25(oh)d","vit d"}'),
  ('Vitamin B12','فيتامين ب12','ڤیتامینی B12','Vitamins','pg/mL','200-900','200-900','400-900','{"cobalamin","b12","cyanocobalamin","b-12"}'),
  ('Folate','حمض الفوليك','فۆلات','Vitamins','ng/mL','>3.0','>3.0','>10','{"folic acid","vitamin b9","serum folate","b9"}'),
  ('Zinc','الزنك','زینک','Vitamins','ug/dL','60-120','60-120','80-120','{"serum zinc","zn","plasma zinc"}'),
  ('Selenium','السيلينيوم','سیلینیۆم','Vitamins','ug/L','70-150','70-150','80-140','{"serum selenium","se"}'),
  ('Vitamin A','فيتامين أ','ڤیتامینی A','Vitamins','ug/dL','30-80','30-80',NULL,'{"retinol","vit a","retinol serum"}'),
  ('Vitamin E','فيتامين هـ','ڤیتامینی E','Vitamins','mg/L','5.5-17.0','5.5-17.0',NULL,'{"alpha-tocopherol","vit e","tocopherol"}'),
  ('Copper','النحاس','مس','Vitamins','ug/dL','70-140','80-155',NULL,'{"serum copper","cu"}'),
  ('Vitamin C','فيتامين ج','ڤیتامینی C','Vitamins','mg/dL','0.4-2.0','0.4-2.0',NULL,'{"ascorbic acid","vit c","ascorbate"}'),
  ('Vitamin K','فيتامين ك','ڤیتامینی K','Vitamins','ng/mL','0.2-3.2','0.2-3.2',NULL,'{"phylloquinone","vit k","k1"}'),
  -- Hormones
  ('Testosterone Total','التستوستيرون الكلي','تیستۆستیرۆنی کۆی','Hormones','ng/dL','300-1000','15-70',NULL,'{"total testosterone","testosterone","testo","t total"}'),
  ('Free Testosterone','التستوستيرون الحر','تیستۆستیرۆنی ئازاد','Hormones','pg/mL','9-30','0.3-1.9',NULL,'{"free testo","ft","testosterone free"}'),
  ('DHEA-S','ديهيدرو إبيأندروستيرون كبريتات','DHEA-S','Hormones','ug/dL','80-560','35-430',NULL,'{"dhea sulfate","dehydroepiandrosterone sulfate","dheas"}'),
  ('Estradiol','الاستراديول','ئیستیرادیۆل','Hormones','pg/mL','10-40','30-120',NULL,'{"e2","oestradiol","estradiol e2"}'),
  ('Progesterone','البروجسترون','پرۆجیستیرۆن','Hormones','ng/mL','0.3-1.2','1.7-27.0',NULL,'{"prog","serum progesterone"}'),
  ('LH','هرمون اللوتين','LH','Hormones','IU/L','1.7-8.6','2.4-12.6',NULL,'{"luteinizing hormone","lh level"}'),
  ('FSH','هرمون تحفيز الجريب','FSH','Hormones','IU/L','1.5-12.4','3.5-12.5',NULL,'{"follicle stimulating hormone","fsh level"}'),
  ('Prolactin','البرولاكتين','پرۆلاکتین','Hormones','ng/mL','2-18','2-29',NULL,'{"prl","serum prolactin"}'),
  ('SHBG','الغلوبولين المرتبط بالهرمونات الجنسية','SHBG','Hormones','nmol/L','10-57','16-119',NULL,'{"sex hormone binding globulin","sex hormone-binding globulin"}'),
  ('Cortisol','الكورتيزول','کۆرتیزۆل','Hormones','ug/dL','6-23','6-23','10-20','{"serum cortisol","morning cortisol","cortisol am"}'),
  ('ACTH','هرمون قشر الغدة الكظرية','ACTH','Hormones','pg/mL','10-60','10-60',NULL,'{"adrenocorticotropic hormone","corticotropin"}'),
  ('IGF-1','عامل النمو الشبيه بالأنسولين','IGF-1','Hormones','ng/mL','116-358','116-358',NULL,'{"insulin-like growth factor 1","igf1","somatomedin c"}'),
  ('Growth Hormone','هرمون النمو','هۆرمۆنی گەشەسەندن','Hormones','ng/mL','<0.4','<10',NULL,'{"gh","hgh","somatotropin","human growth hormone"}'),
  ('Aldosterone','الألدوستيرون','ئالدۆستیرۆن','Hormones','ng/dL','3-35','3-35',NULL,'{"aldo","serum aldosterone"}'),
  ('Renin','الرينين','ریناین','Hormones','ng/mL/hr','0.6-4.3','0.6-4.3',NULL,'{"plasma renin activity","pra","renin activity"}'),
  -- Inflammation / Cardiovascular
  ('CRP','بروتين سي التفاعلي','CRP','Inflammation','mg/L','<1.0','<1.0',NULL,'{"c-reactive protein","crp level"}'),
  ('hsCRP','بروتين سي التفاعلي عالي الحساسية','hsCRP','Inflammation','mg/L','<1.0','<1.0','<0.5','{"high sensitivity crp","hs-crp","highly sensitive crp","cardiac crp"}'),
  ('ESR','سرعة ترسب كريات الدم الحمراء','ESR','Inflammation','mm/hr','0-15','0-20',NULL,'{"erythrocyte sedimentation rate","sed rate","westergren"}'),
  ('Fibrinogen','الفيبرينوجين','فیبرینۆجین','Inflammation','mg/dL','200-400','200-400',NULL,'{"serum fibrinogen","factor i","fibrinogen level"}'),
  ('Homocysteine','الهوموسيستين','هۆمۆسیستین','Inflammation','umol/L','5-15','5-15','<10','{"hcy","plasma homocysteine"}'),
  ('BNP','الببتيد الناتريوريتيكي من النوع B','BNP','Cardiac','pg/mL','<100','<100',NULL,'{"b-type natriuretic peptide","brain natriuretic peptide","nt-probnp"}'),
  ('Troponin I','التروبونين I','ترۆپۆنین I','Cardiac','ng/mL','<0.04','<0.04',NULL,'{"cardiac troponin i","ctni","troponin","hs-troponin"}'),
  ('LDH','لاكتات ديهيدروجينيز','LDH','Cardiac','U/L','122-222','122-222',NULL,'{"lactate dehydrogenase","lactic dehydrogenase","ldh level"}'),
  -- Other
  ('PSA','المستضد النوعي للبروستاتا','PSA','Other','ng/mL','<4.0','N/A',NULL,'{"prostate specific antigen","total psa","psa level"}'),
  ('Omega-3 Index','مؤشر أوميغا-3','ئۆمیگا-3 ئیندێکس','Other','%','8-12','8-12','>8','{"epa+dha","omega 3 index","omega-3 fatty acids"}'),
  ('Methylmalonic Acid','حمض الميثيل مالونيك','میتیلمالۆنیک ئاسید','Other','nmol/L','0-378','0-378',NULL,'{"mma","methylmalonate","serum mma"}'),
  ('Ceruloplasmin','السيرولوبلاسمين','سیرووڵۆپلازمین','Other','mg/dL','20-35','20-35',NULL,'{"serum ceruloplasmin"}'),
  ('Prealbumin','البريألبومين','پرێئالبیومین','Other','mg/dL','18-35','18-35',NULL,'{"transthyretin","ttr","pa"}'),
  ('Chromium','الكروم','کرۆمیۆم','Other','ug/L','0.05-0.50','0.05-0.50',NULL,'{"serum chromium","cr"}'),
  ('Manganese','المنغنيز','مانگانیز','Other','ug/L','4-14','4-14',NULL,'{"serum manganese","mn"}'),
  ('Microalbumin (Urine)','الألبومين الدقيق في البول','مایکرۆئالبیومین','Other','mg/g Cr','<30','<30',NULL,'{"microalbuminuria","urine albumin","uacr","albumin creatinine ratio"}'),
  ('Vitamin D3','فيتامين د3','ڤیتامینی D3','Vitamins','ng/mL','20-50','20-50','40-60','{"cholecalciferol","1,25-dihydroxyvitamin d","calcitriol"}'),
  ('Anti-TG Antibodies','أجسام مضادة للثيروغلوبولين','Anti-TG','Thyroid','IU/mL','<20','<20',NULL,'{"thyroglobulin antibodies","tg ab","anti thyroglobulin"}')
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- RPC: insert_lab_work
-- Encrypts biomarkers + pdf_url, logs audit, returns new lab id.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.insert_lab_work(
  p_lab_date         date,
  p_source           text,
  p_raw_pdf_url      text    DEFAULT NULL,
  p_biomarkers_json  jsonb   DEFAULT '[]'::jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_id  uuid;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'insert_lab_work: not authenticated';
  END IF;

  IF p_source NOT IN ('pdf', 'photo', 'manual') THEN
    RAISE EXCEPTION 'insert_lab_work: invalid source %', p_source;
  END IF;

  INSERT INTO public.lab_work (
    user_id, lab_date, source,
    raw_pdf_url_enc, parsed_at, biomarkers_enc
  ) VALUES (
    v_uid,
    p_lab_date,
    p_source,
    CASE WHEN p_raw_pdf_url IS NOT NULL
         THEN public.vault_encrypt_text(p_raw_pdf_url)
         ELSE NULL
    END,
    now(),
    public.vault_encrypt_text(p_biomarkers_json::text)
  )
  RETURNING id INTO v_id;

  PERFORM public.vault_audit_access(
    p_accessed_user_id := v_uid,
    p_data_class       := 'lab_work',
    p_action           := 'write',
    p_resource_table   := 'lab_work',
    p_resource_id      := v_id,
    p_justification    := 'user_upload; source=' || p_source
  );

  RETURN v_id;
END;
$$;

COMMENT ON FUNCTION public.insert_lab_work IS
  'LABKIT entry point for storing a parsed lab upload. Encrypts biomarkers '
  'and pdf_url before persisting. Always goes through this RPC — never direct INSERT.';

-- ============================================================================
-- RPC: get_lab_detail
-- Self-read or coach-read (consent-checked). Decrypts + audits every call.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_lab_detail(p_lab_work_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_lab           public.lab_work%ROWTYPE;
  v_consent       public.lab_consent_grants%ROWTYPE;
  v_is_owner      boolean;
  v_justification text;
  v_bio_text      text;
BEGIN
  SELECT * INTO v_lab FROM public.lab_work WHERE id = p_lab_work_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'get_lab_detail: lab not found %', p_lab_work_id;
  END IF;

  v_is_owner := (v_lab.user_id = auth.uid());

  IF NOT v_is_owner THEN
    SELECT * INTO v_consent
    FROM public.lab_consent_grants
    WHERE lab_work_id = p_lab_work_id
      AND coach_user_id = auth.uid()
      AND revoked_at IS NULL;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'get_lab_detail: access denied — no active consent grant';
    END IF;
    v_justification := 'coach_view; consent_grant_id=' || v_consent.id::text;
  ELSE
    v_justification := 'self_view';
  END IF;

  PERFORM public.vault_audit_access(
    p_accessed_user_id := v_lab.user_id,
    p_data_class       := 'lab_work',
    p_action           := 'read',
    p_resource_table   := 'lab_work',
    p_resource_id      := p_lab_work_id,
    p_justification    := v_justification
  );

  v_bio_text := CASE
    WHEN v_lab.biomarkers_enc IS NOT NULL
    THEN public.vault_decrypt_text(v_lab.biomarkers_enc)
    ELSE '[]'
  END;

  RETURN jsonb_build_object(
    'id',         v_lab.id,
    'user_id',    v_lab.user_id,
    'lab_date',   v_lab.lab_date,
    'source',     v_lab.source,
    'parsed_at',  v_lab.parsed_at,
    'biomarkers', v_bio_text::jsonb,
    'created_at', v_lab.created_at
  );
END;
$$;

COMMENT ON FUNCTION public.get_lab_detail IS
  'Decrypts and returns lab detail. Self-read or coach-read with active consent. '
  'Always inserts an audit row. Never returns raw data to unauthenticated callers.';

-- ============================================================================
-- RPC: list_my_labs
-- Returns metadata only (no decryption). Audits the list access.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.list_my_labs()
RETURNS TABLE (
  id          uuid,
  lab_date    date,
  source      text,
  parsed_at   timestamptz,
  created_at  timestamptz,
  biomarker_count int
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'list_my_labs: not authenticated';
  END IF;

  PERFORM public.vault_audit_access(
    p_accessed_user_id := v_uid,
    p_data_class       := 'lab_work',
    p_action           := 'read',
    p_resource_table   := 'lab_work',
    p_justification    := 'list_my_labs'
  );

  RETURN QUERY
  SELECT
    lw.id,
    lw.lab_date,
    lw.source,
    lw.parsed_at,
    lw.created_at,
    CASE
      WHEN lw.biomarkers_enc IS NOT NULL
      THEN jsonb_array_length(
             public.vault_decrypt_text(lw.biomarkers_enc)::jsonb
           )
      ELSE 0
    END AS biomarker_count
  FROM public.lab_work lw
  WHERE lw.user_id = v_uid
  ORDER BY lw.lab_date DESC, lw.created_at DESC;
END;
$$;

-- ============================================================================
-- RPC: delete_lab_work  (hard delete — GDPR right to erasure)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.delete_lab_work(p_lab_work_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_lab public.lab_work%ROWTYPE;
BEGIN
  SELECT * INTO v_lab
  FROM public.lab_work
  WHERE id = p_lab_work_id AND user_id = auth.uid();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'delete_lab_work: not found or not authorized';
  END IF;

  DELETE FROM public.lab_work WHERE id = p_lab_work_id;
  -- lab_consent_grants cascade-deleted automatically
END;
$$;

-- ============================================================================
-- RPC: grant_lab_consent / revoke_lab_consent
-- ============================================================================

CREATE OR REPLACE FUNCTION public.grant_lab_consent(
  p_lab_work_id   uuid,
  p_coach_user_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_id  uuid;
BEGIN
  -- Must own the lab
  IF NOT EXISTS (
    SELECT 1 FROM public.lab_work
    WHERE id = p_lab_work_id AND user_id = v_uid
  ) THEN
    RAISE EXCEPTION 'grant_lab_consent: not authorized';
  END IF;

  INSERT INTO public.lab_consent_grants (lab_work_id, coach_user_id, granted_by)
  VALUES (p_lab_work_id, p_coach_user_id, v_uid)
  ON CONFLICT (lab_work_id, coach_user_id)
    DO UPDATE SET revoked_at = NULL, granted_at = now()
  RETURNING id INTO v_id;

  PERFORM public.vault_audit_access(
    p_accessed_user_id := v_uid,
    p_data_class       := 'lab_work',
    p_action           := 'share',
    p_resource_table   := 'lab_work',
    p_resource_id      := p_lab_work_id,
    p_justification    := 'consent_granted; coach=' || p_coach_user_id::text
  );

  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.revoke_lab_consent(
  p_lab_work_id   uuid,
  p_coach_user_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  UPDATE public.lab_consent_grants
  SET revoked_at = now()
  WHERE lab_work_id = p_lab_work_id
    AND coach_user_id = p_coach_user_id
    AND granted_by = v_uid
    AND revoked_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'revoke_lab_consent: no active grant found';
  END IF;
END;
$$;

-- ============================================================================
-- Rollback (run in reverse order)
-- ============================================================================
--
-- DROP FUNCTION IF EXISTS public.revoke_lab_consent(uuid, uuid);
-- DROP FUNCTION IF EXISTS public.grant_lab_consent(uuid, uuid);
-- DROP FUNCTION IF EXISTS public.delete_lab_work(uuid);
-- DROP FUNCTION IF EXISTS public.list_my_labs();
-- DROP FUNCTION IF EXISTS public.get_lab_detail(uuid);
-- DROP FUNCTION IF EXISTS public.insert_lab_work(date, text, text, jsonb);
-- DROP TABLE IF EXISTS public.lab_consent_grants;
-- DROP TABLE IF EXISTS public.lab_work;
-- DROP TABLE IF EXISTS public.biomarkers_dictionary;
