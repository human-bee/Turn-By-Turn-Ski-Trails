import SwiftUI
import SkiTrailsCore

extension SkiDifficulty {
    var color: Color {
        switch self {
        case .beginner:
            return .green
        case .intermediate:
            return .blue
        case .advanced:
            return .black
        case .expert:
            return .black
        }
    }
} 