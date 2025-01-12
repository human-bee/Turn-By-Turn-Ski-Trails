import Foundation
import CoreLocation
import SkiTrailsCore

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
            return "Invalid URL configuration"
        case .invalidResponse:
            return "Invalid server response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let code):
            return "Server error with code: \(code)"
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
    
    func fetchResortList() async throws -> [Resort] {
        let url = try buildURL(path: "/resorts")
        return try await fetch(url)
    }
    
    func fetchWeather(for resort: Resort) async throws -> Weather {
        let url = try buildURL(path: "/weather/\(resort.id)")
        return try await fetch(url)
    }
    
    func fetchLiftStatus(for resort: Resort) async throws -> [Lift] {
        let url = try buildURL(path: "/lifts/\(resort.id)")
        return try await fetch(url)
    }
    
    func fetchResortInfo(id: String) async throws -> Resort {
        let url = try buildURL(path: "/resorts/\(id)")
        return try await fetch(url)
    }
    
    private func buildURL(path: String) throws -> URL {
        guard let baseURL = try? CoreConfig.getAPIBaseURL(),
              let url = URL(string: path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        return url
    }
    
    private func fetch<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw APIError.decodingError(error)
                }
            case 401:
                throw APIError.unauthorized
            case 400...499:
                throw APIError.invalidResponse
            case 500...599:
                throw APIError.serverError(httpResponse.statusCode)
            default:
                throw APIError.unknown
            }
        } catch is CancellationError {
            throw APIError.networkError(NSError(domain: "APIClient", code: -999, userInfo: [NSLocalizedDescriptionKey: "Request was cancelled"]))
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    private func fetch<T: Decodable>(_ url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = try? CoreConfig.getValue(for: "API_AUTH_TOKEN") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return try await fetch(request)
    }
} 