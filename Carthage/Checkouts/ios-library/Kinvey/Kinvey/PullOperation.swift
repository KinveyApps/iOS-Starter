//
//  PullOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-08-11.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class PullOperation<T: Persistable>: FindOperation<T> where T: NSObject {
    
    override init(query: Query, deltaSet: Bool, readPolicy: ReadPolicy, cache: Cache<T>?, client: Client, resultsHandler: ResultsHandler? = nil) {
        super.init(query: query, deltaSet: deltaSet, readPolicy: readPolicy, cache: cache, client: client, resultsHandler: resultsHandler)
    }
    
    override var mustRemoveCachedRecords: Bool {
        get {
            return true
        }
    }
    
}
