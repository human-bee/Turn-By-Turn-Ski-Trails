import SwiftUI
import Combine
import CoreLocation
import Foundation
import SkiTrailsCore

@MainActor
class AppState: ObservableObject {
    @Published var resorts: [Resort] = []
    @Published var selectedResort: Resort?
    @Published var activeRoute: Route?
    @Published var locationManager = LocationManager()
    
    private let apiClient = APIClient.shared
    private let errorHandler = ErrorHandler.shared
    
    init() {
        locationManager.requestAuthorization()
    }
    
    func loadResorts() async {
        do {
            resorts = try await apiClient.fetchResortList()
        } catch {
            await errorHandler.handle(error)
        }
    }
} 
