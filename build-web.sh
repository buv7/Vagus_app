#!/bin/bash

# Vagus App - Flutter Web Build Script
# This script builds the Flutter web app for production deployment

echo "🚀 Building Vagus App for Web..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build for web with production settings
echo "🏗️  Building Flutter web app..."
flutter build web \
  --release \
  --web-renderer html \
  --dart-define=FLUTTER_WEB_AUTO_DETECT=true \
  --source-maps

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "📁 Output directory: build/web"
    echo "🌐 Ready for deployment to vagus.fit"
    
    # List build output
    echo "📋 Build contents:"
    ls -la build/web/
else
    echo "❌ Build failed!"
    exit 1
fi
