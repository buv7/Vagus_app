const { Client } = require('pg');

const connectionString = 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres';

async function executeMigration() {
  const client = new Client({ connectionString });

  try {
    await client.connect();
    console.log('✓ Connected to Supabase database');

    // 1. Add coach_id column
    console.log('\n1. Adding coach_id column...');
    await client.query(`
      ALTER TABLE workout_plans
      ADD COLUMN IF NOT EXISTS coach_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    `);
    console.log('✓ Column added successfully');

    // 2. Create index
    console.log('\n2. Creating index on coach_id...');
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_workout_plans_coach_id ON workout_plans(coach_id);
    `);
    console.log('✓ Index created successfully');

    // 3. Migrate data
    console.log('\n3. Migrating data from created_by to coach_id...');
    const updateResult = await client.query(`
      UPDATE workout_plans
      SET coach_id = created_by
      WHERE coach_id IS NULL AND created_by IS NOT NULL;
    `);
    console.log(`✓ Updated ${updateResult.rowCount} rows`);

    // 4. Verify
    console.log('\n4. Verifying column structure...');
    const verifyResult = await client.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'workout_plans' AND column_name = 'coach_id';
    `);

    if (verifyResult.rows.length > 0) {
      console.log('\n✓ Verification Results:');
      console.log(JSON.stringify(verifyResult.rows[0], null, 2));
    } else {
      console.log('\n✗ ERROR: Column not found after creation!');
    }

    // Additional verification: Check sample data
    console.log('\n5. Sample data check...');
    const sampleResult = await client.query(`
      SELECT id, name, coach_id, created_by
      FROM workout_plans
      LIMIT 5;
    `);
    console.log(`\nSample rows (${sampleResult.rowCount} total):`);
    console.log(JSON.stringify(sampleResult.rows, null, 2));

  } catch (error) {
    console.error('\n✗ ERROR:', error.message);
    console.error('Details:', error);
    process.exit(1);
  } finally {
    await client.end();
    console.log('\n✓ Database connection closed');
  }
}

executeMigration();
