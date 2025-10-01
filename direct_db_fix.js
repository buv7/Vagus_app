// Direct Database Fix using Pooler Connection
// This script connects directly to your Supabase database to fix auth issues

const { Client } = require('pg');

// Your pooler connection string
const connectionString = 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres';

const client = new Client({
  connectionString: connectionString,
  ssl: { rejectUnauthorized: false }
});

async function fixDatabase() {
  console.log('🔧 Connecting to Supabase database to apply fixes...\n');

  try {
    await client.connect();
    console.log('✅ Connected to database successfully\n');

    // 1. Enable required extensions
    console.log('1. Enabling required extensions...');
    await client.query('CREATE EXTENSION IF NOT EXISTS pgcrypto;');
    await client.query('CREATE EXTENSION IF NOT EXISTS "uuid-ossp";');
    console.log('   ✅ Extensions enabled');

    // 2. Fix profiles table
    console.log('\n2. Fixing profiles table...');
    
    // Drop existing profiles table and recreate
    await client.query('DROP TABLE IF EXISTS public.profiles CASCADE;');
    console.log('   ✅ Dropped existing profiles table');

    // Create new profiles table
    await client.query(`
      CREATE TABLE public.profiles (
        id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
        name text,
        email text UNIQUE,
        role text DEFAULT 'client' CHECK (role IN ('client', 'coach', 'admin')),
        avatar_url text,
        created_at timestamptz DEFAULT now(),
        updated_at timestamptz DEFAULT now()
      )
    `);
    console.log('   ✅ Created profiles table');

    // Create indexes
    await client.query('CREATE INDEX idx_profiles_role ON public.profiles(role);');
    await client.query('CREATE INDEX idx_profiles_email ON public.profiles(email);');
    console.log('   ✅ Created indexes');

    // Enable RLS
    await client.query('ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;');
    console.log('   ✅ Enabled RLS');

    // 3. Create RLS policies
    console.log('\n3. Creating RLS policies...');
    
    // Drop existing policies
    await client.query('DROP POLICY IF EXISTS profiles_select_own ON public.profiles;');
    await client.query('DROP POLICY IF EXISTS profiles_update_own ON public.profiles;');
    await client.query('DROP POLICY IF EXISTS profiles_insert_own ON public.profiles;');
    await client.query('DROP POLICY IF EXISTS profiles_select_admin ON public.profiles;');
    console.log('   ✅ Dropped existing policies');

    // Create new policies
    await client.query(`
      CREATE POLICY profiles_select_own ON public.profiles
        FOR SELECT TO authenticated
        USING (id = auth.uid())
    `);
    console.log('   ✅ Created select policy');

    await client.query(`
      CREATE POLICY profiles_update_own ON public.profiles
        FOR UPDATE TO authenticated
        USING (id = auth.uid())
        WITH CHECK (id = auth.uid())
    `);
    console.log('   ✅ Created update policy');

    await client.query(`
      CREATE POLICY profiles_insert_own ON public.profiles
        FOR INSERT TO authenticated
        WITH CHECK (id = auth.uid())
    `);
    console.log('   ✅ Created insert policy');

    await client.query(`
      CREATE POLICY profiles_select_admin ON public.profiles
        FOR SELECT TO authenticated
        USING (
          EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'admin'
          )
        )
    `);
    console.log('   ✅ Created admin select policy');

    // 4. Create profile trigger function
    console.log('\n4. Creating profile trigger function...');
    
    await client.query(`
      CREATE OR REPLACE FUNCTION public.handle_new_user()
      RETURNS TRIGGER AS $$
      BEGIN
        INSERT INTO public.profiles (id, email, name, role)
        VALUES (
          NEW.id,
          NEW.email,
          COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
          'client'
        );
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql SECURITY DEFINER
    `);
    console.log('   ✅ Created trigger function');

    // Create trigger
    await client.query('DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;');
    await client.query(`
      CREATE TRIGGER on_auth_user_created
        AFTER INSERT ON auth.users
        FOR EACH ROW EXECUTE FUNCTION public.handle_new_user()
    `);
    console.log('   ✅ Created trigger');

    // 5. Create missing tables
    console.log('\n5. Creating missing tables...');
    
    // Create ai_usage table
    await client.query(`
      CREATE TABLE IF NOT EXISTS public.ai_usage (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
        feature text NOT NULL,
        tokens_used integer DEFAULT 0,
        cost_usd numeric(10,4) DEFAULT 0,
        created_at timestamptz DEFAULT now()
      )
    `);
    console.log('   ✅ Created ai_usage table');

    await client.query('ALTER TABLE public.ai_usage ENABLE ROW LEVEL SECURITY;');
    await client.query(`
      CREATE POLICY ai_usage_own ON public.ai_usage
        FOR ALL TO authenticated
        USING (user_id = auth.uid())
    `);
    console.log('   ✅ Created ai_usage RLS policy');

    // Create user_devices table
    await client.query(`
      CREATE TABLE IF NOT EXISTS public.user_devices (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
        device_id text,
        platform text CHECK (platform IN ('ios', 'android', 'web')),
        created_at timestamptz DEFAULT now(),
        updated_at timestamptz DEFAULT now(),
        UNIQUE(user_id, device_id)
      )
    `);
    console.log('   ✅ Created user_devices table');

    await client.query('ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;');
    await client.query(`
      CREATE POLICY user_devices_own ON public.user_devices
        FOR ALL TO authenticated
        USING (user_id = auth.uid())
    `);
    console.log('   ✅ Created user_devices RLS policy');

    // 6. Fix existing users without profiles
    console.log('\n6. Creating profiles for existing users...');
    
    const usersWithoutProfiles = await client.query(`
      SELECT u.id, u.email, u.raw_user_meta_data
      FROM auth.users u
      LEFT JOIN public.profiles p ON u.id = p.id
      WHERE p.id IS NULL
    `);
    
    console.log(`   Found ${usersWithoutProfiles.rows.length} users without profiles`);
    
    for (const user of usersWithoutProfiles.rows) {
      try {
        await client.query(`
          INSERT INTO public.profiles (id, email, name, role)
          VALUES ($1, $2, $3, 'client')
        `, [
          user.id,
          user.email,
          user.raw_user_meta_data?.name || user.email
        ]);
        console.log(`   ✅ Created profile for ${user.email}`);
      } catch (error) {
        console.log(`   ❌ Failed to create profile for ${user.email}: ${error.message}`);
      }
    }

    // 7. Clean up orphaned profiles
    console.log('\n7. Cleaning up orphaned profiles...');
    
    const orphanedProfiles = await client.query(`
      SELECT p.id, p.email
      FROM public.profiles p
      LEFT JOIN auth.users u ON p.id = u.id
      WHERE u.id IS NULL
    `);
    
    console.log(`   Found ${orphanedProfiles.rows.length} orphaned profiles`);
    
    if (orphanedProfiles.rows.length > 0) {
      await client.query(`
        DELETE FROM public.profiles 
        WHERE id NOT IN (SELECT id FROM auth.users)
      `);
      console.log('   ✅ Cleaned up orphaned profiles');
    }

    // 8. Create helper functions
    console.log('\n8. Creating helper functions...');
    
    await client.query(`
      CREATE OR REPLACE FUNCTION public.get_user_role(user_id uuid)
      RETURNS text AS $$
      BEGIN
        RETURN (
          SELECT role 
          FROM public.profiles 
          WHERE id = user_id
        );
      END;
      $$ LANGUAGE plpgsql SECURITY DEFINER
    `);
    console.log('   ✅ Created get_user_role function');

    await client.query(`
      CREATE OR REPLACE FUNCTION public.is_admin(user_id uuid)
      RETURNS boolean AS $$
      BEGIN
        RETURN (
          SELECT role = 'admin' 
          FROM public.profiles 
          WHERE id = user_id
        );
      END;
      $$ LANGUAGE plpgsql SECURITY DEFINER
    `);
    console.log('   ✅ Created is_admin function');

    // 9. Final verification
    console.log('\n9. Final verification...');
    
    const finalCheck = await client.query(`
      SELECT 
        (SELECT COUNT(*) FROM auth.users) as total_users,
        (SELECT COUNT(*) FROM public.profiles) as total_profiles,
        (SELECT COUNT(*) FROM auth.users u LEFT JOIN public.profiles p ON u.id = p.id WHERE p.id IS NULL) as users_without_profiles,
        (SELECT COUNT(*) FROM public.profiles p LEFT JOIN auth.users u ON p.id = u.id WHERE u.id IS NULL) as orphaned_profiles
    `);
    
    const stats = finalCheck.rows[0];
    console.log(`   Total users: ${stats.total_users}`);
    console.log(`   Total profiles: ${stats.total_profiles}`);
    console.log(`   Users without profiles: ${stats.users_without_profiles}`);
    console.log(`   Orphaned profiles: ${stats.orphaned_profiles}`);

    if (stats.users_without_profiles == 0 && stats.orphaned_profiles == 0) {
      console.log('\n   ✅ Database is now healthy!');
      console.log('   🎉 Authentication should work properly now');
    } else {
      console.log('\n   ⚠️  Some issues remain, but major fixes applied');
    }

  } catch (error) {
    console.error('❌ Database fix error:', error.message);
    console.error('Stack trace:', error.stack);
  } finally {
    await client.end();
    console.log('\n🔌 Database connection closed');
  }
}

// Run the fix
fixDatabase().catch(console.error);
