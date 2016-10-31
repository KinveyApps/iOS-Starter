//
//  MockKinveyBackend.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-08-11.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class MockKinveyBackend: URLProtocol {
    
    static var kid = "_kid_"
    static var baseURLBaas = URL(string: "https://baas.kinvey.com")!
    static var appdata = [String : [[String : Any]]]()
    
    override class func canInit(with request: URLRequest) -> Bool {
        return request.url!.scheme == MockKinveyBackend.baseURLBaas.scheme && request.url!.host == MockKinveyBackend.baseURLBaas.host
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        if let pathComponents = request.url?.pathComponents {
            if pathComponents.count > 3 {
                if pathComponents[1] == "appdata" && pathComponents[2] == MockKinveyBackend.kid, let collection = MockKinveyBackend.appdata[pathComponents[3]] {
                    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    
                    var array: [[String : Any]]
                    if let query = request.url?.query {
                        var queryParams = [String : String]()
                        let queryComponents = query.components(separatedBy: "&")
                        for queryComponent in queryComponents {
                            let keyValuePair = queryComponent.components(separatedBy: "=")
                            queryParams[keyValuePair[0]] = keyValuePair[1]
                        }
                        if let queryParamStr = queryParams["query"]?.removingPercentEncoding,
                            let data = queryParamStr.data(using: String.Encoding.utf8),
                            let json = try? JSONSerialization.jsonObject(with: data, options: []),
                            let query = json as? [String : Any]
                        {
                            array = collection.filter({ (entity) -> Bool in
                                for keyValuePair in query {
                                    if let value = entity[keyValuePair.0] as? String,
                                        let matchValue = keyValuePair.1 as? String
                                        , value != matchValue
                                    {
                                        return false
                                    }
                                }
                                return true
                            })
                        } else {
                            array = collection
                        }
                    } else {
                        array = collection
                    }
                    let data = try! JSONSerialization.data(withJSONObject: array, options: [])
                    client?.urlProtocol(self, didLoad: data)
                    
                    client?.urlProtocolDidFinishLoading(self)
                } else {
                    reponse404()
                }
            } else {
                reponse404()
            }
        } else {
            reponse404()
        }
    }
    
    override func stopLoading() {
    }
    
    fileprivate func reponse404() {
        let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocolDidFinishLoading(self)
    }
    
}
