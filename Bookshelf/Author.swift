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

class Author: Object, Codable {
    
    @objc dynamic var firstName: String?
    @objc dynamic var lastName: String?
    let books = LinkingObjects(fromType: Book.self, property: "authors")
    
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
    }
    
}
