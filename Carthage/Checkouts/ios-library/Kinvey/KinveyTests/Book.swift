//
//  Book.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-07-11.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Kinvey

class Book: Entity {
    
    dynamic var title: String?
    
    override class func collectionName() -> String {
        return "Book"
    }
    
    override func propertyMapping(_ map: Map) {
        super.propertyMapping(map)
        
        Kinvey.sharedClient.timeoutInterval = 120 //2 minutes timeout
        
        title <- ("title", map["title"])
    }
    
}
