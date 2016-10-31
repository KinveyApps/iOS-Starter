//
//  KinveyKitQueryTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/26/12.
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


#import "KinveyKitQueryTests.h"
#import "NSString+KinveyAdditions.h"
#import "KinveyKit.h"
#import "TestUtils.h"
#import "ASTTestClass.h"

@compatibility_alias TestClass ASTTestClass;

@implementation KinveyKitQueryTests

// All code under test must be linked into the Unit Test bundle
- (void)testSomeQueries
{
    NSString *expectedJSON = @"{\"$or\":[{\"age\":{\"$gt\":30}},{\"jobs\":{\"$gt\":1,\"$lt\":5}}],\"children\":{\"$not\":{\"$lt\":3}}}";
    
    KCSQuery *query  = [KCSQuery queryOnField:@"age" usingConditional:kKCSGreaterThan forValue:[NSNumber numberWithInt:30]];
    KCSQuery *query2 = [KCSQuery queryOnField:@"jobs" usingConditionalsForValues:
                        kKCSGreaterThan, [NSNumber numberWithInt:1],
                        kKCSLessThan, [NSNumber numberWithInt:5], nil];
    KCSQuery *orQuery = [KCSQuery queryForJoiningOperator:kKCSOr onQueries:query, query2, nil];
    
    [orQuery addQueryNegatingQuery:[KCSQuery queryOnField:@"children" usingConditional:kKCSLessThan forValue:[NSNumber numberWithInt:3]]];
    
    NSString *computedJSON = [orQuery JSONStringRepresentation];
    
    XCTAssertEqualObjects(computedJSON, expectedJSON, @"");
    
    
    KCSQuery *geoQuery = [KCSQuery queryOnField:KCSEntityKeyGeolocation usingConditional:kKCSNearSphere forValue:[NSArray arrayWithObjects:[NSNumber numberWithFloat:50.0], [NSNumber numberWithFloat:50.0], nil]];
    
    NSLog(@"%@\n%@", [geoQuery JSONStringRepresentation], [NSString stringByPercentEncodingString:[geoQuery JSONStringRepresentation]]);
}

- (void)testCombo
{
    KCSQuery *q1 = [KCSQuery query];
    [q1 addQueryOnField:@"testField" usingConditional:kKCSGreaterThan forValue:[NSNumber numberWithInt:23]];
    
    KCSQuery *q2 = [KCSQuery queryOnField:@"testField" usingConditional:kKCSGreaterThan forValue:[NSNumber numberWithInt:23]];

    NSString *a = [q1 JSONStringRepresentation];
    NSString *b = [q2 JSONStringRepresentation];
    XCTAssertEqualObjects(a, b, @"");
}

- (void)testMongoOps
{
    KCSQuery *q = [KCSQuery query];
    
    // Ex1 {"age": {"$gte": 18, "$lte": 40}}
    
    [q clear];
    
    // Ex2  {"username": {"$ne": "joe"}}
    // Ex3  {"ticket_no": {"$in": [725, 542, 390]}}
    // Ex4  {"user_id": {"$in": [12345, "joe"]}}
    // Ex5  {"ticket_no": {"$nin": [725, 542, 390]}}
    // Ex6  {"$or": [{"ticket_no": 725}, {"winner": true}]}
    // Ex7  {"$or": [{"ticket_no": {"$in": [725, 542, 390]}, {"winner": true}]}
    // Ex8a {"id_num": {"$mod": [5, 1]}}
    // Ex8b {"id_num": {"$not": {"$mod": [5, 1]}}}
    // Ex9  {"y": null}
    
}


- (void)testBlog
{
    NSString *r1 = @"{\"_geoloc\":{\"$nearSphere\":[-71,41]}}";
    KCSQuery *q1 = [KCSQuery queryOnField:KCSEntityKeyGeolocation
                         usingConditional:kKCSNearSphere
                                 forValue: [NSArray arrayWithObjects:
                                            [NSNumber numberWithInt:-71],
                                            [NSNumber numberWithInt:41], nil]];
    XCTAssertEqualObjects([q1 JSONStringRepresentation], r1, @"");

    NSString *r2 = @"{\"_geoloc\":{\"$nearSphere\":[-71,42],\"$maxDistance\":0.5}}";
    KCSQuery *q2 = [KCSQuery queryOnField:KCSEntityKeyGeolocation
               usingConditionalsForValues:
                    kKCSNearSphere,
                    [NSArray arrayWithObjects:
                     [NSNumber numberWithInt:-71],
                     [NSNumber numberWithInt:42], nil],
                    kKCSMaxDistance,
                    [NSNumber numberWithFloat:0.5], nil]; // Does this need to be a string?
    
    XCTAssertEqualObjects([q2 JSONStringRepresentation], r2, @"");
    
    NSString *r3 = @"{\"_geoloc\":{\"$within\":{\"$box\":[[-70,44],[-72,42]]}}}";
    NSArray *point1 = [NSArray arrayWithObjects:[NSNumber numberWithInt:-70],
                       [NSNumber numberWithInt:44], nil];
    
    NSArray *point2 = [NSArray arrayWithObjects:[NSNumber numberWithInt:-72],
                       [NSNumber numberWithInt:42], nil];

    NSArray *box = [NSArray arrayWithObjects:point1, point2, nil];
    KCSQuery *q3 = [KCSQuery queryOnField:KCSEntityKeyGeolocation
                         usingConditional:kKCSWithinBox
                                 forValue:box];

    XCTAssertEqualObjects([q3 JSONStringRepresentation], r3, @"");

}

- (void) testAscendingDecending
{
    BOOL setup = [TestUtils setUpKinveyUnittestBackend:self];
    XCTAssertTrue(setup, @"Backend should be good to go");
    
    KCSCollection* collection = [TestUtils randomCollection:[TestClass class]];
    
    NSMutableArray* arr = [NSMutableArray arrayWithCapacity:20];
    for (int i=0; i < 20; i++) {
        TestClass* a = [[TestClass alloc] init];
        a.objCount = i;
        [arr addObject:a];
    }
    
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:collection options:nil];
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    [store saveObject:arr withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        XCTAssertNil(errorOrNil);
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    KCSQuery* query = [KCSQuery query];
    query.limitModifer = [[KCSQueryLimitModifier alloc] initWithLimit:10];
    
    [query addSortModifier:[[KCSQuerySortModifier alloc] initWithField:@"objCount" inDirection:kKCSAscending]];
    
    __weak XCTestExpectation* expectationQuery = [self expectationWithDescription:@"query"];
    [store queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        XCTAssertNil(errorOrNil);
        XCTAssertEqual((int)[objectsOrNil count], (int) 10, @"should have 10 objects");
        int count = 0;
        for (TestClass* a in objectsOrNil) {
            count += a.objCount;
        }
        XCTAssertEqual(count, (int) 45, @"count should match");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationQuery fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    query = [KCSQuery query];
    query.limitModifer = [[KCSQueryLimitModifier alloc] initWithLimit:10];
    
    [query addSortModifier:[[KCSQuerySortModifier alloc] initWithField:@"objCount" inDirection:kKCSDescending]];
    
    __weak XCTestExpectation* expectationQuery2 = [self expectationWithDescription:@"query2"];
    [store queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        XCTAssertNil(errorOrNil);
        XCTAssertEqual((int)[objectsOrNil count], (int) 10, @"should have 10 objects");
        int count = 0;
        for (TestClass* a in objectsOrNil) {
            count += a.objCount;
        }
        XCTAssertEqual(count, (int) 145, @"count should match");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationQuery2 fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}


#define AssertQuery STAssertEqualObjects([query JSONStringRepresentation], expectedJSON, @"should match");
- (void) testMetadatQueryDate
{
    BOOL setup = [TestUtils setUpKinveyUnittestBackend:self];
    XCTAssertTrue(setup, @"Backend should be good to go");
    
    KCSCollection* collection = [TestUtils randomCollection:[TestClass class]];
    
    TestClass* t1 = [[TestClass alloc] init];
    t1.objDescription = @"t1";
    t1.objCount = 1;
    
    TestClass* t2 = [[TestClass alloc] init];
    t2.objDescription = @"t2";
    t2.objCount = 1;

    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:collection options:nil];
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    [store saveObject:@[t1,t2] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    KCSQuery* query = [KCSQuery queryOnField:KCSMetadataFieldLastModifiedTime usingConditional:kKCSLessThan forValue:[NSDate date]];
    __weak XCTestExpectation* expectationQuery = [self expectationWithDescription:@"query"];
    [store queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        STAssertObjects(2);
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationQuery fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) loginWithUser:(NSString*)username password:(NSString*)password
{
    __weak XCTestExpectation* expectationLogin = [self expectationWithDescription:@"login"];
    [KCSUser userWithUsername:username password:password fieldsAndValues:nil withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
        if (errorOrNil) {
            [KCSUser loginWithUsername:username password:password withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
                STAssertNoError
                
                XCTAssertTrue([NSThread isMainThread]);
                
                [expectationLogin fulfill];
            }];
        } else {
            self.done = YES;
        }
        
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testMetadataQueryCreator
{
    BOOL setup = [TestUtils setUpKinveyUnittestBackend:self];
    XCTAssertTrue(setup, @"Backend should be good to go");
    
    //setup a test user
    [self loginWithUser:@"testMetadataQueryCreator1" password:@"b"];    
    NSString* origId = [[[KCSUser activeUser] kinveyObjectId] copy];
    XCTAssertNotNil(origId, @"expecting an id");
    
    KCSCollection* collection = [TestUtils randomCollection:[TestClass class]];
    
    TestClass* t1 = [[TestClass alloc] init];
    t1.objDescription = @"t1";
    t1.objCount = 1;
    
    TestClass* t2 = [[TestClass alloc] init];
    t2.objDescription = @"t2";
    t2.objCount = 1;
    
    //create t1 as first user
    
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:collection options:nil];
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    [store saveObject:t1 withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    //create t2 as second user
    [self loginWithUser:@"testMetadataQueryCreator2" password:@"b"];    
    NSString* secondId = [[KCSUser activeUser] kinveyObjectId];
    
    __weak XCTestExpectation* expectationSave2 = [self expectationWithDescription:@"save2"];
    [store saveObject:t2 withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave2 fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];

    //do the queries
    __weak XCTestExpectation* expectationQuery = [self expectationWithDescription:@"query"];
    [store queryWithQuery:[KCSQuery queryOnField:KCSMetadataFieldCreator withExactMatchForValue:origId] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        STAssertObjects(1);
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationQuery fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak XCTestExpectation* expectationQuery2 = [self expectationWithDescription:@"query2"];
    [store queryWithQuery:[KCSQuery queryOnField:KCSMetadataFieldCreator withExactMatchForValue:[KCSUser activeUser]] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        STAssertObjects(1);
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationQuery2 fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak XCTestExpectation* expectationQuery3 = [self expectationWithDescription:@"query3"];
    [store queryWithQuery:[KCSQuery queryOnField:KCSMetadataFieldCreator usingConditional:kKCSIn forValue:@[origId, secondId]] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        STAssertObjects(2);
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationQuery3 fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

//- (void) testAnd
//{
//    //method 1
//    KCSQuery *q1 = [KCSQuery queryOnField:@"eventId" withExactMatchForValue:@"eventId:"];
//    KCSQuery *q2 = [KCSQuery queryOnField:@"isRevoked" withExactMatchForValue:@NO];
//    KCSQuery *query = [KCSQuery queryForJoiningOperator:kKCSAnd onQueries:q1, q2, nil];
//    
//    NSString* exp = @"{\"$and\":[{\"eventId\":\"eventId:\"},{\"isRevoked\":false}]}";
//    NSString* act = [query JSONStringRepresentation];
//    XCTAssertEqualObjects(act, exp, @"queries should match");
//    
//    //method 2
//    KCSQuery *query_2 = [KCSQuery queryOnField:@"eventId" withExactMatchForValue:@"eventId"];
//    KCSQuery *q2_2 = [KCSQuery queryOnField:@"isRevoked" withExactMatchForValue:@NO];
//    [query_2 addQueryForJoiningOperator:kKCSAnd onQueries:q2_2, nil];
//    exp = @"{\"$and\":[{\"isRevoked\":false}],\"eventId\":\"eventId\"}";
//    act = [query_2 JSONStringRepresentation];
//    XCTAssertEqualObjects(act, exp, @"queries should match");
//    
//}

- (void) testNegate
{
    KCSQuery* q1 = [KCSQuery queryOnField:@"field" usingConditional:kKCSGreaterThan forValue:@1];
    XCTAssertEqualObjects(q1.query, @{@"field" : @{@"$gt" : @1}}, @"should properly construct the gt query");
    
    [q1 negateQuery];
    XCTAssertEqualObjects(q1.query, @{@"field" : @{@"$not" : @{@"$gt" : @1}}}, @"should properly construct the gt query");
    
    KCSQuery* q2 = [KCSQuery queryOnField:@"field" withExactMatchForValue:@1];
    XCTAssertThrows([q2 negateQuery], @"InvalidArguments. Should throw an error");

}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void) testNil
{
    KCSQuery* q1 = [KCSQuery queryOnField:@"field" withExactMatchForValue:[NSNull null]];
    XCTAssertEqualObjects(q1.query, @{@"field" : @{@"$type" : @(10)}}, @"should properly construct the null query");
    
    KCSQuery* q2 = [KCSQuery queryForEmptyOrNullValueInField:@"field"];
    XCTAssertEqualObjects(q2.query, @{@"field" : [NSNull null]}, @"should properly construct the null query");

    
    KCSQuery* q3 = [KCSQuery queryForEmptyValueInField:@"field"];
    XCTAssertEqualObjects(q3.query, @{@"field" : @{@"$exists" : @(NO)}}, @"should properly construct the null query");
}
#pragma clang diagnostic pop

- (void) testHamadComplexQuery
{
    
    KCSQuery *queryNewMessages = [KCSQuery queryOnField:@"request_status" withExactMatchForValue:[NSNumber numberWithInt:1]];
    
    KCSQuery *queryRequestMessages = [KCSQuery queryOnField:@"request_type" usingConditional:kKCSIn forValue:[NSArray arrayWithObjects:[NSNumber numberWithInt:10], [NSNumber numberWithInt:20], [NSNumber numberWithInt:30], nil]];
    
    KCSQuery *queryForGroup = [KCSQuery queryForJoiningOperator:kKCSAnd onQueries:queryNewMessages, queryRequestMessages, nil];
//    KCSQuery *queryForGroup2 = [KCSQuery queryForJoiningOperator:kKCSOr onQueries:queryNewMessages, queryRequestMessages, nil];
//    
//    NSString* x = @"f2e40aH2QK2mBcC9_NTl8Q";
    
    NSLog(@"%@", queryForGroup);
}

- (void) testCopyConstructor
{
    KCSQuery* q1 = [KCSQuery queryOnField:@"A" usingConditional:kKCSIn forValue:@[@1,@3]];
    [q1 addQuery:[KCSQuery queryOnField:@"B" withExactMatchForValue:@"foo"]];
    q1.limitModifer = [[KCSQueryLimitModifier alloc] initWithLimit:300];
    [q1 addSortModifier:[[KCSQuerySortModifier alloc] initWithField:@"C" inDirection:kKCSAscending]];
    
    KCSQuery* q2 = [KCSQuery queryWithQuery:q1];
    
    XCTAssertTrue(q1 != q2, @"Should be different objects");
    XCTAssertEqualObjects([q1 parameterStringRepresentation], [q2 parameterStringRepresentation], @"The query strings should match");
    
    q1.limitModifer = [[KCSQueryLimitModifier alloc] initWithLimit:5];
    
    XCTAssertFalse([[q1 parameterStringRepresentation] isEqualToString:[q2 parameterStringRepresentation]], @"strings should be independent");
}


@end
