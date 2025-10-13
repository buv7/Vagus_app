const { spawn } = require('child_process');

console.log('🚀 Forcing Complete Deployment to vagus.fit...\n');

// First, let's build the Flutter web app
console.log('1️⃣ Building Flutter web app...');
const buildProcess = spawn('C:\\src\\flutter\\bin\\flutter.bat', ['build', 'web'], { stdio: 'inherit' });

buildProcess.on('close', (code) => {
  if (code === 0) {
    console.log('✅ Flutter web build completed!\n');
    
    // Now deploy to Vercel
    console.log('2️⃣ Deploying to Vercel...');
    const deployProcess = spawn('npx', ['vercel', '--prod', '--yes'], { stdio: 'inherit' });
    
    deployProcess.on('close', (deployCode) => {
      if (deployCode === 0) {
        console.log('✅ Vercel deployment completed!');
        console.log('🌐 Your app should now be updated at vagus.fit');
      } else {
        console.log('❌ Vercel deployment failed. You may need to run: vercel login');
      }
    });
  } else {
    console.log('❌ Flutter build failed');
  }
});
