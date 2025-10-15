const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_KEY');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkAndCreateTables() {
  console.log('Checking if conversations table exists...');

  const { data, error } = await supabase
    .from('conversations')
    .select('count')
    .limit(1);

  if (error && error.code === '42P01') {
    console.log('❌ conversations table does not exist');
    console.log('\nCreating messaging tables...\n');

    // Read the migration file
    const fs = require('fs');
    const path = require('path');
    const migrationPath = path.join(__dirname, '../supabase/migrations/20250115120031_messaging_system.sql');

    if (!fs.existsSync(migrationPath)) {
      console.error('Migration file not found:', migrationPath);
      process.exit(1);
    }

    const migrationSQL = fs.readFileSync(migrationPath, 'utf8');
    console.log('Executing migration...');

    // Execute the migration using RPC
    const { data: result, error: execError } = await supabase.rpc('exec_sql', {
      sql_query: migrationSQL
    });

    if (execError) {
      console.error('Error executing migration:', execError);
      console.log('\n⚠️  Manual migration required. Please run:');
      console.log('   supabase db push --include-all');
      console.log('\nOr apply the migration file manually from:');
      console.log('   supabase/migrations/20250115120031_messaging_system.sql');
      process.exit(1);
    }

    console.log('✅ Migration executed successfully!');

    // Verify the table now exists
    const { error: verifyError } = await supabase
      .from('conversations')
      .select('count')
      .limit(1);

    if (verifyError) {
      console.error('❌ Table still does not exist after migration:', verifyError);
      process.exit(1);
    } else {
      console.log('✅ conversations table verified');
    }
  } else if (error) {
    console.log('Error checking table:', error);
    process.exit(1);
  } else {
    console.log('✅ conversations table already exists');
  }
}

checkAndCreateTables()
  .then(() => {
    console.log('\n✅ All checks passed!');
    process.exit(0);
  })
  .catch(err => {
    console.error('❌ Error:', err);
    process.exit(1);
  });
