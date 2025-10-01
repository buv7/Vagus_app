const { Client } = require('pg');

const client = new Client({
  connectionString: 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres',
  ssl: { rejectUnauthorized: false }
});

async function checkAuthDetails() {
  try {
    await client.connect();
    console.log('🔍 Checking authentication details...\n');
    
    // Check user details with roles
    const userDetails = await client.query(`
      SELECT 
        u.id, 
        u.email, 
        u.email_confirmed_at, 
        u.last_sign_in_at,
        u.created_at,
        p.role,
        p.name
      FROM auth.users u
      LEFT JOIN public.profiles p ON u.id = p.id
      ORDER BY u.created_at DESC
    `);
    
    console.log('👥 All users in database:');
    userDetails.rows.forEach((user, index) => {
      console.log(`   ${index + 1}. ${user.email}`);
      console.log(`      - Role: ${user.role || 'No role'}`);
      console.log(`      - Name: ${user.name || 'No name'}`);
      console.log(`      - Email confirmed: ${user.email_confirmed_at ? 'Yes' : 'No'}`);
      console.log(`      - Last sign in: ${user.last_sign_in_at || 'Never'}`);
      console.log('');
    });
    
    // Check recent auth events
    try {
      const authEvents = await client.query(`
        SELECT event_type, COUNT(*) as count
        FROM auth.audit_log_entries 
        WHERE created_at > NOW() - INTERVAL '24 hours'
        GROUP BY event_type
        ORDER BY count DESC
      `);
      console.log('📊 Recent auth events (last 24 hours):');
      authEvents.rows.forEach(event => {
        console.log(`   - ${event.event_type}: ${event.count} times`);
      });
    } catch (error) {
      console.log('⚠️  Could not check auth events:', error.message);
    }
    
    // Check if there are any authentication issues
    console.log('\n🔍 Authentication health check:');
    
    const totalUsers = userDetails.rows.length;
    const usersWithProfiles = userDetails.rows.filter(u => u.role).length;
    const confirmedUsers = userDetails.rows.filter(u => u.email_confirmed_at).length;
    
    console.log(`   Total users: ${totalUsers}`);
    console.log(`   Users with profiles: ${usersWithProfiles}`);
    console.log(`   Confirmed users: ${confirmedUsers}`);
    
    if (usersWithProfiles === totalUsers) {
      console.log('   ✅ All users have profiles');
    } else {
      console.log('   ❌ Some users missing profiles');
    }
    
    if (confirmedUsers === totalUsers) {
      console.log('   ✅ All users confirmed');
    } else {
      console.log('   ❌ Some users not confirmed');
    }
    
    // Check for potential login issues
    console.log('\n🚨 Potential login issues:');
    
    const unconfirmedUsers = userDetails.rows.filter(u => !u.email_confirmed_at);
    if (unconfirmedUsers.length > 0) {
      console.log('   ❌ Unconfirmed users (may need email confirmation):');
      unconfirmedUsers.forEach(user => {
        console.log(`      - ${user.email}`);
      });
    }
    
    const usersWithoutRoles = userDetails.rows.filter(u => !u.role);
    if (usersWithoutRoles.length > 0) {
      console.log('   ❌ Users without roles:');
      usersWithoutRoles.forEach(user => {
        console.log(`      - ${user.email}`);
      });
    }
    
    // Test credentials for each user
    console.log('\n🧪 Test credentials for login:');
    userDetails.rows.forEach((user, index) => {
      console.log(`   ${index + 1}. Email: ${user.email}`);
      console.log(`      - Try password: "password123" or "Password123!"`);
      console.log(`      - Role: ${user.role || 'No role'}`);
      console.log(`      - Confirmed: ${user.email_confirmed_at ? 'Yes' : 'No'}`);
      console.log('');
    });
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
    console.log('🔌 Database connection closed');
  }
}

checkAuthDetails();
