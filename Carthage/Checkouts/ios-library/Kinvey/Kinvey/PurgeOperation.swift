//
//  PurgeOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit

internal class PurgeOperation<T: Persistable>: SyncOperation<T, Int?, Swift.Error?> where T: NSObject {
    
    internal override init(sync: Sync<T>?, cache: Cache<T>?, client: Client) {
        super.init(sync: sync, cache: cache, client: client)
    }
    
    override func execute(timeout: TimeInterval? = nil, completionHandler: CompletionHandler?) -> Request {
        let requests = MultiRequest()
        var promises: [Promise<Void>] = []
        if let sync = sync {
            for pendingOperation in sync.pendingOperations() {
                var urlRequest = pendingOperation.buildRequest()
                if let timeout = timeout {
                    urlRequest.timeoutInterval = timeout
                }
                switch HttpMethod.parse(urlRequest.httpMethod ?? "GET").requestType {
                case .update:
                    if let objectId = pendingOperation.objectId {
                        promises.append(Promise<Void> { fulfill, reject in
                            let request = client.networkRequestFactory.buildAppDataGetById(collectionName: T.collectionName(), id: objectId)
                            requests.addRequest(request)
                            request.execute() { data, response, error in
                                if let response = response , response.isOK, let json = self.client.responseParser.parse(data) {
                                    if let cache = self.cache, let persistable = T(JSON: json) {
                                        cache.saveEntity(persistable)
                                    }
                                    self.sync?.removePendingOperation(pendingOperation)
                                    fulfill()
                                } else {
                                    reject(buildError(data, response, error, self.client))
                                }
                            }
                        })
                    } else {
                        sync.removePendingOperation(pendingOperation)
                    }
                case .delete:
                    promises.append(Promise<Void> { fulfill, reject in
                        sync.removePendingOperation(pendingOperation)
                        fulfill()
                    })
                case .create:
                    promises.append(Promise<Void> { fulfill, reject in
                        if let objectId = pendingOperation.objectId {
                            let query = Query(format: "\(T.entityIdProperty()) == %@", objectId)
                            cache?.removeEntitiesByQuery(query)
                        }
                        sync.removePendingOperation(pendingOperation)
                        fulfill()
                    })
                default:
                    break
                }
            }
        }
        
        when(fulfilled: promises).then { results in
            completionHandler?(results.count, nil)
        }.catch { error in
            completionHandler?(nil, error)
        }
        return requests
    }
    
}
