//
//  Response.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal protocol Response {
    
    var isOK: Bool { get }
    var isNotModified: Bool { get }
    var isUnauthorized: Bool { get }
    var isNotFound: Bool { get }
    var isMethodNotAllowed: Bool { get }
    
    var etag: String? { get }

}
