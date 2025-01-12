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
    private var isActive = false
    
    init() {}
    
    deinit {
        statusRefreshTask?.cancel()
        statusRefreshTask = nil
    }
    
    func onAppear() {
        isActive = true
        startStatusRefreshTimer()
    }
    
    func onDisappear() {
        isActive = false
        stopStatusRefresh()
    }
    
    func selectResort(_ resort: Resort) {
        selectedResort = resort
        if isActive {
            startStatusRefreshTimer()
        }
    }
    
    private func startStatusRefreshTimer() {
        stopStatusRefresh()
        statusRefreshTask = Task {
            while !Task.isCancelled && isActive {
                await refreshResortStatus()
                try? await Task.sleep(nanoseconds: UInt64(refreshInterval * 1_000_000_000))
            }
        }
    }
    
    private func stopStatusRefresh() {
        statusRefreshTask?.cancel()
        statusRefreshTask = nil
    }
    
    private func refreshResortStatus() async {
        guard let resort = selectedResort else { return }
        do {
            isLoading = true
            let updatedResort = try await APIClient.shared.fetchResortInfo(id: resort.id.uuidString)
            if isActive { // Check if still active before updating UI
                selectedResort = updatedResort
                isLoading = false
            }
        } catch {
            if isActive { // Check if still active before updating UI
                self.error = error
                isLoading = false
            }
        }
    }
} 