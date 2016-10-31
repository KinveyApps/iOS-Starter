//
//  RequestConfigurationTestsGlobalHttpRequestHeaders.swift
//  KinveyKit
//
//  Created by Victor Barros on 2015-08-21.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

class RequestConfigurationTestsGlobalHttpRequestHeaders: RequestConfigurationTests {
    
    private class MockURLProtocol: NSURLProtocol {
        
        override class func canInitWithRequest(request: NSURLRequest) -> Bool {
            let headers = request.allHTTPHeaderFields!
            
            XCTAssertEqual(headers["X-Kinvey-Client-App-Version"] as NSString!, "2.0")
            
            var error: NSError?
            let expectedResult = [
                "lang" : "fr",
                "globalProperty" : "abc"
                ] as Dictionary<String, String>
            let data: NSData?
            do {
                data = try NSJSONSerialization.dataWithJSONObject(KCSMutableOrderedDictionary(dictionary: expectedResult),
                                options: [])
            } catch let error1 as NSError {
                error = error1
                data = nil
            }
            XCTAssertNil(error)
            let json = NSString(data: data!, encoding: NSUTF8StringEncoding)!
            XCTAssertEqual(headers["X-Kinvey-Custom-Request-Properties"] as NSString!, json)
            
            return false
        }
        
    }
    
    func testGlobalHttpRequestHeaders() {
        let obj = [
            "_id" : "Boston",
            "name" : "Boston",
            "state" : "MA"
        ]
        weak var expectationSave = self.expectationWithDescription("save")
        
        XCTAssertTrue(KCSURLProtocol.registerClass(MockURLProtocol))
        
        self.store.saveObject(obj,
            withCompletionBlock: { (results: [AnyObject]!, error: NSError!) -> Void in
                XCTAssertNil(error)
                XCTAssertNotNil(results)
                
                if let results = results {
                    XCTAssertTrue(results.count == 1)
                    
                    if (results.count > 0) {
                        if let result = results.first as? [String : String] {
                            XCTAssertEqual(result, obj)
                        }
                    }
                }
                
                XCTAssertTrue(NSThread.isMainThread())
                
                expectationSave?.fulfill()
            },
            withProgressBlock: { (results: [AnyObject]!, percentage: Double) -> Void in
                XCTAssertTrue(NSThread.isMainThread())
            }
        )
        
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }
    
    override func tearDown() {
        KCSURLProtocol.unregisterClass(MockURLProtocol)
        
        super.tearDown()
    }
    
}
