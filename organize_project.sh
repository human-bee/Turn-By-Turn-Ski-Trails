#!/bin/bash

echo "🚀 Starting project organization..."

# 1. Ensure SkiTrails-iOS exists and has correct subdirectories
echo "📁 Setting up main project directory structure..."
mkdir -p "SkiTrails-iOS/SkiTrails/"{Views,ViewModels,Extensions,en.lproj,Images.xcassets}
mkdir -p "SkiTrails-iOS/SkiTrailsCore/Sources/SkiTrailsCore/"{Models,Configuration,Services,Routing,ViewModels}

# 2. Move core files from original Sources to SkiTrails-iOS/SkiTrailsCore
echo "📦 Moving core files..."
if [ -d "Sources/SkiTrailsCore" ]; then
    cp -rv "Sources/SkiTrailsCore/Models/"* "SkiTrails-iOS/SkiTrailsCore/Sources/SkiTrailsCore/Models/"
    cp -rv "Sources/SkiTrailsCore/Configuration/"* "SkiTrails-iOS/SkiTrailsCore/Sources/SkiTrailsCore/Configuration/"
    cp -rv "Sources/SkiTrailsCore/Services/"* "SkiTrails-iOS/SkiTrailsCore/Sources/SkiTrailsCore/Services/"
    cp -rv "Sources/SkiTrailsCore/Routing/"* "SkiTrails-iOS/SkiTrailsCore/Sources/SkiTrailsCore/Routing/"
    cp -rv "Sources/SkiTrailsCore/ViewModels/"* "SkiTrails-iOS/SkiTrailsCore/Sources/SkiTrailsCore/ViewModels/"
fi

# 3. Move app files to SkiTrails-iOS/SkiTrails
echo "📱 Moving app files..."
if [ -d "SkiTrails" ]; then
    cp -rv "SkiTrails/Views/"* "SkiTrails-iOS/SkiTrails/Views/"
    cp -rv "SkiTrails/ViewModels/"* "SkiTrails-iOS/SkiTrails/ViewModels/"
    cp -rv "SkiTrails/Extensions/"* "SkiTrails-iOS/SkiTrails/Extensions/"
    cp -rv "SkiTrails/Images.xcassets/"* "SkiTrails-iOS/SkiTrails/Images.xcassets/"
    cp -rv "SkiTrails/en.lproj/"* "SkiTrails-iOS/SkiTrails/en.lproj/"
    cp -v "SkiTrails/Info.plist" "SkiTrails-iOS/SkiTrails/"
    cp -v "SkiTrails/SkiTrailsApp.swift" "SkiTrails-iOS/SkiTrails/"
fi

# 4. Copy configuration files
echo "⚙️ Copying configuration files..."
cp -v ".env" "SkiTrails-iOS/"
cp -v ".env.example" "SkiTrails-iOS/"
cp -v "Package.swift" "SkiTrails-iOS/SkiTrailsCore/"

# 5. Verify the structure
echo "✅ Verifying directory structure..."
tree "SkiTrails-iOS" || ls -R "SkiTrails-iOS"

echo "🧹 Cleaning up..."
# Don't delete anything yet, just list what would be removed
echo "The following directories can be removed after verification:"
echo "- SkiTrails/"
echo "- SkiTrailsCore/"
echo "- Sources/"
echo "- App/"

echo "✨ Organization complete!"
echo "Please verify the contents in SkiTrails-iOS before removing old directories." 