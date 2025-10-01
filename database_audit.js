#!/usr/bin/env node
/**
 * VAGUS Database Audit Script
 * Connects to Supabase PostgreSQL and verifies schema
 */

const { spawn } = require('child_process');
const fs = require('fs');

// Database connection details
const DB_CONFIG = {
  host: 'aws-0-eu-central-1.pooler.supabase.com',
  port: 5432,
  database: 'postgres',
  user: 'postgres.kydrpnrmqbedjflklgue',
  password: 'X.7achoony.X'
};

console.log('================================');
console.log('VAGUS Database Audit (Node.js)');
console.log('================================\n');

// Check if we can use psql via Node
console.log('Attempting database connection...\n');

const connectionString = `postgresql://${DB_CONFIG.user}:${DB_CONFIG.password}@${DB_CONFIG.host}:${DB_CONFIG.port}/${DB_CONFIG.database}`;

// Try using psql if available
const psql = spawn('psql', [connectionString, '-c', 'SELECT version();'], {
  stdio: 'pipe'
});

let output = '';
let errorOutput = '';

psql.stdout.on('data', (data) => {
  output += data.toString();
});

psql.stderr.on('data', (data) => {
  errorOutput += data.toString();
});

psql.on('close', (code) => {
  if (code === 0) {
    console.log('✅ Connection successful!\n');
    console.log('PostgreSQL Version:');
    console.log(output);
    console.log('\n📊 Now run the full audit:');
    console.log('psql "' + connectionString + '" -f database_audit.sql -o database_audit_results.txt');
  } else {
    console.error('❌ psql not available or connection failed\n');
    console.error('Error:', errorOutput);
    console.log('\n💡 Alternative approaches:');
    console.log('1. Install PostgreSQL: scoop install postgresql');
    console.log('2. Use Supabase Dashboard: https://kydrpnrmqbedjflklgue.supabase.co');
    console.log('3. Use Docker: docker run --rm -it postgres:15 psql "' + connectionString + '"');
    console.log('\n📋 See MANUAL_DATABASE_AUDIT.md for detailed instructions');
  }
});

psql.on('error', (err) => {
  console.error('❌ Failed to spawn psql:', err.message);
  console.log('\n💡 psql not installed. Install options:');
  console.log('1. Scoop: scoop install postgresql');
  console.log('2. Manual: https://www.postgresql.org/download/windows/');
  console.log('3. Use Supabase Dashboard instead (no installation needed)');
  console.log('\n📋 See MANUAL_DATABASE_AUDIT.md for step-by-step guide');
});
