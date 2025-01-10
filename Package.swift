// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SkiTrailsCore",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "SkiTrailsCore",
            targets: ["SkiTrailsCore"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/mapbox/mapbox-maps-ios.git", from: "10.0.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
        .package(url: "https://github.com/getsentry/sentry-cocoa.git", from: "8.0.0")
    ],
    targets: [
        .target(
            name: "SkiTrailsCore",
            dependencies: [
                .product(name: "MapboxMaps", package: "mapbox-maps-ios"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "Sentry", package: "sentry-cocoa")
            ],
            path: "Sources/SkiTrailsCore",
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "SkiTrailsCoreTests",
            dependencies: ["SkiTrailsCore"]
        )
    ]
) 