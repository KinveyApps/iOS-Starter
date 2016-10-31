//
//  PersistableTestCase.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-13.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class PersistableTestCase: StoreTestCase {
    
    func testAclNull() {
        store = DataStore<Person>.collection()
        
        class NullAclURLProtocol : URLProtocol {
            
            fileprivate override class func canInit(with request: URLRequest) -> Bool {
                return true
            }
            
            fileprivate override class func canonicalRequest(for request: URLRequest) -> URLRequest {
                return request
            }
            
            fileprivate override func startLoading() {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json"])!
                let json = [
                    [
                        "_id" : UUID().uuidString,
                        "name" : "Victor",
                        "age" : 29,
                        "_kmd" : [
                            "lmt" : "2016-04-13T22:29:38.868Z",
                            "ect" : "2016-04-13T22:29:38.868Z"
                        ]
                    ]
                ]
                let data = try! JSONSerialization.data(withJSONObject: json, options: [])
                
                client!.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client!.urlProtocol(self, didLoad: data)
                client!.urlProtocolDidFinishLoading(self)
            }
            
            fileprivate override func stopLoading() {
            }
            
        }
        
        setURLProtocol(NullAclURLProtocol.self)
        defer { setURLProtocol(nil) }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(readPolicy: .forceNetwork) { (results, error) in
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let results = results {
                XCTAssertEqual(results.count, 1)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testAclEmpty() {
        store = DataStore<Person>.collection()
        
        class NullAclURLProtocol : URLProtocol {
            
            fileprivate override class func canInit(with request: URLRequest) -> Bool {
                return true
            }
            
            fileprivate override class func canonicalRequest(for request: URLRequest) -> URLRequest {
                return request
            }
            
            fileprivate override func startLoading() {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json"])!
                let json = [
                    [
                        "_id" : UUID().uuidString,
                        "name" : "Victor",
                        "age" : 29,
                        "_acl" : JsonDictionary(),
                        "_kmd" : [
                            "lmt" : "2016-04-13T22:29:38.868Z",
                            "ect" : "2016-04-13T22:29:38.868Z"
                        ]
                    ]
                ]
                let data = try! JSONSerialization.data(withJSONObject: json)
                
                client!.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client!.urlProtocol(self, didLoad: data)
                client!.urlProtocolDidFinishLoading(self)
            }
            
            fileprivate override func stopLoading() {
            }
            
        }
        
        setURLProtocol(NullAclURLProtocol.self)
        defer { setURLProtocol(nil) }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(readPolicy: .forceNetwork) { (results, error) in
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let results = results {
                XCTAssertEqual(results.count, 1)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testKmdNull() {
        store = DataStore<Person>.collection()
        
        class NullAclURLProtocol : URLProtocol {
            
            fileprivate override class func canInit(with request: URLRequest) -> Bool {
                return true
            }
            
            fileprivate override class func canonicalRequest(for request: URLRequest) -> URLRequest {
                return request
            }
            
            fileprivate override func startLoading() {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json"])!
                let json = [
                    [
                        "_id" : UUID().uuidString,
                        "name" : "Victor",
                        "age" : 29,
                        "_acl" : [
                            "creator" : UUID().uuidString
                        ]
                    ]
                ]
                let data = try! JSONSerialization.data(withJSONObject: json, options: [])
                
                client!.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client!.urlProtocol(self, didLoad: data)
                client!.urlProtocolDidFinishLoading(self)
            }
            
            fileprivate override func stopLoading() {
            }
            
        }
        
        setURLProtocol(NullAclURLProtocol.self)
        defer { setURLProtocol(nil) }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(readPolicy: .forceNetwork) { (results, error) in
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let results = results {
                XCTAssertEqual(results.count, 1)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testKmdEmpty() {
        store = DataStore<Person>.collection()
        
        class NullAclURLProtocol : URLProtocol {
            
            fileprivate override class func canInit(with request: URLRequest) -> Bool {
                return true
            }
            
            fileprivate override class func canonicalRequest(for request: URLRequest) -> URLRequest {
                return request
            }
            
            fileprivate override func startLoading() {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json"])!
                let json = [
                    [
                        "_id" : UUID().uuidString,
                        "name" : "Victor",
                        "age" : 29,
                        "_acl" : [
                            "creator" : UUID().uuidString
                        ],
                        "_kmd" : JsonDictionary()
                    ]
                ]
                let data = try! JSONSerialization.data(withJSONObject: json)
                
                client!.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client!.urlProtocol(self, didLoad: data)
                client!.urlProtocolDidFinishLoading(self)
            }
            
            fileprivate override func stopLoading() {
            }
            
        }
        
        setURLProtocol(NullAclURLProtocol.self)
        defer { setURLProtocol(nil) }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(readPolicy: .forceNetwork) { (results, error) in
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let results = results {
                XCTAssertEqual(results.count, 1)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
}
