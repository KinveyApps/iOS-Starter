//
//  DirectoryEntry.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-19.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
@testable import Kinvey

class DirectoryEntry: Entity {
    
    dynamic var uniqueId: String?
    dynamic var nameFirst: String?
    dynamic var nameLast: String?
    dynamic var email: String?
    
    dynamic var refProject: RefProject?
    
    override class func collectionName() -> String {
        return "HelixProjectDirectory"
    }
    
    override func propertyMapping(_ map: Map) {
        super.propertyMapping(map)
        
        uniqueId <- map[PersistableIdKey]
        nameFirst <- map["nameFirst"]
        nameLast <- map["nameLast"]
        email <- map["email"]
    }
    
    override class func ignoredProperties() -> [String] {
        return ["refProject"]
    }
    
}
