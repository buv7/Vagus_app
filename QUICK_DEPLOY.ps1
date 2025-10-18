# Quick Deployment Script for VAGUS App
# Run this script to deploy the latest version to Vercel

Write-Host "🚀 VAGUS App - Quick Deployment Script" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Cyan

# Step 1: Clean and Prepare
Write-Host "📦 Step 1: Cleaning and preparing..." -ForegroundColor Blue
flutter clean
flutter pub get

# Step 2: Build the App
Write-Host "🔨 Step 2: Building Flutter web app..." -ForegroundColor Blue
flutter build web --release

# Step 3: Deploy to Vercel
Write-Host "🚀 Step 3: Deploying to Vercel..." -ForegroundColor Blue
Set-Location "build/web"
npx vercel --prod --yes
Set-Location "../.."

Write-Host "✅ Deployment complete!" -ForegroundColor Green
Write-Host "🌐 Check the Vercel URL above for your latest deployment" -ForegroundColor Cyan
Write-Host "🎯 Your Iraqi titles should now be live!" -ForegroundColor Yellow
