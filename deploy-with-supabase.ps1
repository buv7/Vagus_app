# PowerShell script to deploy VAGUS App with Supabase integration

Write-Host "🚀 Deploying VAGUS App with Supabase integration..." -ForegroundColor Green

# Set environment variables for Supabase
$env:SUPABASE_URL = "https://kydrpnrmqbedjflklgue.supabase.co"
$env:SUPABASE_ANON_KEY = "your-anon-key-here"  # You'll need to get this from Supabase dashboard
$env:DATABASE_URL = "postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres"

Write-Host "📦 Getting Flutter dependencies..." -ForegroundColor Blue
flutter pub get

Write-Host "🔨 Building Flutter web app..." -ForegroundColor Blue
flutter build web --release

Write-Host "🚀 Deploying to Vercel with Supabase integration..." -ForegroundColor Blue
vercel --prod

Write-Host "✅ Deployment complete!" -ForegroundColor Green
Write-Host "🌐 Your app should be live at vagus.fit" -ForegroundColor Cyan
Write-Host "🔗 Supabase URL: https://kydrpnrmqbedjflklgue.supabase.co" -ForegroundColor Cyan
