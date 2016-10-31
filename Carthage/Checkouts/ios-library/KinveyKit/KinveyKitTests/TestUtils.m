//
//  TestUtils.m
//  KinveyKit
//
//  Created by Michael Katz on 6/5/12.
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


#import "TestUtils.h"
#import <KinveyKit/KinveyKit.h>
#import <XCTest/XCTest.h>
#import <objc/runtime.h>

#import "KCSHiddenMethods.h"
#import "NSString+KinveyAdditions.h"


#define STAGING_ALPHA @"alpha"
#define STAGING_V3YK1N @"v3yk1n-kcs"

#define STAGING_API STAGING_V3YK1N


NSDictionary* wrapResponseDictionary(NSDictionary* originalResponse)
{
    return [NSDictionary dictionaryWithObjectsAndKeys:originalResponse, @"result", nil];
}


@implementation XCTestCase (TestUtils)
@dynamic done;
@dynamic expectations;
#define POLL_INTERVAL 0.05
#define MAX_POLL_SECONDS 30

- (BOOL) poll
{
    return [self poll:MAX_POLL_SECONDS];
}

- (BOOL) poll:(NSTimeInterval)timeout
{
    int pollCount = 0;
    int maxPollCount = timeout / POLL_INTERVAL;
    while (self.done == NO && pollCount < maxPollCount) {
        NSLog(@"polling... %3.2f", pollCount * POLL_INTERVAL);
        NSRunLoop* loop = [NSRunLoop mainRunLoop];
        NSDate* until = [NSDate dateWithTimeIntervalSinceNow:POLL_INTERVAL];
        [loop runUntilDate:until];
        pollCount++;
    }
    if (pollCount == maxPollCount) {
        XCTFail(@"polling timed out");
    }
    return YES;
}

- (BOOL)done {
    return [objc_getAssociatedObject(self, @"doneval") boolValue];
}

- (void)setDone:(BOOL)newDone {
    objc_setAssociatedObject(self, @"doneval", [NSNumber numberWithBool:newDone], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSMutableArray *)expectations
{
    return objc_getAssociatedObject(self, @"expectationsval");
}

-(void)setExpectations:(NSMutableArray *)expectations
{
    objc_setAssociatedObject(self, @"expectationsval", expectations, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (KCSCompletionBlock) pollBlock
{
    self.done = NO;
    return [^(NSArray *objectsOrNil, NSError *errorOrNil) {
        if (errorOrNil != nil) {
            XCTFail(@"%@", errorOrNil);
        }
        self.done = YES;
    } copy];
}

- (KCSCountBlock) pollBlockCount
{
    self.done = NO;
    return [^(NSUInteger count, NSError *errorOrNil) {
        if (errorOrNil != nil) {
            XCTFail(@"%@", errorOrNil);
        }
        self.done = YES;
    } copy];
}

- (void) useMockUser
{
    KCSUser* mockUser = [[KCSUser alloc] init];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    [KCSClient sharedClient].currentUser = mockUser;
#pragma clang diagnostic pop
}


@end

//@implementation XCTestCase (TestUtils)
//@dynamic done;
//
//- (void) poll
//{
//    int pollCount = 0;
//    while (self.done == NO && pollCount < MAX_POLL_COUNT) {
//        NSLog(@"polling... %i", pollCount);
//        NSRunLoop* loop = [NSRunLoop mainRunLoop];
//        NSDate* until = [NSDate dateWithTimeIntervalSinceNow:POLL_INTERVAL];
//        [loop runUntilDate:until];
//        pollCount++;
//    }
//    if (pollCount == MAX_POLL_COUNT) {
//        STFail(@"polling timed out");
//    }
//}
//
//- (BOOL)done {
//    return [objc_getAssociatedObject(self, @"doneval") boolValue];
//}
//
//- (void)setDone:(BOOL)newDone {
//    objc_setAssociatedObject(self, @"doneval", [NSNumber numberWithBool:newDone], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//}
//
//- (KCSCompletionBlock) pollBlock
//{
//    self.done = NO;
//    return [^(NSArray *objectsOrNil, NSError *errorOrNil) {
//        if (errorOrNil != nil) {
//            STFail(@"%@", errorOrNil);
//        }
//        self.done = YES;
//    } copy];
//}
//
//
//
//@end


#define KCS_APP_SECRET @"KCS_APP_SECRET"
#define KCS_APP_KEY @"KCS_APP_KEY"
#define KCS_API @"KCS_API"

@implementation TestUtils

+ (void) initKinvey:(NSDictionary*)opts
{
    NSString* path = [[NSBundle bundleForClass:[self class]] pathForResource:@"config" ofType:@"plist"];
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:path];

    [[KCSClient sharedClient] initializeKinveyServiceForAppKey: config[KCS_APP_KEY]
                                                 withAppSecret: config[KCS_APP_SECRET]
                                                  usingOptions: opts];

    [[KCSClient sharedClient].configuration setServiceHostname: config[KCS_API]];

}

//+ (void) initCustom:(NSDictionary*)opts
//{
////    (void)[[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid_TT1n4clp2M" withAppSecret:@"4ffcb1c73a0847f28d54ff75225a3944" usingOptions:opts];
////    [[KCSClient sharedClient] setKinveyDomain:@"168.1.18"];
////    [[KCSClient sharedClient] setProtocol:@"http" ];
////    [[KCSClient sharedClient] setPort:@":7007"];
////    [[KCSClient sharedClient].configuration setServiceHostname:@"192"];
//}


//+ (void) initStaging:(NSDictionary*)opts
//{
//    [[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid_-1WAs8Rh2"
//                                                 withAppSecret:@"2f355bfaa8cb4f7299e914e8e85d8c98"
//                                                  usingOptions:opts];
////    [[KCSClient sharedClient].configuration setServiceHostname:STAGING_API];
//    
//}
//
//+ (void) initProduction:(NSDictionary*)opts
//{
//    (void)[[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid1880" withAppSecret:@"6414992408f04132bd467746f7ecbdcf" usingOptions:opts];
//}

+ (void) justInitServer
{
    NSDictionary* opts = @{KCS_TWITTER_CLIENT_SECRET : @"rLUxyvve0neLqO8P8pWY6S8fOToXtL7qcNzxNMaUSA",
                           KCS_TWITTER_CLIENT_KEY : @"5sCifD1tKCjA6zQD5jE6A",
                           KCS_FACEBOOK_APP_KEY: @"432021153527854"};
//    if (/* DISABLES CODE */ (1)) {
//        [self initStaging:opts];
//    } else {
//        [self initProduction:opts];
//    }
    [self initKinvey:opts];
    
    [KCSClient configureLoggingWithNetworkEnabled:YES debugEnabled:YES traceEnabled:YES warningEnabled:YES errorEnabled:YES];
//    [self initCustom:opts];
}

#define KCS_XCTAssertTrue(testCase, expression, ...) \
_XCTPrimitiveAssertTrue(testCase, expression, @#expression, __VA_ARGS__)

+ (BOOL) setUpKinveyUnittestBackend:(XCTestCase*)testCase
{
    [self justInitServer];
    [KCSClient configureLoggingWithNetworkEnabled:YES debugEnabled:YES traceEnabled:YES warningEnabled:YES errorEnabled:YES];
    __block BOOL loaded = NO;
    
    [[KCSUser activeUser] logout];
    //    NSAssert([KCSUser hasSavedCredentials] == NO, @"should have cleared creds");

    __weak __block XCTestExpectation* expectationCreateAutogeneratedUser = [testCase expectationWithDescription:@"createAutogeneratedUser"];
    [KCSUser createAutogeneratedUser:nil completion:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
        KCS_XCTAssertTrue(testCase, errorOrNil == nil, @"should have no errors");
        KCS_XCTAssertTrue(testCase, user.deviceTokens.count == 0, @"should start fresh");

        [expectationCreateAutogeneratedUser fulfill];
    }];
    [testCase waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationCreateAutogeneratedUser = nil;
    }];
    
    __weak __block XCTestExpectation* expectationPingKinvey = [testCase expectationWithDescription:@"pingKinvey"];
    [KCSPing pingKinveyWithBlock:^(KCSPingResult *result) {
        loaded = result.pingWasSuccessful;
        if (!loaded) {
            NSLog(@"ping error: %@", result.description);
        }
        
        [expectationPingKinvey fulfill];
    }];
    [testCase waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationPingKinvey = nil;
    }];
    
    
    loaded = loaded && [KCSUser activeUser] != nil;
    
    return loaded;
}

+ (NSString*) uuid
{
    return [NSString UUID];
}

+ (NSURL*) randomFileUrl:(NSString*)extension
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* basePath = ([paths count] > 0) ? paths[0] : nil;
    NSString* path = [basePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",[self uuid], extension]];
    return [NSURL fileURLWithPath:path];
}

+ (KCSCollection*) randomCollection:(Class)objClass
{
    KCSCollection* collection = [[KCSCollection alloc] init];
    collection.collectionName = [NSString stringWithFormat:@"testObjects%i", arc4random()];
    collection.objectTemplate = objClass;
    return collection;
}

@end
