-- Fix Final Function Search Path Issues
-- This migration fixes the last 3 function search path warnings

SELECT '=== FIXING FINAL FUNCTION SEARCH PATH ISSUES ===' as section;

-- ========================================
-- FIX REMAINING FUNCTION SEARCH PATH ISSUES
-- ========================================

-- Fix is_admin function - there might be multiple versions
DO $$
DECLARE
    func_signature text;
BEGIN
    -- Get all function signatures for is_admin
    FOR func_signature IN 
        SELECT pg_get_function_identity_arguments(oid) as args
        FROM pg_proc 
        WHERE proname = 'is_admin' 
        AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
    LOOP
        BEGIN
            EXECUTE 'ALTER FUNCTION public.is_admin(' || func_signature || ') SET search_path = ''''';
            RAISE NOTICE 'Set search_path for is_admin function with args: %', func_signature;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Could not set search_path for is_admin with args %: %', func_signature, SQLERRM;
        END;
    END LOOP;
END $$;

-- Fix assign_user_role function - there might be multiple versions
DO $$
DECLARE
    func_signature text;
BEGIN
    -- Get all function signatures for assign_user_role
    FOR func_signature IN 
        SELECT pg_get_function_identity_arguments(oid) as args
        FROM pg_proc 
        WHERE proname = 'assign_user_role' 
        AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
    LOOP
        BEGIN
            EXECUTE 'ALTER FUNCTION public.assign_user_role(' || func_signature || ') SET search_path = ''''';
            RAISE NOTICE 'Set search_path for assign_user_role function with args: %', func_signature;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Could not set search_path for assign_user_role with args %: %', func_signature, SQLERRM;
        END;
    END LOOP;
END $$;

-- ========================================
-- ADDITIONAL SEARCH_PATH FIXES
-- ========================================

-- Try to set search_path for any remaining function signatures
DO $$
DECLARE
    func_record RECORD;
BEGIN
    -- Get all function signatures that might still need fixing
    FOR func_record IN 
        SELECT 
            proname as func_name,
            pg_get_function_identity_arguments(oid) as args
        FROM pg_proc 
        WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
        AND proname IN ('is_admin', 'assign_user_role')
        AND (proconfig IS NULL OR NOT ('search_path=' = ANY(proconfig)))
    LOOP
        BEGIN
            EXECUTE 'ALTER FUNCTION public.' || func_record.func_name || '(' || func_record.args || ') SET search_path = ''''';
            RAISE NOTICE 'Set search_path for % function with args: %', func_record.func_name, func_record.args;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Could not set search_path for % with args %: %', func_record.func_name, func_record.args, SQLERRM;
        END;
    END LOOP;
END $$;

-- ========================================
-- VERIFY FUNCTION SEARCH PATH SETTINGS
-- ========================================

-- Check if all functions now have proper search_path
SELECT '=== VERIFYING FUNCTION SEARCH PATH SETTINGS ===' as section;

SELECT 
    proname as function_name,
    pg_get_function_identity_arguments(oid) as arguments,
    CASE 
        WHEN proconfig IS NULL THEN '❌ No search_path set'
        WHEN 'search_path=' = ANY(proconfig) THEN '✅ search_path set to empty'
        ELSE '⚠️ search_path: ' || array_to_string(proconfig, ', ')
    END as search_path_status
FROM pg_proc 
WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
AND proname IN ('is_admin', 'assign_user_role')
ORDER BY proname, arguments;

SELECT '=== FINAL FUNCTION SEARCH PATH FIXES COMPLETE ===' as section;
