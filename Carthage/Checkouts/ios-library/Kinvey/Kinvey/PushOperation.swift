//
//  PushOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit

internal class PushOperation<T: Persistable>: SyncOperation<T, UInt, [Swift.Error]?> where T: NSObject {
    
    internal override init(sync: Sync<T>?, cache: Cache<T>?, client: Client) {
        super.init(sync: sync, cache: cache, client: client)
    }
    
    override func execute(timeout: TimeInterval? = nil, completionHandler: CompletionHandler?) -> Request {
        let requests = OperationQueueRequest()
        requests.operationQueue.maxConcurrentOperationCount = 1
        var count = UInt(0)
        var errors: [Swift.Error] = []
        if let sync = sync {
            let executor = Executor()
            for pendingOperation in sync.pendingOperations() {
                let request = HttpRequest(request: pendingOperation.buildRequest(), timeout: timeout, client: client)
                let operation = BlockOperation {
                    let condition = NSCondition()
                    condition.lock()
                    request.execute() { data, response, error in
                        condition.lock()
                        if let response = response , response.isOK,
                            let data = data
                        {
                            let json = self.client.responseParser.parse(data)
                            var objectId: String?
                            executor.executeAndWait {
                                objectId = pendingOperation.objectId
                            }
                            if let cache = self.cache, let json = json, let objectId = objectId , request.request.httpMethod != "DELETE" {
                                if let entity = cache.findEntity(objectId) {
                                    cache.removeEntity(entity)
                                }
                                
                                let persistable = T(JSON: json)
                                if let persistable = persistable {
                                    cache.saveEntity(persistable)
                                }
                            }
                            if request.request.httpMethod != "DELETE" {
                                self.sync?.removePendingOperation(pendingOperation)
                                count += 1
                            } else if let json = json, let _count = json["count"] as? UInt {
                                self.sync?.removePendingOperation(pendingOperation)
                                count += _count
                            } else {
                                errors.append(buildError(data, response, error, self.client))
                            }
                        } else if let response = response , response.isUnauthorized,
                            let data = data,
                            let json = self.client.responseParser.parse(data) as? [String : String]
                        {
                            let error = Error.buildUnauthorized(json)
                            switch error {
                            case .unauthorized(let error, _):
                                if error == Error.InsufficientCredentials {
                                    self.sync?.removePendingOperation(pendingOperation)
                                }
                            default:
                                break
                            }
                            errors.append(error)
                        } else {
                            errors.append(buildError(data, response, error, self.client))
                        }
                        condition.signal()
                        condition.unlock()
                    }
                    condition.wait()
                    condition.unlock()
                }
                requests.operationQueue.addOperation(operation)
            }
        }
        requests.operationQueue.addOperation {
            completionHandler?(count, errors.count > 0 ? errors : nil)
        }
        return requests
    }
    
}
