//
//  Book.swift
//  Bookshelf
//
//  Created by Victor Barros on 2016-02-08.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import Kinvey

class Book: NSObject, Persistable {
    
    dynamic var objectId: String?
    dynamic var title: String?
    
    override init() {
    }
    
    init(title: String) {
        self.title = title
    }
    
    static func kinveyCollectionName() -> String {
        return "Book"
    }
    
    static func kinveyPropertyMapping() -> [String : String] {
        return [
            "objectId" : Kinvey.PersistableIdKey,
            "title" : "title"
        ]
    }
    
}
