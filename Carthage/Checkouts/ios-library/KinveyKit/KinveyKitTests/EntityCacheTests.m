//
//  EntityCache.m
//  KinveyKit
//
//  Created by Michael Katz on 10/25/13.
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
#import "KinveyUserService.h"

#import "KCSEntityPersistence.h"
#import "KCSObjectCache.h"
#import "ASTTestClass.h"

#undef ddLogLevel
#define ddLogLevel LOG_FLAG_DEBUG

#define KTAssertU XCTAssertTrue(u, @"pass");

@interface EntityCacheTests : KCSTestCase

@end

@implementation EntityCacheTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
    KCSClientConfiguration* cfg = [KCSClientConfiguration configurationWithAppKey:@"Fake" secret:@"Fake"];
    [[KCSClient sharedClient] initializeWithConfiguration:cfg];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

#pragma mark - Persistence

- (void)testRW
{
    KCSEntityPersistence* cache = [[KCSEntityPersistence alloc] initWithPersistenceId:@"x"];
    NSDictionary* o = @{@"_id":@"1",@"foo":@"bar"};
    BOOL u = [cache updateWithEntity:o route:@"r" collection:@"c"];
    KTAssertU
    NSDictionary* d = [cache entityForId:@"1" route:@"r" collection:@"c"];
    XCTAssertNotNil(d, @"should get back value");
    
    XCTAssertEqualObjects(o, d, @"should be restored");
}

- (void) testRemove
{
    KCSEntityPersistence* cache = [[KCSEntityPersistence alloc] initWithPersistenceId:@"x"];
    NSDictionary* o = @{@"_id":@"1",@"foo":@"bar"};
    [cache updateWithEntity:o route:@"r" collection:@"c"];
    NSDictionary* d = [cache entityForId:@"1" route:@"r" collection:@"c"];
    XCTAssertNotNil(d, @"should get back value");
    
    BOOL u = [cache removeEntity:@"1" route:@"r" collection:@"c"];
    KTAssertU

    d = [cache entityForId:@"1" route:@"r" collection:@"c"];
    XCTAssertNil(d, @"should get back no value");
}

- (void) testQueryRW
{
    KCSEntityPersistence* cache = [[KCSEntityPersistence alloc] initWithPersistenceId:@"x"];
    NSArray* ids = @[@"1",@"2",@"3"];
    NSString* query = [NSString UUID];
    NSString* route = @"r";
    NSString* cln = @"c";
    BOOL u = [cache setIds:ids forQuery:query route:route collection:cln];
    KTAssertU
    
    NSArray* loadedIds = [cache idsForQuery:query route:route collection:cln];
    XCTAssertNotNil(loadedIds, @"should have ids");
    XCTAssertEqualObjects(loadedIds, ids, @"should match");
}

- (void) testQueryReplacesOld
{
    KCSEntityPersistence* cache = [[KCSEntityPersistence alloc] initWithPersistenceId:@"x"];
    NSArray* ids = @[@"1",@"2",@"3"];
    NSString* query = [NSString UUID];
    NSString* route = @"r";
    NSString* cln = @"c";
    BOOL u = [cache setIds:ids forQuery:query route:route collection:cln];
    KTAssertU
    
    NSArray* secondSet = @[@"2",@"3",@"4"];
    u = [cache setIds:secondSet forQuery:query route:route collection:cln];
    KTAssertU

    NSArray* loadedIds = [cache idsForQuery:query route:route collection:cln];
    XCTAssertNotNil(loadedIds, @"should have ids");
    XCTAssertEqualObjects(loadedIds, secondSet, @"should match");
}

- (void) testRemoveQueryFromPersistence
{
    KCSEntityPersistence* cache = [[KCSEntityPersistence alloc] initWithPersistenceId:@"x"];
    NSArray* ids = @[@"1",@"2",@"3"];
    NSString* query = [NSString UUID];
    NSString* route = @"r";
    NSString* cln = @"c";
    BOOL u = [cache setIds:ids forQuery:query route:route collection:cln];
    KTAssertU

    NSArray* objs = [cache idsForQuery:query route:route collection:cln];
    KTAssertCount(3, objs);
    
    u = [cache removeQuery:query route:route collection:cln];
    KTAssertU
    
    objs = [cache idsForQuery:query route:route collection:cln];
    XCTAssertNil(objs, @"should have no result");
}

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
    NSArray* entities = [self jsonArray];
    
    KCSEntityPersistence* cache = [[KCSEntityPersistence alloc] initWithPersistenceId:@"x"];
    NSString* route = @"r";
    NSString* cln = @"c";
    
    BOOL u = [cache import:entities route:route collection:cln];
    KTAssertU
    
    NSDictionary* entity = [cache entityForId:@"51c44c5982cd0ade36000013" route:route collection:cln];
    XCTAssertNotNil(entity, @"should get back an entity");
}


- (void) testExport
{
    NSArray* entities = [self jsonArray];
    
    KCSEntityPersistence* cache = [[KCSEntityPersistence alloc] initWithPersistenceId:@"x"];
    NSString* route = @"r";
    NSString* cln = [[NSString UUID] stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    BOOL u = [cache import:entities route:route collection:cln];
    KTAssertU
    
    NSArray* output = [cache export:route collection:cln];
    KTAssertCount(8, output);
    XCTAssertEqualObjects(output, entities, @"should get back original");
    
    [cache clearCaches];
}

- (void) testMetadata
{
    KCSEntityPersistence* cache = [[KCSEntityPersistence alloc] initWithPersistenceId:@"x"];
    NSDictionary* meta = @{@"foo":@"bar",@"fizz":@"buzz"};
    BOOL u = [cache setClientMetadata:meta];
    KTAssertU
    
    NSDictionary* recovered = [cache clientMetadata];
    XCTAssertEqualObjects(recovered, meta, @"Should get the metadata back");
}

#pragma mark - Peristance Unsaveds
- (void) testUnsavedPersistence
{
    KCSEntityPersistence* cache = [[KCSEntityPersistence alloc] initWithPersistenceId:@"x"];
    
    NSString* newid = [cache addUnsavedEntity:@{@"a":@1,@"_id":@"1"} route:@"R" collection:@"C1" method:@"M1" headers:@{@"h1":@"v1"}];
    XCTAssertNotNil(newid, @"should have an id");
    id d2 = @{@"a":@"b",@"_id":@"1"};
    newid = [cache addUnsavedEntity:d2 route:@"R" collection:@"C2" method:@"M2" headers:@{@"h1":@"v1",@"h2":@"v2"}];
    XCTAssertNotNil(newid, @"should have an id");
    id d3 = @{@"a":@2,@"_id":@"1"};
    newid = [cache addUnsavedEntity:d3 route:@"R" collection:@"C1" method:@"M1" headers:@{@"h1":@"v1"}];
    XCTAssertNotNil(newid, @"should have an id");

    int count = [cache unsavedCount];
    XCTAssertEqual(count, (int)2, @"should have 2 objects");
    
    
    NSArray* unsaveds = [cache unsavedEntities];
    KTAssertCount(2, unsaveds);
    XCTAssertEqualObjects(unsaveds[0][@"obj"], d2, @"");
    XCTAssertEqualObjects(unsaveds[1][@"obj"], d3, @"should be the updated 2");
    
    NSDate* saveDate = unsaveds[0][@"time"];
    XCTAssertTrue([saveDate isKindOfClass:[NSDate class]], @"Should be a date");
    
}

#pragma mark - Cache
- (void) testPullQueryGetsFromPersistence
{
    NSArray* entities = [self jsonArray];
    
    KCSEntityPersistence* cache = [[KCSEntityPersistence alloc] initWithPersistenceId:@"offline"];
    NSString* route = @"r";
    NSString* cln = @"c";
    
    BOOL u = [cache import:entities route:route collection:cln];
    KTAssertU

    NSString* _id = @"51c44c5982cd0ade36000013";
    KCSQuery* q = [KCSQuery queryOnField:KCSEntityKeyId withExactMatchForValue:_id];
    u = [cache setIds:@[_id] forQuery:[[KCSQuery2 queryWithQuery1:q] keyString] route:route collection:cln];
    KTAssertU
    
    
    KCSObjectCache* ocache = [[KCSObjectCache alloc] init];
    NSArray* results = [ocache pullQuery:[KCSQuery2 queryWithQuery1:q] route:route collection:cln];
    XCTAssertNotNil(results, @"should have results");
    KTAssertCount(1, results);
    
    id obj = results[0];
    XCTAssertTrue([obj isKindOfClass:[NSMutableDictionary class]], @"default should be nsmutable dictionary");
}

- (void) testSetQuery
{
    NSArray* entities = [self jsonArray];
    KCSObjectCache* ocache = [[KCSObjectCache alloc] init];
    
    KCSQuery* q = [KCSQuery query];
    NSString* route = @"r";
    NSString* cln = @"c";
    NSArray* results = [ocache setObjects:entities forQuery:[KCSQuery2 queryWithQuery1:q] route:route collection:cln persist:YES];
    KTAssertCount(8, results);
    
    [ocache clear];
}

- (void) testSkipLimit
{
    NSArray* entities = [self jsonArray];
    KCSObjectCache* ocache = [[KCSObjectCache alloc] init];

    NSString* route = @"R";
    NSString* collection = [NSString UUID];
    
    KCSQuery* q1 = [KCSQuery query];
    q1.skipModifier = [[KCSQuerySkipModifier alloc] initWithcount:0];
    q1.limitModifer = [[KCSQueryLimitModifier alloc] initWithLimit:4];
    
    NSArray* results1 = [ocache setObjects:[entities subarrayWithRange:NSMakeRange(0, 4)] forQuery:[KCSQuery2 queryWithQuery1:q1] route:route collection:collection persist:YES];
    KTAssertCount(4, results1);


    KCSQuery* q2 = [KCSQuery query];
    q2.skipModifier = [[KCSQuerySkipModifier alloc] initWithcount:4];
    q2.limitModifer = [[KCSQueryLimitModifier alloc] initWithLimit:4];
    
    NSArray* results2 = [ocache setObjects:[entities subarrayWithRange:NSMakeRange(4, 4)] forQuery:[KCSQuery2 queryWithQuery1:q2] route:route collection:collection persist:YES];
    KTAssertCount(4, results2);
    
    NSArray* pull1 = [ocache pullQuery:[KCSQuery2 queryWithQuery1:q1] route:route collection:collection];
    NSArray* pull2 = [ocache pullQuery:[KCSQuery2 queryWithQuery1:q2] route:route collection:collection];
    
    KTAssertCount(4, pull1);
    KTAssertCount(4, pull2);
    
    for (id o in pull1) {
        XCTAssertFalse([pull2 containsObject:o], @"should be different arrays");
    }
}

- (void) testRemoveQueryFromCache
{
    NSArray* entities = [self jsonArray];
    KCSObjectCache* ocache = [[KCSObjectCache alloc] init];
    
    KCSQuery* q = [KCSQuery query];
    NSString* route = @"r";
    NSString* cln = @"c";
    NSArray* results = [ocache setObjects:entities forQuery:[KCSQuery2 queryWithQuery1:q] route:route collection:cln persist:YES];
    KTAssertCount(8, results);
    
    NSArray* preResults = [ocache pullQuery:[KCSQuery2 queryWithQuery1:q] route:route collection:cln];
    KTAssertCount(8, preResults);

    BOOL u = [ocache removeQuery:[KCSQuery2 queryWithQuery1:q] route:route collection:cln];
    KTAssertU
    
//    NSArray* postResults = [ocache pullQuery:[KCSQuery2 queryWithQuery1:q] route:route collection:cln];
//    XCTAssertNil(postResults, @"should have no result");
}

- (void) testDelete
{
    KCSObjectCache* ocache = [[KCSObjectCache alloc] init];
    NSArray* entities = @[@{@"_id":@"X",@"a":@1}];
    KCSQuery* q = [KCSQuery query];
    KCSQuery2* q2 = [KCSQuery2 queryWithQuery1:q];
    NSString* route = @"R";
    NSString* collection = @"zfasdf";
    NSArray* a = [ocache setObjects:entities forQuery:q2 route:route collection:collection persist:YES];
    KTAssertCount(1, a);
    
    NSArray* preResults = [ocache pullQuery:q2 route:route collection:collection];
    KTAssertCount(1, preResults);

    [ocache deleteObject:@"X" route:route collection:collection];
    
    NSArray* idResults = [ocache pullIds:@[@"X"] route:route collection:collection];
    KTAssertCount(0, idResults);
    
    NSArray* postResults = [ocache pullQuery:q2 route:route collection:collection];
    KTAssertCount(0, postResults);
    
    [ocache clear];
}

- (void) testDeleteQuery
{
    KCSObjectCache* ocache = [[KCSObjectCache alloc] init];
    ocache.offlineUpdateEnabled = YES;
    
    KCSQuery* q = [KCSQuery query];
    KCSQuery2* q2 = [KCSQuery2 queryWithQuery1:q];
    NSString* route = @"R";
    NSString* collection = @"zfasdf";
    
    KCSQuery2* qAfter = [ocache addUnsavedDeleteQuery:q2 route:route collection:collection method:@"DELETE" headers:@{} error:nil];
    XCTAssertNotNil(qAfter, @"");

    [ocache clear];
}

- (void) testLocalEvalAll
{
    NSArray* entities = [self jsonArray];
    KCSObjectCache* ocache = [[KCSObjectCache alloc] init];
    
    //seed with data
    KCSQuery* q = [KCSQuery queryOnField:@"A" withExactMatchForValue:@"X"];
    NSString* route = @"r";
    NSString* cln = @"c";
    NSArray* results = [ocache setObjects:entities forQuery:[KCSQuery2 queryWithQuery1:q] route:route collection:cln persist:YES];
    KTAssertCount(8, results);
    
    NSArray* allResults = [ocache pullQuery:[KCSQuery2 allQuery] route:route collection:cln];
    KTAssertCount(8, allResults);
    XCTAssertEqualObjects(entities, allResults, @"should match original");
    
    
    [ocache clear];
}

- (void) testInterestingQueries
{

    NSDate* tenHoursAgo = [NSDate dateWithTimeIntervalSinceNow:-10*60*60];
    KCSQuery* query = [KCSQuery queryOnField:@"location.timestamp" usingConditional:kKCSGreaterThanOrEqual forValue:tenHoursAgo];
    KCSObjectCache* cache = [[KCSObjectCache alloc] init];
    KCSQuery2* q = [KCSQuery2 queryWithQuery1:query];

    ASTTestClass* obj1 = [[ASTTestClass alloc] init];
    obj1.objId = @"1";
    ASTTestClass* obj2 = [[ASTTestClass alloc] init];
    obj2.objId = @"2";
    [cache setObjects:@[obj1,obj2] forQuery:q route:@"user" collection:@"_user" persist:YES];

    
    NSPredicate* queryPredicate = [q predicate];
    NSArray* allObjs = @[obj1,obj2];
    NSArray* filteredObj = [allObjs filteredArrayUsingPredicate:queryPredicate];
    NSArray* results = [filteredObj valueForKeyPath:KCSEntityKeyId];
    XCTAssertEqual(results.count, 0);
    
//    NSArray* results = [cache pullQuery:q route:@"user" collection:@"_user"];
//    NSLog(@"results = %@", results);
}

#pragma mark - Old Tests

- (void) testActiveUser
{
    KCSObjectCache* cache = [[KCSObjectCache alloc] init];

    KCSUser2* user = [[KCSUser2 alloc] init];
    user.userId = [NSString UUID];
    user.username = [NSString UUID];
    user.email = [NSString UUID];
    [cache cacheActiveUser:user];
    
    KCSUser2* restoredUser = [cache lastActiveUser];
    XCTAssertEqualObjects(restoredUser.userId, user.userId, @"ids should match");
    XCTAssertEqualObjects(restoredUser.username, user.username, @"usernames should match");
    XCTAssertEqualObjects(restoredUser.email, user.email, @"emails should match");
}


- (void) testRoundTripQuery
{
    KCSObjectCache* cache = [[KCSObjectCache alloc] init];
    
    KCSQuery* query = [KCSQuery queryOnField:@"foo" withExactMatchForValue:@"bar"];
    [query addSortModifier:[[KCSQuerySortModifier alloc] initWithField:@"sortOrder" inDirection:kKCSAscending]];
    ASTTestClass* obj1 = [[ASTTestClass alloc] init];
    obj1.objId = @"1";
    ASTTestClass* obj2 = [[ASTTestClass alloc] init];
    obj2.objId = @"2";
    [cache setObjects:@[obj1,obj2] forQuery:[KCSQuery2 queryWithQuery1:query] route:@"A" collection:@"B" persist:YES];
    
    KCSQuery* query2 = [KCSQuery queryOnField:@"foo" withExactMatchForValue:@"bar"];
    [query2 addSortModifier:[[KCSQuerySortModifier alloc] initWithField:@"sortOrder" inDirection:kKCSAscending]];
    NSArray* results = [cache pullQuery:[KCSQuery2 queryWithQuery1:query2] route:@"A" collection:@"B"];
    
    XCTAssertTrue(results.count == 2, @"should have both objects");
    XCTAssertTrue([results containsObject:obj1], @"should have item 1");
    XCTAssertTrue([results containsObject:obj2], @"should have item 2");
    
}

-(void)testCacheForRouteCollectionAndClear
{
    KCSObjectCache* ocache = [[KCSObjectCache alloc] init];
    NSString* route = @"R";
    NSString* collection = @"zfasdf";
    
    NSUInteger size = 5000;
    NSMutableArray* expectations = [NSMutableArray arrayWithCapacity:size];
    NSOperationQueue* queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 256;
    for (NSUInteger i = 0; i < size; i++) {
        __weak __block XCTestExpectation* expectation = [self expectationWithDescription:[NSString stringWithFormat:@"expectation %@", @(i + 1)]];
        [expectations addObject:expectation];
        
        [queue addOperationWithBlock:^{
            [ocache addObjects:@[@{@"value" : @(i + 1)}]
                         route:route
                    collection:collection];
            [expectation fulfill];
        }];
        
        __weak __block XCTestExpectation* expectationClear = [self expectationWithDescription:@"clear"];
        [expectations addObject:expectationClear];
        
        [queue addOperationWithBlock:^{
            [ocache clear];
            [expectationClear fulfill];
        }];
    }
    
    [self waitForExpectationsWithTimeout:60 handler:^(NSError *error) {
        [expectations removeAllObjects];
        [queue cancelAllOperations];
        [queue waitUntilAllOperationsAreFinished];
    }];
}

#warning REINSTATE TESTS
#if NEVER


- (void) testRoundTripSingleId
{
    KCSObjectCache*cache = [self cache:nil];
    
    ASTTestClass* obj1 = [[ASTTestClass alloc] init];
    obj1.objId = @"1";
    [cache addResult:obj1];
    
    id result = [cache objectForId:@"1"];
    STAssertEqualObjects(result, obj1, @"should match");
}

- (void) testRoundTripArray
{
    KCSObjectCache* cache = [self cache:nil];
    
    ASTTestClass* obj1 = [[ASTTestClass alloc] init];
    obj1.objId = @"1";
    ASTTestClass* obj2 = [[ASTTestClass alloc] init];
    obj2.objId = @"2";
    [cache addResults:@[obj1, obj2]];
    
    NSArray* results = [cache resultsForIds:@[@"1",@"2",@"3"]];
    STAssertTrue(results.count == 2, @"should have both objects");
    STAssertTrue([results containsObject:obj1], @"should have item 1");
    STAssertTrue([results containsObject:obj2], @"should have item 2");
}

- (void) testUpdate
{
    KCSObjectCache* cache = [self cache:nil];
    
    KCSQuery* query = [KCSQuery queryOnField:@"foo" withExactMatchForValue:@"bar"];
    ASTTestClass* obj1 = [[ASTTestClass alloc] init];
    obj1.objId = @"1";
    obj1.objCount = 10;
    ASTTestClass* obj2 = [[ASTTestClass alloc] init];
    obj2.objId = @"2";
    
    [cache setResults:@[obj1, obj2] forQuery:query];
    
    ASTTestClass* result = [cache objectForId:@"1"];
    STAssertEquals(result.objCount, 10, @"should get back obj1");
    
    ASTTestClass* obj1Prime = [[ASTTestClass alloc] init];
    obj1Prime.objId = @"1";
    obj1Prime.objCount = 100;
    [cache addResult:obj1Prime];
    
    NSArray* primeResults = [cache resultsForQuery:query];
    STAssertTrue(primeResults.count == 2, @"should have both objects");
    __block BOOL found = NO;
    [primeResults enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ASTTestClass* o = obj;
        if ([o.objId isEqualToString:@"1"]) {
            found = YES;
            STAssertEquals(o.objCount, 100, @"should have been updated");
        }
    }];
    STAssertTrue(found, @"Expecting obj1 to be in the results");
}

- (void) testById
{
    KCSObjectCache* cache = [self cache:nil];
    
    ASTTestClass* obj1 = [[ASTTestClass alloc] init];
    obj1.objId = @"1";
    ASTTestClass* obj2 = [[ASTTestClass alloc] init];
    obj2.objId = @"2";
    [cache addResults:@[obj1,obj2]];
    
    NSArray* results = [cache resultsForIds:@[@"1",@"2"]];
    STAssertTrue(results.count == 2, @"should have both objects");
    STAssertTrue([results containsObject:obj1], @"should have item 1");
    STAssertTrue([results containsObject:obj2], @"should have item 2");
}


- (void) testAddBySave
{
    NSLog(@"---------- starting");
    
    ASTTestClass* obj = [[ASTTestClass alloc] init];
    obj.date = [NSDate date];
    obj.objCount = 79000;
    
    //    KCSCollection* c = [TestUtils randomCollection:[ASTTestClass class]];
    //    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:c options:@{KCSStoreKeyUniqueOfflineSaveIdentifier : @"x0"}];
    //
    //    [store setReachable:NO];
    
    KCSObjectCache* cache = [self cache:nil];
    [cache addUnsavedObject:obj];
    
    NSString* objId = obj.objId;
    STAssertNotNil(objId, @"Should have objid assigned");
    
    id ret = [cache objectForId:objId];
    STAssertEqualObjects(obj, ret, @"should get our object back");
}

//    self.done = NO;
//    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
//        STAssertError(errorOrNil, KCSKinveyUnreachableError);
//        NSArray* objs = [[errorOrNil userInfo] objectForKey:KCS_ERROR_UNSAVED_OBJECT_IDS_KEY];
//        STAssertEquals((NSUInteger)1, (NSUInteger) objs.count, @"should have one unsaved obj, from above");
//        self.done = YES;
//    } withProgressBlock:^(NSArray *objects, double percentComplete) {
//        NSLog(@"%f", percentComplete);
//    }];
//
//    [self poll];
//}

- (NSURL*) urlForDB:(NSString*)pid
{
    NSURL* url = nil;
    url = [NSURL fileURLWithPath: [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"com.kinvey.%@_cache.plist", pid]]];
    //    url = [NSURL fileURLWithPath: [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"com.kinvey.%@_cache.sqllite", pid]]];
    return url;
}

- (void) testClearCaches
{
    //setup peristence
    id<KCSEntityCache> cache = [self cache:@"persistenceId"];
    
    KCSQuery* query = [KCSQuery queryOnField:@"foo" withExactMatchForValue:@"bar"];
    ASTTestClass* obj1 = [[ASTTestClass alloc] init];
    obj1.objId = @"1";
    ASTTestClass* obj2 = [[ASTTestClass alloc] init];
    obj2.objId = @"2";
    [cache setResults:@[obj1, obj2] forQuery:query];
    
    NSURL* url = [self urlForDB:@"persistenceId"];
    STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[url path]], @"should have cache at %@", [url path]);
    
    [cache clearCaches];
    
    STAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:[url path]], @"should not have cache at %@", [url path]);
    
    KCSQuery* query2 = [KCSQuery queryOnField:@"foo" withExactMatchForValue:@"bar"];
    NSArray* results = [cache resultsForQuery:query2];
    
    STAssertEquals((int)results.count, (int)0, @"should not have any results after clearing cache");
}

- (void) testCacheClearasOnUserChange
{
    
    id<KCSEntityCache> cache = [self cache:@"persistenceId"];
    
    KCSQuery* query = [KCSQuery queryOnField:@"foo" withExactMatchForValue:@"bar"];
    ASTTestClass* obj1 = [[ASTTestClass alloc] init];
    obj1.objId = @"1";
    ASTTestClass* obj2 = [[ASTTestClass alloc] init];
    obj2.objId = @"2";
    [cache setResults:@[obj1, obj2] forQuery:query];
    
    NSURL* url = [self urlForDB:@"persistenceId"];
    STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[url path]], @"should have cache at %@", [url path]);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    [KCSClient sharedClient].currentUser = [[KCSUser alloc] init];
#pragma clang diagnostic pop
    
    STAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:[url path]], @"should not have cache at %@", [url path]);
}

#endif

//test save updates query
//test save new updates existing query
//save by id, load by query
//test persist
//test removal

@end
