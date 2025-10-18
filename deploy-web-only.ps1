# Deploy only the web build to Vercel (optimized for size)

Write-Host "🚀 Deploying VAGUS App (Web Build Only)..." -ForegroundColor Green

# Set environment variables
$env:SUPABASE_URL = "https://kydrpnrmqbedjflklgue.supabase.co"
$env:SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt5ZHJwbnJtcWJlZGpmbGtsZ3VlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQyMjUxODAsImV4cCI6MjA2OTgwMTE4MH0.qlpGUiy17IbDsfgOf3-F2XBjOajjwxfy2NLMlUZWaqo"
$env:DATABASE_URL = "postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres"

Write-Host "📦 Getting Flutter dependencies..." -ForegroundColor Blue
flutter pub get

Write-Host "🔨 Building Flutter web app..." -ForegroundColor Blue
flutter build web --release

Write-Host "📁 Creating deployment directory..." -ForegroundColor Blue
# Create a clean deployment directory
if (Test-Path "deploy") { Remove-Item -Recurse -Force "deploy" }
New-Item -ItemType Directory -Path "deploy" | Out-Null

# Copy only the web build files
Copy-Item -Recurse "build/web/*" "deploy/"

# Copy necessary config files
Copy-Item "vercel.json" "deploy/" -ErrorAction SilentlyContinue
Copy-Item "web/index.html" "deploy/" -ErrorAction SilentlyContinue

Write-Host "🚀 Deploying to Vercel (web build only)..." -ForegroundColor Blue
Set-Location "deploy"
npx vercel --prod
Set-Location ".."

Write-Host "✅ Deployment complete!" -ForegroundColor Green
Write-Host "🌐 Your app should be live at vagus.fit" -ForegroundColor Cyan
Write-Host "🔗 Supabase URL: https://kydrpnrmqbedjflklgue.supabase.co" -ForegroundColor Cyan
Write-Host "📊 Database: Connected via MCP session pooler" -ForegroundColor Cyan
