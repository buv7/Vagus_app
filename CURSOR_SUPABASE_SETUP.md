# Cursor IDE + Supabase Database Connection Guide

This guide will help you connect Cursor IDE directly to your Supabase PostgreSQL database using the session pooler connection.

## 🔗 Connection Details

### Session Pooler Connection (Recommended)
```
Host: aws-0-eu-central-1.pooler.supabase.com
Port: 5432
Database: postgres
Username: postgres.kydrpnrmqbedjflklgue
Password: X.7achoony.X
```

### Connection String Format
```
postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres
```

## 🛠️ Setting Up Cursor IDE Database Connection

### Method 1: Using Cursor's Database Extension

1. **Install Database Extension**
   - Open Cursor IDE
   - Go to Extensions (Ctrl+Shift+X)
   - Search for "PostgreSQL" or "Database Client"
   - Install a PostgreSQL extension (recommended: "PostgreSQL" by Chris Kolkman)

2. **Add New Connection**
   - Open Command Palette (Ctrl+Shift+P)
   - Type "PostgreSQL: New Connection"
   - Fill in the connection details:
     ```
     Connection Name: Vagus App Supabase
     Host: aws-0-eu-central-1.pooler.supabase.com
     Port: 5432
     Database: postgres
     Username: postgres.kydrpnrmqbedjflklgue
     Password: X.7achoony.X
     SSL Mode: Require
     ```

3. **Test Connection**
   - Click "Test Connection" to verify
   - If successful, click "Save Connection"

### Method 2: Using Cursor's Built-in Database Features

1. **Open Database Panel**
   - Look for database icon in the sidebar
   - Or use Command Palette: "Database: Connect to Database"

2. **Configure Connection**
   - Select PostgreSQL as database type
   - Enter connection details from above
   - Enable SSL for security

### Method 3: Using SQL Files with Connection

1. **Create SQL Connection File**
   - Create a new file: `.vscode/settings.json` (if not exists)
   - Add database connection configuration:

```json
{
  "database.connections": [
    {
      "name": "Vagus Supabase",
      "type": "postgresql",
      "host": "aws-0-eu-central-1.pooler.supabase.com",
      "port": 5432,
      "database": "postgres",
      "username": "postgres.kydrpnrmqbedjflklgue",
      "password": "X.7achoony.X",
      "ssl": true
    }
  ]
}
```

## 🔍 Alternative Connection Options

### Shared Pooler (Port 6543)
```
postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:6543/postgres
```

### Direct Connection (if pooler is unavailable)
```
postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres
```

## 📊 Database Schema Overview

Your Supabase database contains the following key tables:

### Core Tables
- `profiles` - User profile information
- `ai_usage` - AI request tracking with monthly limits
- `user_files` - File metadata and organization
- `user_devices` - OneSignal device registration
- `nutrition_plans` - AI-generated meal plans
- `workout_plans` - Fitness routine data

### Security Features
- **Row Level Security (RLS)** - Data isolation per user
- **JWT Authentication** - Secure API access
- **Service Role Keys** - Admin operations via Edge Functions

## 🚀 Quick Start Queries

### Test Connection
```sql
SELECT version();
SELECT current_database();
SELECT current_user;
```

### View Database Schema
```sql
-- List all tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';

-- View table structure
\d+ profiles
\d+ ai_usage
\d+ user_files
```

### Sample Data Queries
```sql
-- Check user profiles
SELECT id, email, name, role, created_at 
FROM profiles 
LIMIT 10;

-- Check AI usage
SELECT user_id, month, year, tokens_used, request_count 
FROM ai_usage 
ORDER BY created_at DESC 
LIMIT 10;

-- Check user files
SELECT id, user_id, filename, file_type, file_size, created_at 
FROM user_files 
ORDER BY created_at DESC 
LIMIT 10;
```

## 🔧 Troubleshooting

### Common Issues

1. **Connection Timeout**
   - Check if you're using the correct port (5432 for session pooler)
   - Verify SSL is enabled
   - Ensure your IP is not blocked by Supabase

2. **Authentication Failed**
   - Double-check username and password
   - Ensure you're using the correct project reference

3. **SSL Certificate Issues**
   - Enable SSL mode in connection settings
   - Some clients may need to accept self-signed certificates

### Connection Pool Limits

- **Session Pooler**: 15 connections per user/database pair
- **Shared Pooler**: 100 client connections maximum
- **Direct Connection**: 60 connections maximum

## 📝 Best Practices

1. **Use Session Pooler** for development and testing
2. **Use Shared Pooler** for production applications
3. **Always enable SSL** for security
4. **Monitor connection usage** to avoid hitting limits
5. **Use connection pooling** in your applications

## 🔐 Security Notes

- Never commit database credentials to version control
- Use environment variables for sensitive data
- Regularly rotate database passwords
- Monitor database access logs
- Use Row Level Security (RLS) for data protection

## 📚 Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Cursor IDE Database Extensions](https://marketplace.visualstudio.com/search?target=VSCode&category=Databases)

---

**Note**: This connection setup is for development purposes. For production, ensure you're using proper environment variable management and secure credential storage.
