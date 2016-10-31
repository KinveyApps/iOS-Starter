//
//  WriteOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class WriteOperation<T: Persistable, R>: Operation<T> where T: NSObject {
    
    typealias CompletionHandler = (R, Swift.Error?) -> Void
    
    let writePolicy: WritePolicy
    let sync: Sync<T>?
    
    init(writePolicy: WritePolicy, sync: Sync<T>? = nil, cache: Cache<T>? = nil, client: Client) {
        self.writePolicy = writePolicy
        self.sync = sync
        super.init(cache: cache, client: client)
    }
    
    @discardableResult
    func execute(_ completionHandler: CompletionHandler?) -> Request {
        switch writePolicy {
        case .forceLocal:
            return executeLocal(completionHandler)
        case .localThenNetwork:
            executeLocal(completionHandler)
            fallthrough
        case .forceNetwork:
            return executeNetwork(completionHandler)
        }
    }
    
    @discardableResult
    func executeLocal(_ completionHandler: CompletionHandler?) -> Request {
        preconditionFailure("Method needs to be implemented")
    }
    
    @discardableResult
    func executeNetwork(_ completionHandler: CompletionHandler?) -> Request {
        preconditionFailure("Method needs to be implemented")
    }
    
}
