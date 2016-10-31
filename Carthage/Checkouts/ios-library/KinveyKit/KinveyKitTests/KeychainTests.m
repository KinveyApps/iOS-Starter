//
//  KeychainTests.m
//  KinveyKit
//
//  Created by Michael Katz on 12/11/13.
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

#import "KCSTestCase.h"

#import "KinveyCoreInternal.h"

@interface KeychainTests : KCSTestCase

@end

@implementation KeychainTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    [KCSKeychain2 deleteTokens];
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testBasic
{
    NSString* token = [NSString UUID];
    BOOL set = [KCSKeychain2 setKinveyToken:token user:@"macTheKnife"];
    XCTAssertTrue(set, @"should have been set");
    
    NSString* retreivedToken = [KCSKeychain2 kinveyTokenForUserId:@"macTheKnife"];
    XCTAssertEqualObjects(retreivedToken, token, @"token should match");
    
    NSString* unsetToken = [KCSKeychain2 kinveyTokenForUserId:@"bobTheSword"];
    XCTAssertNil(unsetToken, @"Should not be a token for bob");
    
    XCTAssertTrue([KCSKeychain2 hasTokens], @"");
}

- (void)testDelete
{
    NSString* token = [NSString UUID];
    BOOL set = [KCSKeychain2 setKinveyToken:token user:@"macTheKnife"];
    XCTAssertTrue(set, @"should have been set");
    
    NSString* retreivedToken = [KCSKeychain2 kinveyTokenForUserId:@"macTheKnife"];
    XCTAssertEqualObjects(retreivedToken, token, @"token should match");
    
    BOOL deleted = [KCSKeychain2 deleteTokens];
    XCTAssertTrue(deleted, @"Should be deleted");

    NSString* unsetToken = [KCSKeychain2 kinveyTokenForUserId:@"macTheKnife"];
    XCTAssertNil(unsetToken, @"Should not be a token for bob");
    
    XCTAssertFalse([KCSKeychain2 hasTokens], @"");
}

@end
