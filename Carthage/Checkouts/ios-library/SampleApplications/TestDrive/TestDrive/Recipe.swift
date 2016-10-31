//
//  Recipe.swift
//  TestDrive
//
//  Created by Victor Barros on 2016-01-27.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import Kinvey

class Recipe: NSObject, Persistable {
    
    dynamic var id: String?
    dynamic var name: String?
    
    override init() {
    }
    
    init(name: String) {
        self.name = name
    }
    
    static func kinveyCollectionName() -> String {
        return "Recipe"
    }
    
//    static func kinveyPropertyMapping() -> [String : String] {
//        return [
//            "name" : "name",
//            "id" : Kinvey.PersistableIdKey
//        ]
//    }
    
}
