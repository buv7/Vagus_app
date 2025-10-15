const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

// Connection string
const connectionString = 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres';

// Create client with connection string
const client = new Client({
  connectionString,
  ssl: {
    rejectUnauthorized: false
  },
  connectionTimeoutMillis: 30000,
  query_timeout: 60000
});

async function executeMigration() {
  try {
    console.log('Connecting to Supabase database...');
    await client.connect();
    console.log('✓ Connected successfully to Supabase PostgreSQL database');
    console.log('');

    // Read the migration file
    const migrationPath = path.join(__dirname, 'supabase', 'migrations', 'fix_coach_clients_schema.sql');
    const migrationSQL = fs.readFileSync(migrationPath, 'utf8');

    // Split the SQL into individual statements
    const statements = migrationSQL
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt.length > 0 && !stmt.startsWith('--'));

    console.log(`Found ${statements.length} SQL statements to execute`);
    console.log('='.repeat(80));
    console.log('');

    // Execute each statement
    for (let i = 0; i < statements.length; i++) {
      const statement = statements[i];
      const stepNum = i + 1;

      // Extract a description from the statement
      let description = '';
      if (statement.includes('ADD COLUMN') && statement.includes('id UUID')) {
        description = 'Adding primary key (id column) to coach_clients';
      } else if (statement.includes('ALTER COLUMN coach_id SET NOT NULL')) {
        description = 'Setting coach_id and client_id as NOT NULL in coach_clients';
      } else if (statement.includes('ALTER COLUMN created_at')) {
        description = 'Setting created_at as NOT NULL with default in coach_clients';
      } else if (statement.includes('unique_coach_client_pair')) {
        description = 'Adding unique constraint for coach-client pairs';
      } else if (statement.includes('fk_coach_clients_coach')) {
        description = 'Adding foreign key constraint for coach_id';
      } else if (statement.includes('fk_coach_clients_client')) {
        description = 'Adding foreign key constraint for client_id';
      } else if (statement.includes('idx_coach_clients')) {
        description = 'Creating indexes for coach_clients table';
      } else if (statement.includes('UPDATE coach_clients')) {
        description = 'Setting default status for NULL values';
      } else if (statement.includes('check_valid_status') && statement.includes('coach_clients')) {
        description = 'Adding status validation constraint to coach_clients';
      } else if (statement.includes('ALTER TABLE coach_requests') && statement.includes('ALTER COLUMN')) {
        description = 'Setting NOT NULL constraints in coach_requests';
      } else if (statement.includes('fk_coach_requests')) {
        description = 'Adding foreign key constraints to coach_requests';
      } else if (statement.includes('idx_coach_requests')) {
        description = 'Creating indexes for coach_requests table';
      } else if (statement.includes('check_valid_request_status')) {
        description = 'Adding status validation constraint to coach_requests';
      } else {
        description = statement.substring(0, 60).replace(/\n/g, ' ') + '...';
      }

      console.log(`Step ${stepNum}/${statements.length}: ${description}`);
      console.log(`SQL: ${statement.substring(0, 100).replace(/\n/g, ' ')}...`);

      try {
        await client.query(statement);
        console.log('✓ Success');
      } catch (error) {
        console.log('✗ Error:', error.message);
        console.log('Error Details:', {
          code: error.code,
          detail: error.detail,
          hint: error.hint
        });

        // Suggest fixes based on error type
        if (error.code === '23502') {
          console.log('\nSuggestion: This is a NOT NULL constraint violation.');
          console.log('There are rows with NULL values in the column.');
          console.log('Fix: Update NULL values before adding the constraint.');
        } else if (error.code === '23505') {
          console.log('\nSuggestion: This is a unique constraint violation.');
          console.log('There are duplicate values in the table.');
          console.log('Fix: Remove or merge duplicate rows before adding the constraint.');
        } else if (error.code === '23503') {
          console.log('\nSuggestion: This is a foreign key constraint violation.');
          console.log('There are references to non-existent records.');
          console.log('Fix: Remove orphaned records or create the referenced records.');
        } else if (error.code === '42P07') {
          console.log('\nInfo: Object already exists. This may be expected if re-running the migration.');
        }
      }
      console.log('');
    }

    console.log('='.repeat(80));
    console.log('Migration execution completed');
    console.log('');

    // Verify the changes
    console.log('='.repeat(80));
    console.log('VERIFICATION: Checking coach_clients table structure');
    console.log('='.repeat(80));
    console.log('');

    // Query 1: Column information
    console.log('1. Column Information:');
    const columnsQuery = `
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_name = 'coach_clients'
      ORDER BY ordinal_position;
    `;
    const columnsResult = await client.query(columnsQuery);
    console.table(columnsResult.rows);
    console.log('');

    // Query 2: Constraints
    console.log('2. Table Constraints:');
    const constraintsQuery = `
      SELECT constraint_name, constraint_type
      FROM information_schema.table_constraints
      WHERE table_name = 'coach_clients'
      ORDER BY constraint_type, constraint_name;
    `;
    const constraintsResult = await client.query(constraintsQuery);
    console.table(constraintsResult.rows);
    console.log('');

    // Query 3: Indexes
    console.log('3. Indexes:');
    const indexesQuery = `
      SELECT
        indexname as index_name,
        indexdef as index_definition
      FROM pg_indexes
      WHERE tablename = 'coach_clients'
      ORDER BY indexname;
    `;
    const indexesResult = await client.query(indexesQuery);
    console.table(indexesResult.rows);
    console.log('');

    // Query 4: Foreign Keys
    console.log('4. Foreign Key Details:');
    const fkQuery = `
      SELECT
        tc.constraint_name,
        kcu.column_name,
        ccu.table_name AS foreign_table_name,
        ccu.column_name AS foreign_column_name,
        rc.delete_rule
      FROM information_schema.table_constraints AS tc
      JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
        AND tc.table_schema = kcu.table_schema
      JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
        AND ccu.table_schema = tc.table_schema
      JOIN information_schema.referential_constraints AS rc
        ON rc.constraint_name = tc.constraint_name
      WHERE tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_name = 'coach_clients'
      ORDER BY tc.constraint_name;
    `;
    const fkResult = await client.query(fkQuery);
    console.table(fkResult.rows);
    console.log('');

    // Also verify coach_requests table
    console.log('='.repeat(80));
    console.log('VERIFICATION: Checking coach_requests table structure');
    console.log('='.repeat(80));
    console.log('');

    console.log('1. Column Information:');
    const columnsQuery2 = `
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_name = 'coach_requests'
      ORDER BY ordinal_position;
    `;
    const columnsResult2 = await client.query(columnsQuery2);
    console.table(columnsResult2.rows);
    console.log('');

    console.log('2. Table Constraints:');
    const constraintsQuery2 = `
      SELECT constraint_name, constraint_type
      FROM information_schema.table_constraints
      WHERE table_name = 'coach_requests'
      ORDER BY constraint_type, constraint_name;
    `;
    const constraintsResult2 = await client.query(constraintsQuery2);
    console.table(constraintsResult2.rows);
    console.log('');

  } catch (error) {
    console.error('Fatal error:', error);
    process.exit(1);
  } finally {
    await client.end();
    console.log('Database connection closed');
  }
}

// Execute the migration
executeMigration().catch(console.error);
