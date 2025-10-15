const { Client } = require('pg');

const connectionString = 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres';

const client = new Client({
  connectionString,
  ssl: {
    rejectUnauthorized: false
  },
  connectionTimeoutMillis: 30000,
  query_timeout: 60000
});

async function checkFKs() {
  try {
    await client.connect();

    console.log('Checking foreign keys using pg_catalog:');
    console.log('');

    const query = `
      SELECT
        conname AS constraint_name,
        conrelid::regclass AS table_name,
        confrelid::regclass AS referenced_table,
        pg_get_constraintdef(oid) AS constraint_definition
      FROM pg_constraint
      WHERE conrelid = 'user_coach_links'::regclass
        AND contype = 'f'
      ORDER BY conname;
    `;

    const result = await client.query(query);
    console.table(result.rows);
    console.log('');
    console.log(`Found ${result.rows.length} foreign key constraints`);

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await client.end();
  }
}

checkFKs().catch(console.error);
