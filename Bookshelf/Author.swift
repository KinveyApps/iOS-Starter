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

class Author: Object, Mappable {
    
    dynamic var firstName: String?
    dynamic var lastName: String?
    
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
    
    func mapping(map: Map) {
        firstName <- ("firstName", map["first_name"])
        lastName <- ("lastName", map["last_name"])
    }
    
}
