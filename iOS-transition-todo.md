# iOS App Transition Plan

## 1. Create New Xcode Project
- [x] Create new iOS app project using SwiftUI template
- [x] Configure basic app settings (name, bundle ID, team)
- [x] Set minimum deployment target to iOS 17 (using 17.6)
- [x] Ensure SwiftUI lifecycle is selected (verified via SkiTrailsApp.swift)

## 2. Package Structure
### 2.1 Create Local Package
- [x] Create new local package "SkiTrailsCore" in SkiTrails-iOS project
- [x] Configure Package.swift with correct dependencies:
  - [x] MapboxMaps (10.16.0..<11.0.0)
  - [x] Turf (exact: 2.8.0)
- [x] Set platform requirements (iOS 17)

### 2.2 Directory Structure Migration
- [x] Create initial package structure:
  - [x] Sources/SkiTrailsCore/
  - [x] Tests/SkiTrailsCoreTests/
- [x] Migrate core directories maintaining structure:
  - [x] Routing/
  - [x] Services/
  - [x] Models/
  - [x] ViewModels/
  - [x] Configuration/

### 2.3 File Migration (with verification)
- [x] For each directory:
  - [x] Copy files (already in correct location)
  - [x] Verify imports (all required imports are present and correct)
  - [x] Test compilation (package builds successfully)
  - [x] Document any issues or needed changes (no issues found)

### 2.4 Package Integration
- [x] Add SkiTrailsCore package dependency to main app target
- [x] Verify package builds independently (builds successfully)
- [x] Test package integration with main app (Hello World app runs)

## 3. Code Migration
- [x] Move app-specific code from App/SkiTrails to main app target
  - [x] Views (MapView, MapboxMapView, MapSelectionView, etc.)
  - [x] ViewModels (NavigationViewModel, ResortViewModel, ContentViewModel)
  - [x] App lifecycle code (SkiTrailsApp.swift)
  - [x] Resources and assets (moved SkiDifficulty+Color extension)
- [x] Update import statements (all files using correct imports)
- [x] Fix any broken references (no broken references found)

## 4. Resource Migration
- [x] Move Images.xcassets to main app target (created with AppIcon configuration)
- [x] Configure Info.plist (added location and Mapbox keys)
- [x] Move any localization files (created en.lproj/Localizable.strings)
- [x] Set up environment variables/configuration (Mapbox token configured)

## 5. Dependencies
- [x] Set up Mapbox in main app target (MapView and MapboxMapView configured)
- [x] Configure any required capabilities (location services in Info.plist)
- [x] Add any needed app-specific frameworks
  - [x] CoreLocation (already included via Info.plist)
  - [x] CoreMotion (for skiing activity tracking)
  - [x] BackgroundTasks (for navigation updates)
  - [ ] StoreKit (future: in-app purchases)

## 6. Testing
- [ ] Verify all views render correctly
  - [ ] Check localized strings display properly
  - [ ] Verify layout on different screen sizes
- [ ] Test navigation flow
- [ ] Verify map functionality
- [ ] Check all features work as expected
- [ ] Test on different iOS devices/simulators

## 7. Cleanup
- [ ] Remove old package-based project structure
- [ ] Update documentation
- [ ] Update any build scripts or workflows
- [ ] Archive old code if needed

## 8. Future Considerations
- [ ] Plan for visionOS support
- [ ] Consider watchOS companion app
- [ ] Plan for TestFlight distribution
- [ ] Set up CI/CD with Xcode Cloud

## Notes
- Keep the core functionality in SkiTrailsCore package for potential reuse
- Ensure proper separation of concerns between app and package
- Document any configuration requirements for future reference
- Organization identifier: Bens-Bots.SkiTrails 