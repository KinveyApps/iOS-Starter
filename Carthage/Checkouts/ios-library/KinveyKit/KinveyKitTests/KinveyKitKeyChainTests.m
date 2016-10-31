//
//  KinveyKitKeyChainTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/5/12.
//  Copyright (c) 2012-2015 Kinvey. All rights reserved.
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


#import "KinveyKitKeyChainTests.h"
#import "KinveyCoreInternal.h"


@implementation KinveyKitKeyChainTests

- (void) testToknes
{
    NSString* token = [NSString UUID];
    NSString* u1 = [NSString UUID];
    NSString* u2 = [NSString UUID];

    BOOL set = [KCSKeychain2 setKinveyToken:token user:u1];
    XCTAssertTrue(set, @"should be set");
    
    NSString* t1 = [KCSKeychain2 kinveyTokenForUserId:u1];
    NSString* t2 = [KCSKeychain2 kinveyTokenForUserId:u2];
    
    XCTAssertEqualObjects(t1, token, @"should get back original token");
    XCTAssertNil(t2, @"should get no token for u2");
    
    BOOL has = [KCSKeychain2 hasTokens];
    XCTAssertTrue(has, @"has a token");
    
    BOOL deleted = [KCSKeychain2 deleteTokens];
    XCTAssertTrue(deleted, @"should have been deleted.");

    has = [KCSKeychain2 hasTokens];
    XCTAssertFalse(has, @"should not have a token");

    t1 = [KCSKeychain2 kinveyTokenForUserId:u1];
    XCTAssertNil(t1, @"should get no token for u1");
}


@end
