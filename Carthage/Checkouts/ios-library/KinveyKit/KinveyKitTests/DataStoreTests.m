//
//  DataStoreTests.m
//  KinveyKit
//
//  Created by Michael Katz on 9/17/13.
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

#import "KinveyDataStoreInternal.h"
#import "TestUtils2.h"

@interface DataStoreTests : KCSTestCase
@property (nonatomic, retain) NSString* collection;
@property BOOL configRetryDisabled;
@end

@implementation DataStoreTests

- (void)setUp
{
    [super setUp];
    [self setupKCS:YES];
    //  [self useMockUser];
    
    //TODO: msg [INFO (datastore, network)] msg
    self.collection = @"DataStoreTests";
    
    self.configRetryDisabled = [[KCSClient sharedClient].options[KCS_CONFIG_RETRY_DISABLED] boolValue];
}

- (void)tearDown
{
    XCTAssertEqual([[KCSClient sharedClient].options[KCS_CONFIG_RETRY_DISABLED] boolValue], self.configRetryDisabled);
    
    [super tearDown];
}

- (void) testBasic
{
    NSString* _id = [self createEntity];
    XCTAssertNotNil(_id);
    
    __weak __block XCTestExpectation* expectationGetAll = [self expectationWithDescription:@"getAll"];
    
    KCSDataStore* store = [[KCSDataStore alloc] initWithCollection:self.collection];
    [store getAll:^(NSArray *objects, NSError *error) {
        KTAssertNoError
        XCTAssertGreaterThanOrEqual(objects.count, 1);
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationGetAll fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationGetAll = nil;
    }];
}

- (void) testBasicDisableRetry
{
    NSMutableDictionary* options = [NSMutableDictionary dictionaryWithDictionary:[KCSClient sharedClient].options];
    BOOL originalValue = [options[KCS_CONFIG_RETRY_DISABLED] boolValue];
    options[KCS_CONFIG_RETRY_DISABLED] = @YES;
    [KCSClient sharedClient].configuration.options = options.copy;
    
    XCTAssertTrue([KCSClient sharedClient].options[KCS_CONFIG_RETRY_DISABLED]);
    
    NSString* _id = [self createEntity];
    XCTAssertNotNil(_id);
    
    __weak __block XCTestExpectation* expectationGetAll = [self expectationWithDescription:@"getAll"];
    
    KCSDataStore* store = [[KCSDataStore alloc] initWithCollection:self.collection];
    [store getAll:^(NSArray *objects, NSError *error) {
        KTAssertNoError
        XCTAssertGreaterThanOrEqual(objects.count, 1);
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationGetAll fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationGetAll = nil;
        
        NSMutableDictionary* options = [NSMutableDictionary dictionaryWithDictionary:[KCSClient sharedClient].configuration.options];
        options[KCS_CONFIG_RETRY_DISABLED] = @(originalValue);
        [KCSClient sharedClient].configuration.options = options.copy;
    }];
}

- (NSString*) createEntity
{
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:[KCSCollection collectionFromString:self.collection ofClass:[NSMutableDictionary class]] options:nil];
    NSDictionary* entity = [@{@"number":@(arc4random())} mutableCopy];
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    
    __block NSString* _id = nil;
    [store saveObject:entity withCompletionBlock:^(NSArray *objectsOrNil, NSError *error) {
        KTAssertNoError;
        KTAssertCount(1, objectsOrNil);
        XCTAssertTrue([NSThread isMainThread]);
        _id = objectsOrNil[0][KCSEntityKeyId];
        
        [expectationSave fulfill];
    } withProgressBlock:nil];
    
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    XCTAssertNotNil(_id, @"should have an id");
    return _id;
}

- (NSDictionary*) getEntity:(NSString*)_id shouldExist:(BOOL)shouldExist
{
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:[KCSCollection collectionFromString:self.collection ofClass:[NSMutableDictionary class]] options:nil];
    
    __block NSDictionary* obj = nil;
    
    __weak XCTestExpectation* expectationLoad = [self expectationWithDescription:@"load"];
    
    [store loadObjectWithID:_id withCompletionBlock:^(NSArray *objectsOrNil, NSError *error) {
        if (shouldExist) {
            KTAssertNoError
            KTAssertCount(1, objectsOrNil);
            obj = objectsOrNil[0];
        } else {
            KTAssertNotNil(error);
            KTAssertEqualsInt(error.code, 404);
            XCTAssertNil(objectsOrNil, @"should have no objects");
        }
        XCTAssertTrue([NSThread isMainThread]);

        [expectationLoad fulfill];
    } withProgressBlock:nil];
    
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    return obj;
}

- (void) testDelete
{
    NSString* _id = [self createEntity];
    
    KCSDataStore* store = [[KCSDataStore alloc] initWithCollection:self.collection];
    
    __weak __block XCTestExpectation* expectationDelete = [self expectationWithDescription:@"delete"];
    
    [store deleteEntity:_id completion:^(NSUInteger count, NSError *error) {
        KTAssertNoError;
        KTAssertEqualsInt(count, 1);
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDelete fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDelete = nil;
    }];
    
    id obj = [self getEntity:_id shouldExist:NO];
    XCTAssertNil(obj, @"object should be gone");
}

- (void) testDeleteCancel
{
    NSString* _id = [self createEntity];
    
    KCSDataStore* store = [[KCSDataStore alloc] initWithCollection:self.collection];
    
    __weak __block XCTestExpectation* expectationDelete = [self expectationWithDescription:@"delete"];
    
    KCSRequest* request = [store deleteEntity:_id
                                   completion:^(NSUInteger count, NSError *error)
    {
        KTAssertNoError;
        KTAssertEqualsInt(count, 1);
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDelete fulfill];
    }];
    
    XCTAssertFalse(request.isCancelled);
    
    request.cancellationBlock = ^{
        [expectationDelete fulfill];
    };
    
    [request cancel];
    
    XCTAssertTrue(request.isCancelled);
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDelete = nil;
    }];
    
    id obj = [self getEntity:_id shouldExist:YES];
    XCTAssertNotNil(obj, @"object should be gone");
}

- (void) testDeleteByQuery
{
    NSString* _id = [self createEntity];
    
    KCSDataStore* store = [[KCSDataStore alloc] initWithCollection:self.collection];
    KCSQuery* query = [KCSQuery queryOnField:KCSEntityKeyId withExactMatchForValue:_id];
    
    __weak __block XCTestExpectation* expectationDelete = [self expectationWithDescription:@"delete"];
    
    [store deleteByQuery:[KCSQuery2 queryWithQuery1:query] completion:^(NSUInteger count, NSError *error) {
        KTAssertNoError;
        KTAssertEqualsInt(count, 1);
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDelete fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDelete = nil;
    }];
    
    id obj = [self getEntity:_id shouldExist:NO];
    XCTAssertNil(obj, @"object should be gone");
}

- (void) testDeleteByQueryCancel
{
    NSString* _id = [self createEntity];
    
    KCSDataStore* store = [[KCSDataStore alloc] initWithCollection:self.collection];
    KCSQuery* query = [KCSQuery queryOnField:KCSEntityKeyId withExactMatchForValue:_id];
    
    __weak __block XCTestExpectation* expectationDelete = [self expectationWithDescription:@"delete"];
    
    KCSRequest* request = [store deleteByQuery:[KCSQuery2 queryWithQuery1:query]
                                    completion:^(NSUInteger count, NSError *error)
    {
        KTAssertNoError;
        KTAssertEqualsInt(count, 1);
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDelete fulfill];
    }];
    
    XCTAssertFalse(request.isCancelled);
    
    request.cancellationBlock = ^{
        [expectationDelete fulfill];
    };
    
    [request cancel];
    
    XCTAssertTrue(request.isCancelled);
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDelete = nil;
    }];
    
    id obj = [self getEntity:_id shouldExist:YES];
    XCTAssertNotNil(obj, @"object should be gone");
}

@end
