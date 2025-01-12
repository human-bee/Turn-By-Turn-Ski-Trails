import SwiftUI
import MapboxMaps
import SkiTrailsCore

struct RouteOverlayView: UIViewRepresentable {
    let route: Route
    
    func makeUIView(context: Context) -> MapboxMaps.MapView {
        let resourceOptions = ResourceOptions(accessToken: try! CoreConfig.getValue(for: "MAPBOX_ACCESS_TOKEN"))
        let mapInitOptions = MapInitOptions(resourceOptions: resourceOptions)
        let mapView = MapboxMaps.MapView(frame: .zero, mapInitOptions: mapInitOptions)
        
        mapView.mapboxMap.onNext(event: .styleLoaded) { _ in
            Task {
                await addRouteOverlay(to: mapView)
            }
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: MapboxMaps.MapView, context: Context) {
        Task {
            await addRouteOverlay(to: mapView)
        }
    }
    
    private func addRouteOverlay(to mapView: MapboxMaps.MapView) async {
        let coordinates = route.segments.flatMap { segment -> [CLLocationCoordinate2D] in
            return segment.path.map { location in
                CLLocationCoordinate2D(
                    latitude: location.latitude,
                    longitude: location.longitude
                )
            }
        }
        
        let source = GeoJSONSource()
        source.data = .feature(Feature(geometry: .lineString(.init(coordinates))))
        try? await mapView.mapboxMap.style.addSource(source, id: "route")
        
        let layer = LineLayer(id: "route-layer")
        layer.source = "route"
        layer.lineColor = .constant(.init(UIColor.systemBlue))
        layer.lineWidth = .constant(4)
        try? await mapView.mapboxMap.style.addLayer(layer)
        
        let camera = CameraOptions(center: coordinates[0], zoom: 15)
        mapView.camera.fly(to: camera, duration: 1.0)
    }
}

#Preview {
    RouteOverlayView(
        route: Route(
            segments: [
                Route.Segment(
                    type: .run(Run(
                        id: UUID(),
                        name: "Blue Heaven",
                        difficulty: .intermediate,
                        status: .open,
                        startLocation: Location(latitude: 40.5853, longitude: -111.6564, altitude: 2800),
                        endLocation: Location(latitude: 40.5845, longitude: -111.6558, altitude: 2600),
                        length: 500,
                        verticalDrop: 200
                    )),
                    path: [
                        Route.Segment.Location(latitude: 40.5853, longitude: -111.6564, altitude: 2800),
                        Route.Segment.Location(latitude: 40.5845, longitude: -111.6558, altitude: 2600)
                    ],
                    distance: 500
                )
            ],
            totalDistance: 500,
            estimatedTime: 300,
            difficulty: .intermediate
        )
    )
} 