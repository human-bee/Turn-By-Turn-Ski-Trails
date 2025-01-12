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
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        difficulty: SkiDifficulty = .intermediate,
        preferences: RoutePreferences = RoutePreferences()
    ) async throws -> Route {
        guard let graph = resortGraph else {
            throw RoutingError.graphNotInitialized
        }
        
        let startNode = try findNearestNode(to: start, in: graph)
        let endNode = try findNearestNode(to: end, in: graph)
        
        let path = try findPath(
            from: startNode,
            to: endNode,
            in: graph,
            maxDifficulty: difficulty,
            preferences: preferences
        )
        return try buildRoute(from: path, in: graph)
    }
    
    // MARK: - Private Methods
    
    private func buildNodes(from resort: Resort) -> [String: Node] {
        var nodes: [String: Node] = [:]
        
        // Add lift nodes
        for lift in resort.lifts {
            // Add lift base node
            nodes[lift.id.uuidString] = Node(
                id: lift.id.uuidString,
                coordinate: CLLocationCoordinate2D(latitude: lift.startLocation.latitude, longitude: lift.startLocation.longitude),
                elevation: lift.startLocation.altitude,
                type: .lift(lift)
            )
            
            // Add lift top node
            let topNodeId = "\(lift.id.uuidString)_top"
            nodes[topNodeId] = Node(
                id: topNodeId,
                coordinate: CLLocationCoordinate2D(latitude: lift.endLocation.latitude, longitude: lift.endLocation.longitude),
                elevation: lift.endLocation.altitude,
                type: .lift(lift)
            )
        }
        
        // Add run nodes
        for run in resort.runs {
            // Add top node for the run
            let topNodeId = "\(run.id.uuidString)_top"
            nodes[topNodeId] = Node(
                id: topNodeId,
                coordinate: CLLocationCoordinate2D(latitude: run.startLocation.latitude, longitude: run.startLocation.longitude),
                elevation: run.startLocation.altitude,
                type: .run(run)
            )
            
            // Add bottom node for the run
            let bottomNodeId = "\(run.id.uuidString)_bottom"
            nodes[bottomNodeId] = Node(
                id: bottomNodeId,
                coordinate: CLLocationCoordinate2D(latitude: run.endLocation.latitude, longitude: run.endLocation.longitude),
                elevation: run.endLocation.altitude,
                type: .run(run)
            )
        }
        
        return nodes
    }
    
    private func buildEdges(from resort: Resort) -> [Edge] {
        var edges: [Edge] = []
        let connectionThreshold: Double = 500 // 500m connection threshold
        
        // Connect lift bases to lift tops
        for lift in resort.lifts {
            if lift.status != .open {
                continue
            }
            
            // Connect lift base to lift top
            edges.append(Edge(
                from: lift.id.uuidString,
                to: "\(lift.id.uuidString)_top",
                type: .lift,
                distance: lift.endLocation.altitude - lift.startLocation.altitude
            ))
        }
        
        // Connect lift tops to nearby run tops and other lift bases
        for lift in resort.lifts {
            if lift.status != .open {
                continue
            }
            
            let liftTopLocation = CLLocation(
                latitude: lift.endLocation.latitude,
                longitude: lift.endLocation.longitude
            )
            
            // Connect to run tops
            for run in resort.runs {
                if run.status != .open {
                    continue
                }
                
                let runTopLocation = CLLocation(
                    latitude: run.startLocation.latitude,
                    longitude: run.startLocation.longitude
                )
                
                let distance = liftTopLocation.distance(from: runTopLocation)
                if distance < connectionThreshold {
                    edges.append(Edge(
                        from: "\(lift.id.uuidString)_top",
                        to: "\(run.id.uuidString)_top",
                        type: .connection,
                        distance: distance
                    ))
                }
            }
            
            // Connect to other lift bases
            for otherLift in resort.lifts {
                if otherLift.id == lift.id || otherLift.status != .open {
                    continue
                }
                
                let otherLiftBaseLocation = CLLocation(
                    latitude: otherLift.startLocation.latitude,
                    longitude: otherLift.startLocation.longitude
                )
                
                let distance = liftTopLocation.distance(from: otherLiftBaseLocation)
                if distance < connectionThreshold {
                    edges.append(Edge(
                        from: "\(lift.id.uuidString)_top",
                        to: otherLift.id.uuidString,
                        type: .connection,
                        distance: distance
                    ))
                }
            }
        }
        
        // Connect run tops to run bottoms
        for run in resort.runs {
            if run.status != .open {
                continue
            }
            
            edges.append(Edge(
                from: "\(run.id.uuidString)_top",
                to: "\(run.id.uuidString)_bottom",
                type: .run(difficulty: run.difficulty),
                distance: run.length
            ))
        }
        
        // Connect run bottoms to lift bases
        for run in resort.runs {
            if run.status != .open {
                continue
            }
            
            let runBottomLocation = CLLocation(
                latitude: run.endLocation.latitude,
                longitude: run.endLocation.longitude
            )
            
            for lift in resort.lifts {
                if lift.status != .open {
                    continue
                }
                
                let liftBaseLocation = CLLocation(
                    latitude: lift.startLocation.latitude,
                    longitude: lift.startLocation.longitude
                )
                
                let distance = runBottomLocation.distance(from: liftBaseLocation)
                if distance < connectionThreshold {
                    edges.append(Edge(
                        from: "\(run.id.uuidString)_bottom",
                        to: lift.id.uuidString,
                        type: .connection,
                        distance: distance
                    ))
                }
            }
        }
        
        return edges
    }
    
    private func findNearestNode(to coordinate: CLLocationCoordinate2D, in graph: ResortGraph) throws -> Node {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        guard let nearest = graph.nodes.values.min(by: { a, b in
            let aLocation = CLLocation(
                latitude: a.coordinate.latitude,
                longitude: a.coordinate.longitude
            )
            let bLocation = CLLocation(
                latitude: b.coordinate.latitude,
                longitude: b.coordinate.longitude
            )
            
            return location.distance(from: aLocation) < location.distance(from: bLocation)
        }) else {
            throw RoutingError.noRouteFound
        }
        
        return nearest
    }
    
    private func findPath(
        from start: Node,
        to end: Node,
        in graph: ResortGraph,
        maxDifficulty: SkiDifficulty,
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
                   !isRunAllowed(run, maxDifficulty: maxDifficulty) {
                    continue
                }
                
                let tentativeGScore = (gScore[current] ?? .infinity) + calculateEdgeWeight(edge, node: node, preferences: preferences)
                
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
    
    private func calculateEdgeWeight(_ edge: Edge, node: Node, preferences: RoutePreferences) -> Double {
        var weight = edge.distance
        
        switch edge.type {
        case .lift:
            if preferences.avoidCrowds,
               case .lift(let lift) = node.type,
               let waitTime = lift.waitTime,
               waitTime > (preferences.maxWaitTime ?? 15) {
                // Apply significant penalty for crowded lifts
                weight *= 2.5
            }
            
        case .run:
            if preferences.preferLessStrenuous {
                // Apply penalty based on run length and elevation change
                let elevationPenalty = abs(node.elevation) * 0.5
                weight = weight * (1 + elevationPenalty/1000)
            }
            
        case .connection:
            // Apply small penalty to walking connections if preferring less strenuous routes
            if preferences.preferLessStrenuous {
                weight *= 1.2
            }
        }
        
        return weight
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
            latitude: from.coordinate.latitude,
            longitude: from.coordinate.longitude
        )
        let toLocation = CLLocation(
            latitude: to.coordinate.latitude,
            longitude: to.coordinate.longitude
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
    
    private func buildSegment(
        from: Node,
        to: Node,
        edge: Edge
    ) throws -> Route.Segment {
        let type: Route.Segment.SegmentType
        
        switch (from.type, to.type) {
        case (.lift(let lift), _):
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
                    latitude: from.coordinate.latitude,
                    longitude: from.coordinate.longitude,
                    altitude: from.elevation
                ),
                Route.Segment.Location(
                    latitude: to.coordinate.latitude,
                    longitude: to.coordinate.longitude,
                    altitude: to.elevation
                )
            ],
            distance: edge.distance
        )
    }
}

// MARK: - Supporting Types

public struct ResortGraph {
    let nodes: [String: Node]
    let edges: [Edge]
}

public struct Node {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let elevation: Double
    let type: NodeType
    
    init(id: String, coordinate: CLLocationCoordinate2D, elevation: Double, type: NodeType = .point) {
        self.id = id
        self.coordinate = coordinate
        self.elevation = elevation
        self.type = type
    }
}

public enum NodeType {
    case lift(Lift)
    case run(Run)
    case point
}

public struct Edge {
    let from: String
    let to: String
    let type: EdgeType
    let distance: Double
    
    enum EdgeType {
        case run(difficulty: SkiDifficulty)
        case lift
        case connection
    }
}

public struct RoutePreferences {
    public let avoidCrowds: Bool
    public let preferLessStrenuous: Bool
    public let maxWaitTime: TimeInterval?
    
    public init(avoidCrowds: Bool = false, preferLessStrenuous: Bool = false, maxWaitTime: TimeInterval? = nil) {
        self.avoidCrowds = avoidCrowds
        self.preferLessStrenuous = preferLessStrenuous
        self.maxWaitTime = maxWaitTime
    }
}

public enum RoutingError: Error {
    case graphNotInitialized
    case noRouteFound
    case invalidPath
} 