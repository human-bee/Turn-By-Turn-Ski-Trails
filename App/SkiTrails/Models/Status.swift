import SwiftUI

enum Status: String, Codable {
    case open
    case closed
    case hold
    case scheduled
    case grooming
    
    var color: Color {
        switch self {
        case .open:
            return .green
        case .closed:
            return .red
        case .hold:
            return .orange
        case .scheduled:
            return .blue
        case .grooming:
            return .purple
        }
    }
} 