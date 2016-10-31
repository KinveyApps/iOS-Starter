//
//  PendingOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal protocol PendingOperationType {
    
    var objectId: String? { get }
    
    func buildRequest() -> URLRequest
    
}
