import Foundation
import CoreLocation

public actor RoutingEngine {
    public static let shared = RoutingEngine()
    private var resortGraph: ResortGraph?
    
    private init() {}
    
    // MARK: - Graph Management
    
    public func buildGraph(for resort: Resort) {
        let nodes = buildNodes(from: resort)
        let edges = buildEdges(from: resort)
        resortGraph = ResortGraph(nodes: nodes, edges: edges)
    }
    
    public func findRoute(
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
    
    // MARK: - Private Methods
    
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
                    altitude: resort.location.altitude
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
        
        // For each lift, connect to nearby run tops (only if both lift and run are open)
        for lift in resort.lifts {
            if lift.status != .open {
                continue
            }
            
            for run in resort.runs {
                if run.status != .open {
                    continue
                }
                
                // Connect lift to run top if they're close enough
                let liftLocation = CLLocation(
                    latitude: lift.latitude,
                    longitude: lift.longitude
                )
                let runTopLocation = CLLocation(
                    latitude: run.topLatitude,
                    longitude: run.topLongitude
                )
                
                if liftLocation.distance(from: runTopLocation) < 100 { // 100m threshold
                    edges.append(Edge(
                        from: lift.id,
                        to: "\(run.id)_top",
                        weight: calculateWeight(lift: lift, run: run),
                        type: .liftToRun
                    ))
                }
            }
        }
        
        // For each run, connect its top to its bottom (only if run is open)
        for run in resort.runs {
            if run.status != .open {
                continue
            }
            
            let topNodeId = "\(run.id)_top"
            let bottomNodeId = "\(run.id)_bottom"
            
            edges.append(Edge(
                from: topNodeId,
                to: bottomNodeId,
                weight: run.length,
                type: .run
            ))
        }
        
        // For each run's bottom, connect to nearby lift bases (only if both run and lift are open)
        for run in resort.runs {
            if run.status != .open {
                continue
            }
            
            let runBottomLocation = CLLocation(
                latitude: run.bottomLatitude,
                longitude: run.bottomLongitude
            )
            
            for lift in resort.lifts {
                if lift.status != .open {
                    continue
                }
                
                let liftBaseLocation = CLLocation(
                    latitude: lift.latitude,
                    longitude: lift.longitude
                )
                
                if runBottomLocation.distance(from: liftBaseLocation) < 100 { // 100m threshold
                    edges.append(Edge(
                        from: "\(run.id)_bottom",
                        to: lift.id,
                        weight: 50, // 50m walking distance
                        type: .connection
                    ))
                }
            }
        }
        
        return edges
    }
    
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
            let current = openSet.min { a, b in
                (fScore[a] ?? .infinity) < (fScore[b] ?? .infinity)
            }!
            
            if current == end.id {
                return reconstructPath(cameFrom: cameFrom, current: current)
            }
            
            openSet.remove(current)
            closedSet.insert(current)
            
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
                
                let tentativeGScore = (gScore[current] ?? .infinity) + calculateEdgeWeight(
                    edge,
                    preferences: preferences
                )
                
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
    
    private func calculateEdgeWeight(_ edge: Edge, preferences: RoutePreferences) -> Double {
        var weight = edge.weight
        
        switch edge.type {
        case .lift:
            if preferences.avoidCrowds,
               let lift = graph.nodes[edge.from]?.type.lift,
               let waitTime = lift.waitTime,
               waitTime > (preferences.maxWaitTime ?? 15) {
                weight *= 2
            }
        case .run:
            if preferences.preferLessStrenuous {
                weight *= 1.5 // Penalty for longer runs when preferring less strenuous routes
            }
        default:
            break
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

public struct ResortGraph {
    let nodes: [String: Node]
    let edges: [Edge]
}

public struct Node {
    let id: String
    let position: Resort.Location
    let type: NodeType
    
    enum NodeType {
        case lift(Lift)
        case run(Run)
        
        var lift: Lift? {
            if case .lift(let lift) = self {
                return lift
            }
            return nil
        }
        
        var run: Run? {
            if case .run(let run) = self {
                return run
            }
            return nil
        }
    }
}

public struct Edge {
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

public struct RoutePreferences {
    public let avoidCrowds: Bool
    public let preferLessStrenuous: Bool
    public let maxWaitTime: TimeInterval?
    
    public init(avoidCrowds: Bool, preferLessStrenuous: Bool, maxWaitTime: TimeInterval? = nil) {
        self.avoidCrowds = avoidCrowds
        self.preferLessStrenuous = preferLessStrenuous
        self.maxWaitTime = maxWaitTime
    }
}

public enum RoutingError: Error {
    case graphNotInitialized
    case noRouteFound
    case invalidPath
    
    public var localizedDescription: String {
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