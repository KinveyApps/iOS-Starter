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
import RealmSwift

class Book: Entity {
    
    dynamic var title: String?
    let authors = List<Author>()
    
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
        authors <- ("authors", map["authors"])
    }
}

func <-<T: BaseMappable>(lhs: List<T>, rhs: (String, Map)) {
    var list = lhs
    let transform = TransformOf<List<T>, [[String : Any]]>(fromJSON: { (array) -> List<T>? in
        if let array = array {
            let list = List<T>()
            for item in array {
                if let item = T(JSON: item) {
                    list.append(item)
                }
            }
            return list
        }
        return nil
    }, toJSON: { (list) -> [[String : Any]]? in
        if let list = list {
            return list.map { $0.toJSON() }
        }
        return nil
    })
    switch rhs.1.mappingType {
    case .fromJSON:
        list <- (rhs.1, transform)
    case .toJSON:
        list <- (rhs.1, transform)
    }
}
