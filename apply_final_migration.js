const fs = require('fs');
const { Client } = require('pg');

async function applyMigration() {
  const client = new Client({
    connectionString: 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres',
    ssl: { rejectUnauthorized: false }
  });

  try {
    console.log('Connecting to Supabase...');
    await client.connect();
    console.log('Connected successfully!');

    // Read the migration file
    const migration = fs.readFileSync('supabase/migrations/20251013120001_safe_schema_updates.sql', 'utf8');
    
    console.log('Applying safe schema updates...');
    await client.query(migration);
    console.log('✅ Migration applied successfully!');

  } catch (error) {
    console.error('❌ Error applying migration:', error.message);
    console.error('Details:', error.detail || error.hint || '');
    process.exit(1);
  } finally {
    await client.end();
  }
}

applyMigration();

