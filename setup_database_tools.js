// Setup script for database diagnosis and fix tools
// Run this first: node setup_database_tools.js

const { execSync } = require('child_process');
const fs = require('fs');

console.log('🔧 Setting up database diagnosis and fix tools...\n');

try {
  // Check if Node.js is installed
  console.log('1. Checking Node.js installation...');
  const nodeVersion = execSync('node --version', { encoding: 'utf8' }).trim();
  console.log(`   ✅ Node.js version: ${nodeVersion}`);

  // Check if npm is available
  console.log('\n2. Checking npm installation...');
  const npmVersion = execSync('npm --version', { encoding: 'utf8' }).trim();
  console.log(`   ✅ npm version: ${npmVersion}`);

  // Install required packages
  console.log('\n3. Installing required packages...');
  try {
    execSync('npm install pg', { stdio: 'inherit' });
    console.log('   ✅ Installed pg (PostgreSQL client)');
  } catch (error) {
    console.log('   ❌ Failed to install pg:', error.message);
    console.log('   💡 Try running: npm install pg');
  }

  // Create package.json if it doesn't exist
  if (!fs.existsSync('package.json')) {
    console.log('\n4. Creating package.json...');
    const packageJson = {
      "name": "vagus-database-tools",
      "version": "1.0.0",
      "description": "Database diagnosis and fix tools for VAGUS app",
      "main": "direct_db_diagnosis.js",
      "scripts": {
        "diagnose": "node direct_db_diagnosis.js",
        "fix": "node direct_db_fix.js"
      },
      "dependencies": {
        "pg": "^8.11.3"
      }
    };
    
    fs.writeFileSync('package.json', JSON.stringify(packageJson, null, 2));
    console.log('   ✅ Created package.json');
  }

  // Check if the database scripts exist
  console.log('\n5. Checking database scripts...');
  const scripts = [
    'direct_db_diagnosis.js',
    'direct_db_fix.js'
  ];

  scripts.forEach(script => {
    if (fs.existsSync(script)) {
      console.log(`   ✅ ${script} exists`);
    } else {
      console.log(`   ❌ ${script} missing`);
    }
  });

  console.log('\n🎉 Setup complete!');
  console.log('\n📋 Next steps:');
  console.log('1. Run diagnosis: node direct_db_diagnosis.js');
  console.log('2. Apply fixes: node direct_db_fix.js');
  console.log('3. Test your Flutter app login');

} catch (error) {
  console.error('❌ Setup failed:', error.message);
  console.log('\n💡 Manual setup:');
  console.log('1. Install Node.js: https://nodejs.org/');
  console.log('2. Run: npm install pg');
  console.log('3. Run: node direct_db_diagnosis.js');
}
