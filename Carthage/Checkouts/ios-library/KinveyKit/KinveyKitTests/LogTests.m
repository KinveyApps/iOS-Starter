//
//  LogTests.m
//  KinveyKit
//
//  Created by Michael Katz on 9/18/13.
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

#import "TestUtils2.h"
#import "KinveyCoreInternal.h"

@interface LogTests : KCSTestCase

@end

@implementation LogTests

- (void)testDefaultLevel
{
    KCSClientConfiguration* config = [KCSClientConfiguration configurationWithAppKey:@"A" secret:@"S"];
    int level = [config loglevel];
    KTAssertEqualsInt(level, LOG_LEVEL_FATAL);
}

- (void) testCustomLevel
{
    KCSClientConfiguration* config = [KCSClientConfiguration configurationWithAppKey:@"A" secret:@"S" options:@{KCS_LOG_LEVEL : @3}];
    int level = [config loglevel];
    KTAssertEqualsInt(level, LOG_LEVEL_NOTICE);
}

- (void) testExtraLevel
{
    KCSClientConfiguration* config = [KCSClientConfiguration configurationWithAppKey:@"A" secret:@"S" options:@{KCS_LOG_LEVEL : @30}];
    int level = [config loglevel];
    KTAssertEqualsInt(level, LOG_LEVEL_DEBUG);
    
}

//- (void) testManualVerify
//{
//    [self setupKCS:NO];
//
//    NSString* infoStr = [NSString UUID];
//    NSString* warnStr = [NSString UUID];
//    
//    
//    KCSLogInfo(KCS_LOG_CONTEXT_TEST, @"%@", infoStr);
//    KCSLogWarn(KCS_LOG_CONTEXT_TEST, @"%@", warnStr);
//    
//    LogTester* logger = [LogTester sharedInstance];
//    NSArray* logs = logger.logs;
//    XCTAssertEqualObjects(logs[0], infoStr, @"");
//    XCTAssertEqualObjects(logs[1], warnStr, @"");
//
//}

@end
