public enum MapFeature {
    case run(name: String, difficulty: String, status: Status, length: Double, verticalDrop: Double)
    case lift(name: String, type: String, status: Status)
} 