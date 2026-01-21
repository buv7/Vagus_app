-- OCR Cardio Enhancement Migration
-- Adds support for OCR capture strategy in health_merges

-- Update health_merges table to allow 'ocr_capture' strategy
ALTER TABLE health_merges 
DROP CONSTRAINT IF EXISTS health_merges_strategy_check;

ALTER TABLE health_merges 
ADD CONSTRAINT health_merges_strategy_check 
CHECK (strategy IN ('overlap70', 'manual', 'ocr_capture'));

-- Add created_at to ocr_cardio_logs if it doesn't have default
ALTER TABLE ocr_cardio_logs 
ALTER COLUMN created_at SET DEFAULT now();

-- Add index for faster OCR workout queries
CREATE INDEX IF NOT EXISTS idx_health_workouts_source 
ON health_workouts(user_id, source);

-- Add raw_ocr_text column to ocr_cardio_logs for debugging/auditing
ALTER TABLE ocr_cardio_logs 
ADD COLUMN IF NOT EXISTS raw_ocr_text TEXT;

-- Update the admin policy to also allow reading OCR workouts
CREATE POLICY IF NOT EXISTS "Admins can read all health workouts" ON health_workouts
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Add comment for documentation
COMMENT ON COLUMN health_workouts.source IS 'Source of workout data: manual_entry, ocr_capture, healthkit, healthconnect, googlefit, hms';
COMMENT ON COLUMN ocr_cardio_logs.raw_ocr_text IS 'Raw OCR text from AI vision for debugging/auditing';
