//
//  TestUtils2.m
//  KinveyKit
//
//  Created by Michael Katz on 8/15/13.
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


#import "TestUtils2.h"
#import <objc/runtime.h>
#import "KinveyCoreInternal.h"

#import "KCSClient.h"

#define POLL_INTERVAL 0.05
#define MAX_POLL_COUNT 30 / POLL_INTERVAL

#define STAGING_ALPHA @"alpha"
#define STAGING_V3YK1N @"v3yk1n-kcs"

#define STAGING_API STAGING_V3YK1N


@interface MockCredentials : NSObject <KCSCredentials>

@end
@implementation MockCredentials

- (NSString *)authString
{
    return @"";
}

- (void)handleErrorResponse:(KCSNetworkResponse *)response
{
    //do nothing
}

@end

id<KCSCredentials> mockCredentails()
{
    return [[MockCredentials alloc] init];
}

@implementation XCTestCase (TestUtils2)
@dynamic done;

- (BOOL) poll
{
    int pollCount = 0;
    while (self.done == NO && pollCount < MAX_POLL_COUNT) @autoreleasepool {
        NSLog(@"polling... %4.2fs", pollCount * POLL_INTERVAL);
        NSRunLoop* loop = [NSRunLoop mainRunLoop];
        NSDate* until = [NSDate dateWithTimeIntervalSinceNow:POLL_INTERVAL];
        [loop runUntilDate:until];
        pollCount++;
    }
    return pollCount == MAX_POLL_COUNT;
}

- (BOOL)done {
    return [objc_getAssociatedObject(self, @"doneval") boolValue];
}

- (void)setDone:(BOOL)newDone {
    objc_setAssociatedObject(self, @"doneval", [NSNumber numberWithBool:newDone], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Kinvey

- (void) setupStaging
{
    (void)[[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid10005"
                                                       withAppSecret:@"8cce9613ecb7431ab580d20863a91e20"
                                                        usingOptions:@{KCS_LOG_LEVEL              : @255,
                                                                       KCS_LOG_ADDITIONAL_LOGGERS : @[[LogTester sharedInstance]]}];
    [[KCSClient sharedClient].configuration setServiceHostname:STAGING_API];
    
}
- (void) setupProduction:(BOOL)initUser
                 options:(NSDictionary*)_options
    requestConfiguration:(KCSRequestConfiguration*)requestConfiguration
{
    NSMutableDictionary *options = [NSMutableDictionary dictionaryWithDictionary:@{
        KCS_LOG_LEVEL : @255,
        KCS_LOG_ADDITIONAL_LOGGERS : @[[LogTester sharedInstance]]
    }];
    
    if (_options) {
        [options addEntriesFromDictionary:_options];
    }
    
    (void)[[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid1880"
                                                       withAppSecret:@"6414992408f04132bd467746f7ecbdcf"
                                                        usingOptions:options
                                                requestConfiguration:requestConfiguration];
    if (initUser) {
        [self useProductionUser];
    }
}

- (void)setupKCS:(BOOL)initUser
{
    [self   setupKCS:initUser
             options:nil
requestConfiguration:nil];
}

- (void)    setupKCS:(BOOL)initUser
             options:(NSDictionary*)options
requestConfiguration:(KCSRequestConfiguration*)requestConfiguration
{
    //    [self setupStaging];
    [self setupProduction:initUser
                  options:options
     requestConfiguration:requestConfiguration];
}

- (void) useMockUser
{
    KCSUser* mockUser = [[KCSUser alloc] init];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    [KCSClient sharedClient].currentUser = mockUser;
#pragma clang diagnostic pop
}

- (void) useProductionUser
{
    static NSString* username = @"Big Bob";
    static NSString* password = @"BrianWilson'sBeard";
    if ([KCSUser activeUser] == nil || [[KCSUser activeUser].username isEqualToString:username] == NO) {
        __weak XCTestExpectation* expectationLogin = [self expectationWithDescription:@"login"];
        [KCSUser loginWithUsername:username password:password withCompletionBlock:^(KCSUser *user, NSError *error, KCSUserActionResult result) {
            KTAssertNoError
            
            [expectationLogin fulfill];
        }];
        [self waitForExpectationsWithTimeout:30 handler:nil];
    }
}

@end

@implementation TestUtils2

@end
