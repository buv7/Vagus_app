-- =====================================================
-- PHASE J: RPC FUNCTION - REFRESH FATIGUE SNAPSHOT
-- =====================================================
-- Upserts a fatigue snapshot for a user/date
-- Note: Actual fatigue computation happens in Flutter app
-- This RPC only handles the database upsert operation
-- Created: 2025-01-22

CREATE OR REPLACE FUNCTION public.refresh_fatigue_snapshot(
  p_user_id uuid,
  p_date date DEFAULT current_date,
  p_fatigue_score int DEFAULT 0,
  p_cns_score int DEFAULT 0,
  p_local_score int DEFAULT 0,
  p_joint_score int DEFAULT 0,
  p_volume_load numeric DEFAULT 0,
  p_hard_sets int DEFAULT 0,
  p_near_failure_sets int DEFAULT 0,
  p_high_fatigue_intensifier_uses int DEFAULT 0,
  p_muscle_fatigue jsonb DEFAULT '{}'::jsonb,
  p_intensifier_fatigue jsonb DEFAULT '{}'::jsonb,
  p_notes jsonb DEFAULT '{}'::jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result jsonb;
  v_inserted boolean := false;
  v_updated boolean := false;
BEGIN
  -- Check permissions: user can only upsert their own snapshots
  -- Coaches/admins handled by RLS policies on SELECT
  IF p_user_id != auth.uid() AND NOT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Permission denied: can only upsert own snapshots';
  END IF;

  -- Upsert snapshot
  INSERT INTO public.fatigue_snapshots (
    user_id,
    snapshot_date,
    fatigue_score,
    cns_score,
    local_score,
    joint_score,
    volume_load,
    hard_sets,
    near_failure_sets,
    high_fatigue_intensifier_uses,
    muscle_fatigue,
    intensifier_fatigue,
    notes
  ) VALUES (
    p_user_id,
    p_date,
    p_fatigue_score,
    p_cns_score,
    p_local_score,
    p_joint_score,
    p_volume_load,
    p_hard_sets,
    p_near_failure_sets,
    p_high_fatigue_intensifier_uses,
    p_muscle_fatigue,
    p_intensifier_fatigue,
    p_notes
  )
  ON CONFLICT (user_id, snapshot_date)
  DO UPDATE SET
    fatigue_score = EXCLUDED.fatigue_score,
    cns_score = EXCLUDED.cns_score,
    local_score = EXCLUDED.local_score,
    joint_score = EXCLUDED.joint_score,
    volume_load = EXCLUDED.volume_load,
    hard_sets = EXCLUDED.hard_sets,
    near_failure_sets = EXCLUDED.near_failure_sets,
    high_fatigue_intensifier_uses = EXCLUDED.high_fatigue_intensifier_uses,
    muscle_fatigue = EXCLUDED.muscle_fatigue,
    intensifier_fatigue = EXCLUDED.intensifier_fatigue,
    notes = EXCLUDED.notes,
    updated_at = now()
  RETURNING id INTO v_result;

  -- Determine if inserted or updated
  SELECT EXISTS (
    SELECT 1 FROM public.fatigue_snapshots
    WHERE user_id = p_user_id AND snapshot_date = p_date
      AND created_at = updated_at
  ) INTO v_inserted;

  v_updated := NOT v_inserted;

  -- Return result
  SELECT jsonb_build_object(
    'inserted', v_inserted,
    'updated', v_updated,
    'snapshot', row_to_json(fs.*)
  )
  FROM public.fatigue_snapshots fs
  WHERE fs.user_id = p_user_id AND fs.snapshot_date = p_date
  INTO v_result;

  RETURN v_result;
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION public.refresh_fatigue_snapshot TO authenticated;
