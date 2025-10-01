// Direct Database Diagnosis using Pooler Connection
// This script connects directly to your Supabase database to diagnose auth issues

const { Client } = require('pg');

// Your pooler connection string
const connectionString = 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres';

const client = new Client({
  connectionString: connectionString,
  ssl: { rejectUnauthorized: false }
});

async function diagnoseDatabase() {
  console.log('🔍 Connecting to Supabase database...\n');

  try {
    await client.connect();
    console.log('✅ Connected to database successfully\n');

    // 1. Check auth.users table
    console.log('1. Checking auth.users table...');
    const authUsersResult = await client.query(`
      SELECT 
        COUNT(*) as total_users,
        COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END) as confirmed_users,
        COUNT(CASE WHEN email_confirmed_at IS NULL THEN 1 END) as unconfirmed_users
      FROM auth.users
    `);
    console.log('   Total users:', authUsersResult.rows[0].total_users);
    console.log('   Confirmed users:', authUsersResult.rows[0].confirmed_users);
    console.log('   Unconfirmed users:', authUsersResult.rows[0].unconfirmed_users);

    // Show recent users
    const recentUsers = await client.query(`
      SELECT id, email, email_confirmed_at, created_at, last_sign_in_at
      FROM auth.users
      ORDER BY created_at DESC
      LIMIT 5
    `);
    console.log('   Recent users:');
    recentUsers.rows.forEach(user => {
      console.log(`     - ${user.email} (${user.email_confirmed_at ? 'confirmed' : 'unconfirmed'})`);
    });

    // 2. Check profiles table
    console.log('\n2. Checking profiles table...');
    const profilesResult = await client.query(`
      SELECT 
        COUNT(*) as total_profiles,
        COUNT(CASE WHEN role = 'client' THEN 1 END) as client_profiles,
        COUNT(CASE WHEN role = 'coach' THEN 1 END) as coach_profiles,
        COUNT(CASE WHEN role = 'admin' THEN 1 END) as admin_profiles
      FROM public.profiles
    `);
    console.log('   Total profiles:', profilesResult.rows[0].total_profiles);
    console.log('   Client profiles:', profilesResult.rows[0].client_profiles);
    console.log('   Coach profiles:', profilesResult.rows[0].coach_profiles);
    console.log('   Admin profiles:', profilesResult.rows[0].admin_profiles);

    // 3. Check for orphaned profiles
    console.log('\n3. Checking for orphaned profiles...');
    const orphanedProfiles = await client.query(`
      SELECT COUNT(*) as orphaned_count
      FROM public.profiles p
      LEFT JOIN auth.users u ON p.id = u.id
      WHERE u.id IS NULL
    `);
    console.log('   Orphaned profiles:', orphanedProfiles.rows[0].orphaned_count);

    // 4. Check for users without profiles
    console.log('\n4. Checking for users without profiles...');
    const usersWithoutProfiles = await client.query(`
      SELECT COUNT(*) as users_without_profiles
      FROM auth.users u
      LEFT JOIN public.profiles p ON u.id = p.id
      WHERE p.id IS NULL
    `);
    console.log('   Users without profiles:', usersWithoutProfiles.rows[0].users_without_profiles);

    // Show users without profiles
    if (usersWithoutProfiles.rows[0].users_without_profiles > 0) {
      const usersWithoutProfilesList = await client.query(`
        SELECT u.id, u.email, u.email_confirmed_at, u.created_at
        FROM auth.users u
        LEFT JOIN public.profiles p ON u.id = p.id
        WHERE p.id IS NULL
        LIMIT 5
      `);
      console.log('   Users without profiles:');
      usersWithoutProfilesList.rows.forEach(user => {
        console.log(`     - ${user.email} (${user.email_confirmed_at ? 'confirmed' : 'unconfirmed'})`);
      });
    }

    // 5. Check RLS policies
    console.log('\n5. Checking RLS policies...');
    const rlsPolicies = await client.query(`
      SELECT policyname, permissive, roles, cmd
      FROM pg_policies 
      WHERE schemaname = 'public' 
      AND tablename = 'profiles'
      ORDER BY policyname
    `);
    console.log('   RLS policies for profiles table:');
    rlsPolicies.rows.forEach(policy => {
      console.log(`     - ${policy.policyname} (${policy.cmd})`);
    });

    // 6. Check table structure
    console.log('\n6. Checking profiles table structure...');
    const tableStructure = await client.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_name = 'profiles' 
      AND table_schema = 'public'
      ORDER BY ordinal_position
    `);
    console.log('   Profiles table columns:');
    tableStructure.rows.forEach(column => {
      console.log(`     - ${column.column_name}: ${column.data_type} (${column.is_nullable === 'YES' ? 'nullable' : 'not null'})`);
    });

    // 7. Check for triggers
    console.log('\n7. Checking for profile creation triggers...');
    const triggers = await client.query(`
      SELECT trigger_name, event_manipulation, action_statement
      FROM information_schema.triggers 
      WHERE event_object_table = 'users'
      AND event_object_schema = 'auth'
    `);
    console.log('   Triggers on auth.users:');
    if (triggers.rows.length === 0) {
      console.log('     - No triggers found (this might be the problem!)');
    } else {
      triggers.rows.forEach(trigger => {
        console.log(`     - ${trigger.trigger_name}: ${trigger.event_manipulation}`);
      });
    }

    // 8. Check auth configuration
    console.log('\n8. Checking auth configuration...');
    const authConfig = await client.query(`
      SELECT key, value
      FROM auth.config
      WHERE key IN ('SITE_URL', 'DISABLE_SIGNUP', 'ENABLE_EMAIL_CONFIRMATIONS', 'ENABLE_PHONE_CONFIRMATIONS')
    `);
    console.log('   Auth configuration:');
    authConfig.rows.forEach(config => {
      console.log(`     - ${config.key}: ${config.value}`);
    });

    // 9. Summary and recommendations
    console.log('\n9. Summary and Recommendations:');
    const totalUsers = parseInt(authUsersResult.rows[0].total_users);
    const totalProfiles = parseInt(profilesResult.rows[0].total_profiles);
    const usersWithoutProfilesCount = parseInt(usersWithoutProfiles.rows[0].users_without_profiles);
    const orphanedCount = parseInt(orphanedProfiles.rows[0].orphaned_count);

    console.log(`   Total users: ${totalUsers}`);
    console.log(`   Total profiles: ${totalProfiles}`);
    console.log(`   Users without profiles: ${usersWithoutProfilesCount}`);
    console.log(`   Orphaned profiles: ${orphanedCount}`);

    if (usersWithoutProfilesCount > 0) {
      console.log('\n   🚨 ISSUE FOUND: Users exist without profiles!');
      console.log('   💡 SOLUTION: Run the fix_auth_issues.sql script to create missing profiles');
    }

    if (orphanedCount > 0) {
      console.log('\n   🚨 ISSUE FOUND: Orphaned profiles exist!');
      console.log('   💡 SOLUTION: Clean up orphaned profiles');
    }

    if (triggers.rows.length === 0) {
      console.log('\n   🚨 ISSUE FOUND: No profile creation trigger!');
      console.log('   💡 SOLUTION: Create trigger to auto-create profiles for new users');
    }

    if (totalUsers === totalProfiles && usersWithoutProfilesCount === 0 && orphanedCount === 0) {
      console.log('\n   ✅ Database looks healthy!');
      console.log('   💡 If login still fails, check:');
      console.log('      - Email confirmation requirements');
      console.log('      - Password requirements');
      console.log('      - Network connectivity');
    }

  } catch (error) {
    console.error('❌ Database connection error:', error.message);
  } finally {
    await client.end();
    console.log('\n🔌 Database connection closed');
  }
}

// Run the diagnosis
diagnoseDatabase().catch(console.error);
