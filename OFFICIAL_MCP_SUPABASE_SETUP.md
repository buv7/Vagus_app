# 🚀 Official MCP Supabase Setup for Cursor IDE

This guide shows you how to install and configure the **official** Supabase MCP server for Cursor IDE.

## 📋 Prerequisites

- Cursor IDE installed
- Supabase account and project
- Node.js (for npx command)

## 🔑 Step 1: Generate Supabase Personal Access Token

### Get Your Access Token

1. **Log in to Supabase Dashboard**
   - Go to [supabase.com](https://supabase.com)
   - Sign in to your account

2. **Navigate to Account Settings**
   - Click on your profile/avatar in the top right
   - Select "Account Settings"

3. **Create Personal Access Token**
   - Go to **Access Tokens** section
   - Click **"Create New Token"**
   - Give it a descriptive name: `"Cursor MCP Server"`
   - Click **"Generate Token"**
   - **⚠️ IMPORTANT**: Copy the token immediately - it won't be shown again!

4. **Save the Token Safely**
   - Store it in a secure place
   - You'll need it for the configuration

## 🔧 Step 2: Find Your Project Reference

### Get Your Project Reference ID

1. **Go to Your Supabase Project**
   - Open your VAGUS project in Supabase Dashboard

2. **Find Project Reference**
   - Look at your project URL: `https://supabase.com/dashboard/project/kydrpnrmqbedjflklgue`
   - Your project reference is: `kydrpnrmqbedjflklgue`

## ⚙️ Step 3: Configure Cursor IDE

### Create MCP Configuration File

**Windows Path:**
```
%APPDATA%\Cursor\User\globalStorage\cursor.mcp\config.json
```

**macOS Path:**
```
~/Library/Application Support/Cursor/User/globalStorage/cursor.mcp/config.json
```

**Linux Path:**
```
~/.config/Cursor/User/globalStorage/cursor.mcp/config.json
```

### Configuration Options

#### Option 1: Basic Configuration (All Projects Access)
```json
{
  "mcpServers": {
    "supabase": {
      "command": "npx",
      "args": [
        "-y",
        "@supabase/mcp-server-supabase@latest",
        "--access-token",
        "YOUR_PERSONAL_ACCESS_TOKEN_HERE"
      ]
    }
  }
}
```

#### Option 2: Project-Scoped Configuration (Recommended)
```json
{
  "mcpServers": {
    "supabase": {
      "command": "npx",
      "args": [
        "-y",
        "@supabase/mcp-server-supabase@latest",
        "--access-token",
        "YOUR_PERSONAL_ACCESS_TOKEN_HERE",
        "--project-ref",
        "kydrpnrmqbedjflklgue"
      ]
    }
  }
}
```

#### Option 3: Read-Only Configuration (Safe for Production)
```json
{
  "mcpServers": {
    "supabase": {
      "command": "npx",
      "args": [
        "-y",
        "@supabase/mcp-server-supabase@latest",
        "--access-token",
        "YOUR_PERSONAL_ACCESS_TOKEN_HERE",
        "--project-ref",
        "kydrpnrmqbedjflklgue",
        "--read-only"
      ]
    }
  }
}
```

### Replace the Placeholders

1. **Replace `YOUR_PERSONAL_ACCESS_TOKEN_HERE`** with your actual token
2. **Replace `kydrpnrmqbedjflklgue`** with your project reference (if using project-scoped mode)

## 🔄 Step 4: Restart Cursor IDE

1. **Close Cursor completely**
2. **Reopen Cursor IDE**
3. **Check MCP status** in the bottom status bar

## 🧪 Step 5: Test the Connection

### Test Commands in Cursor Chat

Open a new chat in Cursor and try these commands:

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

## 🛠️ Available MCP Commands

Once connected, you can use these commands:

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

## 🚨 Troubleshooting

### Common Issues

1. **"MCP server not found"**
   - Check your config file path
   - Ensure the file is named `config.json` (not `config.json.txt`)
   - Restart Cursor after making changes

2. **"Authentication failed"**
   - Verify your Personal Access Token is correct
   - Make sure the token hasn't expired
   - Check that you copied the token completely

3. **"Project not found"**
   - Verify your project reference ID
   - Make sure you have access to the project
   - Try without `--project-ref` flag first

4. **"Connection timeout"**
   - Check your internet connection
   - Verify Supabase services are running
   - Try again in a few minutes

### Debug Steps

1. **Check MCP Status**
   - Look at the bottom status bar in Cursor
   - Should show "MCP: Connected" or similar

2. **Verify Configuration**
   - Double-check your config.json syntax
   - Ensure no extra commas or missing quotes

3. **Test with Simple Commands**
   - Start with `@supabase list projects`
   - Then try `@supabase list tables`

## 🔐 Security Best Practices

1. **Use Project-Scoped Mode**
   - Restrict access to only your VAGUS project
   - Prevents accidental access to other projects

2. **Use Read-Only Mode for Production**
   - Prevents accidental data modifications
   - Safe for monitoring and debugging

3. **Rotate Access Tokens Regularly**
   - Generate new tokens periodically
   - Revoke old tokens when no longer needed

4. **Store Tokens Securely**
   - Don't commit tokens to version control
   - Use environment variables if possible

## 📚 Additional Resources

- [Official Supabase MCP Documentation](https://supabase.com/docs/guides/getting-started/mcp)
- [Supabase Personal Access Tokens](https://supabase.com/docs/guides/platform/access-tokens)
- [Cursor IDE MCP Integration](https://cursor.sh/docs)

## 🎯 Quick Start Checklist

- [ ] Generated Personal Access Token from Supabase
- [ ] Found your project reference ID
- [ ] Created MCP config file in correct location
- [ ] Added configuration with your token and project ref
- [ ] Restarted Cursor IDE
- [ ] Tested with `@supabase list projects`
- [ ] Tested with `@supabase list tables`

---

**You're now ready to use the official Supabase MCP server with Cursor IDE!** 🚀

Start with `@supabase list projects` to verify everything is working.
