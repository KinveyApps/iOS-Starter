//
//  Book.swift
//  Bookshelf
//
//  Created by Victor Barros on 2016-02-08.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import Kinvey
import ObjectMapper

class Book: Entity {
    
    dynamic var title: String?
    dynamic var authorName: String?
    
    override class func collectionName() -> String {
        //return the name of the backend collection corresponding to this entity
        return "Book"
    }
    
    //Map properties in your backend collection to the members of this entity
    override func propertyMapping(_ map: Map) {
        
        //This maps the "_id", "_kmd" and "_acl" properties
        super.propertyMapping(map)
        
        //Each property in your entity should be mapped using the following scheme:
        //<member variable> <- ("<backend property>", map["<backend property>"])
        title <- ("title", map["title"])
        authorName <- ("author", map["author"])
    }
}
