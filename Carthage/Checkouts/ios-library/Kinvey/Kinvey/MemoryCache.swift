//
//  MemoryCache.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-29.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class MemoryCache<T: Persistable>: Cache<T> where T: NSObject {
    
    var memory = [String : T]()
    
    init() {
        super.init(persistenceId: "")
    }
    
    override func saveEntity(_ entity: T) {
        let objId = entity.entityId!
        memory[objId] = entity
    }
    
    override func saveEntities(_ entities: [T]) {
        for entity in entities {
            saveEntity(entity)
        }
    }
    
    override func findEntity(_ objectId: String) -> T? {
        return memory[objectId]
    }
    
    override func findEntityByQuery(_ query: Query) -> [T] {
        guard let predicate = query.predicate else {
            return memory.values.map({ (json) -> Type in
                return json
            })
        }
        return memory.filter({ (key, obj) -> Bool in
            return predicate.evaluate(with: obj)
        }).map({ (key, obj) -> Type in
            return obj
        })
    }
    
    override func findIdsLmtsByQuery(_ query: Query) -> [String : String] {
        var results = [String : String]()
        let array = findEntityByQuery(query).map { (entity) -> (String, String) in
            let kmd = entity.metadata!
            return (entity.entityId!, kmd.lmt!)
        }
        for item in array {
            results[item.0] = item.1
        }
        return results
    }
    
    override func findAll() -> [T] {
        return findEntityByQuery(Query())
    }
    
    override func count(_ query: Query? = nil) -> Int {
        if let query = query {
            return findEntityByQuery(query).count
        }
        return memory.count
    }
    
    @discardableResult
    override func removeEntity(_ entity: T) -> Bool {
        let objId = entity.entityId!
        return memory.removeValue(forKey: objId) != nil
    }
    
    @discardableResult
    override func removeEntitiesByQuery(_ query: Query) -> Int {
        let objs = findEntityByQuery(query)
        for obj in objs {
            removeEntity(obj)
        }
        return objs.count
    }
    
    override func removeAllEntities() {
        memory.removeAll()
    }
    
}
