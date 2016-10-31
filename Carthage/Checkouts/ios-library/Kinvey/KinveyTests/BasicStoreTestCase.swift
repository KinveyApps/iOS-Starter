//
//  BasicStoreTestCase.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-11.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class BasicStoreTestCase: StoreTestCase {
    
    func testSubscript() {
        let person = self.person
        let age = 30
        person["age"] = age
        XCTAssertEqual(person.age, age)
    }
    
}
