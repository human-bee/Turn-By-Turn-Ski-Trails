import XCTest
import CoreLocation
@testable import SkiTrailsCore

final class SkiTrailsTests: XCTestCase {
    var routingEngine: RoutingEngine!
    var testResort: Resort!
    
    override func setUp() async throws {
        routingEngine = RoutingEngine.shared
        testResort = createTestResort()
        await routingEngine.buildGraph(for: testResort)
    }
    
    func testRouteCalculation() async throws {
        let start = CLLocationCoordinate2D(latitude: 39.6403, longitude: -106.3742)
        let end = CLLocationCoordinate2D(latitude: 39.6500, longitude: -106.3800)
        
        let route = try await routingEngine.findRoute(
            from: start,
            to: end,
            difficulty: .intermediate
        )
        
        XCTAssertFalse(route.segments.isEmpty, "Route should contain segments")
        XCTAssertGreaterThan(route.totalDistance, 0, "Route should have positive distance")
        XCTAssertGreaterThan(route.estimatedTime, 0, "Route should have positive duration")
    }
    
    func testDifficultyFiltering() async throws {
        let start = CLLocationCoordinate2D(latitude: 39.6450, longitude: -106.3750)
        let end = CLLocationCoordinate2D(latitude: 39.6403, longitude: -106.3742)
        
        let beginnerRoute = try await routingEngine.findRoute(
            from: start,
            to: end,
            difficulty: .beginner
        )
        
        XCTAssertEqual(
            beginnerRoute.difficulty,
            .beginner,
            "Route difficulty should not exceed specified maximum"
        )
        
        for segment in beginnerRoute.segments {
            if case .run(let run) = segment.type {
                XCTAssertEqual(
                    run.difficulty,
                    .beginner,
                    "Run difficulty should not exceed beginner level"
                )
            }
        }
    }
    
    func testRoutePreferences() async throws {
        let start = CLLocationCoordinate2D(latitude: 39.6403, longitude: -106.3742)
        let end = CLLocationCoordinate2D(latitude: 39.6500, longitude: -106.3800)
        
        let preferences = RoutePreferences(
            avoidCrowds: true,
            preferLessStrenuous: true,
            maxWaitTime: 300
        )
        
        let route = try await routingEngine.findRoute(
            from: start,
            to: end,
            difficulty: .intermediate,
            preferences: preferences
        )
        
        for segment in route.segments {
            if case .lift(let lift) = segment.type {
                XCTAssertLessThanOrEqual(
                    lift.waitTime ?? 0,
                    preferences.maxWaitTime ?? .infinity,
                    "Lift wait time should not exceed maximum"
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestResort() -> Resort {
        let lifts = [
            Lift(
                id: UUID(),
                name: "Test Lift 1",
                status: .open,
                startLocation: Location(latitude: 39.6403, longitude: -106.3742, altitude: 2500),
                endLocation: Location(latitude: 39.6450, longitude: -106.3750, altitude: 3000),
                capacity: 4,
                waitTime: 300
            ),
            Lift(
                id: UUID(),
                name: "Test Lift 2",
                status: .open,
                startLocation: Location(latitude: 39.6450, longitude: -106.3750, altitude: 3000),
                endLocation: Location(latitude: 39.6500, longitude: -106.3800, altitude: 3500),
                capacity: 6,
                waitTime: 600
            )
        ]
        
        let runs = [
            Run(
                id: UUID(),
                name: "Easy Street",
                difficulty: .beginner,
                status: .open,
                startLocation: Location(latitude: 39.6450, longitude: -106.3750, altitude: 3000),
                endLocation: Location(latitude: 39.6403, longitude: -106.3742, altitude: 2500),
                length: 1000,
                verticalDrop: 500
            ),
            Run(
                id: UUID(),
                name: "Blue Heaven",
                difficulty: .intermediate,
                status: .open,
                startLocation: Location(latitude: 39.6500, longitude: -106.3800, altitude: 3500),
                endLocation: Location(latitude: 39.6450, longitude: -106.3750, altitude: 3000),
                length: 1500,
                verticalDrop: 500
            )
        ]
        
        return Resort(
            id: UUID(),
            name: "Test Resort",
            lifts: lifts,
            runs: runs
        )
    }
} 