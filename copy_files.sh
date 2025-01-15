#!/bin/bash

# Create necessary directories in SkiTrailsCore
mkdir -p SkiTrailsCore/Sources/SkiTrailsCore/{Models,Configuration,Services,Routing,ViewModels}

# Copy core files from original Sources/SkiTrailsCore to new SkiTrailsCore
echo "Copying core files..."
cp -r Sources/SkiTrailsCore/Models/* SkiTrailsCore/Sources/SkiTrailsCore/Models/
cp -r Sources/SkiTrailsCore/Configuration/* SkiTrailsCore/Sources/SkiTrailsCore/Configuration/
cp -r Sources/SkiTrailsCore/Services/* SkiTrailsCore/Sources/SkiTrailsCore/Services/
cp -r Sources/SkiTrailsCore/Routing/* SkiTrailsCore/Sources/SkiTrailsCore/Routing/
cp -r Sources/SkiTrailsCore/ViewModels/* SkiTrailsCore/Sources/SkiTrailsCore/ViewModels/
cp Sources/SkiTrailsCore/SkiTrailsCore.swift SkiTrailsCore/Sources/SkiTrailsCore/

# Copy app files from App/SkiTrails to new SkiTrails
echo "Copying app files..."
mkdir -p SkiTrails/{Views,ViewModels,Extensions,en.lproj}

cp -r App/SkiTrails/Views/* SkiTrails/Views/
cp -r App/SkiTrails/ViewModels/* SkiTrails/ViewModels/
cp -r App/SkiTrails/Extensions/* SkiTrails/Extensions/
cp App/SkiTrails/SkiTrailsApp.swift SkiTrails/
cp App/SkiTrails/Info.plist SkiTrails/

# Copy resources
echo "Copying resources..."
cp -r App/SkiTrails/Images.xcassets SkiTrails/
cp App/SkiTrails/en.lproj/Localizable.strings SkiTrails/en.lproj/

echo "Copy complete! Please verify the files." 