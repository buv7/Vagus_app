#!/usr/bin/env node
/**
 * Test the new tables with sample operations
 */
const { Client } = require('pg');

const DB_URL = "postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres";

async function testTables() {
    const client = new Client({ connectionString: DB_URL });

    try {
        await client.connect();
        console.log('Connected to database\n');
        console.log('='.repeat(80));
        console.log('DATABASE STRUCTURE TEST');
        console.log('='.repeat(80));

        // Test 1: Query calendar_events with new event_type column
        console.log('\n1. Testing calendar_events.event_type:');
        const eventsResult = await client.query(`
            SELECT event_type, COUNT(*) as count
            FROM calendar_events
            GROUP BY event_type
            ORDER BY count DESC;
        `);

        if (eventsResult.rows.length > 0) {
            console.log('   Event types in database:');
            eventsResult.rows.forEach(row => {
                console.log(`     - ${row.event_type}: ${row.count} events`);
            });
        } else {
            console.log('   No events in database yet');
        }

        // Test 2: Check client_feedback structure
        console.log('\n2. Testing client_feedback table:');
        const feedbackResult = await client.query(`
            SELECT
                category,
                COUNT(*) as count,
                AVG(rating)::NUMERIC(3,2) as avg_rating
            FROM client_feedback
            GROUP BY category
            ORDER BY count DESC;
        `);

        if (feedbackResult.rows.length > 0) {
            console.log('   Feedback by category:');
            feedbackResult.rows.forEach(row => {
                console.log(`     - ${row.category}: ${row.count} items (avg: ${row.avg_rating} stars)`);
            });
        } else {
            console.log('   No feedback in database yet');
        }

        // Test 3: Check payments structure
        console.log('\n3. Testing payments table:');
        const paymentsResult = await client.query(`
            SELECT
                status,
                COUNT(*) as count,
                SUM(amount)::NUMERIC(10,2) as total_amount,
                currency
            FROM payments
            GROUP BY status, currency
            ORDER BY count DESC;
        `);

        if (paymentsResult.rows.length > 0) {
            console.log('   Payments by status:');
            paymentsResult.rows.forEach(row => {
                console.log(`     - ${row.status}: ${row.count} payments, ${row.total_amount} ${row.currency}`);
            });
        } else {
            console.log('   No payments in database yet');
        }

        // Test 4: Check analytical views
        console.log('\n4. Testing analytical views:');
        const feedbackSummaryCount = await client.query(`
            SELECT COUNT(*) as coach_count
            FROM coach_feedback_summary;
        `);
        console.log(`   Coaches with feedback: ${feedbackSummaryCount.rows[0].coach_count}`);

        const paymentSummaryCount = await client.query(`
            SELECT COUNT(*) as coach_count
            FROM coach_payment_summary;
        `);
        console.log(`   Coaches with payments: ${paymentSummaryCount.rows[0].coach_count}`);

        // Test 5: Test constraints
        console.log('\n5. Testing constraints:');

        // Test event_type constraint
        try {
            await client.query(`
                INSERT INTO calendar_events (
                    title, event_type, coach_id, client_id, start_at, end_at, created_by
                ) VALUES (
                    'Test Event',
                    'invalid_type',
                    '00000000-0000-0000-0000-000000000000',
                    '00000000-0000-0000-0000-000000000000',
                    NOW(),
                    NOW() + INTERVAL '1 hour',
                    '00000000-0000-0000-0000-000000000000'
                );
            `);
            console.log('   ✗ event_type constraint NOT working (allowed invalid value)');
        } catch (error) {
            if (error.message.includes('calendar_events_event_type_check')) {
                console.log('   ✓ event_type constraint working (rejected invalid value)');
            } else {
                console.log(`   ? event_type test failed with different error: ${error.message.substring(0, 50)}`);
            }
        }

        // Test rating constraint
        try {
            await client.query(`
                INSERT INTO client_feedback (
                    client_id, coach_id, rating, category
                ) VALUES (
                    '00000000-0000-0000-0000-000000000000',
                    '00000000-0000-0000-0000-000000000000',
                    10,
                    'workout'
                );
            `);
            console.log('   ✗ rating constraint NOT working (allowed value > 5)');
        } catch (error) {
            if (error.message.includes('client_feedback_rating_check')) {
                console.log('   ✓ rating constraint working (rejected invalid rating)');
            } else {
                console.log(`   ? rating test failed with different error: ${error.message.substring(0, 50)}`);
            }
        }

        // Test payment amount constraint
        try {
            await client.query(`
                INSERT INTO payments (
                    client_id, coach_id, amount, currency, status
                ) VALUES (
                    '00000000-0000-0000-0000-000000000000',
                    '00000000-0000-0000-0000-000000000000',
                    -100.00,
                    'USD',
                    'completed'
                );
            `);
            console.log('   ✗ amount constraint NOT working (allowed negative value)');
        } catch (error) {
            if (error.message.includes('payments_amount_check')) {
                console.log('   ✓ amount constraint working (rejected negative amount)');
            } else {
                console.log(`   ? amount test failed with different error: ${error.message.substring(0, 50)}`);
            }
        }

        // Test 6: Check indexes
        console.log('\n6. Testing indexes:');
        const indexCount = await client.query(`
            SELECT
                tablename,
                COUNT(*) as index_count
            FROM pg_indexes
            WHERE schemaname = 'public'
            AND tablename IN ('calendar_events', 'client_feedback', 'payments')
            GROUP BY tablename
            ORDER BY tablename;
        `);

        indexCount.rows.forEach(row => {
            console.log(`   ${row.tablename}: ${row.index_count} indexes`);
        });

        // Test 7: Check RLS
        console.log('\n7. Testing RLS:');
        const rlsStatus = await client.query(`
            SELECT
                tablename,
                relrowsecurity as rls_enabled
            FROM pg_tables t
            JOIN pg_class c ON c.relname = t.tablename
            WHERE t.schemaname = 'public'
            AND t.tablename IN ('calendar_events', 'client_feedback', 'payments')
            ORDER BY t.tablename;
        `);

        rlsStatus.rows.forEach(row => {
            const status = row.rls_enabled ? '✓ enabled' : '✗ disabled';
            console.log(`   ${row.tablename}: ${status}`);
        });

        // Test 8: Count policies
        const policyCount = await client.query(`
            SELECT
                tablename,
                COUNT(*) as policy_count
            FROM pg_policies
            WHERE tablename IN ('calendar_events', 'client_feedback', 'payments')
            GROUP BY tablename
            ORDER BY tablename;
        `);

        console.log('\n8. RLS Policies:');
        policyCount.rows.forEach(row => {
            console.log(`   ${row.tablename}: ${row.policy_count} policies`);
        });

        console.log('\n' + '='.repeat(80));
        console.log('ALL TESTS COMPLETED');
        console.log('='.repeat(80));

    } catch (error) {
        console.error('\nERROR during testing:', error.message);
        if (error.stack) {
            console.error(error.stack);
        }
    } finally {
        await client.end();
    }
}

testTables();
