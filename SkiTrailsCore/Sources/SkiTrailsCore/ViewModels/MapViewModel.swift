import SwiftUI
import CoreLocation

public class MapViewModel: ObservableObject {
    @Published public var selectedFeature: MapFeature?
    
    public let defaultCenter = CLLocationCoordinate2D(latitude: 39.6403, longitude: -106.3742) // Vail, CO
    public let defaultZoom = 14.0
    public let defaultPitch = 45.0
    public let defaultBearing = 0.0
    
    public init() {}
} 