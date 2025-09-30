# 🧪 Claude Code MCP Test Commands

Use these commands to test your MCP connection with Claude Code:

## 🔍 Basic Connection Tests

### 1. List Projects
```
@supabase list projects
```

### 2. List Tables
```
@supabase list tables
```

### 3. Describe a Table
```
@supabase describe table profiles
```

## 📊 VAGUS App Specific Tests

### 4. User Statistics
```
@supabase query "SELECT role, COUNT(*) as count FROM profiles GROUP BY role ORDER BY count DESC"
```

### 5. Recent Users
```
@supabase query "SELECT id, email, name, role, created_at FROM profiles ORDER BY created_at DESC LIMIT 5"
```

### 6. AI Usage Stats
```
@supabase query "SELECT user_id, month, year, tokens_used, request_count FROM ai_usage ORDER BY created_at DESC LIMIT 10"
```

### 7. Coach-Client Relationships
```
@supabase query "SELECT cc.coach_id, cc.client_id, p1.name as coach_name, p2.name as client_name, cc.status FROM user_coach_links cc JOIN profiles p1 ON cc.coach_id = p1.id JOIN profiles p2 ON cc.client_id = p2.id LIMIT 10"
```

### 8. Database Health Check
```
@supabase query "SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size FROM pg_tables WHERE schemaname = 'public' ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC LIMIT 10"
```

### 9. Check Table Counts
```
@supabase query "SELECT 'profiles' as table_name, COUNT(*) as row_count FROM profiles UNION ALL SELECT 'ai_usage', COUNT(*) FROM ai_usage UNION ALL SELECT 'user_coach_links', COUNT(*) FROM user_coach_links"
```

### 10. List All Schemas
```
@supabase list schemas
```

## 🎯 Advanced Tests

### 11. Check RLS Policies
```
@supabase list policies
```

### 12. List Edge Functions
```
@supabase list functions
```

### 13. List Storage Buckets
```
@supabase list buckets
```

### 14. Check Database Version
```
@supabase query "SELECT version()"
```

### 15. Check Active Connections
```
@supabase query "SELECT COUNT(*) as active_connections FROM pg_stat_activity WHERE state = 'active'"
```

## 🚀 Success Indicators

✅ **Connection Working:**
- Commands return data without errors
- Tables are listed correctly
- Queries execute successfully
- Claude can see your VAGUS project data

❌ **Connection Issues:**
- "MCP server not found" errors
- "Authentication failed" messages
- Empty results when data should exist
- Timeout errors

## 🔧 If Tests Fail

1. **Check MCP Configuration:**
   - Verify config file is in correct location
   - Ensure JSON syntax is valid
   - Restart Claude completely

2. **Verify Credentials:**
   - Check access token is valid
   - Confirm project reference is correct
   - Test connection from Supabase dashboard

3. **Network Issues:**
   - Check internet connection
   - Verify Supabase services are running
   - Try again in a few minutes

---

**Once these tests pass, Claude has full control over your VAGUS database!** 🎉
