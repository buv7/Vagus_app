-- Calendar & Booking QA Verification Tests
-- Section 9: RLS & RPC Verification

-- Test 1: Verify linked client can insert event with coach_id
-- Expected: Should succeed if coach_clients link exists
-- Run this as a linked client:
/*
INSERT INTO public.events (
  created_by, coach_id, title, start_at, end_at, 
  tags, visibility, status, is_booking_slot, capacity
) VALUES (
  'client-uuid-here', 'coach-uuid-here', 'Test Session',
  '2024-01-15 10:00:00+00', '2024-01-15 11:00:00+00',
  ARRAY['session'], 'private', 'scheduled', true, 1
);
*/

-- Test 2: Verify unlinked client is blocked from inserting with coach_id
-- Expected: Should fail with RLS policy violation
-- Run this as an unlinked client:
/*
INSERT INTO public.events (
  created_by, coach_id, title, start_at, end_at,
  tags, visibility, status, is_booking_slot, capacity
) VALUES (
  'unlinked-client-uuid', 'coach-uuid-here', 'Blocked Session',
  '2024-01-15 14:00:00+00', '2024-01-15 15:00:00+00',
  ARRAY['session'], 'private', 'scheduled', true, 1
);
*/

-- Test 3: Verify capacity and conflict RPC functions
-- Expected: check_event_capacity returns true/false, check_booking_conflicts returns true/false

-- Test capacity function with empty event
SELECT check_event_capacity('00000000-0000-0000-0000-000000000000');
-- Expected: false (event doesn't exist)

-- Test capacity function with event that has capacity
-- First create a test event:
/*
INSERT INTO public.events (
  id, created_by, title, start_at, end_at,
  tags, visibility, status, is_booking_slot, capacity
) VALUES (
  'test-event-001', 'coach-uuid-here', 'Test Capacity Event',
  '2024-01-15 16:00:00+00', '2024-01-15 17:00:00+00',
  ARRAY['session'], 'private', 'scheduled', true, 3
);

-- Then test capacity:
SELECT check_event_capacity('test-event-001');
-- Expected: true (0 participants < 3 capacity)
*/

-- Test conflict function with overlapping times
/*
SELECT check_booking_conflicts(
  'user-uuid-here',
  '2024-01-15 10:30:00+00',
  '2024-01-15 11:30:00+00'
);
-- Expected: true if user has event 10:00-11:00, false otherwise
*/

-- Cleanup test data
-- DELETE FROM public.events WHERE id = 'test-event-001';
