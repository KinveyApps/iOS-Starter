//
//  Operation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class Operation<T: Persistable>: NSObject where T: NSObject {
    
    typealias ArrayCompletionHandler = ([T]?, Swift.Error?) -> Void
    typealias ObjectCompletionHandler = (T?, Swift.Error?) -> Void
    typealias UIntCompletionHandler = (UInt?, Swift.Error?) -> Void
    typealias UIntArrayCompletionHandler = (UInt?, [T]?, Swift.Error?) -> Void
    
    let cache: Cache<T>?
    let client: Client
    
    init(cache: Cache<T>? = nil, client: Client) {
        self.cache = cache
        self.client = client
    }
    
    func reduceToIdsLmts(_ jsonArray: [JsonDictionary]) -> [String : String] {
        var items = [String : String](minimumCapacity: jsonArray.count)
        for json in jsonArray {
            if let id = json[PersistableIdKey] as? String,
                let kmd = json[PersistableMetadataKey] as? JsonDictionary,
                let lmt = kmd[Metadata.LmtKey] as? String
            {
                items[id] = lmt
            }
        }
        return items
    }
    
    func computeDeltaSet(_ query: Query, refObjs: [String : String]) -> (created: Set<String>, updated: Set<String>, deleted: Set<String>) {
        guard let cache = cache else {
            return (created: Set<String>(), updated: Set<String>(), deleted: Set<String>())
        }
        let refKeys = Set<String>(refObjs.keys)
        let cachedObjs = cache.findIdsLmtsByQuery(query)
        let cachedKeys = Set<String>(cachedObjs.keys)
        let createdKeys = refKeys.subtracting(cachedKeys)
        let deletedKeys = cachedKeys.subtracting(refKeys)
        var updatedKeys = refKeys.intersection(cachedKeys)
        if updatedKeys.count > 0 {
            updatedKeys = Set<String>(updatedKeys.filter({ refObjs[$0] != cachedObjs[$0] }))
        }
        return (created: createdKeys, updated: updatedKeys, deleted: deletedKeys)
    }
    
    func fillObject(_ persistable: inout T) -> T {
        if persistable.entityId == nil {
            persistable.entityId = "\(ObjectIdTmpPrefix)\(UUID().uuidString)"
        }
        if persistable.acl == nil, let activeUser = client.activeUser {
            persistable.acl = Acl(creator: activeUser.userId)
        }
        return persistable
    }
    
    func merge(_ persistableArray: inout [T], jsonArray: [JsonDictionary]) {
        if persistableArray.count == jsonArray.count && persistableArray.count > 0 {
            for (index, _) in persistableArray.enumerated() {
                merge(&persistableArray[index], json: jsonArray[index])
            }
        }
    }
    
    func merge(_ persistable: inout T, json: JsonDictionary) {
        let map = Map(mappingType: .fromJSON, JSON: json)
        persistable.mapping(map: map)
    }
    
}
