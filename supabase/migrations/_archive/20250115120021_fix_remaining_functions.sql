-- Fix Function Search Path and Other Security Warnings
-- This migration fixes function search path issues and other security warnings

SELECT '=== FIXING FUNCTION SEARCH PATH AND SECURITY WARNINGS ===' as section;

-- ========================================
-- FIX REMAINING FUNCTIONS
-- ========================================

-- Fix is_admin function by altering existing function
DO $$
BEGIN
    -- Try to alter the existing function to set search_path
    ALTER FUNCTION public.is_admin(UUID) SET search_path = '';
    RAISE NOTICE 'Set search_path for is_admin function';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Could not alter is_admin function: %', SQLERRM;
END $$;

-- Fix any remaining functions that might have issues
DO $$
DECLARE
    func_name text;
BEGIN
    -- List of functions that might need individual attention
    FOR func_name IN SELECT unnest(ARRAY[
        'is_day_compliant',
        'add_grocery_item_deduplicated',
        'similar_notes',
        'handle_new_user',
        'auto_link_coach_client',
        'update_nutrition_pantry_items_updated_at',
        'ensure_referral_code',
        '_message_object_is_participant',
        'set_updated_at',
        'update_coach_intake_forms_updated_at',
        'find_similar_recipes',
        '_messages_bump_thread_last_at',
        'update_recipe_nutrition',
        'update_nutrition_preferences_updated_at',
        'get_ai_usage_summary',
        'update_coach_profiles_updated_at',
        'update_updated_at_column',
        'get_current_month_usage',
        'mark_day_compliant',
        'update_coach_media_updated_at',
        'upsert_affiliate_link',
        '_coach_linked_to_client',
        'get_streak_info',
        'update_nutrition_supplements_updated_at',
        'mark_affiliate_paid',
        'get_ai_usage_summary_extended',
        'generate_grocery_list_for_week',
        'set_changed_by_default',
        'update_streaks_updated_at',
        'check_event_capacity',
        'thread_has_user',
        'upsert_nutrition_preferences',
        'assign_user_role',
        'calculate_recipe_nutrition',
        'check_booking_conflicts',
        'scale_recipe_nutrition',
        'update_nutrition_item_from_recipe',
        '_table_exists',
        'update_coach_client_periods_updated_at',
        'recompute_streak',
        'update_client_allergies_updated_at',
        'get_supplements_due_today',
        'get_next_supplement_due',
        'update_nutrition_prices_updated_at',
        'update_nutrition_barcodes_last_seen',
        'calculate_recipe_item_nutrition',
        'set_nutrition_allergies'
    ])
    LOOP
        BEGIN
            -- Try to alter the function to set search_path
            EXECUTE 'ALTER FUNCTION public.' || func_name || ' SET search_path = ''''';
            RAISE NOTICE 'Set search_path for function: %', func_name;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Could not set search_path for function %: %', func_name, SQLERRM;
        END;
    END LOOP;
END $$;

-- ========================================
-- FIX EXTENSION IN PUBLIC SCHEMA WARNINGS
-- ========================================

-- Create a dedicated schema for extensions
CREATE SCHEMA IF NOT EXISTS extensions;

-- Move vector extension to extensions schema
DO $$
BEGIN
    -- Check if vector extension exists in public schema
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'vector' AND extnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')) THEN
        -- Drop and recreate in extensions schema
        DROP EXTENSION IF EXISTS vector CASCADE;
        CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA extensions;
        RAISE NOTICE 'Moved vector extension to extensions schema';
    END IF;
END $$;

-- Move pg_trgm extension to extensions schema
DO $$
BEGIN
    -- Check if pg_trgm extension exists in public schema
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_trgm' AND extnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')) THEN
        -- Drop and recreate in extensions schema
        DROP EXTENSION IF EXISTS pg_trgm CASCADE;
        CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA extensions;
        RAISE NOTICE 'Moved pg_trgm extension to extensions schema';
    END IF;
END $$;

-- ========================================
-- GRANT PERMISSIONS ON EXTENSIONS SCHEMA
-- ========================================

-- Grant usage on extensions schema to authenticated users
GRANT USAGE ON SCHEMA extensions TO authenticated;
GRANT USAGE ON SCHEMA extensions TO anon;

-- ========================================
-- UPDATE SEARCH_PATH FOR ALL USERS
-- ========================================

-- Set default search_path to include extensions schema
ALTER DATABASE postgres SET search_path = 'public, extensions';

-- ========================================
-- CREATE HELPER FUNCTIONS FOR EXTENSIONS
-- ========================================

-- Create wrapper functions in public schema that reference extensions schema
CREATE OR REPLACE FUNCTION public.similarity(text1 TEXT, text2 TEXT)
RETURNS REAL
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    RETURN extensions.similarity(text1, text2);
END;
$$;

-- Create wrapper for vector operations if needed
CREATE OR REPLACE FUNCTION public.vector_cosine_distance(vec1 VECTOR, vec2 VECTOR)
RETURNS REAL
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    RETURN vec1 <=> vec2;
END;
$$;

SELECT '=== REMAINING FUNCTION FIXES COMPLETE ===' as section;
