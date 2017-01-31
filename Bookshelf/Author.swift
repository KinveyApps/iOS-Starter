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

class Author: Object, StaticMappable {
    
    dynamic var firstName: String?
    dynamic var lastName: String?
    
    static func objectForMapping(map: Map) -> BaseMappable? {
        guard
            let firstName: String = map["first_name"].value(),
            let lastName: String = map["last_name"].value()
            else
        {
            return nil
        }
        
        let author = Author()
        author.firstName = firstName
        author.lastName = lastName
        return author
    }
    
    func mapping(map: Map) {
        firstName <- ("firstName", map["first_name"])
        lastName <- ("lastName", map["last_name"])
    }
    
}
