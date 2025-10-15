const { Client } = require('pg');

const connectionString = 'postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres';

async function checkMessagingSchema() {
  const client = new Client({
    connectionString,
    ssl: {
      rejectUnauthorized: false
    }
  });

  try {
    console.log('Connecting to Supabase database...');
    await client.connect();
    console.log('Connected successfully!\n');

    console.log('=== CONVERSATIONS TABLE SCHEMA ===\n');
    const convColumnsQuery = `
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'conversations'
      ORDER BY ordinal_position;
    `;
    const convColumns = await client.query(convColumnsQuery);
    console.log('Columns:');
    convColumns.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} ${col.is_nullable === 'NO' ? 'NOT NULL' : 'NULL'} ${col.column_default ? `DEFAULT ${col.column_default}` : ''}`);
    });

    console.log('\n=== MESSAGES TABLE SCHEMA ===\n');
    const msgColumnsQuery = `
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'messages'
      ORDER BY ordinal_position;
    `;
    const msgColumns = await client.query(msgColumnsQuery);
    console.log('Columns:');
    msgColumns.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} ${col.is_nullable === 'NO' ? 'NOT NULL' : 'NULL'} ${col.column_default ? `DEFAULT ${col.column_default}` : ''}`);
    });

    console.log('\n=== MESSAGE_ATTACHMENTS TABLE SCHEMA ===\n');
    const attColumnsQuery = `
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'message_attachments'
      ORDER BY ordinal_position;
    `;
    const attColumns = await client.query(attColumnsQuery);
    console.log('Columns:');
    attColumns.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} ${col.is_nullable === 'NO' ? 'NOT NULL' : 'NULL'} ${col.column_default ? `DEFAULT ${col.column_default}` : ''}`);
    });

    console.log('\n=== FOREIGN KEY CONSTRAINTS ===\n');
    const fkQuery = `
      SELECT
        tc.table_name,
        kcu.column_name,
        ccu.table_name AS foreign_table_name,
        ccu.column_name AS foreign_column_name,
        rc.delete_rule
      FROM information_schema.table_constraints AS tc
      JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
      JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
      JOIN information_schema.referential_constraints AS rc
        ON rc.constraint_name = tc.constraint_name
      WHERE tc.constraint_type = 'FOREIGN KEY'
      AND tc.table_name IN ('conversations', 'messages', 'message_attachments')
      ORDER BY tc.table_name, kcu.column_name;
    `;
    const fks = await client.query(fkQuery);
    fks.rows.forEach(fk => {
      console.log(`  ${fk.table_name}.${fk.column_name} -> ${fk.foreign_table_name}.${fk.foreign_column_name} (ON DELETE ${fk.delete_rule})`);
    });

    console.log('\n=== INDEXES ===\n');
    const indexQuery = `
      SELECT tablename, indexname, indexdef
      FROM pg_indexes
      WHERE schemaname = 'public'
      AND tablename IN ('conversations', 'messages', 'message_attachments')
      ORDER BY tablename, indexname;
    `;
    const indexes = await client.query(indexQuery);
    indexes.rows.forEach(idx => {
      console.log(`  ${idx.tablename}.${idx.indexname}`);
      console.log(`    ${idx.indexdef}`);
    });

    console.log('\n=== RLS POLICIES ===\n');
    const policyQuery = `
      SELECT tablename, policyname, permissive, roles, cmd, qual, with_check
      FROM pg_policies
      WHERE schemaname = 'public'
      AND tablename IN ('conversations', 'messages', 'message_attachments')
      ORDER BY tablename, policyname;
    `;
    const policies = await client.query(policyQuery);
    policies.rows.forEach(pol => {
      console.log(`  ${pol.tablename}.${pol.policyname}`);
      console.log(`    Command: ${pol.cmd}, Roles: ${pol.roles}`);
      if (pol.qual) console.log(`    USING: ${pol.qual}`);
      if (pol.with_check) console.log(`    WITH CHECK: ${pol.with_check}`);
      console.log('');
    });

  } catch (error) {
    console.error('\n❌ Error:', error.message);
    throw error;
  } finally {
    await client.end();
    console.log('\nDatabase connection closed.');
  }
}

checkMessagingSchema()
  .then(() => {
    console.log('\n✅ Schema check completed successfully.');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Schema check failed:', error.message);
    process.exit(1);
  });
