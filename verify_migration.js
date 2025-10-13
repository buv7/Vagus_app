#!/usr/bin/env node
/**
 * Verify migration was applied successfully
 */
const { Client } = require('pg');

const DB_URL = "postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres";

async function verifyMigration() {
    const client = new Client({ connectionString: DB_URL });

    try {
        await client.connect();
        console.log('Connected to database\n');
        console.log('='.repeat(80));
        console.log('VERIFICATION REPORT');
        console.log('='.repeat(80));

        // 1. Verify calendar_events.event_type column
        console.log('\n1. calendar_events.event_type column:');
        const eventTypeCheck = await client.query(`
            SELECT column_name, data_type, is_nullable, column_default
            FROM information_schema.columns
            WHERE table_schema = 'public'
            AND table_name = 'calendar_events'
            AND column_name = 'event_type';
        `);

        if (eventTypeCheck.rows.length > 0) {
            const col = eventTypeCheck.rows[0];
            console.log('   ✓ Column exists');
            console.log(`   - Type: ${col.data_type}`);
            console.log(`   - Nullable: ${col.is_nullable}`);
            console.log(`   - Default: ${col.column_default}`);

            // Check constraint
            const constraintCheck = await client.query(`
                SELECT conname, pg_get_constraintdef(oid) as definition
                FROM pg_constraint
                WHERE conname = 'calendar_events_event_type_check';
            `);
            if (constraintCheck.rows.length > 0) {
                console.log('   ✓ Check constraint exists');
            }

            // Check indexes
            const indexCheck = await client.query(`
                SELECT indexname, indexdef
                FROM pg_indexes
                WHERE tablename = 'calendar_events'
                AND indexname LIKE '%event_type%';
            `);
            console.log(`   ✓ Indexes created: ${indexCheck.rows.length}`);
            indexCheck.rows.forEach(idx => {
                console.log(`     - ${idx.indexname}`);
            });
        } else {
            console.log('   ✗ Column NOT found');
        }

        // 2. Verify client_feedback table
        console.log('\n2. client_feedback table:');
        const feedbackCheck = await client.query(`
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns
            WHERE table_schema = 'public'
            AND table_name = 'client_feedback'
            ORDER BY ordinal_position;
        `);

        if (feedbackCheck.rows.length > 0) {
            console.log('   ✓ Table exists');
            console.log(`   - Columns: ${feedbackCheck.rows.length}`);
            feedbackCheck.rows.forEach(col => {
                console.log(`     - ${col.column_name} (${col.data_type})`);
            });

            // Check RLS
            const rlsCheck = await client.query(`
                SELECT relrowsecurity
                FROM pg_class
                WHERE relname = 'client_feedback';
            `);
            console.log(`   ✓ RLS enabled: ${rlsCheck.rows[0]?.relrowsecurity || false}`);

            // Check policies
            const policiesCheck = await client.query(`
                SELECT policyname, cmd
                FROM pg_policies
                WHERE tablename = 'client_feedback';
            `);
            console.log(`   ✓ RLS policies: ${policiesCheck.rows.length}`);
            policiesCheck.rows.forEach(p => {
                console.log(`     - ${p.policyname} (${p.cmd})`);
            });

            // Check indexes
            const indexCheck = await client.query(`
                SELECT indexname
                FROM pg_indexes
                WHERE tablename = 'client_feedback';
            `);
            console.log(`   ✓ Indexes: ${indexCheck.rows.length}`);
        } else {
            console.log('   ✗ Table NOT found');
        }

        // 3. Verify payments table
        console.log('\n3. payments table:');
        const paymentsCheck = await client.query(`
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns
            WHERE table_schema = 'public'
            AND table_name = 'payments'
            ORDER BY ordinal_position;
        `);

        if (paymentsCheck.rows.length > 0) {
            console.log('   ✓ Table exists');
            console.log(`   - Columns: ${paymentsCheck.rows.length}`);
            paymentsCheck.rows.forEach(col => {
                console.log(`     - ${col.column_name} (${col.data_type})`);
            });

            // Check RLS
            const rlsCheck = await client.query(`
                SELECT relrowsecurity
                FROM pg_class
                WHERE relname = 'payments';
            `);
            console.log(`   ✓ RLS enabled: ${rlsCheck.rows[0]?.relrowsecurity || false}`);

            // Check policies
            const policiesCheck = await client.query(`
                SELECT policyname, cmd, roles
                FROM pg_policies
                WHERE tablename = 'payments';
            `);
            console.log(`   ✓ RLS policies: ${policiesCheck.rows.length}`);
            policiesCheck.rows.forEach(p => {
                console.log(`     - ${p.policyname} (${p.cmd}) [${p.roles}]`);
            });

            // Check indexes
            const indexCheck = await client.query(`
                SELECT indexname
                FROM pg_indexes
                WHERE tablename = 'payments';
            `);
            console.log(`   ✓ Indexes: ${indexCheck.rows.length}`);
        } else {
            console.log('   ✗ Table NOT found');
        }

        // 4. Verify views
        console.log('\n4. Analytical Views:');
        const viewsCheck = await client.query(`
            SELECT table_name
            FROM information_schema.views
            WHERE table_schema = 'public'
            AND table_name IN ('coach_feedback_summary', 'coach_payment_summary');
        `);

        const expectedViews = ['coach_feedback_summary', 'coach_payment_summary'];
        expectedViews.forEach(viewName => {
            const exists = viewsCheck.rows.some(r => r.table_name === viewName);
            console.log(`   ${exists ? '✓' : '✗'} ${viewName}`);
        });

        console.log('\n' + '='.repeat(80));
        console.log('MIGRATION VERIFICATION COMPLETE');
        console.log('='.repeat(80));

    } catch (error) {
        console.error('\nERROR:', error.message);
        if (error.stack) {
            console.error(error.stack);
        }
    } finally {
        await client.end();
    }
}

verifyMigration();
