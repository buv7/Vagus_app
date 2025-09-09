-- Seed admin user for development/testing
-- This will add the current authenticated user as an admin
-- Run this in the Supabase SQL editor after creating an account

-- Uncomment and run this in the SQL editor to make yourself an admin:
-- insert into public.admin_users(user_id) values (auth.uid());

-- Or if you know the user ID, you can insert it directly:
-- insert into public.admin_users(user_id) values ('your-user-id-here');

-- To check if you're an admin:
-- select * from public.admin_users where user_id = auth.uid();
