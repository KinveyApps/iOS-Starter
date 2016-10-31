//
//  Command.swift
//  Kinvey
//
//  Created by Thomas Conner on 3/15/16.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

/// Class to interact with a custom endpoint in the backend.
@objc(KNVCustomEndpoint)
open class CustomEndpoint: NSObject {
    
    /// Completion handler block for execute custom endpoints.
    public typealias CompletionHandler = (JsonDictionary?, Swift.Error?) -> Void
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    open static func execute(_ name: String, params: JsonDictionary? = nil, client: Client = sharedClient, completionHandler: CompletionHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildCustomEndpoint(name)
        if let params = params {
            request.request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.request.httpBody = try! JSONSerialization.data(withJSONObject: params.toJson(), options: [])
        }
        request.request.setValue(nil, forHTTPHeaderField: RequestIdHeaderKey)
        request.execute() { data, response, error in
            if let completionHandler = dispatchAsyncMainQueue(completionHandler) {
                if let response = response , response.isOK, let json = client.responseParser.parse(data) {
                    completionHandler(json, nil)
                } else {
                    completionHandler(nil, buildError(data, response, error, client))
                }
            }
        }
        return request
    }
    
    //MARK: Dispatch Async Main Queue
    
    fileprivate static func dispatchAsyncMainQueue<R>(_ completionHandler: ((R?, Swift.Error?) -> Void)? = nil) -> ((JsonDictionary?, Swift.Error?) -> Void)? {
        if let completionHandler = completionHandler {
            return { (obj, error) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    completionHandler(obj as? R, error)
                })
            }
        }
        return nil
    }
}
