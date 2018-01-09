//
//  Person.swift
//  Bookshelf
//
//  Created by Victor Hugo on 2017-01-31.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import Kinvey
import RealmSwift
import ObjectMapper

class Author: Entity {
    
    @objc dynamic var firstName: String?
    @objc dynamic var lastName: String?
    let books = LinkingObjects(fromType: Book.self, property: "authors")
    
    override class func collectionName() -> String {
        //return the name of the backend collection corresponding to this entity
        return "Author"
    }
    
    convenience required init?(map: Map) {
        guard
            let firstName: String = map["first_name"].value(),
            let lastName: String = map["last_name"].value()
            else
        {
            return nil
        }
        
        self.init()
        self.firstName = firstName
        self.lastName = lastName
    }
    
    override func propertyMapping(_ map: Map) {
        super.propertyMapping(map)
        
        firstName <- ("firstName", map["first_name"])
        lastName <- ("lastName", map["last_name"])
    }
    
}
