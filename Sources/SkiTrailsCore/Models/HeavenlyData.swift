import Foundation

public enum HeavenlyData {
    public static let runs = """
    {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "properties": {
            "name": "Orion",
            "difficulty": "blue",
            "status": "open"
          },
          "geometry": {
            "type": "Polygon",
            "coordinates": [[
              [-119.939, 38.935],
              [-119.938, 38.934],
              [-119.937, 38.933],
              [-119.938, 38.932],
              [-119.939, 38.935]
            ]]
          }
        },
        {
          "type": "Feature",
          "properties": {
            "name": "Comet",
            "difficulty": "black",
            "status": "open"
          },
          "geometry": {
            "type": "Polygon",
            "coordinates": [[
              [-119.940, 38.936],
              [-119.939, 38.935],
              [-119.938, 38.934],
              [-119.939, 38.933],
              [-119.940, 38.936]
            ]]
          }
        },
        {
          "type": "Feature",
          "properties": {
            "name": "Big Dipper",
            "difficulty": "blue",
            "status": "open"
          },
          "geometry": {
            "type": "Polygon",
            "coordinates": [[
              [-119.941, 38.937],
              [-119.940, 38.936],
              [-119.939, 38.935],
              [-119.940, 38.934],
              [-119.941, 38.937]
            ]]
          }
        }
      ]
    }
    """
    
    public static let lifts = """
    {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "properties": {
            "name": "Heavenly Gondola",
            "type": "gondola",
            "status": "open"
          },
          "geometry": {
            "type": "LineString",
            "coordinates": [
              [-119.939, 38.935],
              [-119.938, 38.934],
              [-119.937, 38.933]
            ]
          }
        },
        {
          "type": "Feature",
          "properties": {
            "name": "Comet Express",
            "type": "chairlift",
            "status": "open"
          },
          "geometry": {
            "type": "LineString",
            "coordinates": [
              [-119.940, 38.936],
              [-119.939, 38.935],
              [-119.938, 38.934]
            ]
          }
        },
        {
          "type": "Feature",
          "properties": {
            "name": "Dipper Express",
            "type": "chairlift",
            "status": "open"
          },
          "geometry": {
            "type": "LineString",
            "coordinates": [
              [-119.941, 38.937],
              [-119.940, 38.936],
              [-119.939, 38.935]
            ]
          }
        }
      ]
    }
    """
    
    public static let boundaries = """
    {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "properties": {
            "name": "Heavenly Resort Boundary"
          },
          "geometry": {
            "type": "Polygon",
            "coordinates": [[
              [-119.942, 38.938],
              [-119.936, 38.938],
              [-119.936, 38.932],
              [-119.942, 38.932],
              [-119.942, 38.938]
            ]]
          }
        }
      ]
    }
    """
} 