import Foundation
import SwiftUI
import CoreLocation

public class AppState: ObservableObject {
    public static var shared: AppState?
    
    @Published public var isLoading: Bool = false
    @Published public var selectedTrail: String? = nil
    @Published public var navigationActive: Bool = false
    @Published public var error: Error?
    @Published public private(set) var resorts: [Resort] = []
    @Published public private(set) var selectedResort: Resort?
    @Published public var selectedDestination: Location?
    @Published public var currentLocation: CLLocation?
    @Published public var activeRoute: Route?
    
    public let locationManager: LocationManager
    private let apiClient: APIClient
    public let configuration: Configuration?
    
    public init() {
        self.apiClient = .shared
        self.locationManager = LocationManager()
        do {
            self.configuration = try Configuration.default()
        } catch {
            self.configuration = nil
            self.error = error
        }
        Self.shared = self
    }
    
    public init(configuration: Configuration) {
        self.apiClient = .shared
        self.locationManager = LocationManager()
        self.configuration = configuration
        Self.shared = self
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

extension AppState {
    public static var preview: AppState {
        let state = AppState()
        state.resorts = [Resort.preview]
        state.selectedResort = .preview
        return state
    }
} 