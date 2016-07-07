//
//  Book.swift
//  Bookshelf
//
//  Created by Victor Barros on 2016-02-08.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import Kinvey

class Book: Entity {
    
    dynamic var title: String?
    
    override static func collectionName() -> String {
        return "Book"
    }
    
    override func propertyMapping(map: Map) {
        super.propertyMapping(map)
        
        title <- map["title"]
    }

}
