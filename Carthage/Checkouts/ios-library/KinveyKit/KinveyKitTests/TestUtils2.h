//
//  TestUtils2.h
//  KinveyKit
//
//  Created by Michael Katz on 8/15/13.
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


#import <Foundation/Foundation.h>
#import "KCSTestCase.h"

#import "LogTester.h"
#import "KCSMockServer.h"
#import "KCSMockReachability.h"
#import "KCSRequestConfiguration.h"
#import "KCSAssert.h"

#define KTAssertNoError XCTAssertNil(error, @"Should not get an error: %@", error);

#define KTAssertNotNil(x) XCTAssertNotNil(x, @#x" should not be nil.");
#define KTAssertEqualsInt(x,y) XCTAssertEqual((int)x,(int)y, @#x" != "#y);
#define KTAssertCount(c, obj) XCTAssertNotNil(obj, @#obj" should be non-nil"); XCTAssertEqual((int)[obj count], (int)c, @"count did not match expectation");
#define KTAssertCountAtLeast(c, obj) XCTAssertTrue( [obj count] >= c, @"count (%lul) should be at least (%lul)", (unsigned long) [obj count], (unsigned long) c);
#define KTAssertLengthAtLeast(obj, c) XCTAssertTrue( [obj length] >= c, @"count (%i) should be at least (%i)", [obj length], c);
#define KTAssertEqualsDates(date1,date2) XCTAssertTrue([date1 isEqualToDate:date2], @"Dates should match.");

#define KTNIY XCTFail(@"'%s' Not Implemented Yet.", __PRETTY_FUNCTION__);


#define KTPollDone self.done = YES;
#define KTPollStart self.done = NO; XCTAssertTrue([self poll], @"polling timed out");
#define KTPollNoAssert self.done = NO; [self poll];

@protocol KCSCredentials;
id<KCSCredentials> mockCredentails();

@interface XCTestCase (TestUtils2)
@property (nonatomic) BOOL done;
@property (nonatomic, strong) NSMutableArray* expectations;

- (BOOL) poll;

- (void)setupKCS:(BOOL)initUser;

- (void)    setupKCS:(BOOL)initUser
             options:(NSDictionary*)options
requestConfiguration:(KCSRequestConfiguration*)requestConfiguration;

- (void) useMockUser;

@end

@interface TestUtils2 : NSObject

@end
