//
//  KinveyKitClientTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 12/15/11.
//  Copyright (c) 2011-2015 Kinvey. All rights reserved.
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


#import "KinveyKitClientTests.h"
#import "KCSClient.h"
#import "KinveyCollection.h"
#import "KCSHiddenMethods.h"

@implementation KinveyKitClientTests

- (void) testNilAppKeyRaisesException
{
    XCTAssertThrows((void) [[KCSClient sharedClient] initializeKinveyServiceForAppKey:nil withAppSecret:@"text" usingOptions:nil],
                   @"nil AppKey Did Not raise exception!");
}

- (void) testNilAppSecretRaisesException
{
    XCTAssertThrows((void) [[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid6969" withAppSecret:nil usingOptions:nil],
                   @"nil AppSecret did not raise exception!");
}


- (void)testUserAgentStringIsMeaningful
{
    KCSClient *client = [KCSClient sharedClient];
    XCTAssertTrue([client.userAgent hasPrefix:@"ios-kinvey-http/"], @"should be meaningful string: %@", client.userAgent);
    NSString* suffix = [NSString stringWithFormat:@"kcs/%@", MINIMUM_KCS_VERSION_SUPPORTED];
    XCTAssertTrue([client.userAgent hasSuffix:suffix], @"should be meaningful string: %@", client.userAgent);
}

- (void)testAppdataBaseURL
{
    NSString *kidID = @"kid6969";
    NSString *urlString = [NSString stringWithFormat:
                           @"https://baas.kinvey.com/appdata/%@/",
                           kidID];
    
    (void) [[KCSClient sharedClient] initializeKinveyServiceForAppKey:kidID
                                                 withAppSecret:@"secret"
                                                  usingOptions:nil];
    
    XCTAssertEqualObjects([[KCSClient sharedClient] appdataBaseURL], urlString, @"should match");
}

- (void)testResourceBaseURL
{
    NSString *kidID = @"kid6969";
    NSString *urlString = [NSString stringWithFormat:
                           @"https://baas.kinvey.com/blob/%@/",
                           kidID];
    
    (void) [[KCSClient sharedClient] initializeKinveyServiceForAppKey:kidID
                                                 withAppSecret:@"secret"
                                                  usingOptions:nil];
    
    XCTAssertEqualObjects([[KCSClient sharedClient] resourceBaseURL], urlString, @"should match");
}

- (void)testUserBaseURL
{
    NSString *kidID = @"kid6969";
    NSString *urlString = [NSString stringWithFormat:
                           @"https://baas.kinvey.com/user/%@/",
                           kidID];
    
    (void) [[KCSClient sharedClient] initializeKinveyServiceForAppKey:kidID
                                                 withAppSecret:@"secret"
                                                  usingOptions:nil];
    
    
    XCTAssertEqualObjects([[KCSClient sharedClient] userBaseURL], urlString, @"should match");
}

- (void)testBaseURLIsValid
{
    (void) [[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid6969"
                                                 withAppSecret:@"secret"
                                                  usingOptions:nil];
    
    NSURL *baseURL = [NSURL URLWithString:[[KCSClient sharedClient] appdataBaseURL]];
    XCTAssertNotNil(baseURL, @"url should not be nil");
}

- (void)testURLOverrideWorks
{
    NSString *newHost = @"latestbeta";
    
    NSString *kidID = @"kid6969";
    NSString *urlString = [NSString stringWithFormat:
                           @"https://baas.kinvey.com/user/%@/",
                           kidID];
    
    (void) [[KCSClient sharedClient] initializeKinveyServiceForAppKey:kidID
                                                 withAppSecret:@"secret"
                                                  usingOptions:nil];

    // Make sure starting value is good
    XCTAssertEqualObjects([[KCSClient sharedClient] userBaseURL], urlString, @"should match");
    
    [[KCSClient sharedClient].configuration setServiceHostname:newHost];

    NSString* testStr = [NSString stringWithFormat:@"https://%@.kinvey.com/appdata/%@/", newHost, kidID];
    XCTAssertEqualObjects([[KCSClient sharedClient] appdataBaseURL], testStr, @"should match");
    testStr = [NSString stringWithFormat:@"https://%@.kinvey.com/blob/%@/", newHost, kidID];
    XCTAssertEqualObjects([[KCSClient sharedClient] resourceBaseURL], testStr, @"should match");
    testStr = [NSString stringWithFormat:@"https://%@.kinvey.com/user/%@/", newHost, kidID];
    XCTAssertEqualObjects([[KCSClient sharedClient] userBaseURL], testStr, @"should match");
}

- (void)testThatInitializeWithKeyAndSecretRejectsInvalidInput
{
    XCTAssertThrows((void) [[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"<app key>"
                                                 withAppSecret:@"secret"
                                                  usingOptions:nil],
                   @"Malformed input DID NOT raise exception!");
}

- (void)testSingletonIsSingleton
{
    KCSClient *client1 = [[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid6969"
                                                                      withAppSecret:@"secret"
                                                                       usingOptions:nil];
    KCSClient *client2 = [KCSClient sharedClient];
    XCTAssertEqual(client1, client2, @"should be same instance");
}


@end
