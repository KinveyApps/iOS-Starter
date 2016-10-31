//
//  KCSAssert.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-08-31.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import <XCTest/XCTest.h>

#define XCTAssertTrueWait(condition, seconds) \
{ \
    NSDate* now = [NSDate date]; \
    while (!condition && [now timeIntervalSinceNow] > -seconds); \
    XCTAssertTrue(condition); \
}
