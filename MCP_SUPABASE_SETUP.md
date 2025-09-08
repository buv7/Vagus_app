# 🚀 MCP Supabase Integration with Cursor IDE

This guide will help you connect your Supabase database to Cursor IDE using the Model Context Protocol (MCP) service for direct database access and querying.

## 📋 Prerequisites

- Node.js 18+ installed
- Cursor IDE
- Supabase project with database access
- Your Supabase connection details

## 🔧 Step 1: Install MCP Supabase Server

### Option A: Using npm (Recommended)

```bash
# Install the MCP Supabase server globally
npm install -g @modelcontextprotocol/server-supabase

# Or install locally in your project
npm install @modelcontextprotocol/server-supabase
```

### Option B: Using npx (No installation required)

```bash
# Run directly without installation
npx @modelcontextprotocol/server-supabase
```

## 🔑 Step 2: Get Your Supabase Credentials

You'll need these from your Supabase project:

1. **Project URL**: `https://your-project-ref.supabase.co`
2. **Database Password**: Your database password
3. **Database Host**: `aws-0-eu-central-1.pooler.supabase.com` (from your connection string)
4. **Database Port**: `5432` (for session pooler)
5. **Database Name**: `postgres`

From your connection string:
```
postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres
```

Extract:
- **Username**: `postgres.kydrpnrmqbedjflklgue`
- **Password**: `X.7achoony.X`
- **Host**: `aws-0-eu-central-1.pooler.supabase.com`
- **Port**: `5432`
- **Database**: `postgres`

## ⚙️ Step 3: Configure Cursor IDE

### Create MCP Configuration File

Create a configuration file for Cursor IDE:

**Windows**: `%APPDATA%\Cursor\User\globalStorage\cursor.mcp\config.json`
**macOS**: `~/Library/Application Support/Cursor/User/globalStorage/cursor.mcp/config.json`
**Linux**: `~/.config/Cursor/User/globalStorage/cursor.mcp/config.json`

```json
{
  "mcpServers": {
    "supabase": {
      "command": "npx",
      "args": [
        "@modelcontextprotocol/server-supabase",
        "--host", "aws-0-eu-central-1.pooler.supabase.com",
        "--port", "5432",
        "--database", "postgres",
        "--username", "postgres.kydrpnrmqbedjflklgue",
        "--password", "X.7achoony.X",
        "--ssl", "true"
      ],
      "env": {
        "SUPABASE_URL": "https://kydrpnrmqbedjflklgue.supabase.co",
        "SUPABASE_ANON_KEY": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt5ZHJwbnJtcWJlZGpmbGtsZ3VlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQyMjUxODAsImV4cCI6MjA2OTgwMTE4MH0.qlpGUiy17IbDsfgOf3-F2XBjOajjwxfy2NLMlUZWaqo"
      }
    }
  }
}
```

### Alternative: Environment Variables Configuration

Create a `.env` file in your project root:

```env
# Supabase Database Connection
SUPABASE_DB_HOST=aws-0-eu-central-1.pooler.supabase.com
SUPABASE_DB_PORT=5432
SUPABASE_DB_NAME=postgres
SUPABASE_DB_USERNAME=postgres.kydrpnrmqbedjflklgue
SUPABASE_DB_PASSWORD=X.7achoony.X
SUPABASE_DB_SSL=true

# Supabase API
SUPABASE_URL=https://kydrpnrmqbedjflklgue.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt5ZHJwbnJtcWJlZGpmbGtsZ3VlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQyMjUxODAsImV4cCI6MjA2OTgwMTE4MH0.qlpGUiy17IbDsfgOf3-F2XBjOajjwxfy2NLMlUZWaqo
```

Then update your config.json:

```json
{
  "mcpServers": {
    "supabase": {
      "command": "npx",
      "args": [
        "@modelcontextprotocol/server-supabase"
      ],
      "env": {
        "SUPABASE_DB_HOST": "aws-0-eu-central-1.pooler.supabase.com",
        "SUPABASE_DB_PORT": "5432",
        "SUPABASE_DB_NAME": "postgres",
        "SUPABASE_DB_USERNAME": "postgres.kydrpnrmqbedjflklgue",
        "SUPABASE_DB_PASSWORD": "X.7achoony.X",
        "SUPABASE_DB_SSL": "true",
        "SUPABASE_URL": "https://kydrpnrmqbedjflklgue.supabase.co",
        "SUPABASE_ANON_KEY": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt5ZHJwbnJtcWJlZGpmbGtsZ3VlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQyMjUxODAsImV4cCI6MjA2OTgwMTE4MH0.qlpGUiy17IbDsfgOf3-F2XBjOajjwxfy2NLMlUZWaqo"
      }
    }
  }
}
```

## 🔄 Step 4: Restart Cursor IDE

1. **Close Cursor IDE completely**
2. **Reopen Cursor IDE**
3. **Check the MCP status** in the bottom status bar

## 🧪 Step 5: Test the Connection

### Test Database Connection

Open a new chat in Cursor and try these commands:

```
@supabase list tables
```

```
@supabase describe table profiles
```

```
@supabase query "SELECT COUNT(*) FROM profiles"
```

### Example Queries You Can Run

```sql
-- Check user roles
@supabase query "SELECT role, COUNT(*) FROM profiles GROUP BY role"

-- View recent users
@supabase query "SELECT id, email, name, role, created_at FROM profiles ORDER BY created_at DESC LIMIT 10"

-- Check AI usage
@supabase query "SELECT user_id, month, year, tokens_used FROM ai_usage ORDER BY created_at DESC LIMIT 5"

-- View coach-client relationships
@supabase query "SELECT cc.coach_id, cc.client_id, p.name as client_name FROM coach_clients cc JOIN profiles p ON cc.client_id = p.id LIMIT 10"
```

## 🛠️ Step 6: Advanced Configuration

### Custom MCP Server Script

Create a custom MCP server script for more control:

**`mcp-supabase-server.js`**:
```javascript
#!/usr/bin/env node

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const { CallToolRequestSchema, ListToolsRequestSchema } = require('@modelcontextprotocol/sdk/types.js');

const server = new Server(
  {
    name: 'supabase-mcp-server',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Add your custom tools here
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: 'query_database',
        description: 'Execute SQL queries on Supabase database',
        inputSchema: {
          type: 'object',
          properties: {
            query: {
              type: 'string',
              description: 'SQL query to execute',
            },
          },
          required: ['query'],
        },
      },
      {
        name: 'list_tables',
        description: 'List all tables in the database',
        inputSchema: {
          type: 'object',
          properties: {},
        },
      },
    ],
  };
});

// Start the server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('Supabase MCP server running on stdio');
}

main().catch(console.error);
```

### Package.json Script

Add to your `package.json`:

```json
{
  "scripts": {
    "mcp:supabase": "node mcp-supabase-server.js"
  },
  "dependencies": {
    "@modelcontextprotocol/server-supabase": "^1.0.0"
  }
}
```

## 🔍 Step 7: Available MCP Commands

Once connected, you can use these commands in Cursor:

### Database Operations
- `@supabase list tables` - List all tables
- `@supabase describe table <table_name>` - Get table schema
- `@supabase query "<SQL>"` - Execute SQL queries
- `@supabase list schemas` - List database schemas

### Supabase Specific
- `@supabase list projects` - List Supabase projects
- `@supabase describe project` - Get project details
- `@supabase list functions` - List Edge Functions
- `@supabase list buckets` - List Storage buckets

## 🚨 Troubleshooting

### Common Issues

1. **Connection Failed**
   ```
   Error: Connection refused
   ```
   **Solution**: Check your database credentials and network connectivity

2. **SSL Certificate Error**
   ```
   Error: SSL certificate verification failed
   ```
   **Solution**: Ensure SSL is enabled and certificates are valid

3. **Authentication Failed**
   ```
   Error: Authentication failed
   ```
   **Solution**: Verify your username and password

4. **MCP Server Not Found**
   ```
   Error: MCP server not found
   ```
   **Solution**: Check your config.json path and restart Cursor

### Debug Mode

Enable debug mode in your config:

```json
{
  "mcpServers": {
    "supabase": {
      "command": "npx",
      "args": [
        "@modelcontextprotocol/server-supabase",
        "--debug"
      ],
      "env": {
        // ... your environment variables
      }
    }
  }
}
```

## 📚 Useful Queries for Your VAGUS App

### Check Database Health
```sql
-- User count by role
SELECT role, COUNT(*) as count FROM profiles GROUP BY role;

-- Recent AI usage
SELECT user_id, month, year, tokens_used, request_count 
FROM ai_usage 
ORDER BY created_at DESC LIMIT 10;

-- Coach-client relationships
SELECT 
    cc.coach_id,
    p1.name as coach_name,
    cc.client_id,
    p2.name as client_name,
    cc.status
FROM user_coach_links cc
JOIN profiles p1 ON cc.coach_id = p1.id
JOIN profiles p2 ON cc.client_id = p2.id
ORDER BY cc.created_at DESC;
```

### Monitor Performance
```sql
-- Table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Index usage
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_tup_read DESC;
```

## 🎯 Next Steps

1. **Test the connection** with simple queries
2. **Explore your database schema** using MCP commands
3. **Create custom queries** for your specific needs
4. **Set up monitoring** for database performance
5. **Integrate with your development workflow**

---

**You're now ready to use MCP Supabase integration with Cursor IDE!** 🚀

Try running `@supabase list tables` in a new Cursor chat to get started.
