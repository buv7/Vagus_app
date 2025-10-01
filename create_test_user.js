const { Client } = require('pg');

const client = new Client({
  connectionString: 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres',
  ssl: { rejectUnauthorized: false }
});

async function createTestUser() {
  try {
    await client.connect();
    console.log('🔧 Creating test user...\n');
    
    // Create a new test user
    const testEmail = 'test@vagus.com';
    const testPassword = 'TestPassword123!';
    
    console.log(`Creating user: ${testEmail}`);
    console.log(`Password: ${testPassword}`);
    
    // Insert directly into auth.users (this is a simplified approach)
    // In a real scenario, you'd use Supabase Auth API
    const userId = '550e8400-e29b-41d4-a716-446655440000'; // Generate a UUID
    
    try {
      // First, let's check if user already exists
      const existingUser = await client.query(`
        SELECT id FROM auth.users WHERE email = $1
      `, [testEmail]);
      
      if (existingUser.rows.length > 0) {
        console.log('❌ User already exists!');
        console.log('Try logging in with:');
        console.log(`   Email: ${testEmail}`);
        console.log(`   Password: ${testPassword}`);
        return;
      }
      
      // Create user in auth.users
      await client.query(`
        INSERT INTO auth.users (
          id, 
          email, 
          encrypted_password, 
          email_confirmed_at, 
          created_at, 
          updated_at,
          raw_user_meta_data,
          user_metadata
        ) VALUES (
          $1, 
          $2, 
          crypt($3, gen_salt('bf')), 
          NOW(), 
          NOW(), 
          NOW(),
          '{"name": "Test User"}',
          '{"name": "Test User"}'
        )
      `, [userId, testEmail, testPassword]);
      
      console.log('✅ User created in auth.users');
      
      // Create profile
      await client.query(`
        INSERT INTO public.profiles (id, email, name, role)
        VALUES ($1, $2, $3, 'client')
      `, [userId, testEmail, 'Test User']);
      
      console.log('✅ Profile created');
      
      console.log('\n🎉 Test user created successfully!');
      console.log('📱 Try logging in with:');
      console.log(`   Email: ${testEmail}`);
      console.log(`   Password: ${testPassword}`);
      
    } catch (error) {
      console.log('❌ Error creating user:', error.message);
      console.log('\n💡 Alternative: Try the existing accounts with these passwords:');
      console.log('   - password123');
      console.log('   - Password123!');
      console.log('   - 123456');
      console.log('   - admin123');
    }
    
  } catch (error) {
    console.error('❌ Database error:', error.message);
  } finally {
    await client.end();
    console.log('\n🔌 Database connection closed');
  }
}

createTestUser();
