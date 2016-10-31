//
//  ReadPolicy.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-21.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

/// Policy that describes how a read operation should perform.
@objc
public enum ReadPolicy: UInt {
    
    /// Doesn't hit the network, forcing the data to be read only from the local cache.
    case forceLocal = 0
    
    /// Doesn't hit the local cache, forcing the data to be read only from the network (backend).
    case forceNetwork
    
    /// Read first from the local cache and then try to get data from the network (backend).
    case both
    
}
