const { Client } = require('pg');

const client = new Client({
  connectionString: 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres',
  ssl: { rejectUnauthorized: false }
});

async function testPassword() {
  try {
    await client.connect();
    console.log('🔍 Testing password for client2@vagus.com...\n');
    
    // Test the password "client12"
    const result = await client.query(`
      SELECT (encrypted_password = crypt('client12', encrypted_password)) as password_match
      FROM auth.users 
      WHERE email = 'client2@vagus.com'
    `);
    
    if (result.rows.length === 0) {
      console.log('❌ User not found');
      return;
    }
    
    const passwordMatch = result.rows[0].password_match;
    console.log('Password "client12" test:', passwordMatch ? '✅ CORRECT' : '❌ WRONG');
    
    if (!passwordMatch) {
      console.log('\n💡 Testing common passwords...');
      
      const commonPasswords = [
        'password123',
        'Password123!', 
        '123456',
        'admin123',
        'test123',
        'password',
        'client123',
        'Client123!',
        'vagus123',
        'Vagus123!'
      ];
      
      for (const pwd of commonPasswords) {
        try {
          const test = await client.query(`
            SELECT (encrypted_password = crypt($1, encrypted_password)) as match
            FROM auth.users 
            WHERE email = 'client2@vagus.com'
          `, [pwd]);
          
          if (test.rows[0].match) {
            console.log(`✅ CORRECT PASSWORD FOUND: "${pwd}"`);
            console.log('\n🎉 Use this password to log in!');
            return;
          }
        } catch (error) {
          // Continue to next password
        }
      }
      
      console.log('❌ None of the common passwords worked');
      console.log('\n💡 Try these alternatives:');
      console.log('   - Check if you remember the original password');
      console.log('   - Try creating a new account instead');
      console.log('   - Use one of the other test accounts');
    } else {
      console.log('\n🎉 Password "client12" is CORRECT!');
      console.log('✅ You should be able to log in with:');
      console.log('   Email: client2@vagus.com');
      console.log('   Password: client12');
    }
    
  } catch (error) {
    console.log('❌ Error:', error.message);
  } finally {
    await client.end();
    console.log('\n🔌 Database connection closed');
  }
}

testPassword();
