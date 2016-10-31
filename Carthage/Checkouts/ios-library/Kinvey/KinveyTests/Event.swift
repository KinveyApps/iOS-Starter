//
//  Event.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-07-08.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Kinvey

/// Event.swift - an entity in the 'Events' collection
class Event : Entity {

    var name: String?
    var publishDate: Date?
    var location: String?
    
    override class func collectionName() -> String {
        return "Event"
    }
    
    override func propertyMapping(_ map: Map) {
        super.propertyMapping(map)
        
        name <- ("name", map["name"])
        publishDate <- ("date", map["date"], ISO8601DateTransform())
        location <- ("location", map["location"])
    }
    
}
