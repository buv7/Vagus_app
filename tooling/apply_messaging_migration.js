const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// Use DATABASE_URL from environment
const dbUrl = process.env.DATABASE_URL || 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres';

// Parse connection string to get Supabase URL and construct service key
const supabaseUrl = 'https://kydrpnrmqbedjflklgue.supabase.co';
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt5ZHJwbnJtcWJlZGpmbGtsZ3VlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQyMjUxODAsImV4cCI6MjA2OTgwMTE4MH0.qlpGUiy17IbDsfgOf3-F2XBjOajjwxfy2NLMlUZWaqo';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function applyMessagingMigration() {
  console.log('Checking if conversations table exists...\n');

  const { data, error } = await supabase
    .from('conversations')
    .select('count')
    .limit(1);

  if (error && error.code === '42P01') {
    console.log('❌ conversations table does not exist');
    console.log('\n📋 Reading migration file...');

    const migrationPath = path.join(__dirname, '../supabase/migrations/20250115120031_messaging_system.sql');

    if (!fs.existsSync(migrationPath)) {
      console.error('❌ Migration file not found:', migrationPath);
      process.exit(1);
    }

    const migrationSQL = fs.readFileSync(migrationPath, 'utf8');

    console.log('\n⚠️  Cannot apply migration directly through Supabase JS client.');
    console.log('The messaging tables need to be created manually.\n');
    console.log('Please run ONE of the following options:\n');
    console.log('Option 1 - Using Supabase CLI:');
    console.log('  supabase db execute --file supabase/migrations/20250115120031_messaging_system.sql\n');
    console.log('Option 2 - Using Supabase Dashboard:');
    console.log('  1. Go to: https://supabase.com/dashboard/project/kydrpnrmqbedjflklgue/sql/new');
    console.log('  2. Copy and paste the contents of: supabase/migrations/20250115120031_messaging_system.sql');
    console.log('  3. Click "Run"\n');
    console.log('Option 3 - Direct DB connection (if you have psql):');
    console.log('  psql "$DATABASE_URL" -f supabase/migrations/20250115120031_messaging_system.sql\n');

    process.exit(1);
  } else if (error) {
    console.log('❌ Error checking table:', error.message);
    process.exit(1);
  } else {
    console.log('✅ conversations table already exists!');
    console.log('\nChecking messages table...');

    const { error: msgError } = await supabase
      .from('messages')
      .select('count')
      .limit(1);

    if (msgError) {
      console.log('❌ messages table does not exist');
      console.log('Migration may be incomplete. Please apply it manually.');
    } else {
      console.log('✅ messages table exists!');
      console.log('\n✅ All messaging tables are properly configured!');
    }
  }
}

applyMessagingMigration()
  .then(() => process.exit(0))
  .catch(err => {
    console.error('❌ Error:', err);
    process.exit(1);
  });
