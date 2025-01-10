import Foundation

public actor RoutingEngine {
    private var graph: Graph
    
    public init() {
        self.graph = Graph()
    }
    
    public func findRoute(from start: Location, to end: Location, in resort: Resort) async -> Route? {
        // Build graph from resort data
        buildGraph(from: resort)
        
        // Find nearest nodes to start and end locations
        guard let startNode = findNearestNode(to: start),
              let endNode = findNearestNode(to: end) else {
            return nil
        }
        
        // Use A* algorithm to find path
        let path = findPath(from: startNode, to: endNode)
        
        // Convert path to route segments
        return buildRoute(from: path)
    }
    
    private func buildGraph(from resort: Resort) {
        graph = Graph()
        
        // Add nodes for all lift stations and run endpoints
        for lift in resort.lifts where lift.status == .open {
            graph.addNode(lift.startLocation)
            graph.addNode(lift.endLocation)
            
            // Add edge for lift
            graph.addEdge(from: lift.startLocation, to: lift.endLocation, segment: RouteSegment(type: .lift(lift)))
        }
        
        for run in resort.runs where run.status == .open {
            graph.addNode(run.startLocation)
            graph.addNode(run.endLocation)
            
            // Add edge for run
            graph.addEdge(from: run.startLocation, to: run.endLocation, segment: RouteSegment(type: .run(run)))
        }
    }
    
    private func findNearestNode(to location: Location) -> Location? {
        return graph.nodes.min { a, b in
            location.distance(to: a) < location.distance(to: b)
        }
    }
    
    private func findPath(from start: Location, to end: Location) -> [Location] {
        var openSet = Set([start])
        var cameFrom: [Location: Location] = [:]
        var gScore: [Location: Double] = [start: 0]
        var fScore: [Location: Double] = [start: heuristic(start, end)]
        
        while !openSet.isEmpty {
            let current = openSet.min { a, b in
                (fScore[a] ?? .infinity) < (fScore[b] ?? .infinity)
            }!
            
            if current == end {
                return reconstructPath(cameFrom: cameFrom, current: current)
            }
            
            openSet.remove(current)
            
            for neighbor in graph.neighbors(of: current) {
                let tentativeGScore = (gScore[current] ?? .infinity) + current.distance(to: neighbor)
                
                if tentativeGScore < (gScore[neighbor] ?? .infinity) {
                    cameFrom[neighbor] = current
                    gScore[neighbor] = tentativeGScore
                    fScore[neighbor] = tentativeGScore + heuristic(neighbor, end)
                    openSet.insert(neighbor)
                }
            }
        }
        
        return []
    }
    
    private func heuristic(_ a: Location, _ b: Location) -> Double {
        return a.distance(to: b)
    }
    
    private func reconstructPath(cameFrom: [Location: Location], current: Location) -> [Location] {
        var path = [current]
        var current = current
        
        while let next = cameFrom[current] {
            path.insert(next, at: 0)
            current = next
        }
        
        return path
    }
    
    private func buildRoute(from path: [Location]) -> Route? {
        guard path.count >= 2 else { return nil }
        
        var segments: [RouteSegment] = []
        
        for i in 0..<(path.count - 1) {
            let start = path[i]
            let end = path[i + 1]
            
            if let segment = graph.edge(from: start, to: end) {
                segments.append(segment)
            }
        }
        
        return Route(segments: segments)
    }
}

// MARK: - Supporting Types
extension RoutingEngine {
    public struct Route {
        public let segments: [RouteSegment]
        
        public var totalDistance: Double {
            segments.reduce(0) { sum, segment in
                switch segment.type {
                case .lift(let lift):
                    return sum + lift.startLocation.distance(to: lift.endLocation)
                case .run(let run):
                    return sum + run.length
                }
            }
        }
        
        public var totalVerticalDrop: Double {
            segments.reduce(0) { sum, segment in
                switch segment.type {
                case .lift(let lift):
                    return sum + (lift.endLocation.elevation - lift.startLocation.elevation)
                case .run(let run):
                    return sum + run.verticalDrop
                }
            }
        }
    }
    
    public struct RouteSegment: Identifiable {
        public let id = UUID()
        public let type: SegmentType
        
        public enum SegmentType {
            case lift(Lift)
            case run(Run)
        }
    }
    
    private class Graph {
        private var adjacencyList: [Location: Set<Location>] = [:]
        private var edges: [String: RouteSegment] = [:]
        
        var nodes: Set<Location> {
            Set(adjacencyList.keys)
        }
        
        func addNode(_ node: Location) {
            if adjacencyList[node] == nil {
                adjacencyList[node] = []
            }
        }
        
        func addEdge(from source: Location, to destination: Location, segment: RouteSegment) {
            addNode(source)
            addNode(destination)
            adjacencyList[source]?.insert(destination)
            edges[edgeKey(from: source, to: destination)] = segment
        }
        
        func neighbors(of node: Location) -> Set<Location> {
            adjacencyList[node] ?? []
        }
        
        func edge(from source: Location, to destination: Location) -> RouteSegment? {
            edges[edgeKey(from: source, to: destination)]
        }
        
        private func edgeKey(from source: Location, to destination: Location) -> String {
            "\(source.latitude),\(source.longitude),\(source.elevation)->\(destination.latitude),\(destination.longitude),\(destination.elevation)"
        }
    }
} 