//
//  NSDate2StringValueConverter.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-01.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class NSDate2StringValueTransformer: Foundation.ValueTransformer, NSValueTransformerReverse {
    
    static let rfc3339DateFormatter: DateFormatter = {
        let rfc3339DateFormatter = DateFormatter()
        rfc3339DateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale!
        rfc3339DateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
        rfc3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return rfc3339DateFormatter
    }()
    
    static let rfc3339MilliSecondsDateFormatter: DateFormatter = {
        let rfc3339DateFormatter = DateFormatter()
        rfc3339DateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale!
        rfc3339DateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"
        rfc3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return rfc3339DateFormatter
    }()
    
    override class func transformedValueClass() -> AnyClass {
        return NSString.self
    }
    
    static func reverseTransformedValueClass() -> AnyClass {
        return NSDate.self
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let date = value as? Date else { return nil }
        return date.toString()
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let string = value as? String else { return nil }
        return string.toDate()
    }
    
}
