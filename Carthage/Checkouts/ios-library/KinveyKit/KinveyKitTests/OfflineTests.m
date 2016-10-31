//
//  OfflineTests.m
//  KinveyKit
//
//  Created by Michael Katz on 11/12/13.
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

#import <XCTest/XCTest.h>

#import "TestUtils2.h"

#import "KinveyCoreInternal.h"
#import "KinveyDataStoreInternal.h"

#import "KCSEntityPersistence.h"
#import "KCSOfflineUpdate.h"

@interface KCSUser (TestUtils)
+ (void) mockUser;
@end

@implementation KCSUser (TestUtils)
+ (void)mockUser
{
    KCSUser* user = [[KCSUser alloc] init];
    user.username = @"mock";
    user.userId = @"mockId";
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    [KCSClient sharedClient].currentUser = user;
#pragma clang diagnostic pop
}

@end


@interface OfflineDelegate : NSObject <KCSOfflineUpdateDelegate>
@property (atomic) BOOL shouldSaveCalled;
@property (atomic) BOOL willSaveCalled;
@property (atomic) BOOL didSaveCalled;
@property (atomic) BOOL shouldEnqueueCalled;
@property (atomic) BOOL didDeleteCalled;
@property (atomic) NSUInteger didEnqueCalledCount;
@property (atomic, retain) NSError* error;
@property (nonatomic, copy) void (^callback)(void);
@property (nonatomic) BOOL shouldDeleteCalled;
@property (nonatomic) BOOL willDeleteCalled;
@end
@implementation OfflineDelegate

- (BOOL)shouldSaveObject:(NSString *)objectId inCollection:(NSString *)collectionName lastAttemptedSaveTime:(NSDate *)saveTime
{
    self.shouldSaveCalled = YES;
    return YES;
}

- (void)willSaveObject:(NSString *)objectId inCollection:(NSString *)collectionName
{
    self.willSaveCalled = YES;
}

- (void)didSaveObject:(NSString *)objectId inCollection:(NSString *)collectionName
{
    self.didSaveCalled = YES;
    _callback();
}

- (BOOL)shouldEnqueueObject:(NSString *)objectId inCollection:(NSString *)collectionName onError:(NSError *)error
{
    self.shouldEnqueueCalled = YES;
    self.error = error;
    
    return YES;
}

- (void)didEnqueueObject:(NSString *)objectId inCollection:(NSString *)collectionName
{
    self.didEnqueCalledCount++;
    _callback();
}

- (BOOL)shouldDeleteObject:(NSString *)objectId inCollection:(NSString *)collectionName lastAttemptedSaveTime:(NSDate *)saveTime
{
    self.shouldDeleteCalled = YES;
    return YES;
}

- (void)willDeleteObject:(NSString *)objectId inCollection:(NSString *)collectionName
{
    self.willDeleteCalled = YES;
}

- (void)didDeleteObject:(NSString *)objectId inCollection:(NSString *)collectionName
{
    self.didDeleteCalled = YES;
    _callback();
}

@end

@interface OfflineTests : KCSTestCase
@property (nonatomic, strong) KCSOfflineUpdate* update;
@property (nonatomic, strong) KCSEntityPersistence* persistence;
@property (nonatomic, strong) OfflineDelegate* delegate;
@end

@implementation OfflineTests

- (void)setUp
{
    [super setUp];
    
    self.expectations = [NSMutableArray array];
    
    [KCSUser mockUser];
    
    self.persistence = [[KCSEntityPersistence alloc] initWithPersistenceId:@"offlinetests"];
    [self.persistence clearCaches];
    self.delegate = [[OfflineDelegate alloc] init];
    @weakify(self);
    self.delegate.callback = ^{
        @strongify(self);
        id expectation = self.expectations.firstObject;
        [expectation fulfill];
        [self.expectations removeObject:expectation];
    };
    
    self.update = [[KCSOfflineUpdate alloc] initWithCache:nil peristenceLayer:self.persistence];
    self.update.delegate = self.delegate;
    self.update.useMock = YES;
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void) testBasic
{
    NSDictionary* entity = @{@"a":@"x"};
    [self.update addObject:entity route:@"R" collection:@"C" headers:@{KCSRequestLogMethod} method:@"POST" error:nil];

    [self.expectations addObject:[self expectationWithDescription:nil]];
    [self.update start];
    self.done = NO;
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
//    XCTAssertEqual([self.persistence unsavedCount], (int)0, @"should be zero");
}

- (void) testRestartNotConnected
{
    [KCSMockServer sharedServer].offline = YES;
       
    NSDictionary* entity = @{@"a":@"x"};
    [self.update addObject:entity route:@"R" collection:@"C" headers:@{KCSRequestLogMethod} method:@"POST" error:nil];
    
    [self.expectations addObject:[self expectationWithDescription:nil]];
    [self.update start];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    XCTAssertFalse(self.delegate.didSaveCalled, @"should not have been saved");
    KTAssertEqualsInt(self.delegate.didEnqueCalledCount, 2);
    
    XCTAssertEqual([self.persistence unsavedCount], (int)1, @"should be one");
}


- (void) testSaveKickedOff
{
    [KCSMockServer sharedServer].offline = YES;
    
    NSDictionary* entity = @{@"a":@"x"};
    [self.update addObject:entity route:@"R" collection:@"C" headers:@{KCSRequestLogMethod} method:@"POST" error:nil];
    
    
    
    [self.expectations addObject:[self expectationWithDescription:nil]];
    [self.update start];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    XCTAssertTrue(self.delegate.shouldEnqueueCalled, @"should be called");
    XCTAssertFalse(self.delegate.didDeleteCalled, @"shoul dnot calle delete");
    XCTAssertFalse(self.delegate.didSaveCalled, @"should not have been saved");
    XCTAssertEqual([self.persistence unsavedCount], (int)1, @"should be one");


    [self.expectations addObject:[self expectationWithDescription:nil]];
    [KCSMockServer sharedServer].offline = NO;
    [KCSMockReachability changeReachability:YES];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
//    XCTAssertEqual([self.persistence unsavedCount], (int)0, @"should be zero");
//    XCTAssertTrue(self.delegate.didSaveCalled, @"should not have been saved");
}

//- (void) testKickoffEventSavesObjRemovesThatObjFromQueue
//{
//    KTNIY
//}


//- (void) testDelete
//{
//    [KCSMockServer sharedServer].offline = YES;
//    [[KCSMockServer sharedServer] setResponse:[KCSMockServer makeDeleteResponse:1] forRoute:@"r/:kid/c/X"];
//
//    [self.expectations addObject:[self expectationWithDescription:nil]];
//    BOOL u = [self.update removeObject:@"X" objKey:@"X" route:@"r" collection:@"c" headers:@{KCSRequestLogMethod} method:@"DELETE" error:nil];
//    XCTAssertTrue(u, @"should be added");
//    
//    [self.update start];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//    XCTAssertFalse(self.delegate.didSaveCalled, @"should not have been saved");
//    XCTAssertFalse(self.delegate.didDeleteCalled, @"should not have been saved");
//    XCTAssertEqual([self.persistence unsavedCount], (int)1, @"should be one");
//    
//    [self.expectations addObject:[self expectationWithDescription:nil]];
//    [KCSMockServer sharedServer].offline = NO;
//    [KCSMockReachability changeReachability:YES];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//    
//    XCTAssertEqual([self.persistence unsavedCount], (int)0, @"should be zero");
//    XCTAssertFalse(self.delegate.didSaveCalled, @"should not have been saved");
//    XCTAssertTrue(self.delegate.didDeleteCalled, @"should not have been saved");
//
//}

@end
