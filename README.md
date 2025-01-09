# Turn-By-Turn Ski Trails

A 3D ski resort mapping application built with SwiftUI that provides interactive trail maps, turn-by-turn navigation, and real-time resort information.

## Features

- Interactive 3D map of ski resorts with lifts and runs
- Turn-by-turn navigation between points
- Filtering for runs by difficulty level
- Real-time lift and run status updates
- Weather and snow condition information

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

## Installation

1. Clone the repository
2. Copy `.env.example` to `.env` and fill in your API keys
3. Open `SkiTrails.xcodeproj` in Xcode
4. Build and run

## APIs Used

- Mapbox for 3D terrain visualization
- Weather Unlocked for snow and weather data
- Liftie API for real-time lift status
- Custom routing engine for navigation

## Architecture

The app follows a clean architecture pattern with:

- SwiftUI views for the UI layer
- MVVM pattern for presentation logic
- Domain layer for business logic
- Data layer for API integration

## License

This project is licensed under the MIT License - see the LICENSE file for details. 