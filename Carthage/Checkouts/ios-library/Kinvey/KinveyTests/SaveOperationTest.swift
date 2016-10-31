//
//  SaveOperationTest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-17.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest

class SaveOperationTest: StoreTestCase {
    
    func testForceNetwork() {
        weak var expectationSave = expectationWithDescription("Save")
        
        store.save(person, writePolicy: .ForceNetwork) { (person, error) -> Void in
            XCTAssertNotNil(person)
            XCTAssertNil(error)
            
            if let person = person {
                XCTAssertEqual(person, self.person)
                XCTAssertNotNil(person.personId)
            }
            
            expectationSave?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationSave = nil
        }
    }
    
    func testForceLocal() {
        weak var expectationSave = expectationWithDescription("Save")
        
        store.save(person, writePolicy: .ForceLocal) { (person, error) -> Void in
            XCTAssertNotNil(person)
            XCTAssertNil(error)
            
            if let person = person {
                XCTAssertEqual(person, self.person)
                XCTAssertNotNil(person.personId)
            }
            
            expectationSave?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationSave = nil
        }
    }
    
    func testLocalThenNetwork() {
        weak var expectationSaveLocal = expectationWithDescription("SaveLocal")
        weak var expectationSaveNetwork = expectationWithDescription("SaveNetwork")
        
        var isLocal = true
        
        store.save(person, writePolicy: .LocalThenNetwork) { (person, error) -> Void in
            XCTAssertNotNil(person)
            XCTAssertNil(error)
            
            if let person = person {
                XCTAssertEqual(person, self.person)
                XCTAssertNotNil(person.personId)
            }
            
            if isLocal {
                expectationSaveLocal?.fulfill()
                isLocal = false
            } else {
                expectationSaveNetwork?.fulfill()
            }
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { error in
            expectationSaveLocal = nil
            expectationSaveNetwork = nil
        }
    }
    
}
