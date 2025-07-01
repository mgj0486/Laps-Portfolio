//
//  CLLocationCoordinate2D+Codable.swift
//  Core
//
//  Created by Assistant on 2025/06/21.
//

import CoreLocation

extension CLLocationCoordinate2D: Codable {
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
}

// Polyline Encoding/Decoding
public extension Array where Element == CLLocationCoordinate2D {
    func encodePolyline() -> String {
        var encodedString = ""
        var previousLat = 0
        var previousLng = 0
        
        for coordinate in self {
            let lat = Int(round(coordinate.latitude * 1e5))
            let lng = Int(round(coordinate.longitude * 1e5))
            
            let dLat = lat - previousLat
            let dLng = lng - previousLng
            
            encodedString += encodeValue(dLat)
            encodedString += encodeValue(dLng)
            
            previousLat = lat
            previousLng = lng
        }
        
        return encodedString
    }
    
    private func encodeValue(_ value: Int) -> String {
        var value = value
        value = value < 0 ? ~(value << 1) : (value << 1)
        var encoded = ""
        
        while value >= 0x20 {
            encoded += String(Character(UnicodeScalar((0x20 | (value & 0x1f)) + 63)!))
            value >>= 5
        }
        
        encoded += String(Character(UnicodeScalar(value + 63)!))
        return encoded
    }
}

public extension String {
    func decodePolyline() -> [CLLocationCoordinate2D]? {
        var coordinates = [CLLocationCoordinate2D]()
        var index = self.startIndex
        var lat = 0
        var lng = 0
        
        while index < self.endIndex {
            var shift = 0
            var result = 0
            var byte: Int
            
            repeat {
                let char = self[index]
                index = self.index(after: index)
                byte = Int(char.asciiValue! - 63)
                result |= (byte & 0x1f) << shift
                shift += 5
            } while byte >= 0x20
            
            let dLat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1)
            lat += dLat
            
            shift = 0
            result = 0
            
            repeat {
                let char = self[index]
                index = self.index(after: index)
                byte = Int(char.asciiValue! - 63)
                result |= (byte & 0x1f) << shift
                shift += 5
            } while byte >= 0x20
            
            let dLng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1)
            lng += dLng
            
            let coordinate = CLLocationCoordinate2D(
                latitude: Double(lat) / 1e5,
                longitude: Double(lng) / 1e5
            )
            coordinates.append(coordinate)
        }
        
        return coordinates
    }
}
