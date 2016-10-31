//
//  ErrorTestCase.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-05-11.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class ErrorTestCase: XCTestCase {
    
    func testObjectIDMissing() {
        XCTAssertEqual(Kinvey.Error.objectIdMissing.localizedDescription, "Object ID is required and is missing")
    }
    
    func testInvalidResponse() {
        XCTAssertEqual(Kinvey.Error.invalidResponse.localizedDescription, "Invalid response from the server")
    }
    
    func testUnauthorized() {
        XCTAssertEqual(Kinvey.Error.unauthorized(error: "Error", description: "Description").localizedDescription, "Description")
    }
    
    func testNoActiveUser() {
        XCTAssertEqual(Kinvey.Error.noActiveUser.localizedDescription, "An active user is required and none was found")
    }
    
    func testRequestCancelled() {
        XCTAssertEqual(Kinvey.Error.requestCancelled.localizedDescription, "Request was cancelled")
    }
    
    func testInvalidDataStoreType() {
        XCTAssertEqual(Kinvey.Error.invalidDataStoreType.localizedDescription, "DataStore type does not support this operation")
    }
    
    func testUserWithoutEmailOrUsername() {
        XCTAssertEqual(Kinvey.Error.userWithoutEmailOrUsername.localizedDescription, "User has no email or username")
    }
    
}
