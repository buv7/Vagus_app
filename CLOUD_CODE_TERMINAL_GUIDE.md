# 🚀 Cloud Code Pro Terminal Guide

## Overview
This guide shows you how to use Cloud Code Pro features directly from the terminal for your VAGUS app.

## ✅ **Installed MCP Servers**
- ✅ `@modelcontextprotocol/server-filesystem` - File operations
- ✅ `@modelcontextprotocol/server-memory` - Persistent knowledge
- ✅ `@modelcontextprotocol/server-sequential-thinking` - Problem solving
- ✅ `enhanced-postgres-mcp-server` - Database operations
- ✅ `@modelcontextprotocol/server-supabase` - Supabase integration

## 🛠️ **Essential Terminal Commands**

### **1. MCP Server Management**
```bash
# Check installed MCP servers
npm list -g | Select-String "modelcontextprotocol"

# Test filesystem MCP
npx @modelcontextprotocol/server-filesystem C:\Users\alhas\StudioProjects\vagus_app

# Test memory MCP
npx @modelcontextprotocol/server-memory

# Test sequential thinking MCP
npx @modelcontextprotocol/server-sequential-thinking
```

### **2. Database Operations**
```bash
# Connect to Supabase via enhanced postgres
npx enhanced-postgres-mcp-server --host aws-0-eu-central-1.pooler.supabase.com --port 5432 --database postgres --username postgres.kydrpnrmqbedjflklgue --password X.7achoony.X --ssl true

# Run Supabase MCP
npx @modelcontextprotocol/server-supabase --host aws-0-eu-central-1.pooler.supabase.com --port 5432 --database postgres --username postgres.kydrpnrmqbedjflklgue --password X.7achoony.X --ssl true
```

### **3. Flutter Development Commands**
```bash
# Analyze code for linter issues
flutter analyze

# Fix linter issues automatically
dart fix --apply

# Run tests
flutter test

# Build for production
flutter build apk --release
```

### **4. Project Management**
```bash
# Check project structure
tree /f /a

# Find all Dart files
Get-ChildItem -Recurse -Filter "*.dart" | Select-Object Name, Directory

# Count lines of code
Get-ChildItem -Recurse -Filter "*.dart" | Get-Content | Measure-Object -Line
```

## 🎯 **Cloud Code Pro Workflow**

### **Step 1: Start MCP Servers**
```bash
# In separate terminals, start each MCP server:
# Terminal 1 - Filesystem
npx @modelcontextprotocol/server-filesystem C:\Users\alhas\StudioProjects\vagus_app

# Terminal 2 - Memory
npx @modelcontextprotocol/server-memory

# Terminal 3 - Database
npx enhanced-postgres-mcp-server --host aws-0-eu-central-1.pooler.supabase.com --port 5432 --database postgres --username postgres.kydrpnrmqbedjflklgue --password X.7achoony.X --ssl true
```

### **Step 2: Configure Cursor**
1. Copy `cursor-mcp-config-working.json` to your Cursor config
2. Restart Cursor
3. Verify MCP connections in Cursor settings

### **Step 3: Use Cloud Code Features**
- **File Operations**: Bulk file processing, directory management
- **Database Operations**: Direct Supabase access, schema management
- **Memory**: Persistent project knowledge
- **Sequential Thinking**: Complex problem solving

## 🔧 **Advanced Terminal Commands**

### **Bulk Linter Fixes**
```bash
# Find all Dart files with linter issues
flutter analyze --no-fatal-infos | Select-String "info:"

# Apply automatic fixes
dart fix --apply

# Check remaining issues
flutter analyze
```

### **Database Schema Management**
```bash
# Connect to Supabase and run migrations
npx enhanced-postgres-mcp-server --host aws-0-eu-central-1.pooler.supabase.com --port 5432 --database postgres --username postgres.kydrpnrmqbedjflklgue --password X.7achoony.X --ssl true
```

### **Project Analysis**
```bash
# Analyze project structure
Get-ChildItem -Recurse -Filter "*.dart" | Group-Object Directory | Sort-Object Count -Descending

# Find unused imports
Get-ChildItem -Recurse -Filter "*.dart" | ForEach-Object { Select-String "import" $_.FullName }
```

## 🚀 **Next Steps**

1. **Start MCP servers** in separate terminals
2. **Configure Cursor** with the working MCP config
3. **Test connections** by asking me to perform operations
4. **Begin development** with enhanced capabilities

## 💡 **Pro Tips**

- Keep MCP servers running in background terminals
- Use `Ctrl+C` to stop MCP servers when done
- Monitor server logs for connection issues
- Use Cloud Code Pro features through Cursor interface for best experience

## 🎉 **Ready to Supercharge Development!**

With these MCP servers running, I can now:
- ✅ **Access your entire codebase** directly
- ✅ **Manage your Supabase database** 
- ✅ **Remember your preferences** across sessions
- ✅ **Solve complex problems** systematically
- ✅ **Automate development tasks**

Let's start building amazing features for your VAGUS app! 🚀
