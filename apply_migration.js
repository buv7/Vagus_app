#!/usr/bin/env node
/**
 * Apply migration to Supabase database
 */
const { readFileSync } = require('fs');
const { join } = require('path');

// Database connection string
const DB_URL = "postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres";

// Migration file path
const MIGRATION_FILE = join(__dirname, 'supabase', 'migrations', '20251002140000_add_missing_tables_and_columns.sql');

async function applyMigration() {
    let client;

    try {
        // Import pg dynamically
        const { Client } = require('pg');

        console.log('Connecting to Supabase database...');
        client = new Client({ connectionString: DB_URL });
        await client.connect();

        console.log(`Reading migration file: ${MIGRATION_FILE}`);
        const migrationSQL = readFileSync(MIGRATION_FILE, 'utf-8');

        console.log('Applying migration...');
        await client.query(migrationSQL);

        console.log('\n' + '='.repeat(80));
        console.log('SUCCESS! Migration applied successfully!');
        console.log('='.repeat(80));
        console.log('\nCreated/Modified:');
        console.log('  1. calendar_events.event_type column (with index)');
        console.log('  2. client_feedback table (with RLS policies)');
        console.log('  3. payments table (with RLS policies)');
        console.log('  4. coach_feedback_summary view');
        console.log('  5. coach_payment_summary view');
        console.log('='.repeat(80));

    } catch (error) {
        console.error('\nERROR: Failed to apply migration:');
        console.error(error.message);
        if (error.stack) {
            console.error('\nStack trace:');
            console.error(error.stack);
        }
        process.exit(1);
    } finally {
        if (client) {
            await client.end();
        }
    }
}

// Check if pg is installed
try {
    require.resolve('pg');
} catch (e) {
    console.error('ERROR: pg package is not installed');
    console.error('Please run: npm install pg');
    process.exit(1);
}

applyMigration();
