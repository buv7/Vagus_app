# Vagus App MCP Deployment Control

## 🚀 Full Control Over Your Vagus App Deployment

This MCP (Model Context Protocol) server gives you complete programmatic control over your Vagus app deployments across GitHub, Vercel, and Supabase.

## 📋 Available Tools

### 1. **deploy_to_github**
- Commit and push all changes to GitHub
- Push to all branches (main, develop)
- Push all tags

### 2. **deploy_to_vercel** 
- Build Flutter web app
- Deploy to Vercel production (vagus.fit)
- Handle build optimization

### 3. **deploy_to_supabase**
- Apply database migrations safely
- Use session pooler connection
- Handle schema updates

### 4. **full_deployment** ⭐
- Complete deployment pipeline
- GitHub → Flutter Build → Vercel → Supabase
- One command deployment

### 5. **check_deployment_status**
- Check Git status
- Verify Flutter installation
- Check Vercel CLI
- Check Supabase CLI

### 6. **build_flutter_web**
- Build Flutter web application
- Optimize for production

### 7. **run_database_migration**
- Run specific migration files
- Direct database control

## 🛠️ Setup Instructions

### 1. Install Dependencies
```bash
npm install @modelcontextprotocol/sdk pg
```

### 2. Configure MCP Server
The MCP server is already configured in `mcp-vagus-config.json`:
```json
{
  "mcpServers": {
    "vagus-deployment": {
      "command": "node",
      "args": ["mcp-vagus-deployment.js"],
      "cwd": "C:\\Users\\alhas\\StudioProjects\\vagus_app"
    }
  }
}
```

### 3. Test the Server
```bash
node test-mcp.js
```

## 🎯 Usage Examples

### Full Deployment (Recommended)
```javascript
// Deploy everything with one command
{
  "name": "full_deployment",
  "arguments": {
    "message": "Deploy latest features: Revolutionary Plan Builder + Coach Marketplace",
    "buildFlutter": true
  }
}
```

### Check Status
```javascript
// Check deployment status
{
  "name": "check_deployment_status",
  "arguments": {}
}
```

### Deploy to Vercel Only
```javascript
// Deploy to vagus.fit
{
  "name": "deploy_to_vercel",
  "arguments": {
    "build": true,
    "production": true
  }
}
```

## 🔧 Configuration

### Supabase Connection
- **Connection String**: `postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres`
- **Safe Mode**: Enabled by default
- **Migration Files**: Located in `supabase/migrations/`

### Vercel Configuration
- **Production Domain**: vagus.fit
- **Build Command**: `flutter build web`
- **Output Directory**: web/

### GitHub Configuration
- **Repository**: https://github.com/buv7/Vagus_app.git
- **Branches**: main, develop
- **Auto-push**: All branches and tags

## 🚨 Troubleshooting

### Common Issues
1. **Vercel CLI not authenticated**: Run `vercel login`
2. **Flutter not found**: Ensure Flutter is in PATH
3. **Database connection failed**: Check connection string
4. **Git conflicts**: Resolve conflicts before deployment

### Debug Mode
```bash
# Run with debug output
DEBUG=* node mcp-vagus-deployment.js
```

## 📊 Deployment Pipeline

```
1. GitHub Push
   ├── Stage all changes
   ├── Commit with message
   ├── Push to all branches
   └── Push all tags

2. Flutter Build
   ├── Clean build
   ├── Optimize for web
   └── Output to web/

3. Vercel Deployment
   ├── Deploy to production
   ├── Update vagus.fit
   └── Handle CDN cache

4. Supabase Migration
   ├── Apply schema updates
   ├── Run safe migrations
   └── Verify database
```

## 🎉 Benefits

- **One Command Deployment**: Deploy everything with a single MCP call
- **Full Control**: Programmatic access to all deployment steps
- **Safe Migrations**: Prevents database conflicts
- **Status Monitoring**: Real-time deployment status
- **Error Handling**: Comprehensive error reporting
- **Automation Ready**: Perfect for CI/CD pipelines

## 🔗 Integration

This MCP server can be integrated with:
- Claude Desktop
- Cursor IDE
- Custom deployment scripts
- CI/CD pipelines
- Monitoring systems

---

**Ready to deploy?** Use the `full_deployment` tool for complete control! 🚀
