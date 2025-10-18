#!/bin/bash

echo "🚀 Deploying VAGUS App to Vercel..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    exit 1
fi

# Check if Vercel CLI is installed
if ! command -v vercel &> /dev/null; then
    echo "📦 Installing Vercel CLI..."
    npm install -g vercel
fi

echo "📦 Getting Flutter dependencies..."
flutter pub get

echo "🔨 Building Flutter web app..."
flutter build web --release

echo "🚀 Deploying to Vercel..."
vercel --prod

echo "✅ Deployment complete!"
echo "🌐 Your app should be live at vagus.fit"
