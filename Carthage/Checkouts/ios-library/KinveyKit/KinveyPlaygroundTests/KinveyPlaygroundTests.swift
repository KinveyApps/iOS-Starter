//
//  KinveyPlaygroundTests.swift
//  KinveyPlaygroundTests
//
//  Created by Victor Barros on 2015-04-09.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

import UIKit
import XCTest

class KinveyPlaygroundTests: KCSTestCase {
    
    let n = 10000
    
    func testKCSKeychain2() {
        let token = NSUUID().UUIDString
        let userId = NSUUID().UUIDString
        
        KCSKeychain2.setKinveyToken(token, user: userId)
        
        let backgroundOperationQueue = NSOperationQueue()
        backgroundOperationQueue.qualityOfService = NSQualityOfService.UserInteractive
        backgroundOperationQueue.maxConcurrentOperationCount = 8
        
        for index in 1...n {
            autoreleasepool {
                let mainExpectation = expectationWithDescription("main expectation \(index)")
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        XCTAssertEqual(token, KCSKeychain2.kinveyTokenForUserId(userId))
                        
                        mainExpectation.fulfill()
                    })
                })
            }
        }
        
        for index in 1...n {
            autoreleasepool {
                let backgroundExpectation = expectationWithDescription("background expectation \(index)")
                
                backgroundOperationQueue.addOperationWithBlock { () -> Void in
                    XCTAssertEqual(token, KCSKeychain2.kinveyTokenForUserId(userId))
                    
                    backgroundExpectation.fulfill()
                }
            }
        }
        
        waitForExpectationsWithTimeout(NSTimeInterval(60 * (n / 1000)), handler: nil)
    }
    
}
