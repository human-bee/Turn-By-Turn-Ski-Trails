import SwiftUI
import SkiTrailsCore
import Combine

@MainActor
class ResortViewModel: ObservableObject {
    @Published private(set) var selectedResort: Resort?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    private var statusRefreshTask: Task<Void, Never>?
    private let refreshInterval: TimeInterval = 60 // Refresh every minute
    
    init() {
        startStatusRefreshTimer()
    }
    
    deinit {
        statusRefreshTask?.cancel()
    }
    
    func selectResort(_ resort: Resort) {
        selectedResort = resort
    }
    
    private func startStatusRefreshTimer() {
        statusRefreshTask = Task {
            while !Task.isCancelled {
                await refreshResortStatus()
                try? await Task.sleep(nanoseconds: UInt64(refreshInterval * 1_000_000_000))
            }
        }
    }
    
    private func refreshResortStatus() async {
        guard let resort = selectedResort else { return }
        
        do {
            isLoading = true
            // TODO: Implement API call to fetch updated status
            // For now, just simulate a delay
            try await Task.sleep(nanoseconds: 1_000_000_000)
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
} 