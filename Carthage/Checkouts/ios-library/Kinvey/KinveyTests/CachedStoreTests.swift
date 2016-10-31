////
////  CachedStoreTests.swift
////  Kinvey
////
////  Created by Victor Barros on 2015-12-15.
////  Copyright © 2015 Kinvey. All rights reserved.
////
//
//import XCTest
//@testable import Kinvey
//@testable import KinveyKit
//
//class CachedStoreTests: NetworkStoreTests {
//    
//    override func setUp() {
//        super.setUp()
//        
//        store = client.getCachedStore(Person.self, expiration: (1, .Day))
//    }
//    
//    func testExpiredObjects() {
//        save()
//        
//        NSThread.sleepForTimeInterval(1)
//        
//        weak var expectationUpdate = expectationWithDescription("Update")
//        
//        XCTAssertNotNil(client.activeUser)
//        
//        let store = client.getCachedStore(Person.self, expiration: (1, .Second))
//        store.find(Query(format: "age == %@ AND _acl.creator == %@", 29, client.activeUser!.acl!.creator)) { (persons, error) -> Void in
//            self.assertThread()
//            XCTAssertNotNil(persons)
//            XCTAssertNil(error)
//            
//            if let persons = persons {
//                XCTAssertEqual(persons.count, 0)
//            }
//            
//            expectationUpdate?.fulfill()
//        }
//        
//        waitForExpectationsWithTimeout(defaultTimeout) { error in
//            expectationUpdate = nil
//        }
//    }
//    
//}
