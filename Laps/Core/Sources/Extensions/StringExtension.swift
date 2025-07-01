//
//  StringExtension.swift
//  Core
//
//  Created by Moon kyu Jung on 3/16/25.
//  Copyright © 2025 mooq. All rights reserved.
//

import Foundation

public extension String {
    func toDate(format: String = "yyyyMMdd HH:mm") -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale.current
        return dateFormatter.date(from: self)
    }
    
    func extractValue(for key: String) -> String? {
        let pattern = "<\(key)>(.*?)</\(key)>"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsString = self as NSString
            let results = regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if let matchRange = results?.range(at: 1) {
                return nsString.substring(with: matchRange)
            }
        } catch {
            print("Regex error: \(error)")
        }
        
        return nil
    }
    
    subscript (safe range: CountableRange<Int>) -> String? {
        if max(self.count, range.lowerBound) == range.lowerBound || self.count < range.upperBound{
            return nil
        }
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
        let end = index(start, offsetBy: min(self.count - range.lowerBound, range.upperBound - range.lowerBound))
        
        return String(self[start..<end])
    }
    
    subscript(_ range: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
        let end = index(start, offsetBy: min(self.count - range.lowerBound, range.upperBound - range.lowerBound))
        return String(self[start..<end])
    }
    
    var yyyy: String? {
        return self[safe: 0..<4]
    }
    
    var MM: String? {
        return self[safe: 4..<6]
    }
    
    var dd: String? {
        return self[safe: 6..<8]
    }
    
    var ee: String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale.current
        guard let date = dateFormatter.date(from: self) else { return nil }
        dateFormatter.dateFormat = "EE"
        return dateFormatter.string(from: date)
    }
    
    var yyyy_MM_dd: String? {
        var temp = self
        temp.insert("-", at: temp.index(temp.startIndex, offsetBy: 6))
        temp.insert("-", at: temp.index(temp.startIndex, offsetBy: 4))
        return temp
    }
    
}
