# Turn-By-Turn Ski Trails

A 3D ski resort mapping application built with SwiftUI that provides interactive trail maps, turn-by-turn navigation, and real-time resort information.

## Features

- Interactive 3D map of ski resorts with lifts and runs
- Turn-by-turn navigation between points
- Filtering for runs by difficulty level
- Real-time lift and run status updates
- Weather and snow condition information

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

1. Clone the repository
2. Set up environment variables (see Environment Configuration below)
3. Open `SkiTrails.xcodeproj` in Xcode
4. Build and run

## Environment Configuration

The app requires several environment variables to be set. These can be configured in two ways:

1. Using Xcode scheme environment variables (recommended for development)
2. Using launch arguments when running the app (recommended for CI/CD)

Required environment variables:
```
MAPBOX_ACCESS_TOKEN=your_mapbox_token
WEATHER_UNLOCKED_API_KEY=your_weather_api_key
WEATHER_UNLOCKED_APP_ID=your_weather_app_id
SKI_API_KEY=your_ski_api_key
SENTRY_DSN=your_sentry_dsn
```

See `.env.example` for a complete list of available configuration options.

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

The project is structured into two main targets:
- `SkiTrails`: The main iOS app
- `SkiTrailsCore`: A Swift Package containing core business logic and models

## License

This project is licensed under the MIT License - see the LICENSE file for details. 