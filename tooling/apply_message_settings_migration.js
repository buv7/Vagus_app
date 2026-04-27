const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

async function applyMigration() {
  const connectionString = 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres';
  
  const client = new Client({
    connectionString,
    ssl: { rejectUnauthorized: false }
  });

  try {
    console.log('Connecting to database...');
    await client.connect();
    console.log('Connected successfully!');

    // Read the migration file
    const migrationPath = path.join(__dirname, '..', 'supabase', 'migrations', '20250121200000_message_settings_table.sql');
    const migrationSQL = fs.readFileSync(migrationPath, 'utf8');

    console.log('\nApplying message_settings migration...');
    
    // Split the SQL by statements (handling $$ function bodies)
    // We'll execute the whole thing as one transaction
    await client.query('BEGIN');
    
    try {
      await client.query(migrationSQL);
      await client.query('COMMIT');
      console.log('\n✅ Migration applied successfully!');
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    }

    // Verify the table was created
    console.log('\nVerifying table structure...');
    const result = await client.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_name = 'message_settings'
      ORDER BY ordinal_position;
    `);

    if (result.rows.length > 0) {
      console.log('\n📋 Table columns:');
      result.rows.forEach(row => {
        console.log(`  - ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
      });
    } else {
      console.log('⚠️ Table not found - migration may have failed');
    }

    // Check RLS policies
    const policies = await client.query(`
      SELECT policyname, cmd, qual 
      FROM pg_policies 
      WHERE tablename = 'message_settings';
    `);

    if (policies.rows.length > 0) {
      console.log('\n🔒 RLS Policies:');
      policies.rows.forEach(row => {
        console.log(`  - ${row.policyname} (${row.cmd})`);
      });
    }

    console.log('\n✅ Migration completed and verified!');

  } catch (error) {
    console.error('\n❌ Migration failed:', error.message);
    if (error.detail) console.error('Detail:', error.detail);
    if (error.hint) console.error('Hint:', error.hint);
    process.exit(1);
  } finally {
    await client.end();
    console.log('\nConnection closed.');
  }
}

applyMigration();
