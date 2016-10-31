//
//  RefProject.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-19.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
@testable import Kinvey

class RefProject: Entity {
    
    dynamic var uniqueId: String?
    dynamic var name: String?
    
    override class func collectionName() -> String {
        return "HelixProjectProjects"
    }
    
    override func propertyMapping(_ map: Map) {
        super.propertyMapping(map)
        
        uniqueId <- map[PersistableIdKey]
        name <- map["name"]
    }
    
}
