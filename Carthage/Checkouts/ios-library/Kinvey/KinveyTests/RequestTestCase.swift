//
//  RequestTestCase.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class RequestTestCase: KinveyTestCase {
    
    override func setUp() {
        super.setUp()
        
        signUp()
    }
    
    func testCancelGetUser() {
        XCTAssertNotNil(client.activeUser)
        
        if let activeUser = client.activeUser {
            let request = HttpRequest(endpoint: Endpoint.UserById(client: client, userId: activeUser.userId))
            request.execute()
            XCTAssertFalse(request.cancelled)
            request.cancel()
            NSThread.sleepForTimeInterval(3)
            XCTAssertTrue(request.cancelled)
        }
    }
    
    func testProgressDownloadFile() {
        XCTAssertNotNil(client.activeUser)
        
        if let activeUser = client.activeUser {
            weak var expectationFileCreate = expectationWithDescription("FileCreate")
            
            var json: [String : AnyObject]?
            
            let request = HttpRequest(httpMethod: .Post, endpoint: Endpoint.BlobUpload(client: client, fileId: nil, tls: true), credential: activeUser)
            request.request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(["_public" : true], options: [])
            request.execute() { (data, response, error) in
                XCTAssertNil(error)
                XCTAssertNotNil(response)
                if let response = response {
                    XCTAssertTrue(response.isResponseOK)
                }
                XCTAssertNotNil(data)
                
                if let data = data {
                    json = try! NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String : AnyObject]
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    expectationFileCreate?.fulfill()
                }
            }
            
            waitForExpectationsWithTimeout(defaultTimeout) { error in
                expectationFileCreate = nil
            }
            
            if let json = json, let uploadUrl = json["_uploadURL"] as? String {
                weak var expectationFileUpload = expectationWithDescription("FileUpload")
                
                let url = NSURL(string: uploadUrl)!
                let request = HttpRequest(httpMethod: .Put, endpoint: Endpoint.URL(url: url))
                if let requiredHeaders = json["_requiredHeaders"] as? [String : String] {
                    for header in requiredHeaders {
                        request.request.addValue(header.1, forHTTPHeaderField: header.0)
                    }
                }
                
                let bundle = NSBundle(forClass: self.dynamicType)
                let image = UIImage(named: "Kinvey Logo", inBundle: bundle, compatibleWithTraitCollection: nil)!
                let data = UIImagePNGRepresentation(image)
                request.request.HTTPBody = data
                
                request.execute() { (data, response, error) in
                    XCTAssertNil(error)
                    XCTAssertNotNil(response)
                    if let response = response {
                        XCTAssertTrue(response.isResponseOK)
                    }
                    XCTAssertNotNil(data)
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        expectationFileUpload?.fulfill()
                    }
                }
                
                waitForExpectationsWithTimeout(defaultTimeout) { error in
                    expectationFileUpload = nil
                }
            }
        }
    }
    
}
