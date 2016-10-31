//
//  GetOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class GetOperation<T: Persistable>: ReadOperation<T, T, Swift.Error> where T: NSObject {
    
    let id: String
    
    init(id: String, readPolicy: ReadPolicy, cache: Cache<T>?, client: Client) {
        self.id = id
        super.init(readPolicy: readPolicy, cache: cache, client: client)
    }
    
    override func executeLocal(_ completionHandler: CompletionHandler?) -> Request {
        let request = LocalRequest()
        request.execute { () -> Void in
            let persistable = self.cache?.findEntity(self.id)
            completionHandler?(persistable, nil)
        }
        return request
    }
    
    override func executeNetwork(_ completionHandler: CompletionHandler?) -> Request {
        let request = client.networkRequestFactory.buildAppDataGetById(collectionName: T.collectionName(), id: id)
        request.execute() { data, response, error in
            if let response = response , response.isOK, let json = self.client.responseParser.parse(data) {
                let obj = T(JSON: json)
                if let obj = obj, let cache = self.cache {
                    cache.saveEntity(obj)
                }
                completionHandler?(obj, nil)
            } else {
                completionHandler?(nil, buildError(data, response, error, self.client))
            }
        }
        return request
    }
    
}
