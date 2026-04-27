-- Create a comprehensive database function to get all coach profile data
-- Save as supabase/migrations/20250115_unified_coach_profile.sql

CREATE OR REPLACE FUNCTION get_coach_profile_complete(p_coach_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'profile', row_to_json(cp.*),
    'media', COALESCE((
      SELECT jsonb_agg(row_to_json(cm.*))
      FROM coach_media cm
      WHERE cm.coach_id = p_coach_id
      ORDER BY cm.created_at DESC
    ), '[]'::jsonb),
    'stats', COALESCE((
      SELECT row_to_json(s.*)
      FROM (
        SELECT
          COUNT(DISTINCT cc.client_id) as client_count,
          COALESCE(AVG(cr.rating), 0) as avg_rating,
          COUNT(DISTINCT cr.id) as review_count
        FROM coach_clients cc
        LEFT JOIN coach_reviews cr ON cr.coach_id = cc.coach_id
        WHERE cc.coach_id = p_coach_id
      ) s
    ), '{}'::jsonb),
    'completeness', jsonb_build_object(
      'hasDisplayName', cp.display_name IS NOT NULL,
      'hasUsername', cp.username IS NOT NULL,
      'hasHeadline', cp.headline IS NOT NULL,
      'hasBio', cp.bio IS NOT NULL AND LENGTH(cp.bio) > 0,
      'hasSpecialties', COALESCE(array_length(cp.specialties, 1), 0) > 0,
      'hasIntroVideo', cp.intro_video_url IS NOT NULL,
      'mediaCount', (
        SELECT COUNT(*) FROM coach_media WHERE coach_id = p_coach_id
      )
    )
  ) INTO v_result
  FROM coach_profiles cp
  WHERE cp.coach_id = p_coach_id;

  -- Create empty profile if doesn't exist
  IF v_result IS NULL THEN
    INSERT INTO coach_profiles (coach_id, created_at, updated_at)
    VALUES (p_coach_id, NOW(), NOW())
    ON CONFLICT (coach_id) DO NOTHING;

    -- Recursively call to get the created profile
    RETURN get_coach_profile_complete(p_coach_id);
  END IF;

  RETURN v_result;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_coach_profile_complete(UUID) TO authenticated;
