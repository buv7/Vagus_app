# PowerShell script to deploy VAGUS App to Vercel

Write-Host "🚀 Deploying VAGUS App to Vercel..." -ForegroundColor Green

# Check if Flutter is installed
try {
    flutter --version | Out-Null
    Write-Host "✅ Flutter is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Flutter is not installed. Please install Flutter first." -ForegroundColor Red
    exit 1
}

# Check if Vercel CLI is installed
try {
    vercel --version | Out-Null
    Write-Host "✅ Vercel CLI is installed" -ForegroundColor Green
} catch {
    Write-Host "📦 Installing Vercel CLI..." -ForegroundColor Yellow
    npm install -g vercel
}

Write-Host "📦 Getting Flutter dependencies..." -ForegroundColor Blue
flutter pub get

Write-Host "🔨 Building Flutter web app..." -ForegroundColor Blue
flutter build web --release

Write-Host "🚀 Deploying to Vercel..." -ForegroundColor Blue
vercel --prod

Write-Host "✅ Deployment complete!" -ForegroundColor Green
Write-Host "🌐 Your app should be live at vagus.fit" -ForegroundColor Cyan
