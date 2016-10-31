//
//  KCSClientConfigurationTests.m
//  KinveyKit
//
//  Created by Michael Katz on 8/22/13.
//
//  Copyright (c) 2013-2015 Kinvey. All rights reserved.
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


#import "KCSTestCase.h"

#import "KCSClientConfiguration.h"
#import "KCSClient.h"
#import "KinveyUser.h"
#import "KCSHiddenMethods.h"
#import "NSString+KinveyAdditions.h"

@interface KCSClientConfigurationTests : KCSTestCase

@end

@implementation KCSClientConfigurationTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

// Still need tests for push and initializing via plist

//- (void) testEnvironmentVariable
//{
//    //Tests that we get a configuration from environment in hidden cases
//    NSString* appKey = [[[NSProcessInfo processInfo] environment] objectForKey:@"KCS_APP_KEY"];
//    XCTAssertEqualObjects(appKey, @"TEST_KEY", @"test keys should match");
//    NSString* appSecret = [[[NSProcessInfo processInfo] environment] objectForKey:@"KCS_APP_SECRET"];
//    XCTAssertEqualObjects(appSecret, @"TEST_SECRET", @"test keys should match");
//    NSString* appHost = [[[NSProcessInfo processInfo] environment] objectForKey:@"KCS_SERVICE_HOST"];
//    XCTAssertEqualObjects(appHost, @"TEST_HOST", @"test keys should match");
//    
//    KCSClientConfiguration* config = [KCSClientConfiguration configurationWithAppKey:@"<#KEY#>" secret:@"<#SECRET#>"];
//    XCTAssertEqualObjects(config.appKey, @"TEST_KEY", @"test keys should match");
//    XCTAssertEqualObjects(config.appSecret, @"TEST_SECRET", @"test keys should match");
//    XCTAssertEqualObjects(config.serviceHostname, @"TEST_HOST", @"test keys should match");
//}

- (void) testPlist
{
    KCSClientConfiguration* config = [KCSClientConfiguration configurationFromPlist:@"TestConfig"];
    XCTAssertNotNil(config, @"should have valid config");

    KCSClient* client = [KCSClient sharedClient];
    [client initializeWithConfiguration:config];
    XCTAssertEqualObjects(config.options, client.options, @"Equals Objects");
    
    XCTAssertEqualObjects(config.options[@"NOT USED"], @"FOO", @"Crazy string");
    XCTAssertEqualObjects(config.appSecret, @"TEST_SECRET", @"Crazy string");
    XCTAssertEqualObjects(config.appKey, @"TEST_KEY", @"Crazy string");
}


- (void) testThrowsIfNoSecretOrKey
{
    KCSClientConfiguration* badConfig = [KCSClientConfiguration new];
    XCTAssertThrows([[KCSClient sharedClient] initializeWithConfiguration:badConfig], @"throws");
}

- (void) setUser
{
    KCSUser* u = [[KCSUser alloc] init];
    u.userId = [NSString UUID];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    [KCSClient sharedClient].currentUser = u;
#pragma clang diagnostic pop
    XCTAssertNotNil([KCSUser  activeUser], @"should have a user");
}

- (void) testKeyChangesClearsUser
{
    KCSClientConfiguration* c1 = [KCSClientConfiguration configurationWithAppKey:@"1" secret:@"1"];
    [[KCSClient sharedClient] initializeWithConfiguration:c1];
    
    NSString* ak1 = [[KCSAppdataStore caches] cachedAppKey];
    XCTAssertNotNil(ak1, @"should have a key");
    
    [self setUser];
    
    KCSClientConfiguration* c2 = [KCSClientConfiguration configurationWithAppKey:@"2" secret:@"2"];
    [[KCSClient sharedClient] initializeWithConfiguration:c2];
    
    NSString* ak2 = [[KCSAppdataStore caches] cachedAppKey];
    XCTAssertNotNil(ak2, @"should have a key");
    XCTAssertFalse([ak1 isEqualToString:ak2], @"should change");
    
    XCTAssertNil([KCSUser  activeUser], @"user should be cleared");
}

@end
