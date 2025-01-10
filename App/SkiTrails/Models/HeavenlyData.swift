import Foundation
import MapboxMaps
import Combine

class HeavenlyData: ObservableObject {
    @Published private(set) var boundaries: String?
    @Published private(set) var runs: String?
    @Published private(set) var lifts: String?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    private let dataService = ResortDataService()
    private var cancellables = Set<AnyCancellable>()
    
    static let shared = HeavenlyData()
    
    private init() {
        // Subscribe to data service updates
        dataService.$boundaries
            .assign(to: &$boundaries)
        
        dataService.$runs
            .assign(to: &$runs)
        
        dataService.$lifts
            .assign(to: &$lifts)
        
        dataService.$isLoading
            .assign(to: &$isLoading)
        
        dataService.$error
            .assign(to: &$error)
        
        // Fetch initial data
        fetchData()
    }
    
    func fetchData() {
        dataService.fetchResortData(resortId: "heavenly")
    }
    
    // Fallback data in case API is not available
    static let fallbackBoundaries: String = """
    {
        "type": "Feature",
        "geometry": {
            "type": "Polygon",
            "coordinates": [[
                [-119.9500, 38.9300],
                [-119.9500, 38.9400],
                [-119.9300, 38.9400],
                [-119.9300, 38.9300],
                [-119.9500, 38.9300]
            ]]
        },
        "properties": {
            "name": "Heavenly Mountain Resort"
        }
    }
    """
    
    static let fallbackRuns: String = """
    {
        "type": "FeatureCollection",
        "features": [
            {
                "type": "Feature",
                "geometry": {
                    "type": "Polygon",
                    "coordinates": [[
                        [-119.9400, 38.9350],
                        [-119.9400, 38.9370],
                        [-119.9380, 38.9370],
                        [-119.9380, 38.9350],
                        [-119.9400, 38.9350]
                    ]]
                },
                "properties": {
                    "name": "Ridge Run",
                    "difficulty": "blue",
                    "status": "open"
                }
            },
            {
                "type": "Feature",
                "geometry": {
                    "type": "Polygon",
                    "coordinates": [[
                        [-119.9380, 38.9350],
                        [-119.9380, 38.9370],
                        [-119.9360, 38.9370],
                        [-119.9360, 38.9350],
                        [-119.9380, 38.9350]
                    ]]
                },
                "properties": {
                    "name": "Orion's Run",
                    "difficulty": "black",
                    "status": "open"
                }
            },
            {
                "type": "Feature",
                "geometry": {
                    "type": "Polygon",
                    "coordinates": [[
                        [-119.9420, 38.9350],
                        [-119.9420, 38.9370],
                        [-119.9400, 38.9370],
                        [-119.9400, 38.9350],
                        [-119.9420, 38.9350]
                    ]]
                },
                "properties": {
                    "name": "Comet Run",
                    "difficulty": "green",
                    "status": "open"
                }
            }
        ]
    }
    """
    
    static let fallbackLifts: String = """
    {
        "type": "FeatureCollection",
        "features": [
            {
                "type": "Feature",
                "geometry": {
                    "type": "LineString",
                    "coordinates": [
                        [-119.9450, 38.9320],
                        [-119.9400, 38.9380]
                    ]
                },
                "properties": {
                    "name": "Gondola",
                    "type": "gondola",
                    "status": "operating"
                }
            },
            {
                "type": "Feature",
                "geometry": {
                    "type": "LineString",
                    "coordinates": [
                        [-119.9380, 38.9320],
                        [-119.9350, 38.9380]
                    ]
                },
                "properties": {
                    "name": "Comet Express",
                    "type": "chairlift",
                    "status": "operating"
                }
            }
        ]
    }
    """
} 