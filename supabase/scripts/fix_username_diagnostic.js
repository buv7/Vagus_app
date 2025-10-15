const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const connectionString = process.argv[2] || 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres';

async function runDiagnostics() {
  const client = new Client({
    connectionString,
    ssl: {
      rejectUnauthorized: false
    },
    connectionTimeoutMillis: 30000,
    query_timeout: 60000
  });

  try {
    console.log('Connecting to Supabase database...');
    await client.connect();
    console.log('Connected successfully!\n');

    // Query 1: Check coach_profiles schema
    console.log('=== 1. COACH_PROFILES TABLE SCHEMA ===');
    const schemaResult = await client.query(`
      SELECT column_name, data_type, is_nullable, character_maximum_length
      FROM information_schema.columns
      WHERE table_name = 'coach_profiles'
      ORDER BY ordinal_position
    `);
    console.table(schemaResult.rows);

    // Query 2: Check if profiles table has username
    console.log('\n=== 2. PROFILES TABLE USERNAME COLUMN ===');
    const profilesUsernameResult = await client.query(`
      SELECT column_name, data_type, is_nullable, character_maximum_length
      FROM information_schema.columns
      WHERE table_name = 'profiles' AND column_name = 'username'
    `);
    console.table(profilesUsernameResult.rows);

    if (profilesUsernameResult.rows.length === 0) {
      console.log('WARNING: profiles table does not have a username column!');
    }

    // Query 3: Add username column to coach_profiles
    console.log('\n=== 3. ADDING USERNAME COLUMN TO COACH_PROFILES ===');
    const alterResult = await client.query(`
      ALTER TABLE coach_profiles
      ADD COLUMN IF NOT EXISTS username TEXT
    `);
    console.log('Username column added (or already exists)');

    // Query 4: Create index
    console.log('\n=== 4. CREATING INDEX ON USERNAME ===');
    const indexResult = await client.query(`
      CREATE INDEX IF NOT EXISTS idx_coach_profiles_username ON coach_profiles(username)
    `);
    console.log('Index created (or already exists)');

    // Query 5: Update coach_profiles with usernames from profiles
    console.log('\n=== 5. UPDATING COACH_PROFILES WITH USERNAMES FROM PROFILES ===');
    const updateResult = await client.query(`
      UPDATE coach_profiles cp
      SET username = p.username
      FROM profiles p
      WHERE cp.coach_id = p.id AND cp.username IS NULL
    `);
    console.log(`Updated ${updateResult.rowCount} coach profiles with usernames`);

    // Query 6: Verify the fix
    console.log('\n=== 6. SAMPLE COACH_PROFILES WITH USERNAME ===');
    const sampleResult = await client.query(`
      SELECT coach_id, username, display_name, updated_at
      FROM coach_profiles
      LIMIT 5
    `);
    console.table(sampleResult.rows);

    // Query 7: Statistics
    console.log('\n=== 7. USERNAME STATISTICS ===');
    const statsResult = await client.query(`
      SELECT
        COUNT(*) as total_coaches,
        COUNT(username) as with_username,
        COUNT(*) - COUNT(username) as without_username
      FROM coach_profiles
    `);
    console.table(statsResult.rows);

    console.log('\n✓ All diagnostic and fix queries completed successfully!');

  } catch (error) {
    console.error('\n✗ Error executing queries:');
    console.error('Error code:', error.code);
    console.error('Error message:', error.message);
    console.error('Error detail:', error.detail);
    console.error('Error hint:', error.hint);
    throw error;
  } finally {
    await client.end();
    console.log('\nConnection closed.');
  }
}

runDiagnostics().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
