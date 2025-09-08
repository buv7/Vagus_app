# 🚀 MCP Supabase Setup - Ready to Go!

Your MCP Supabase configuration is ready! Here's exactly what you need to do:

## ✅ **Step 1: Copy the Configuration File**

I've created `cursor-mcp-config-final.json` with your access token already configured.

## 📁 **Step 2: Place the Config File**

Copy the config file to the correct location for your operating system:

### **Windows:**
```bash
# Copy the file to:
%APPDATA%\Cursor\User\globalStorage\cursor.mcp\config.json

# Or manually navigate to:
C:\Users\[YourUsername]\AppData\Roaming\Cursor\User\globalStorage\cursor.mcp\
```

### **macOS:**
```bash
# Copy the file to:
~/Library/Application Support/Cursor/User/globalStorage/cursor.mcp/config.json
```

### **Linux:**
```bash
# Copy the file to:
~/.config/Cursor/User/globalStorage/cursor.mcp/config.json
```

## 🔄 **Step 3: Restart Cursor IDE**

1. **Close Cursor completely** (all windows)
2. **Reopen Cursor IDE**
3. **Check the bottom status bar** - you should see MCP status

## 🧪 **Step 4: Test the Connection**

Open a new chat in Cursor and try these commands:

```
@supabase list projects
```

```
@supabase list tables
```

```
@supabase query "SELECT COUNT(*) FROM profiles"
```

## 🎯 **What You Can Do Now**

Once connected, you can:

### **Database Operations:**
- `@supabase list tables` - See all your tables
- `@supabase describe table profiles` - Get table structure
- `@supabase query "SELECT * FROM profiles LIMIT 5"` - Run SQL queries

### **VAGUS App Specific:**
- `@supabase query "SELECT role, COUNT(*) FROM profiles GROUP BY role"` - Check user roles
- `@supabase query "SELECT * FROM ai_usage ORDER BY created_at DESC LIMIT 10"` - View AI usage
- `@supabase query "SELECT * FROM user_coach_links LIMIT 10"` - Check coach-client relationships

### **Project Management:**
- `@supabase list functions` - List Edge Functions
- `@supabase list buckets` - List Storage buckets
- `@supabase list policies` - List RLS policies

## 🚨 **If Something Goes Wrong**

1. **Check the file location** - Make sure it's in the exact path above
2. **Verify file name** - Must be `config.json` (not `config.json.txt`)
3. **Restart Cursor** - Always restart after config changes
4. **Check MCP status** - Look at bottom status bar

## 🔐 **Security Note**

Your access token is now in the config file. Keep this file secure and don't share it publicly.

## 🎉 **You're All Set!**

Your MCP Supabase integration is configured and ready to use. Start with `@supabase list projects` to verify everything is working!

---

**Need help?** Try the test commands above, and let me know if you encounter any issues!
