import Foundation

public enum MapFeature {
    case run(Run)
    case lift(Lift)
    case point(name: String, latitude: Double, longitude: Double)
    
    public var name: String {
        switch self {
        case .run(let run):
            return run.name
        case .lift(let lift):
            return lift.name
        case .point(let name, _, _):
            return name
        }
    }
    
    public var coordinates: (latitude: Double, longitude: Double) {
        switch self {
        case .run(let run):
            return (run.startLocation.latitude, run.startLocation.longitude)
        case .lift(let lift):
            return (lift.startLocation.latitude, lift.startLocation.longitude)
        case .point(_, let latitude, let longitude):
            return (latitude, longitude)
        }
    }
} 