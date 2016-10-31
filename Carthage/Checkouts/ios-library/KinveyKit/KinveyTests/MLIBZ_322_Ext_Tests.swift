//
//  MLIBZ_322_Ext_Tests.swift
//  KinveyKit
//
//  Created by Victor Barros on 2015-06-10.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

import UIKit
import XCTest

class MLIBZ_322_Ext_Tests: KCSTestCase {

    func testInvalidOperator() {
        let low = 1;
        let high = 5;
        KCSTryCatch.`try`(
            { () -> Void in
                KCSQuery(onField: "age", usingConditionalPairs: [-1234, low, KCSQueryConditional.KCSLessThan.rawValue, high])
                
                XCTAssert(false)
            }, `catch`: { (exception: NSException!) -> Void in
                XCTAssert(true)
            }, finally: nil
        )
    }
    
    func testInvalidOperatorString() {
        let low = 1;
        let high = 5;
        KCSTryCatch.`try`(
            { () -> Void in
                KCSQuery(onField: "age", usingConditionalPairs: ["-1234", low, KCSQueryConditional.KCSLessThan.rawValue, high])
                
                XCTAssert(false)
            }, `catch`: { (exception: NSException!) -> Void in
                XCTAssert(true)
            }, finally: nil
        )
    }
    
    func testInvalidArray() {
        let low = 1;
        let high = 5;
        KCSTryCatch.`try`(
            { () -> Void in
                KCSQuery(onField: "age", usingConditionalPairs: [KCSQueryConditional.KCSGreaterThan.rawValue, low, KCSQueryConditional.KCSLessThan.rawValue, high, KCSQueryConditional.KCSSize.rawValue])
                
                XCTAssert(false)
            }, `catch`: { (exception: NSException!) -> Void in
                XCTAssert(true)
            }, finally: nil
        )
    }

}
