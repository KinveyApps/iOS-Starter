//
//  NSData.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-03.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

extension Data {
    
    func hexString() -> String {
        let str = NSMutableString()
        let bytes = UnsafeBufferPointer<UInt8>(start: (self as NSData).bytes.bindMemory(to: UInt8.self, capacity: self.count), count:self.count)
        for byte in bytes {
            str.appendFormat("%02hhx", byte)
        }
        return str as String
    }
    
}
