// Simple script to run SQL migration
const https = require('https');
const fs = require('fs');

const SUPABASE_URL = 'https://kydrpnrmqbedjflklgue.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt5ZHJwbnJtcWJlZGpmbGtsZ3VlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQyMjUxODAsImV4cCI6MjA2OTgwMTE4MH0.qlpGUiy17IbDsfgOf3-F2XBjOajjwxfy2NLMlUZWaqo';

// SQL to execute
const sql = `
ALTER TABLE workout_plans
ADD COLUMN IF NOT EXISTS duration_weeks INTEGER;

COMMENT ON COLUMN workout_plans.duration_weeks IS 'Total duration of the workout plan in weeks';
`;

// Make request to Supabase REST API
const data = JSON.stringify({
  query: sql
});

const options = {
  hostname: 'kydrpnrmqbedjflklgue.supabase.co',
  port: 443,
  path: '/rest/v1/rpc/exec_sql',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'apikey': SUPABASE_ANON_KEY,
    'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
    'Content-Length': data.length
  }
};

const req = https.request(options, (res) => {
  let responseData = '';

  res.on('data', (chunk) => {
    responseData += chunk;
  });

  res.on('end', () => {
    console.log('Status Code:', res.statusCode);
    console.log('Response:', responseData);
  });
});

req.on('error', (error) => {
  console.error('Error:', error);
});

req.write(data);
req.end();
