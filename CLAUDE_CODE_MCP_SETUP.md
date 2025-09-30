# 🚀 Claude Code MCP Setup for Supabase

This guide shows you how to configure **Claude Code** to have full control over your VAGUS app's Supabase database using the Model Context Protocol (MCP).

## 📋 Prerequisites

- Claude Code installed and running
- Node.js (for npx command)
- Your VAGUS Supabase project access

## 🔧 Step 1: Install Claude Code MCP Configuration

### Option A: Using Claude Desktop (Recommended)

1. **Find Claude Desktop Config Directory:**
   - **Windows:** `%APPDATA%\Claude\claude_desktop_config.json`
   - **macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`
   - **Linux:** `~/.config/claude/claude_desktop_config.json`

2. **Create or Edit Configuration File:**
   ```json
   {
     "mcpServers": {
       "supabase": {
         "command": "npx",
         "args": [
           "-y",
           "@supabase/mcp-server-supabase@latest",
           "--access-token",
           "sbp_18948856afbd636e7a4e101e4cea3987e1fe148b",
           "--project-ref",
           "kydrpnrmqbedjflklgue"
         ]
       }
     }
   }
   ```

### Option B: Using Claude Code Extension

1. **Open VS Code with Claude Code Extension**
2. **Go to Settings** → **Extensions** → **Claude Code**
3. **Add MCP Configuration:**
   ```json
   {
     "mcpServers": {
       "supabase": {
         "command": "npx",
         "args": [
           "-y",
           "@supabase/mcp-server-supabase@latest",
           "--access-token",
           "sbp_18948856afbd636e7a4e101e4cea3987e1fe148b",
           "--project-ref",
           "kydrpnrmqbedjflklgue"
         ]
       }
     }
   }
   ```

## 🔄 Step 2: Restart Claude Code

1. **Close Claude Desktop/VS Code completely**
2. **Reopen the application**
3. **Check MCP status** in the bottom status bar or settings

## 🧪 Step 3: Test the Connection

### Test Commands in Claude Chat

Open a new chat in Claude and try these commands:

```
@supabase list projects
```

```
@supabase list tables
```

```
@supabase describe table profiles
```

```
@supabase query "SELECT COUNT(*) FROM profiles"
```

## 🛠️ Available MCP Commands for Claude

Once connected, Claude can use these commands to manage your VAGUS database:

### Project Management
- `@supabase list projects` - List all your Supabase projects
- `@supabase describe project` - Get project details

### Database Operations
- `@supabase list tables` - List all tables in your database
- `@supabase describe table <table_name>` - Get table schema
- `@supabase query "<SQL>"` - Execute SQL queries
- `@supabase list schemas` - List database schemas

### Supabase Features
- `@supabase list functions` - List Edge Functions
- `@supabase list buckets` - List Storage buckets
- `@supabase list policies` - List RLS policies

## 🔍 Example Queries for Your VAGUS App

### Check User Statistics
```sql
@supabase query "SELECT role, COUNT(*) FROM profiles GROUP BY role"
```

### View Recent Users
```sql
@supabase query "SELECT id, email, name, role, created_at FROM profiles ORDER BY created_at DESC LIMIT 10"
```

### Check AI Usage
```sql
@supabase query "SELECT user_id, month, year, tokens_used FROM ai_usage ORDER BY created_at DESC LIMIT 5"
```

### Coach-Client Relationships
```sql
@supabase query "SELECT cc.coach_id, cc.client_id, p.name as client_name FROM user_coach_links cc JOIN profiles p ON cc.client_id = p.id LIMIT 10"
```

### Check Database Health
```sql
@supabase query "SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size FROM pg_tables WHERE schemaname = 'public' ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC LIMIT 10"
```

## 🚨 Troubleshooting

### Common Issues

1. **"MCP server not found"**
   - Check your config file path
   - Ensure the file is named correctly
   - Restart Claude after making changes

2. **"Authentication failed"**
   - Verify your Personal Access Token is correct
   - Make sure the token hasn't expired
   - Check that you copied the token completely

3. **"Project not found"**
   - Verify your project reference ID: `kydrpnrmqbedjflklgue`
   - Make sure you have access to the project
   - Try without `--project-ref` flag first

4. **"Connection timeout"**
   - Check your internet connection
   - Verify Supabase services are running
   - Try again in a few minutes

### Debug Steps

1. **Check MCP Status**
   - Look at the bottom status bar in Claude
   - Should show "MCP: Connected" or similar

2. **Verify Configuration**
   - Double-check your config.json syntax
   - Ensure no extra commas or missing quotes

3. **Test with Simple Commands**
   - Start with `@supabase list projects`
   - Then try `@supabase list tables`

## 🔐 Security Best Practices

1. **Project-Scoped Access**
   - Your configuration is limited to project `kydrpnrmqbedjflklgue`
   - Prevents accidental access to other projects

2. **Token Management**
   - Your access token is already configured
   - Rotate tokens periodically for security

3. **Read-Only for Production**
   - Add `--read-only` flag for production monitoring
   - Prevents accidental data modifications

## 📚 What Claude Can Do With This Access

✅ **Full Database Control:**
- Execute any SQL queries
- View all tables and schemas
- Monitor user statistics
- Track AI usage metrics
- Check coach-client relationships
- Monitor database health
- Create and modify data
- Run migrations

✅ **Your Project Details:**
- **Project Reference:** `kydrpnrmqbedjflklgue`
- **Access Token:** Already configured
- **Database:** Connected to your VAGUS Supabase instance

## 🎯 Quick Start Checklist

- [ ] Created MCP config file in correct location
- [ ] Added configuration with your token and project ref
- [ ] Restarted Claude Code
- [ ] Tested with `@supabase list projects`
- [ ] Tested with `@supabase list tables`

## 🚀 Next Steps

Once configured, you can ask Claude to:

1. **"Show me all users in my database"**
2. **"Check the health of my database"**
3. **"Find all coach-client relationships"**
4. **"Show me AI usage statistics"**
5. **"Create a new table for [feature]"**
6. **"Run this migration: [SQL]"**
7. **"Optimize my database performance"**

---

**Claude now has full control over your VAGUS Supabase database!** 🎉

Start with `@supabase list projects` to verify everything is working.
