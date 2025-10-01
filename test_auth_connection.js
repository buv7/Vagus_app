// Test Supabase Authentication Connection
// Run this with: node test_auth_connection.js

const { createClient } = require('@supabase/supabase-js');

// Your Supabase credentials
const supabaseUrl = 'https://kydrpnrmqbedjflklgue.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt5ZHJwbnJtcWJlZGpmbGtsZ3VlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQyMjUxODAsImV4cCI6MjA2OTgwMTE4MH0.qlpGUiy17IbDsfgOf3-F2XBjOajjwxfy2NLMlUZWaqo';

// Create Supabase client
const supabase = createClient(supabaseUrl, supabaseKey);

async function testAuthentication() {
  console.log('🔍 Testing Supabase Authentication...\n');

  try {
    // Test 1: Check if we can connect to Supabase
    console.log('1. Testing Supabase connection...');
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    
    if (authError) {
      console.log('❌ Auth error:', authError.message);
    } else {
      console.log('✅ Supabase connection successful');
      console.log('   Current user:', user ? user.email : 'No user logged in');
    }

    // Test 2: Check profiles table
    console.log('\n2. Testing profiles table access...');
    const { data: profiles, error: profilesError } = await supabase
      .from('profiles')
      .select('*')
      .limit(5);

    if (profilesError) {
      console.log('❌ Profiles table error:', profilesError.message);
    } else {
      console.log('✅ Profiles table accessible');
      console.log('   Found', profiles.length, 'profiles');
    }

    // Test 3: Check auth users (this might fail due to RLS)
    console.log('\n3. Testing auth.users access...');
    const { data: users, error: usersError } = await supabase
      .from('auth.users')
      .select('*')
      .limit(5);

    if (usersError) {
      console.log('⚠️  Auth.users access restricted (this is normal):', usersError.message);
    } else {
      console.log('✅ Auth.users accessible');
      console.log('   Found', users.length, 'users');
    }

    // Test 4: Try to sign up a test user
    console.log('\n4. Testing user signup...');
    const testEmail = `test-${Date.now()}@example.com`;
    const testPassword = 'TestPassword123!';
    
    const { data: signupData, error: signupError } = await supabase.auth.signUp({
      email: testEmail,
      password: testPassword,
    });

    if (signupError) {
      console.log('❌ Signup error:', signupError.message);
    } else {
      console.log('✅ Signup successful');
      console.log('   User ID:', signupData.user?.id);
      console.log('   Email confirmed:', signupData.user?.email_confirmed_at ? 'Yes' : 'No');
      
      // Test 5: Try to sign in with the test user
      console.log('\n5. Testing user signin...');
      const { data: signinData, error: signinError } = await supabase.auth.signInWithPassword({
        email: testEmail,
        password: testPassword,
      });

      if (signinError) {
        console.log('❌ Signin error:', signinError.message);
      } else {
        console.log('✅ Signin successful');
        console.log('   User ID:', signinData.user?.id);
        console.log('   Session valid:', signinData.session ? 'Yes' : 'No');
        
        // Test 6: Check if profile was created
        console.log('\n6. Testing profile creation...');
        const { data: userProfile, error: profileError } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', signinData.user.id)
          .single();

        if (profileError) {
          console.log('❌ Profile error:', profileError.message);
        } else {
          console.log('✅ Profile found');
          console.log('   Profile role:', userProfile.role);
          console.log('   Profile email:', userProfile.email);
        }
      }
    }

    // Test 7: Check database tables
    console.log('\n7. Testing database tables...');
    const tables = ['profiles', 'ai_usage', 'user_devices'];
    
    for (const table of tables) {
      const { data, error } = await supabase
        .from(table)
        .select('*')
        .limit(1);
      
      if (error) {
        console.log(`❌ ${table} table error:`, error.message);
      } else {
        console.log(`✅ ${table} table accessible`);
      }
    }

  } catch (error) {
    console.log('❌ Unexpected error:', error.message);
  }
}

// Run the test
testAuthentication().then(() => {
  console.log('\n🏁 Authentication test completed');
}).catch(error => {
  console.log('❌ Test failed:', error.message);
});
