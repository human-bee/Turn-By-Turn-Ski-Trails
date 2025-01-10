import Foundation
import SwiftUI

public class AppState: ObservableObject {
    @Published public var isLoading: Bool = false
    @Published public var selectedTrail: String? = nil
    @Published public var navigationActive: Bool = false
    @Published public var error: Error?
    
    public let configuration: Configuration?
    
    public init() {
        do {
            self.configuration = try Configuration.default()
        } catch {
            self.configuration = nil
            self.error = error
        }
    }
    
    public init(configuration: Configuration) {
        self.configuration = configuration
    }
} 