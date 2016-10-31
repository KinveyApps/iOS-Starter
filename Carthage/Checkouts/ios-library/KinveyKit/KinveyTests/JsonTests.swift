//
//  QueryTests.swift
//  KinveyKit
//
//  Created by Victor Barros on 2016-04-06.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest

class JsonTests: XCTestCase {
    
    func testPushDeviceTokens() {
        let devicetokens: NSSet = [NSUUID().UUIDString]
        let json: NSDictionary = [
            "_push" : [
                "_devicetokens" : devicetokens
            ]
        ]
        do {
            let data = try json.kcsJSONDataRepresentation()
            XCTAssertNotNil(data)
            let jsonResult = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String : [String : [String]]]
            XCTAssertNotNil(jsonResult)
            if let jsonResult = jsonResult {
                let push = jsonResult["_push"]
                XCTAssertNotNil(push)
                if let push = push {
                    let devicetokens = push["_devicetokens"]
                    XCTAssertNotNil(devicetokens)
                    if let devicetokens = devicetokens {
                        XCTAssertEqual(devicetokens.count, 1)
                    }
                }
            }
        } catch {
            XCTFail()
        }
    }
    
}
