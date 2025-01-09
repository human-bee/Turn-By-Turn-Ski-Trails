import Foundation

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int)
    case unauthorized
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let code):
            return "Server error: \(code)"
        case .unauthorized:
            return "Unauthorized access"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

actor APIClient {
    static let shared = APIClient()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        
        self.session = URLSession(configuration: configuration)
        
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
        
        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder.dateEncodingStrategy = .iso8601
    }
    
    // MARK: - Weather API
    
    func fetchWeather(for resort: Resort) async throws -> WeatherInfo {
        let baseURL = "http://api.weatherunlocked.com/api/resortforecast"
        let coordinates = "\(resort.location.latitude),\(resort.location.longitude)"
        
        guard let url = URL(string: "\(baseURL)/\(coordinates)?app_id=\(EnvConfig.weatherUnlockedAppId)&app_key=\(EnvConfig.weatherUnlockedApiKey)") else {
            throw APIError.invalidURL
        }
        
        return try await fetch(url)
    }
    
    // MARK: - Lift Status API
    
    func fetchLiftStatus(for resort: Resort) async throws -> [Lift] {
        let baseURL = "https://ski-api.p.rapidapi.com/lifts"
        
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw APIError.invalidURL
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "resort_id", value: resort.id)
        ]
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.addValue(EnvConfig.skiApiKey, forHTTPHeaderField: "X-RapidAPI-Key")
        request.addValue("ski-api.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")
        
        return try await fetch(request)
    }
    
    // MARK: - Resort Info API
    
    func fetchResortInfo(id: String) async throws -> Resort {
        let baseURL = "https://ski-resorts-and-conditions.p.rapidapi.com/resort"
        
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw APIError.invalidURL
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "resort_id", value: id)
        ]
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.addValue(EnvConfig.skiResortsInformationApiKey, forHTTPHeaderField: "X-RapidAPI-Key")
        request.addValue("ski-resorts-and-conditions.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")
        
        return try await fetch(request)
    }
    
    // MARK: - Generic Fetch Methods
    
    private func fetch<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                return try decoder.decode(T.self, from: data)
            case 401:
                throw APIError.unauthorized
            case 400...499:
                throw APIError.invalidResponse
            case 500...599:
                throw APIError.serverError(httpResponse.statusCode)
            default:
                throw APIError.unknown
            }
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    private func fetch<T: Decodable>(_ url: URL) async throws -> T {
        try await fetch(URLRequest(url: url))
    }
}

// MARK: - API Response Types

struct WeatherResponse: Codable {
    let temperature: Double
    let snowDepth: Double
    let windSpeed: Double
    let visibility: Double
    let forecast: String
    let lastUpdated: Date
    
    enum CodingKeys: String, CodingKey {
        case temperature = "temp_c"
        case snowDepth = "snow_depth_cm"
        case windSpeed = "wind_speed_kmh"
        case visibility = "visibility_km"
        case forecast = "weather_desc"
        case lastUpdated = "time"
    }
}

struct LiftStatusResponse: Codable {
    let lifts: [LiftStatus]
    
    struct LiftStatus: Codable {
        let id: String
        let name: String
        let status: String
        let capacity: Int
        let waitTime: Int?
    }
}

struct ResortInfoResponse: Codable {
    let id: String
    let name: String
    let location: Location
    let runs: [RunInfo]
    let lifts: [LiftInfo]
    
    struct Location: Codable {
        let latitude: Double
        let longitude: Double
        let altitude: Double
    }
    
    struct RunInfo: Codable {
        let id: String
        let name: String
        let difficulty: String
        let length: Double
        let verticalDrop: Double
    }
    
    struct LiftInfo: Codable {
        let id: String
        let name: String
        let capacity: Int
    }
} 