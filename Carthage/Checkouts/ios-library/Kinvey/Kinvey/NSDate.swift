//
//  NSDate.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-01.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

extension Date {
    
    func toString() -> String {
        return NSDate2StringValueTransformer.rfc3339MilliSecondsDateFormatter.string(from: self)
    }
    
}
