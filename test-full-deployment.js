const { spawn } = require('child_process');

console.log('🚀 Testing MCP Full Deployment Control...\n');

const server = spawn('node', ['mcp-vagus-deployment.js'], {
  stdio: ['pipe', 'pipe', 'pipe']
});

// Full deployment request
const fullDeployment = {
  jsonrpc: '2.0',
  id: 1,
  method: 'tools/call',
  params: {
    name: 'full_deployment',
    arguments: {
      message: 'MCP Full Deployment: Revolutionary Plan Builder + Coach Marketplace + Complete Sprint Features',
      buildFlutter: true
    }
  }
};

server.stdin.write(JSON.stringify(fullDeployment) + '\n');

server.stdout.on('data', (data) => {
  console.log('🚀 MCP Deployment Response:', data.toString());
});

server.stderr.on('data', (data) => {
  console.log('📋 MCP Log:', data.toString());
});

server.on('close', (code) => {
  console.log(`\n✅ MCP Full Deployment test completed with code ${code}`);
});

// Clean up after 30 seconds
setTimeout(() => {
  server.kill();
  console.log('\n🏁 Test completed');
}, 30000);
