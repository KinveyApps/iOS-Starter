//
//  MLIBZ_322_Tests.swift
//  KinveyKit
//
//  Created by Victor Barros on 2015-05-27.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

import UIKit
import XCTest

class MLIBZ_322_Tests: KCSTestCase {

    func testDouble() {
        // Find all entites within .5 miles of the sphere centered at [-71.05, 42.35]
        let q2 = KCSQuery(
            onField: KCSEntityKeyGeolocation,
            usingConditionalPairs: [
                KCSQueryConditional.KCSNearSphere.rawValue, [-71.05, 42.35],
                KCSQueryConditional.KCSMaxDistance.rawValue, 0.5
            ]
        )
    }
    
    func testInt() {
        // Find all entites within .5 miles of the sphere centered at [-71.05, 42.35]
        let q2 = KCSQuery(
            onField: KCSEntityKeyGeolocation,
            usingConditionalPairs: [
                KCSQueryConditional.KCSNearSphere.rawValue, [-71.05, 42.35],
                KCSQueryConditional.KCSMaxDistance.rawValue, 5
            ]
        )
    }

}
