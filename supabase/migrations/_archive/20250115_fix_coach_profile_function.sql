-- Fix get_coach_profile_complete function to handle missing coach_reviews table gracefully
-- This version checks if tables exist before using them

CREATE OR REPLACE FUNCTION get_coach_profile_complete(p_coach_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
  v_has_reviews_table BOOLEAN;
BEGIN
  -- Check if coach_reviews table exists
  SELECT EXISTS (
    SELECT FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name = 'coach_reviews'
  ) INTO v_has_reviews_table;

  -- Build result with conditional joins
  IF v_has_reviews_table THEN
    -- Full query with reviews
    SELECT jsonb_build_object(
      'profile', row_to_json(cp.*),
      'media', COALESCE((
        SELECT jsonb_agg(row_to_json(cm.*))
        FROM coach_media cm
        WHERE cm.coach_id = p_coach_id
        ORDER BY cm.created_at DESC
      ), '[]'::jsonb),
      'stats', COALESCE((
        SELECT jsonb_build_object(
          'client_count', COUNT(DISTINCT cc.client_id),
          'avg_rating', COALESCE(AVG(cr.rating), 0),
          'review_count', COUNT(DISTINCT cr.id)
        )
        FROM coach_clients cc
        LEFT JOIN coach_reviews cr ON cr.coach_id = cc.coach_id
        WHERE cc.coach_id = p_coach_id
      ), jsonb_build_object('client_count', 0, 'avg_rating', 0, 'review_count', 0)),
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
  ELSE
    -- Query without reviews
    SELECT jsonb_build_object(
      'profile', row_to_json(cp.*),
      'media', COALESCE((
        SELECT jsonb_agg(row_to_json(cm.*))
        FROM coach_media cm
        WHERE cm.coach_id = p_coach_id
        ORDER BY cm.created_at DESC
      ), '[]'::jsonb),
      'stats', COALESCE((
        SELECT jsonb_build_object(
          'client_count', COUNT(DISTINCT cc.client_id),
          'avg_rating', 0,
          'review_count', 0
        )
        FROM coach_clients cc
        WHERE cc.coach_id = p_coach_id
      ), jsonb_build_object('client_count', 0, 'avg_rating', 0, 'review_count', 0)),
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
  END IF;

  -- Create empty profile if doesn't exist
  IF v_result IS NULL THEN
    INSERT INTO coach_profiles (coach_id, updated_at)
    VALUES (p_coach_id, NOW())
    ON CONFLICT (coach_id) DO NOTHING;

    -- Recursively call to get the created profile
    RETURN get_coach_profile_complete(p_coach_id);
  END IF;

  RETURN v_result;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_coach_profile_complete(UUID) TO authenticated;
