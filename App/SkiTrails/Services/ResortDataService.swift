import Foundation
import MapboxMaps
import Combine

class ResortDataService: ObservableObject {
    @Published var boundaries: String?
    @Published var runs: String?
    @Published var lifts: String?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let baseURL = "https://api.skiresort.com/v1" // Example API endpoint
    private var cancellables = Set<AnyCancellable>()
    
    func fetchResortData(resortId: String) {
        isLoading = true
        error = nil
        
        // Create API request
        let url = URL(string: "\(baseURL)/resorts/\(resortId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add API key if required
        if let apiKey = try? ResortConfig.getApiKey() {
            request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        }
        
        // Make API request
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: ResortResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.error = error
                }
            } receiveValue: { response in
                self.boundaries = response.boundaries
                self.runs = response.runs
                self.lifts = response.lifts
            }
            .store(in: &cancellables)
    }
}

// Response models
struct ResortResponse: Codable {
    let boundaries: String // GeoJSON string
    let runs: String // GeoJSON string
    let lifts: String // GeoJSON string
}

// Configuration
enum ResortConfig {
    enum ConfigError: LocalizedError {
        case missingApiKey
        
        var errorDescription: String? {
            switch self {
            case .missingApiKey:
                return "Resort API key not found. Please set RESORT_API_KEY in your environment or Info.plist."
            }
        }
    }
    
    static func getApiKey() throws -> String {
        // First try environment variable
        if let key = ProcessInfo.processInfo.environment["RESORT_API_KEY"] {
            return key
        }
        
        // Then try Info.plist
        if let key = Bundle.main.object(forInfoDictionaryKey: "ResortApiKey") as? String {
            return key
        }
        
        throw ConfigError.missingApiKey
    }
} 