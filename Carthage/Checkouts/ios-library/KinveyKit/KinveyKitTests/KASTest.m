//
//  KASTest.m
//  KinveyKit
//
//  Created by Michael Katz on 6/18/14.
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

#import <KinveyKit/KinveyKit.h>

#import "TestUtils.h"

@interface KASTest : KCSTestCase

@end

@implementation KASTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

//- (void)testExample {
//    // This is an example of a functional test case.
//    
//    KCSClientConfiguration* config = [KCSClientConfiguration configurationWithAppKey:@"kid_eeDgeL5lAJ" secret:@"ad6e3a563f394d3ea56672764b0be936"];
//    config.serviceHostname = @"v3yk1n-kcs";
//    [[KCSClient sharedClient] initializeWithConfiguration:config];
//    [KCSClient configureLoggingWithNetworkEnabled:YES debugEnabled:YES traceEnabled:YES warningEnabled:YES errorEnabled:YES];
//    
//    XCTestExpectation* expectationLogin = [self expectationWithDescription:@"login"];
//
//    [KCSUser loginWithSocialIdentity:KCSSocialIDKinvey accessDictionary:@{@"access_token":@"abc"} withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
//        STAssertNoError
//        XCTAssertTrue([NSThread mainThread]);
//        
//        [expectationLogin fulfill];
//    }];
//    
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//}


@end
