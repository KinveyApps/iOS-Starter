//
//  LongData.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Kinvey

class LongData: Entity {
    
    dynamic var id: String?
    dynamic var seq: Int = 0
    dynamic var first: String?
    dynamic var last: String?
    dynamic var age: Int = 0
    dynamic var street: String?
    dynamic var city: String?
    dynamic var state: String?
    dynamic var zip: Int = 0
    dynamic var dollar: String?
    dynamic var pick: String?
    dynamic var paragraph: String?
    
    override class func collectionName() -> String {
        return "longdata"
    }
    
    override func propertyMapping(_ map: Map) {
        super.propertyMapping(map)
        
        id <- map[PersistableIdKey]
        seq <- map["seq"]
        first <- map["first"]
        last <- map["last"]
        age <- map["age"]
        street <- map["street"]
        city <- map["city"]
        state <- map["state"]
        zip <- map["zip"]
        dollar <- map["dollar"]
        pick <- map["pick"]
        paragraph <- map["paragraph"]
    }
    
}
