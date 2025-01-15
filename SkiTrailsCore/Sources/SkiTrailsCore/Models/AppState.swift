import Foundation
import SwiftUI
import CoreLocation

public class AppState: ObservableObject {
    @Published public var isLoading: Bool = false
    @Published public var selectedTrail: String? = nil
    @Published public var navigationActive: Bool = false
    @Published public var error: Error?
    @Published public private(set) var resorts: [Resort] = []
    @Published public private(set) var selectedResort: Resort?
    @Published public var selectedDestination: Location?
    @Published public var currentLocation: CLLocation?
    
    private let apiClient: APIClient
    public let configuration: Configuration?
    
    public init() {
        self.apiClient = .shared
        do {
            self.configuration = try Configuration.default()
        } catch {
            self.configuration = nil
            self.error = error
        }
    }
    
    public init(configuration: Configuration) {
        self.apiClient = .shared
        self.configuration = configuration
    }
    
    @MainActor
    public func loadResorts() async {
        isLoading = true
        do {
            let resortList = try await apiClient.fetchResortList()
            self.resorts = resortList
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    @MainActor
    public func selectResort(_ resort: Resort) {
        selectedResort = resort
    }
} 