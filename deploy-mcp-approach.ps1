# MCP-based deployment script for VAGUS App
# Uses the correct Supabase connection string and MCP approach

Write-Host "🚀 MCP-based deployment for VAGUS App..." -ForegroundColor Green

# Set the correct environment variables
$env:SUPABASE_URL = "https://kydrpnrmqbedjflklgue.supabase.co"
$env:DATABASE_URL = "postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres"

# You'll need to get the anon key from Supabase dashboard
# Go to: https://supabase.com/dashboard/project/kydrpnrmqbedjflklgue/settings/api
$env:SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt5ZHJwbnJtcWJlZGpmbGtsZ3VlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQyMjUxODAsImV4cCI6MjA2OTgwMTE4MH0.qlpGUiy17IbDsfgOf3-F2XBjOajjwxfy2NLMlUZWaqo"

Write-Host "📦 Getting Flutter dependencies..." -ForegroundColor Blue
flutter pub get

Write-Host "🔨 Building Flutter web app..." -ForegroundColor Blue
flutter build web --release

Write-Host "🚀 Deploying to Vercel with MCP integration..." -ForegroundColor Blue
vercel --prod

Write-Host "✅ Deployment complete!" -ForegroundColor Green
Write-Host "🌐 Your app should be live at vagus.fit" -ForegroundColor Cyan
Write-Host "🔗 Supabase URL: https://kydrpnrmqbedjflklgue.supabase.co" -ForegroundColor Cyan
Write-Host "📊 Database: Connected via MCP session pooler" -ForegroundColor Cyan
