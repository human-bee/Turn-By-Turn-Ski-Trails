import XCTest
@testable import SkiTrails
@testable import SkiTrailsCore

final class APIConnectivityTests: XCTestCase {
    
    func testEnvironmentVariablesLoaded() {
        // Test that critical environment variables are available
        XCTAssertFalse(EnvConfig.mapboxAccessToken.isEmpty, "Mapbox access token should be set")
        XCTAssertFalse(EnvConfig.weatherUnlockedApiKey.isEmpty, "Weather API key should be set")
        XCTAssertFalse(EnvConfig.liftieApiBaseUrl.isEmpty, "Liftie API URL should be set")
    }
    
    func testMapboxInitialization() async {
        // Test Mapbox initialization
        let resourceOptions = ResourceOptions(accessToken: EnvConfig.mapboxAccessToken)
        XCTAssertNotNil(resourceOptions, "Should be able to create Mapbox resource options")
    }
    
    func testLiftieAPIConnection() async throws {
        // Test Liftie API connectivity
        let baseUrl = EnvConfig.liftieApiBaseUrl
        let resortList = EnvConfig.liftieResortList
        
        guard let url = URL(string: "\(baseUrl)/\(resortList.first!)") else {
            XCTFail("Failed to create Liftie API URL")
            return
        }
        
        let (_, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            XCTFail("Expected HTTP response")
            return
        }
        
        XCTAssertEqual(httpResponse.statusCode, 200, "Liftie API should return 200 OK")
    }
    
    func testWeatherAPIConnection() async throws {
        // Test Weather API connectivity
        guard let apiKey = EnvConfig.weatherUnlockedApiKey,
              let appId = EnvConfig.weatherUnlockedAppId else {
            XCTFail("Weather API credentials not found")
            return
        }
        
        // Example coordinates for Palisades Tahoe
        let lat = "39.1969"
        let lon = "-120.2376"
        let baseUrl = "http://api.weatherunlocked.com/api/resortforecast"
        
        guard let url = URL(string: "\(baseUrl)/\(lat),\(lon)?app_id=\(appId)&app_key=\(apiKey)") else {
            XCTFail("Failed to create Weather API URL")
            return
        }
        
        let (_, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            XCTFail("Expected HTTP response")
            return
        }
        
        XCTAssertEqual(httpResponse.statusCode, 200, "Weather API should return 200 OK")
    }
} 