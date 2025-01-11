import SwiftUI

enum TrailDifficulty: String, Codable {
    case beginner = "green"
    case intermediate = "blue"
    case advanced = "black"
    case expert = "double_black"
    
    var description: String {
        switch self {
        case .beginner:
            return "Beginner"
        case .intermediate:
            return "Intermediate"
        case .advanced:
            return "Advanced"
        case .expert:
            return "Expert"
        }
    }
} 