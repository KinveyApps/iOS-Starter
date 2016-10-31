//
//  KCSPingTests.m
//  KinveyKit
//
//  Created by Michael Katz on 9/11/13.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//
// This software is licensed to you under the Kinvey terms of service located at
// http://www.kinvey.com/terms-of-use. By downloading, accessing and/or using this
// software, you hereby accept such terms of service  (and any agreement referenced
// therein) and agree that you have read, understand and agree to be bound by such
// terms of service and are of legal age to agree to such terms with Kinvey.
//
// This software contains valuable confidential and proprietary information of
// KINVEY, INC and is subject to applicable licensing agreements.
// Unauthorized reproduction, transmission or distribution of this file and its
// contents is a violation of applicable laws.
//


#import <XCTest/XCTest.h>

#import "KinveyCoreInternal.h"
#import "TestUtils2.h"

@interface KCSPingTests : KCSTestCase

@end

@implementation KCSPingTests

- (void)setUp
{
    [super setUp];
    [self setupKCS:YES];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void) testPing
{
    __weak XCTestExpectation* expectationPing = [self expectationWithDescription:@"ping"];
    [KCSPing2 pingKinveyWithBlock:^(NSDictionary *appInfo, NSError *error) {
        KTAssertNoError
        XCTAssertNotNil(appInfo, @"should be a valid value");
        NSString* version = appInfo[KCS_PING_KINVEY_VERSION];
        NSString* appname = appInfo[KCS_PING_APP_NAME];
        
        XCTAssertEqualObjects(appname, @"0 iOS Tests", @"Should be test app name");
        KTAssertLengthAtLeast(version, 1); //don't hardcode backend version
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationPing fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

@end
