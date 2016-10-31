//
//  RemoveOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class RemoveByQueryOperation<T: Persistable>: RemoveOperation<T> where T: NSObject {
    
    override init(query: Query, writePolicy: WritePolicy, sync: Sync<T>? = nil, cache: Cache<T>? = nil, client: Client) {
        super.init(query: query, writePolicy: writePolicy, sync: sync, cache: cache, client: client)
    }
    
    override func buildRequest() -> HttpRequest {
        return client.networkRequestFactory.buildAppDataRemoveByQuery(collectionName: T.collectionName(), query: query)
    }
    
}
