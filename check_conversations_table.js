const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_KEY');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkTables() {
  console.log('Checking if conversations table exists...');

  const { data, error } = await supabase
    .from('conversations')
    .select('count')
    .limit(1);

  if (error) {
    console.log('❌ conversations table does not exist');
    console.log('Error:', error.message);
    return false;
  } else {
    console.log('✅ conversations table exists');
    return true;
  }
}

checkTables().then(exists => {
  process.exit(exists ? 0 : 1);
});
