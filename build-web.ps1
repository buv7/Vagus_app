# Vagus App - Flutter Web Build Script for Vercel
# This script builds the Flutter web app for Vercel deployment

Write-Host "🚀 Building Vagus App for Vercel Web Deployment..." -ForegroundColor Green

# Clean previous builds
Write-Host "🧹 Cleaning previous builds..." -ForegroundColor Yellow
flutter clean

# Get dependencies
Write-Host "📦 Getting dependencies..." -ForegroundColor Yellow
flutter pub get

# Build for web with production settings
Write-Host "🏗️  Building Flutter web app for Vercel..." -ForegroundColor Yellow
flutter build web --release --web-renderer html --dart-define=FLUTTER_WEB_AUTO_DETECT=true

# Check if build was successful
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build successful!" -ForegroundColor Green
    Write-Host "📁 Output directory: build/web" -ForegroundColor Cyan
    Write-Host "🌐 Ready for Vercel deployment to vagus.fit" -ForegroundColor Cyan
    
    # List build output
    Write-Host "📋 Build contents:" -ForegroundColor Yellow
    Get-ChildItem -Path "build/web" | Format-Table Name, Length, LastWriteTime
    
    Write-Host "`n🚀 Next steps:" -ForegroundColor Green
    Write-Host "1. Run: vercel --prod" -ForegroundColor White
    Write-Host "2. Or deploy via Vercel dashboard" -ForegroundColor White
    Write-Host "3. Configure custom domain: vagus.fit" -ForegroundColor White
} else {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}
