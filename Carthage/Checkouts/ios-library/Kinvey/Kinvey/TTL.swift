//
//  CachedStoreExpiration.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-13.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

/// Describes a unit to be used in a time perspective.
public enum TimeUnit {
    
    /// Time unit that represents seconds.
    case second
    
    /// Time unit that represents minutes.
    case minute
    
    /// Time unit that represents hours.
    case hour
    
    /// Time unit that represents days.
    case day
}

extension TimeUnit {
    
    var timeInterval: TimeInterval {
        switch self {
        case .second: return 1
        case .minute: return 60
        case .hour: return 60 * TimeUnit.minute.timeInterval
        case .day: return 24 * TimeUnit.hour.timeInterval
        }
    }
    
    func toTimeInterval(_ value: Int) -> TimeInterval {
        return TimeInterval(value) * timeInterval
    }
    
}

public typealias TTL = (Int, TimeUnit)

extension Int {
    
    internal var seconds: TTL { return TTL(self, .second) }
    internal var minutes: TTL { return TTL(self, .minute) }
    internal var hours: TTL { return TTL(self, .hour) }
    internal var days: TTL { return TTL(self, .day) }
    
    var secondsDate : Date { return date(.second) }
    var minutesDate : Date { return date(.minute) }
    var hoursDate   : Date { return date(.hour) }
    var daysDate    : Date { return date(.day) }
    
    internal func date(_ timeUnit: TimeUnit, calendar: Calendar = Calendar.current) -> Date {
        var dateComponents = DateComponents()
        switch timeUnit {
        case .second:
            dateComponents.day = -self
        case .minute:
            dateComponents.minute = -self
        case .hour:
            dateComponents.hour = -self
        case .day:
            dateComponents.day = -self
        }
        let newDate = (calendar as NSCalendar).date(byAdding: dateComponents, to: Date(), options: [])
        return newDate!
    }
    
}
