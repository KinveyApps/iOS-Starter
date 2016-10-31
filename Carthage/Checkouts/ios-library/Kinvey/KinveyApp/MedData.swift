//
//  MedData.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Kinvey

class MedData: Entity {
    
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
    
    override class func collectionName() -> String {
        return "meddata"
    }
    
    override func propertyMapping(_ map: Map) {
        super.propertyMapping(map)
        
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
    }
    
}
