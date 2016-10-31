//
//  CustomEndpointTests.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-30.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class CustomEndpointTests: KinveyTestCase {
    
    func testCustomEndpoint() {
        signUp()
        
        let params: [String : Any] = [
            "stringParam" : "Test",
            "numberParam" : 1,
            "booleanParam" : true,
            "queryParam" : Query(format: "age >= %@", 21)
        ]
        
        weak var expectationCustomEndpoint = expectation(description: "Custom Endpoint")
        
        CustomEndpoint.execute("echo", params: params) { response, error in
            XCTAssertNotNil(response)
            XCTAssertNil(error)
            
            if let response = response {
                XCTAssertEqual(response.count, 4)
                
                XCTAssertEqual(response["stringParam"] as? String, "Test")
                XCTAssertEqual(response["numberParam"] as? Int, 1)
                XCTAssertEqual(response["booleanParam"] as? Bool, true)
                
                XCTAssertNotNil(response["queryParam"] as? JsonDictionary)
                if let queryParam = response["queryParam"] as? JsonDictionary {
                    XCTAssertNotNil(queryParam["age"] as? JsonDictionary)
                    if let age = queryParam["age"] as? JsonDictionary {
                        XCTAssertNotNil(age["$gte"] as? Int)
                        if let age = age["$gte"] as? Int {
                            XCTAssertEqual(age, 21)
                        }
                    }
                }
            }
            
            expectationCustomEndpoint?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCustomEndpoint = nil
        }
    }
    
    func testQueryCount() {
        signUp()
        
        let params = [
            "query" : Query(format: "colors.@count == %@", 2)
        ]
        
        weak var expectationCustomEndpoint = expectation(description: "Custom Endpoint")
        
        CustomEndpoint.execute("echo", params: params) { response, error in
            XCTAssertNotNil(response)
            XCTAssertNil(error)
            
            if let response = response {
                XCTAssertEqual(response.count, 1)
                
                XCTAssertNotNil(response["query"] as? JsonDictionary)
                if let query = response["query"] as? JsonDictionary {
                    XCTAssertNotNil(query["colors"] as? JsonDictionary)
                    if let colors = query["colors"] as? JsonDictionary {
                        XCTAssertNotNil(colors["$size"] as? Int)
                        if let size = colors["size"] as? Int {
                            XCTAssertEqual(size, 2)
                        }
                    }
                }
            }
            
            expectationCustomEndpoint?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCustomEndpoint = nil
        }
    }
    
    func testNestedDictionary() {
        signUp()
        
        let params = [
            "query" : [
                "query" : Query(format: "colors.@count == %@", 2)
            ]
        ]
        
        weak var expectationCustomEndpoint = expectation(description: "Custom Endpoint")
        
        CustomEndpoint.execute("echo", params: params) { response, error in
            XCTAssertNotNil(response)
            XCTAssertNil(error)
            
            if let response = response {
                XCTAssertEqual(response.count, 1)
                
                XCTAssertNotNil(response["query"] as? JsonDictionary)
                if let query = response["query"] as? JsonDictionary {
                    XCTAssertNotNil(query["query"] as? JsonDictionary)
                    if let query = query["query"] as? JsonDictionary {
                        XCTAssertNotNil(query["colors"] as? JsonDictionary)
                        if let colors = query["colors"] as? JsonDictionary {
                            XCTAssertNotNil(colors["$size"] as? Int)
                            if let size = colors["size"] as? Int {
                                XCTAssertEqual(size, 2)
                            }
                        }
                    }
                }
            }
            
            expectationCustomEndpoint?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCustomEndpoint = nil
        }
    }
    
    func testNestedArray() {
        signUp()
        
        let params = [
            "queries" : [
                Query(format: "colors.@count == %@", 2),
                Query(format: "colors.@count == %@", 5)
            ]
        ]
        
        weak var expectationCustomEndpoint = expectation(description: "Custom Endpoint")
        
        CustomEndpoint.execute("echo", params: params) { response, error in
            XCTAssertNotNil(response)
            XCTAssertNil(error)
            
            if let response = response {
                XCTAssertEqual(response.count, 1)
                
                XCTAssertNotNil(response["queries"] as? [JsonDictionary])
                if let queries = response["queries"] as? [JsonDictionary] {
                    XCTAssertEqual(queries.count, 2)
                    
                    if queries.count > 1 {
                        XCTAssertNotNil(queries[0]["colors"] as? JsonDictionary)
                        if let colors = queries[0]["colors"] as? JsonDictionary {
                            XCTAssertNotNil(colors["$size"] as? Int)
                            if let size = colors["size"] as? Int {
                                XCTAssertEqual(size, 2)
                            }
                        }
                        XCTAssertNotNil(queries[1]["colors"] as? JsonDictionary)
                        if let colors = queries[1]["colors"] as? JsonDictionary {
                            XCTAssertNotNil(colors["$size"] as? Int)
                            if let size = colors["size"] as? Int {
                                XCTAssertEqual(size, 5)
                            }
                        }
                    }
                }
            }
            
            expectationCustomEndpoint?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationCustomEndpoint = nil
        }
    }
    
}
