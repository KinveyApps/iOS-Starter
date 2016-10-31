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
#import <SenTestingKit/SenTestingKit.h>
#import <KinveyKit/KinveyKit.h>

#define STAssertNoError STAssertNil(errorOrNil,@"Should not get error: %@", errorOrNil);
#define STAssertError(error, cd) STAssertNotNil(error, @"should have an error"); STAssertEquals((int)cd, (int)[error code], @"error codes should match.");

NSDictionary* wrapResponseDictionary(NSDictionary* originalResponse);

@interface SenTestCase (TestUtils)
@property (nonatomic) BOOL done;
- (BOOL) poll;
- (KCSCompletionBlock) pollBlock;
@end

@interface TestUtils : NSObject

+ (BOOL) setUpKinveyUnittestBackend;
+ (void) justInitServer;
+ (NSURL*) randomFileUrl:(NSString*)extension;

+ (KCSCollection*) randomCollection:(Class)objClass;
@end
