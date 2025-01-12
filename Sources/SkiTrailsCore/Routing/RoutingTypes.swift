import Foundation
import CoreLocation

public typealias SkiDifficulty = Run.Difficulty

public struct Route {
    public let segments: [Segment]
    public let totalDistance: Double
    public let estimatedTime: TimeInterval
    public let difficulty: SkiDifficulty
    
    public struct Segment {
        public let type: SegmentType
        public let path: [Location]
        public let distance: Double
        
        public enum SegmentType {
            case run(Run)
            case lift(Lift)
            case connection
        }
        
        public struct Location {
            public let latitude: Double
            public let longitude: Double
            public let altitude: Double
            
            public init(latitude: Double, longitude: Double, altitude: Double) {
                self.latitude = latitude
                self.longitude = longitude
                self.altitude = altitude
            }
        }
        
        public init(type: SegmentType, path: [Location], distance: Double) {
            self.type = type
            self.path = path
            self.distance = distance
        }
    }
    
    public init(segments: [Segment], totalDistance: Double, estimatedTime: TimeInterval, difficulty: SkiDifficulty) {
        self.segments = segments
        self.totalDistance = totalDistance
        self.estimatedTime = estimatedTime
        self.difficulty = difficulty
    }
} 