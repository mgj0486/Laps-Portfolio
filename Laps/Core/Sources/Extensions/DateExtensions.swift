//
//  DateExtensions.swift
//  Entities
//
//  Created by dev team on 1/16/24.
//  Copyright © 2024 perspective. All rights reserved.
//

import Foundation

public extension Date {
    func fromDate(day: Int) -> Date? {
        return Calendar.current.date(byAdding: .day, value: day, to: self)
    }
    
    func timeAgoDisplay() -> String {
        let secondsAgo = Int(Date().timeIntervalSince(self))
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
//        let week = 7 * day
//        let month = 30 * day

        if secondsAgo < minute {
            return "\(secondsAgo) seconds ago"
        } else if secondsAgo < hour {
            return "\(secondsAgo / minute) minutes ago"
        } else if secondsAgo < day {
            return "\(secondsAgo / hour) hours ago"
        }
        return "\(secondsAgo / day) days ago"
    }
    
    func getFormattedDate(format: String) -> String {
        let dateformat = DateFormatter()
        dateformat.dateFormat = format
        dateformat.locale = Locale.current
        return dateformat.string(from: self)
    }
    
    func secondgap() -> String {
        if Date.now.timeIntervalSince1970 - self.timeIntervalSince1970 >= 3600*9 {
            return "\(Int(Date.now.timeIntervalSince1970 - self.timeIntervalSince1970 - (3600*9)))"
        } else {
            return "\(Int(Date.now.timeIntervalSince1970 - self.timeIntervalSince1970))"
        }
    }
    
    var nextDate: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: self)!
    }
    
    var prevDate: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: self)!
    }
}
