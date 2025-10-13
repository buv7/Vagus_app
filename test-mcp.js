const { spawn } = require('child_process');

// Test the MCP server
console.log('🧪 Testing Vagus Deployment MCP Server...\n');

const server = spawn('node', ['mcp-vagus-deployment.js'], {
  stdio: ['pipe', 'pipe', 'pipe']
});

// Send a list tools request
const listToolsRequest = {
  jsonrpc: '2.0',
  id: 1,
  method: 'tools/list',
  params: {}
};

server.stdin.write(JSON.stringify(listToolsRequest) + '\n');

server.stdout.on('data', (data) => {
  console.log('📡 MCP Response:', data.toString());
});

server.stderr.on('data', (data) => {
  console.log('🔧 MCP Server Log:', data.toString());
});

server.on('close', (code) => {
  console.log(`\n✅ MCP Server test completed with code ${code}`);
});

// Test call tool request
setTimeout(() => {
  const callToolRequest = {
    jsonrpc: '2.0',
    id: 2,
    method: 'tools/call',
    params: {
      name: 'check_deployment_status',
      arguments: {}
    }
  };
  
  console.log('\n🔧 Testing deployment status check...');
  server.stdin.write(JSON.stringify(callToolRequest) + '\n');
}, 2000);

// Clean up after 5 seconds
setTimeout(() => {
  server.kill();
  console.log('\n🏁 Test completed');
}, 5000);
