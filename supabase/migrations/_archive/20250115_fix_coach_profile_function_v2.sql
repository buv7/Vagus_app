-- Fix get_coach_profile_complete function - proper aggregation handling
-- This version properly handles GROUP BY and missing tables

CREATE OR REPLACE FUNCTION get_coach_profile_complete(p_coach_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
  v_profile_data JSONB;
  v_media_data JSONB;
  v_stats_data JSONB;
  v_completeness_data JSONB;
BEGIN
  -- Get profile data
  SELECT row_to_json(cp.*)::jsonb INTO v_profile_data
  FROM coach_profiles cp
  WHERE cp.coach_id = p_coach_id;

  -- If profile doesn't exist, create it
  IF v_profile_data IS NULL THEN
    INSERT INTO coach_profiles (coach_id, updated_at)
    VALUES (p_coach_id, NOW())
    ON CONFLICT (coach_id) DO NOTHING;

    -- Recursively call to get the created profile
    RETURN get_coach_profile_complete(p_coach_id);
  END IF;

  -- Get media data
  SELECT COALESCE(jsonb_agg(row_to_json(cm.*)::jsonb ORDER BY cm.created_at DESC), '[]'::jsonb)
  INTO v_media_data
  FROM coach_media cm
  WHERE cm.coach_id = p_coach_id;

  -- Get stats data (without reviews for now since table doesn't exist)
  SELECT jsonb_build_object(
    'client_count', COUNT(DISTINCT cc.client_id),
    'avg_rating', 0,
    'review_count', 0
  )
  INTO v_stats_data
  FROM coach_clients cc
  WHERE cc.coach_id = p_coach_id;

  -- If no stats, return zeros
  IF v_stats_data IS NULL THEN
    v_stats_data := jsonb_build_object(
      'client_count', 0,
      'avg_rating', 0,
      'review_count', 0
    );
  END IF;

  -- Calculate completeness
  SELECT jsonb_build_object(
    'hasDisplayName', cp.display_name IS NOT NULL,
    'hasUsername', cp.username IS NOT NULL,
    'hasHeadline', cp.headline IS NOT NULL,
    'hasBio', cp.bio IS NOT NULL AND LENGTH(cp.bio) > 0,
    'hasSpecialties', COALESCE(array_length(cp.specialties, 1), 0) > 0,
    'hasIntroVideo', cp.intro_video_url IS NOT NULL,
    'mediaCount', (SELECT COUNT(*) FROM coach_media WHERE coach_id = p_coach_id)
  )
  INTO v_completeness_data
  FROM coach_profiles cp
  WHERE cp.coach_id = p_coach_id;

  -- Build final result
  v_result := jsonb_build_object(
    'profile', v_profile_data,
    'media', v_media_data,
    'stats', v_stats_data,
    'completeness', v_completeness_data
  );

  RETURN v_result;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_coach_profile_complete(UUID) TO authenticated;

COMMENT ON FUNCTION get_coach_profile_complete IS 'Returns complete coach profile data including profile, media, stats, and completeness metrics';
