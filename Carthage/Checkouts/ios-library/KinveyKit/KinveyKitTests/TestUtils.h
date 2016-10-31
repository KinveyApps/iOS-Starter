//
//  TestUtils.h
//  KinveyKit
//
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


#import <Foundation/Foundation.h>
#import "KCSTestCase.h"
#import <KinveyKit/KinveyKit.h>
#import "KCSAssert.h"

#define STAssertNoError XCTAssertNil(errorOrNil,@"Should not get error: %@", errorOrNil);
#define STAssertNoError_ XCTAssertNil(error, @"Should not get error: %@", error);
#define STAssertError(error, cd) XCTAssertNotNil(error, @"should have an error"); XCTAssertEqual((int)cd, (int)[error code], @"error codes should match.");
#define STAssertObjects(cnt) XCTAssertNotNil(objectsOrNil,@"should get non-nil return objects"); \
                               XCTAssertEqual((int)[objectsOrNil count], (int)cnt, @"Expecting %i items", cnt);

#define KTAssertEqualsInt(x,y, desc) XCTAssertEqual((int)x,(int)y, desc)
#define KTAssertCount(c, obj) XCTAssertNotNil(obj, @"obj should be non-nil"); XCTAssertEqual((int)[obj count], (int)c, @"count did not match expectation")
#define KTAssertCountAtLeast(c, obj) XCTAssertTrue( [obj count] >= c, @"count (%@) should be at least (%@)", @(obj.count), @(c));
#define KTAssertEqualsDates(date1,date2) XCTAssertTrue([date1 isEqualToDate:date2], @"Dates should match.");

NSDictionary* wrapResponseDictionary(NSDictionary* originalResponse);

@interface XCTestCase (TestUtils)
@property (nonatomic) BOOL done;
@property (nonatomic, strong) NSMutableArray* expectations;
- (BOOL) poll;
- (BOOL) poll:(NSTimeInterval)timeout;
- (KCSCompletionBlock) pollBlock;
- (KCSCountBlock) pollBlockCount;
- (void) useMockUser;
@end


@interface TestUtils : NSObject

+ (BOOL) setUpKinveyUnittestBackend:(XCTestCase*)testCase;
+ (void) justInitServer;
+ (NSURL*) randomFileUrl:(NSString*)extension;

+ (KCSCollection*) randomCollection:(Class)objClass;
@end
