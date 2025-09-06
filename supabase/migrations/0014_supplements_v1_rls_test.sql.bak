-- RLS Smoke Tests for Supplements v1 Migration
-- This file documents the Row Level Security policies and provides test queries
-- Run these queries to verify RLS is working correctly

-- ===== TEST SETUP =====
-- These queries should be run as different users to test RLS policies

-- ===== SUPPLEMENTS TABLE RLS TESTS =====

-- Test 1: Users can view their own supplements
-- Expected: Should return supplements where created_by = current_user OR client_id = current_user
-- Query: SELECT * FROM supplements;

-- Test 2: Users can create supplements
-- Expected: Should succeed when created_by = current_user
-- Query: INSERT INTO supplements (name, dosage, created_by) VALUES ('Test Supplement', '1 pill', auth.uid());

-- Test 3: Users can update their own supplements
-- Expected: Should succeed when created_by = current_user
-- Query: UPDATE supplements SET name = 'Updated Name' WHERE created_by = auth.uid();

-- Test 4: Users can delete their own supplements
-- Expected: Should succeed when created_by = current_user
-- Query: DELETE FROM supplements WHERE created_by = auth.uid();

-- ===== SUPPLEMENT SCHEDULES TABLE RLS TESTS =====

-- Test 5: Users can view schedules for supplements they can see
-- Expected: Should return schedules for supplements where user has access
-- Query: SELECT * FROM supplement_schedules;

-- Test 6: Users can create schedules
-- Expected: Should succeed when created_by = current_user
-- Query: INSERT INTO supplement_schedules (supplement_id, schedule_type, frequency, times_per_day, created_by) 
--        VALUES ('supplement-uuid', 'daily', '2x daily', 2, auth.uid());

-- Test 7: Users can update their own schedules
-- Expected: Should succeed when created_by = current_user
-- Query: UPDATE supplement_schedules SET frequency = '3x daily' WHERE created_by = auth.uid();

-- Test 8: Users can delete their own schedules
-- Expected: Should succeed when created_by = current_user
-- Query: DELETE FROM supplement_schedules WHERE created_by = auth.uid();

-- ===== SUPPLEMENT LOGS TABLE RLS TESTS =====

-- Test 9: Users can view their own logs
-- Expected: Should return logs where user_id = current_user
-- Query: SELECT * FROM supplement_logs;

-- Test 10: Users can create logs for themselves
-- Expected: Should succeed when user_id = current_user
-- Query: INSERT INTO supplement_logs (supplement_id, user_id, status) 
--        VALUES ('supplement-uuid', auth.uid(), 'taken');

-- Test 11: Users can update their own logs
-- Expected: Should succeed when user_id = current_user
-- Query: UPDATE supplement_logs SET notes = 'Updated note' WHERE user_id = auth.uid();

-- Test 12: Users can delete their own logs
-- Expected: Should succeed when user_id = current_user
-- Query: DELETE FROM supplement_logs WHERE user_id = auth.uid();

-- ===== COACH ACCESS TESTS =====

-- Test 13: Coaches can view supplements created for their clients
-- Expected: Should return supplements where client_id matches coach's clients
-- Query: SELECT s.* FROM supplements s 
--        JOIN coach_clients cc ON s.client_id = cc.client_id 
--        WHERE cc.coach_id = auth.uid();

-- ===== FUNCTION TESTS =====

-- Test 14: get_next_supplement_due function
-- Expected: Should return next due time for a supplement
-- Query: SELECT get_next_supplement_due('supplement-uuid', auth.uid());

-- Test 15: get_supplements_due_today function
-- Expected: Should return supplements due today for current user
-- Query: SELECT * FROM get_supplements_due_today(auth.uid());

-- ===== NEGATIVE TESTS =====

-- Test 16: Users cannot view other users' supplements
-- Expected: Should return empty or error when trying to access other user's data
-- Query: SELECT * FROM supplements WHERE created_by != auth.uid() AND client_id != auth.uid();

-- Test 17: Users cannot create supplements for other users
-- Expected: Should fail when created_by != current_user
-- Query: INSERT INTO supplements (name, dosage, created_by) VALUES ('Test', '1 pill', 'other-user-uuid');

-- Test 18: Users cannot update other users' supplements
-- Expected: Should fail when created_by != current_user
-- Query: UPDATE supplements SET name = 'Hacked' WHERE created_by != auth.uid();

-- Test 19: Users cannot delete other users' supplements
-- Expected: Should fail when created_by != current_user
-- Query: DELETE FROM supplements WHERE created_by != auth.uid();

-- ===== NOTES =====
-- 
-- To run these tests:
-- 1. Connect as different users (client, coach, admin)
-- 2. Execute the queries and verify expected behavior
-- 3. Check that RLS policies are enforced correctly
-- 4. Verify that functions work as expected
--
-- Expected behavior:
-- - Users can only access their own data
-- - Coaches can access their clients' data
-- - Functions respect RLS policies
-- - No unauthorized access is possible
