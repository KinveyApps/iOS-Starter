//
//  KCSCachedStoreTests.m
//  KinveyKit
//
//  Created by Michael Katz on 5/10/12.
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


#import "KCSCachedStoreTests.h"
#import "KCSCachedStore.h"
#import "KCSEntityDict.h"

#import "KinveyKit.h"

#import "TestUtils.h"
#import "KCSHiddenMethods.h"
#import "NSString+KinveyAdditions.h"
#import "KCSHttpRequest.h"
#import "KCS_DDLog.h"

@interface TestEntity : NSObject
@property (nonatomic, retain) NSString* key;
@property (nonatomic, retain) NSString* objId;

@end
@implementation TestEntity
@synthesize key;

- (NSDictionary *)hostToKinveyPropertyMapping
{
    return @{@"key" : @"key" , @"objId" : KCSEntityKeyId};
}
@end

@interface KCSCachedStoreTests ()
@property (nonatomic, retain) NSMutableArray* requestArray;
@property (nonatomic) NSUInteger callbackCount;
@end

@implementation KCSCachedStoreTests

static float pollTime;

- (BOOL) queryServer:(id<KCSStore>) store
{
    if (store == nil) {
        return false;
    }

    id query = [KCSQuery query];
 
    NSUInteger previouscount = self.requestArray.count;
    __block NSUInteger newcount = 0;
    
    __weak __block XCTestExpectation* expectationQueryServer = [self expectationWithDescription:@"queryServer"];
    
    [store queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        XCTAssertTrue([NSThread isMainThread]);
        
        NSLog(@"completion block: %@", query);
        _callbackCount++;
        newcount = self.requestArray.count;
        
        [expectationQueryServer fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
        
        NSLog(@"progress block");
        //DO nothing on progress
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationQueryServer = nil;
    }];
    
    NSLog(@"done");
    return newcount > previouscount;
}

- (id<KCSStore>) createStore:(KCSCachePolicy)cachePolicy
{
    NSString* clnName = [NSString stringWithFormat:@"KCSCachedStoreTestsCollection"];
    KCSCollection* collection = [KCSCollection collectionFromString:clnName ofClass:[TestEntity class]];
    KCSCachedStore* store = [KCSCachedStore storeWithOptions:@{KCSStoreKeyResource : collection, KCSStoreKeyCachePolicy: @(cachePolicy)}];
    
    TestEntity* t1 = [[TestEntity alloc] init];
    t1.key = [NSString UUID];
    
    TestEntity* t2 = [[TestEntity alloc] init];
    t2.key = [NSString UUID];
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    
    [store saveObject:@[t1,t2] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    return store;
}


- (void) setUp
{
    [super setUp];
    
    NSLog(@"%@ %@", [UIDevice currentDevice].model, [UIDevice currentDevice].systemVersion);
    
    pollTime = 0.1;
    _callbackCount = 0;
    
    [TestUtils setUpKinveyUnittestBackend:self];
//    KCSUser* mockUser = [[KCSUser alloc] init];
//    mockUser.userId = [NSString UUID];
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wdeprecated"
//    [KCSClient sharedClient].currentUser = mockUser;
//#pragma clang diagnostic pop
    
    self.requestArray = [NSMutableArray array];
    [KCSHttpRequest setRequestArray:self.requestArray];
}

- (void) tearDown
{
    [[KCSUser activeUser] logout];
    
    [super tearDown];
}

- (void) testCachedStoreNoCache
{
    pollTime = 2.;
    
    id<KCSStore> store = [self createStore:KCSCachePolicyNone];
    XCTAssertNotNil(store, @"must make a store");
    
    XCTAssertTrue([self queryServer:store], @"expecting to call server");
    XCTAssertTrue([self queryServer:store], @"expecting to call server");
    XCTAssertTrue([self queryServer:store], @"expecting to call server");    
}

- (void) testCachedStoreLocalCache
{
    id<KCSStore> store = [self createStore:KCSCachePolicyLocalOnly];
    XCTAssertNotNil(store, @"must make a store");
    
    XCTAssertFalse([self queryServer:store], @"expecting to use cache, not server");
    XCTAssertFalse([self queryServer:store], @"expecting to use cache, not server");
    XCTAssertFalse([self queryServer:store], @"expecting to use cache, call server");    
}

#define POLL_INTERVAL 0.05
#define MAX_POLL_SECONDS 30
- (BOOL) cpoll:(NSTimeInterval)timeout block:(dispatch_block_t)block
{
    int pollCount = 0;
    int maxPollCount = timeout / POLL_INTERVAL;
    while (self.done == NO && pollCount < maxPollCount) {
        NSLog(@"polling... %3.2f", pollCount * POLL_INTERVAL);
        NSRunLoop* loop = [NSRunLoop mainRunLoop];
        NSDate* until = [NSDate dateWithTimeIntervalSinceNow:POLL_INTERVAL];
        [loop runUntilDate:until];
        pollCount++;
        block();
    }
    if (pollCount == maxPollCount) {
        XCTFail(@"polling timed out");
    }
    
    return YES;
}


- (void) testCachedStoreLocalFirst
{
    id<KCSStore> store = [self createStore:KCSCachePolicyLocalFirst];
    XCTAssertNotNil(store, @"must make a store");
    NSUInteger prevCount = self.requestArray.count;
    
    //call 1
    XCTAssertTrue([self queryServer:store], @"expecting to call server for first time");

    //call 2
    XCTAssertFalse([self queryServer:store], @"expecting to use cache, not server on repeat call");
    
    self.done = NO;
    //need this extra poll to wait for the background completion block to be called
    [self cpoll:MAX_POLL_SECONDS block:^{
        self.done  = self.requestArray.count == prevCount + 2;
    }];
    
    KTAssertEqualsInt(prevCount + 2, self.requestArray.count, @"expecting to call server twice, once for the initial load, and second for the bg update on the second from cache read.");
    KTAssertEqualsInt(_callbackCount, 2, @"expecting callback to be called twice");
}

- (void) testCachedStoreNetworkFirst
{
    pollTime = 2.;
    
    id<KCSStore> store = [self createStore:KCSCachePolicyNetworkFirst];
    XCTAssertNotNil(store, @"must make a store");
    
    XCTAssertTrue([self queryServer:store], @"expecting to call server");
    XCTAssertTrue([self queryServer:store], @"expecting to call server");

    _callbackCount = 0;
    XCTAssertTrue([self queryServer:store], @"expecting to call server");
    XCTAssertTrue(1 == _callbackCount, @"expecting callback to be called only once");
    
//#warning [(KCSCachedStore*)store setReachable:NO];
//
//    XCTAssertFalse([self queryServer:store], @"expecting to use cache, not server on repeat call");

}

- (void) testCachedStoreBoth
{
    id<KCSStore> store = [self createStore:KCSCachePolicyBoth];
    XCTAssertNotNil(store, @"must make a store");
    
    BOOL useServer = [self queryServer:store];
    XCTAssertTrue(useServer, @"expecting to call server for first time");
    
    NSLog(@"0");
    _callbackCount = 0;
    
    useServer = [self queryServer:store];
    XCTAssertFalse(useServer, @"expecting to use cache, not server on repeat call");
//#warning  STAssertTrue(_conn.wasCalled, @"expecting to call server after cache");
//    XCTAssertTrue(2 == _callbackCount, @"expecting callback to be called twice");
}

- (void) testTwoCollectionsNotSameCache
{
    KCSCollection* collection1 = [[KCSCollection alloc] init];
    collection1.collectionName = @"lists";
    collection1.objectTemplate = [TestEntity class];
    KCSCachedStore* store1 = [KCSCachedStore storeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:collection1, KCSStoreKeyResource, [NSNumber numberWithInt:KCSCachePolicyLocalFirst],KCSStoreKeyCachePolicy, nil]];
    
    KCSCollection* collection2 = [[KCSCollection alloc] init];
    collection2.collectionName = @"fists";
    collection2.objectTemplate = [TestEntity class];
    KCSCachedStore* store2 = [KCSCachedStore storeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:collection2, KCSStoreKeyResource, [NSNumber numberWithInt:KCSCachePolicyLocalFirst], KCSStoreKeyCachePolicy, nil]];
    
    XCTAssertTrue([self queryServer:store1], @"expecting to call server for first time");    
//    XCTAssertFalse([self queryServer:store1], @"expecting to use cache, not server on repeat call");
    XCTAssertTrue([self queryServer:store2], @"expecting to call server for first time");
//    XCTAssertFalse([self queryServer:store2], @"expecting to use cache, not server on repeat call");
}

- (void) testTwoCollectionsReuseCache
{
    KCSCollection* collection1 = [[KCSCollection alloc] init];
    collection1.collectionName = @"reusecachelists";
    collection1.objectTemplate = [TestEntity class];
    KCSCachedStore* store1 = [KCSCachedStore storeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:collection1, KCSStoreKeyResource, [NSNumber numberWithInt:KCSCachePolicyLocalFirst],KCSStoreKeyCachePolicy, nil]];
    
    KCSCollection* collection2 = [[KCSCollection alloc] init];
    collection2.collectionName = @"reusecachelists";
    collection2.objectTemplate = [TestEntity class];
    KCSCachedStore* store2 = [KCSCachedStore storeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:collection2, KCSStoreKeyResource, [NSNumber numberWithInt:KCSCachePolicyLocalFirst], KCSStoreKeyCachePolicy, nil]];
    
    XCTAssertTrue([self queryServer:store1], @"expecting to call server for first time");    
//    XCTAssertFalse([self queryServer:store1], @"expecting to use cache, not server on repeat call");
//    XCTAssertFalse([self queryServer:store2], @"expecting to use cache, even with new store because of shared cache");
//    XCTAssertFalse([self queryServer:store2], @"expecting to use cache, not server on repeat call");
}

#pragma mark - Import/Export

- (NSArray*) jsonArray
{
    NSString* cdata = @"[{\"date\":\"ISODate(\\\"2013-06-21T12:51:38.969Z\\\")\",\"objCount\":10,\"objDescription\":\"one\",\"_acl\":{\"creator\":\"51c44c5982cd0ade36000012\"},\"_kmd\":{\"lmt\":\"2013-06-21T12:51:37.817Z\",\"ect\":\"2013-06-21T12:51:37.817Z\"},\"_id\":\"51c44c5982cd0ade36000013\"},{\"date\":\"ISODate(\\\"2013-06-21T12:51:38.969Z\\\")\",\"objCount\":10,\"objDescription\":\"two\",\"_acl\":{\"creator\":\"51c44c5982cd0ade36000012\"},\"_kmd\":{\"lmt\":\"2013-06-21T12:51:37.818Z\",\"ect\":\"2013-06-21T12:51:37.818Z\"},\"_id\":\"51c44c5982cd0ade36000014\"},{\"date\":\"ISODate(\\\"2013-06-21T12:51:38.969Z\\\")\",\"objCount\":10,\"objDescription\":\"two\",\"_acl\":{\"creator\":\"51c44c5982cd0ade36000012\"},\"_kmd\":{\"lmt\":\"2013-06-21T12:51:37.819Z\",\"ect\":\"2013-06-21T12:51:37.819Z\"},\"_id\":\"51c44c5982cd0ade36000015\"},{\"_acl\":{\"creator\":\"kid10005\"},\"_kmd\":{\"lmt\":\"2013-08-07T02:22:50.154Z\",\"ect\":\"2013-08-07T02:22:50.154Z\"},\"_id\":\"5201af7a3bb9501365000025\"},{\"_acl\":{\"creator\":\"506f3c35aa9734091d0000ee\"},\"_kmd\":{\"lmt\":\"2013-08-07T02:23:02.122Z\",\"ect\":\"2013-08-07T02:23:02.122Z\"},\"_id\":\"5201af863bb9501365000026\"},{\"_acl\":{\"creator\":\"kid10005\"},\"_kmd\":{\"lmt\":\"2013-09-24T19:14:55.984Z\",\"ect\":\"2013-09-24T19:14:55.984Z\"},\"_id\":\"5241e4af8daed3725400009c\"},{\"abc\":\"1\",\"_acl\":{\"creator\":\"kid10005\"},\"_kmd\":{\"lmt\":\"2013-09-24T19:15:02.536Z\",\"ect\":\"2013-09-24T19:15:02.536Z\"},\"_id\":\"5241e4b68daed3725400009d\"},{\"abc\":\"true\",\"_acl\":{\"creator\":\"kid10005\"},\"_kmd\":{\"lmt\":\"2013-09-24T19:15:11.263Z\",\"ect\":\"2013-09-24T19:15:11.263Z\"},\"_id\":\"5241e4bf8daed3725400009e\"}]";
    
    NSError* error = nil;
    NSMutableArray* entities = [NSJSONSerialization JSONObjectWithData:[cdata dataUsingEncoding:NSUTF8StringEncoding]
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&error];
    XCTAssertNotNil(entities, @"Should have data to import: %@", error);
    
    return entities;
}

- (void) testImport
{
    KCSCachedStore* store = [KCSCachedStore storeWithCollection:[TestUtils randomCollection:[NSMutableDictionary class]] options:@{KCSStoreKeyCachePolicy : @(KCSCachePolicyLocalOnly)}];
    
    //1. import data
    NSArray* array = [self jsonArray];
    [store importCache:array];
    
    //2. do a query all and get the objs back
    __weak XCTestExpectation* expectationQuery = [self expectationWithDescription:@"query"];

    [store queryWithQuery:[KCSQuery query] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        KTAssertCount(8, objectsOrNil);
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationQuery fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    //3. do an export and check the data
    NSArray* _out = [store exportCache];
    KTAssertCount(8, _out);
//    XCTAssertEqualObjects(_out, array, @"should match");
    
}

- (void) testNoCachePolicy
{
    KCSCollection* rc = [TestUtils randomCollection:[NSMutableDictionary class]];
    KCSCachedStore* store = [KCSCachedStore storeWithCollection:rc options:@{KCSStoreKeyCachePolicy : @(KCSCachePolicyNone)}];
    
    NSMutableDictionary* obj = [@{@"foo":@"bar"} mutableCopy];

    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:nil];

    __weak XCTestExpectation* expectationQuery = [self expectationWithDescription:@"query"];
    [store queryWithQuery:[KCSQuery query] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        KTAssertCount(1, objectsOrNil);
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationQuery fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak XCTestExpectation* expectationRemove = [self expectationWithDescription:@"remove"];
    [store removeObject:obj[KCSEntityKeyId]
    withCompletionBlock:^(unsigned long count, NSError *errorOrNil) {
        STAssertNoError
        KTAssertEqualsInt(count, 1, @"Should delete one");
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationRemove fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    //the pay-off the object should no longer be in the cache
    __weak XCTestExpectation* expectationQuery2 = [self expectationWithDescription:@"query2"];
    [store queryWithQuery:[KCSQuery query] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        KTAssertCount(0, objectsOrNil);
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationQuery2 fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

@end
