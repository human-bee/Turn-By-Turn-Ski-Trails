import Foundation
import CoreLocation

actor RoutingEngine {
    static let shared = RoutingEngine()
    
    private var resortGraph: ResortGraph?
    
    private init() {}
    
    // MARK: - Graph Management
    
    func buildGraph(for resort: Resort) {
        let nodes = buildNodes(from: resort)
        let edges = buildEdges(from: resort)
        resortGraph = ResortGraph(nodes: nodes, edges: edges)
    }
    
    private func buildNodes(from resort: Resort) -> [String: Node] {
        var nodes: [String: Node] = [:]
        
        // Add lift nodes
        for lift in resort.lifts {
            nodes[lift.id] = Node(
                id: lift.id,
                position: Resort.Location(
                    latitude: lift.latitude,
                    longitude: lift.longitude,
                    altitude: resort.location.altitude
                ),
                type: .lift(lift)
            )
        }
        
        // Add run nodes
        for run in resort.runs {
            // Add top node for the run
            let topNodeId = "\(run.id)_top"
            nodes[topNodeId] = Node(
                id: topNodeId,
                position: Resort.Location(
                    latitude: run.topLatitude,
                    longitude: run.topLongitude,
                    altitude: resort.location.altitude + run.verticalDrop
                ),
                type: .run(run)
            )
            
            // Add bottom node for the run
            let bottomNodeId = "\(run.id)_bottom"
            nodes[bottomNodeId] = Node(
                id: bottomNodeId,
                position: Resort.Location(
                    latitude: run.bottomLatitude,
                    longitude: run.bottomLongitude,
                    altitude: resort.location.altitude
                ),
                type: .run(run)
            )
        }
        
        return nodes
    }
    
    private func buildEdges(from resort: Resort) -> [Edge] {
        var edges: [Edge] = []
        
        // For each lift, connect to the top of nearby runs
        for lift in resort.lifts {
            for run in resort.runs {
                // Calculate distance between lift top and run top
                let liftLocation = CLLocation(
                    latitude: lift.latitude,
                    longitude: lift.longitude
                )
                let runTopLocation = CLLocation(
                    latitude: run.topLatitude,
                    longitude: run.topLongitude
                )
                
                // If the lift is close to the run's top (within 100 meters), create a connection
                let distance = liftLocation.distance(from: runTopLocation)
                if distance <= 100 { // Threshold for considering a lift services a run
                    edges.append(Edge(
                        from: lift.id,
                        to: "\(run.id)_top",
                        weight: distance,
                        type: .liftToRun
                    ))
                }
            }
        }
        
        // For each run, connect its top to its bottom
        for run in resort.runs {
            let topNodeId = "\(run.id)_top"
            let bottomNodeId = "\(run.id)_bottom"
            
            edges.append(Edge(
                from: topNodeId,
                to: bottomNodeId,
                weight: run.length,
                type: .run
            ))
        }
        
        // For each run's bottom, connect to nearby lift bases
        for run in resort.runs {
            let runBottomLocation = CLLocation(
                latitude: run.bottomLatitude,
                longitude: run.bottomLongitude
            )
            
            for lift in resort.lifts {
                let liftLocation = CLLocation(
                    latitude: lift.latitude,
                    longitude: lift.longitude
                )
                
                // If the lift base is close to the run's bottom (within 100 meters), create a connection
                let distance = runBottomLocation.distance(from: liftLocation)
                if distance <= 100 {
                    edges.append(Edge(
                        from: "\(run.id)_bottom",
                        to: lift.id,
                        weight: distance,
                        type: .connection
                    ))
                }
            }
        }
        
        return edges
    }
    
    func debugPrintGraph() {
        guard EnvConfig.isDebugMode else { return }
        
        guard let graph = resortGraph else {
            print("No graph available")
            return
        }
        
        print("\n=== Resort Graph Debug Info ===")
        print("Nodes (\(graph.nodes.count)):")
        for (id, node) in graph.nodes {
            let typeStr = switch node.type {
            case .lift(let lift): "Lift: \(lift.name)"
            case .run(let run): "Run: \(run.name)"
            }
            print("- \(id): \(typeStr) at (\(node.position.latitude), \(node.position.longitude))")
        }
        
        print("\nEdges (\(graph.edges.count)):")
        for edge in graph.edges {
            let fromNode = graph.nodes[edge.from]
            let toNode = graph.nodes[edge.to]
            print("- \(edge.from) -> \(edge.to) (\(edge.type))")
            print("  Weight: \(edge.weight)m")
            if let from = fromNode, let to = toNode {
                let distance = CLLocation(
                    latitude: from.position.latitude,
                    longitude: from.position.longitude
                ).distance(from: CLLocation(
                    latitude: to.position.latitude,
                    longitude: to.position.longitude
                ))
                print("  Actual Distance: \(Int(distance))m")
            }
        }
        print("==============================\n")
    }
    
    // MARK: - Route Finding
    
    func findRoute(
        from startPoint: CLLocationCoordinate2D,
        to endPoint: CLLocationCoordinate2D,
        difficulty: SkiDifficulty,
        preferences: RoutePreferences
    ) async throws -> Route {
        guard let graph = resortGraph else {
            throw RoutingError.graphNotInitialized
        }
        
        // Find nearest nodes to start and end points
        let startNode = findNearestNode(to: startPoint, in: graph)
        let endNode = findNearestNode(to: endPoint, in: graph)
        
        // Calculate route using A* algorithm
        let path = try findPath(
            from: startNode,
            to: endNode,
            in: graph,
            difficulty: difficulty,
            preferences: preferences
        )
        
        // Convert path to route segments
        return try buildRoute(from: path, in: graph)
    }
    
    private func findPath(
        from start: Node,
        to end: Node,
        in graph: ResortGraph,
        difficulty: SkiDifficulty,
        preferences: RoutePreferences
    ) throws -> [String] {
        var openSet = Set<String>([start.id])
        var closedSet = Set<String>()
        
        var cameFrom: [String: String] = [:]
        var gScore: [String: Double] = [start.id: 0]
        var fScore: [String: Double] = [start.id: heuristic(from: start, to: end)]
        
        while !openSet.isEmpty {
            // Find node with lowest fScore
            let current = openSet.min { a, b in
                (fScore[a] ?? .infinity) < (fScore[b] ?? .infinity)
            }!
            
            if current == end.id {
                return reconstructPath(cameFrom: cameFrom, current: current)
            }
            
            openSet.remove(current)
            closedSet.insert(current)
            
            // Check all neighbors
            let edges = graph.edges.filter { $0.from == current }
            for edge in edges {
                guard !closedSet.contains(edge.to),
                      let node = graph.nodes[edge.to] else {
                    continue
                }
                
                // Skip if difficulty is too high
                if case .run(let run) = node.type,
                   !isRunAllowed(run, maxDifficulty: difficulty) {
                    continue
                }
                
                let tentativeGScore = (gScore[current] ?? .infinity) + edge.weight
                
                if !openSet.contains(edge.to) {
                    openSet.insert(edge.to)
                } else if tentativeGScore >= (gScore[edge.to] ?? .infinity) {
                    continue
                }
                
                cameFrom[edge.to] = current
                gScore[edge.to] = tentativeGScore
                fScore[edge.to] = tentativeGScore + heuristic(from: node, to: end)
            }
        }
        
        throw RoutingError.noRouteFound
    }
    
    private func reconstructPath(cameFrom: [String: String], current: String) -> [String] {
        var path = [current]
        var currentNode = current
        
        while let previous = cameFrom[currentNode] {
            path.insert(previous, at: 0)
            currentNode = previous
        }
        
        return path
    }
    
    private func buildRoute(from path: [String], in graph: ResortGraph) throws -> Route {
        var segments: [Route.Segment] = []
        var totalDistance: Double = 0
        var maxDifficulty: SkiDifficulty = .beginner
        
        for i in 0..<(path.count - 1) {
            let fromId = path[i]
            let toId = path[i + 1]
            
            guard let fromNode = graph.nodes[fromId],
                  let toNode = graph.nodes[toId],
                  let edge = graph.edges.first(where: { $0.from == fromId && $0.to == toId }) else {
                throw RoutingError.invalidPath
            }
            
            let segment = try buildSegment(
                from: fromNode,
                to: toNode,
                edge: edge
            )
            
            segments.append(segment)
            totalDistance += segment.distance
            
            if case .run(let run) = segment.type {
                maxDifficulty = max(maxDifficulty, run.difficulty)
            }
        }
        
        return Route(
            segments: segments,
            totalDistance: totalDistance,
            estimatedTime: calculateEstimatedTime(for: segments),
            difficulty: maxDifficulty
        )
    }
    
    // MARK: - Helper Methods
    
    private func findNearestNode(to coordinate: CLLocationCoordinate2D, in graph: ResortGraph) -> Node {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        return graph.nodes.values.min { a, b in
            let aLocation = CLLocation(
                latitude: a.position.latitude,
                longitude: a.position.longitude
            )
            let bLocation = CLLocation(
                latitude: b.position.latitude,
                longitude: b.position.longitude
            )
            
            return location.distance(from: aLocation) < location.distance(from: bLocation)
        }!
    }
    
    private func heuristic(from: Node, to: Node) -> Double {
        let fromLocation = CLLocation(
            latitude: from.position.latitude,
            longitude: from.position.longitude
        )
        let toLocation = CLLocation(
            latitude: to.position.latitude,
            longitude: to.position.longitude
        )
        
        return fromLocation.distance(from: toLocation)
    }
    
    private func isRunAllowed(_ run: Run, maxDifficulty: SkiDifficulty) -> Bool {
        switch (run.difficulty, maxDifficulty) {
        case (.beginner, _):
            return true
        case (.intermediate, .intermediate), (.intermediate, .advanced), (.intermediate, .expert):
            return true
        case (.advanced, .advanced), (.advanced, .expert):
            return true
        case (.expert, .expert):
            return true
        default:
            return false
        }
    }
    
    private func calculateWeight(lift: Lift, run: Run) -> Double {
        // Base weight is the length of the run
        var weight = run.length
        
        // Add penalties
        if lift.status != .open {
            weight *= 1000 // Effectively exclude closed lifts
        }
        
        if run.status != .open {
            weight *= 1000 // Effectively exclude closed runs
        }
        
        if let waitTime = lift.waitTime {
            weight += Double(waitTime) * 10 // Factor in lift wait times
        }
        
        return weight
    }
    
    private func buildSegment(
        from: Node,
        to: Node,
        edge: Edge
    ) throws -> Route.Segment {
        let type: Route.Segment.SegmentType
        
        switch (from.type, to.type) {
        case (.lift(let lift), .run):
            type = .lift(lift)
        case (.run(let run), _):
            type = .run(run)
        default:
            type = .connection
        }
        
        return Route.Segment(
            type: type,
            path: [
                Route.Segment.Location(
                    latitude: from.position.latitude,
                    longitude: from.position.longitude,
                    altitude: from.position.altitude
                ),
                Route.Segment.Location(
                    latitude: to.position.latitude,
                    longitude: to.position.longitude,
                    altitude: to.position.altitude
                )
            ],
            distance: edge.weight
        )
    }
    
    private func calculateEstimatedTime(for segments: [Route.Segment]) -> TimeInterval {
        segments.reduce(0) { total, segment in
            switch segment.type {
            case .run:
                // Assume average speed of 20 km/h on runs
                return total + (segment.distance / 5.56) // 5.56 m/s = 20 km/h
            case .lift:
                // Assume average lift speed of 5 m/s
                return total + (segment.distance / 5.0)
            case .connection:
                // Assume walking speed of 1.4 m/s
                return total + (segment.distance / 1.4)
            }
        }
    }
}

// MARK: - Supporting Types

struct ResortGraph {
    let nodes: [String: Node]
    let edges: [Edge]
}

struct Node {
    let id: String
    let position: Resort.Location
    let type: NodeType
    
    enum NodeType {
        case lift(Lift)
        case run(Run)
    }
}

struct Edge {
    let from: String
    let to: String
    let weight: Double
    let type: EdgeType
    
    enum EdgeType {
        case lift
        case run
        case connection
        case liftToRun
    }
}

struct RoutePreferences {
    let avoidCrowds: Bool
    let preferLessStrenuous: Bool
    let maxWaitTime: TimeInterval?
}

enum RoutingError: Error {
    case graphNotInitialized
    case noRouteFound
    case invalidPath
    
    var localizedDescription: String {
        switch self {
        case .graphNotInitialized:
            return "Resort data not loaded"
        case .noRouteFound:
            return "No valid route found between the selected points"
        case .invalidPath:
            return "Invalid path data"
        }
    }
} 