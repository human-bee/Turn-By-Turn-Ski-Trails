// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "SkiTrails",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "SkiTrails",
            targets: ["SkiTrails"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/mapbox/mapbox-maps-ios.git", from: "10.0.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
        .package(url: "https://github.com/getsentry/sentry-cocoa.git", from: "8.0.0")
    ],
    targets: [
        .executableTarget(
            name: "SkiTrails",
            dependencies: [
                .product(name: "MapboxMaps", package: "mapbox-maps-ios"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "Sentry", package: "sentry-cocoa")
            ],
            path: "Sources/SkiTrails",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "SkiTrailsTests",
            dependencies: ["SkiTrails"],
            path: "Tests/SkiTrailsTests"
        )
    ]
) 