-- Final correct version of get_coach_profile_complete function
-- Joins with profiles table for username and avatar, uses correct schema

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
  -- Get combined profile data from coach_profiles and profiles tables
  SELECT jsonb_build_object(
    'coach_id', cp.coach_id,
    'display_name', cp.display_name,
    'headline', cp.headline,
    'bio', cp.bio,
    'specialties', cp.specialties,
    'intro_video_url', cp.intro_video_url,
    'updated_at', cp.updated_at,
    'username', p.username,
    'avatarUrl', p.avatar_url,
    'email', p.email
  )
  INTO v_profile_data
  FROM coach_profiles cp
  LEFT JOIN profiles p ON p.id = cp.coach_id
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
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', cm.id,
      'coach_id', cm.coach_id,
      'title', cm.title,
      'description', cm.description,
      'media_url', cm.media_url,
      'media_type', cm.media_type,
      'visibility', cm.visibility,
      'is_approved', cm.is_approved,
      'created_at', cm.created_at,
      'updated_at', cm.updated_at
    ) ORDER BY cm.created_at DESC
  ), '[]'::jsonb)
  INTO v_media_data
  FROM coach_media cm
  WHERE cm.coach_id = p_coach_id;

  -- Get stats data (without reviews since table doesn't exist)
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
    'hasUsername', p.username IS NOT NULL,
    'hasHeadline', cp.headline IS NOT NULL,
    'hasBio', cp.bio IS NOT NULL AND LENGTH(cp.bio) > 0,
    'hasSpecialties', COALESCE(array_length(cp.specialties, 1), 0) > 0,
    'hasIntroVideo', cp.intro_video_url IS NOT NULL,
    'mediaCount', (SELECT COUNT(*) FROM coach_media WHERE coach_id = p_coach_id)
  )
  INTO v_completeness_data
  FROM coach_profiles cp
  LEFT JOIN profiles p ON p.id = cp.coach_id
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

COMMENT ON FUNCTION get_coach_profile_complete IS 'Returns complete coach profile data including profile (joined with profiles table for username/avatar), media, stats, and completeness metrics';
