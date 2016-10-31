//
//  KinveyCollectionStoreTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 5/1/12.
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


#import "KinveyAppdataStoreTests.h"
#import <KinveyKit/KinveyKit.h>
#import "ASTTestClass.h"

#import "TestUtils.h"

@implementation KinveyAppdataStoreTests

- (void) setUp
{
    [super setUp];
    
    BOOL setup = [TestUtils setUpKinveyUnittestBackend:self];
    XCTAssertTrue(setup, @"should be set-up");
    
    _collection = [[KCSCollection alloc] init];
    _collection.collectionName = [NSString stringWithFormat:@"testObjects%i", arc4random()];
    _collection.objectTemplate = [ASTTestClass class];
    
    _store = [KCSAppdataStore storeWithCollection:_collection options:nil];

}

-(void)testSaveOne
{
    __weak XCTestExpectation* expectationLoad = [self expectationWithDescription:@"load"];
    [_store loadObjectWithID:@"testobj" withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        XCTAssertNil(objectsOrNil, @"expecting a nil objects");
        XCTAssertNotNil(errorOrNil, @"expecting an error");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationLoad fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    ASTTestClass *obj = [self makeObject:@"description" count:-88 objId:@"testobj"];
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    [_store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak XCTestExpectation* expectationLoad2 = [self expectationWithDescription:@"load2"];
    [_store loadObjectWithID:@"testobj" withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        XCTAssertNotNil(objectsOrNil, @"expecting a non-nil objects");
        XCTAssertEqual((int) [objectsOrNil count], 1, @"expecting one object of id 'testobj' to be found");
        XCTAssertEqual((int) [[objectsOrNil objectAtIndex:0] objCount], -88, @"expecting save to have completed sucessfully");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationLoad2 fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

-(void)testSaveMany
{
    NSMutableArray* baseObjs = [NSMutableArray array];
    [baseObjs addObject:[self makeObject:@"one" count:10]];
    [baseObjs addObject:[self makeObject:@"two" count:10]];
    [baseObjs addObject:[self makeObject:@"two" count:30]];
    [baseObjs addObject:[self makeObject:@"two" count:70]];
    [baseObjs addObject:[self makeObject:@"one" count:5]];
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    [_store saveObject:baseObjs withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        XCTAssertNotNil(objectsOrNil, @"expecting a non-nil objects");
        XCTAssertEqual((int) [objectsOrNil count], 5, @"expecting five objects returned for saving five objects");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}


NSString* largeStringOfSize(int size) 
{
    NSMutableString* string  = [NSMutableString stringWithCapacity:size];
    while (string.length < size) {
        [string appendFormat:@"%i",arc4random()];
    }
    return string;
}

NSString* largeString() 
{
    return largeStringOfSize(1e3);
}

- (void) upTimeout
{
    KCSClientConfiguration* conifg = [KCSClient sharedClient].configuration;
    NSMutableDictionary* d = [NSMutableDictionary dictionaryWithDictionary:conifg.options];
    d[KCS_CONNECTION_TIMEOUT] = @1000;
    conifg.options = d;
    [[KCSClient sharedClient] setConfiguration:conifg];
}

- (void)testQueryHuge
{
    [self upTimeout];
    
    __weak XCTestExpectation* expectationQuery = [self expectationWithDescription:@"query"];
    KCSQuery* query = [KCSQuery queryOnField:@"foo" withExactMatchForValue:largeString()];
    [_store queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationQuery fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
        NSLog(@"progress = %f", percentComplete);
    }];
    [self waitForExpectationsWithTimeout:120 handler:nil];
}

NSArray* largeArray() 
{
    int size = 1e2;
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:size];
    for (int i=0; i<size; i++) {
        [array addObject:largeStringOfSize(1e0)];
    }
    return array;
}

- (void)testQueryLargeIn
{
    [self upTimeout];
    self.done = NO;
    KCSQuery* query = [KCSQuery queryOnField:@"foo" usingConditional:kKCSIn forValue:largeArray()];
    __weak XCTestExpectation* expectationQuery = [self expectationWithDescription:@"query"];
    [_store queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationQuery fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
        NSLog(@"progress = %f", percentComplete);
    }];
    [self waitForExpectationsWithTimeout:120 handler:nil];
}

- (void)testRemoveOne
{
    self.done = NO;
    __block ASTTestClass* obj = [self makeObject:@"abc" count:100];
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    [_store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        obj = [objectsOrNil objectAtIndex:0];
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    NSString* objId = obj.objId;
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:4]];
    
    __weak XCTestExpectation* expectationRemove = [self expectationWithDescription:@"remove"];
    [_store removeObject:obj withCompletionBlock:^(unsigned long count, NSError *errorOrNil) {
        STAssertNoError;
        KTAssertEqualsInt(count, 1, @"should delete one object");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationRemove fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak XCTestExpectation* expectationLoad = [self expectationWithDescription:@"load"];
    [_store loadObjectWithID:objId withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        NSLog(@"--- %@ -- %@", objectsOrNil, errorOrNil);
        XCTAssertNotNil(errorOrNil, @"should have an error");
        XCTAssertEqual((int)KCSNotFoundError, [errorOrNil code], @"should have been not found");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationLoad fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void)testRemoveXAll
{
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    NSMutableArray* all = [NSMutableArray arrayWithCapacity:10];
    for (int i=0; i < 10; i++) {
        ASTTestClass* obj = [self makeObject:@"testRemoveAll" count:i];
        [all addObject:obj];
    }
    __block NSArray* vals = nil;
    [_store saveObject:all withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        vals = objectsOrNil;
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    
    __weak XCTestExpectation* expectationRemove = [self expectationWithDescription:@"remove"];
    [_store removeObject:vals withCompletionBlock:^(unsigned long count, NSError *errorOrNil) {
        STAssertNoError;
        KTAssertEqualsInt(count, 10, @"should delete one object");
        
        XCTAssertTrue([NSThread isMainThread]);

        [expectationRemove fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak XCTestExpectation* expectationCount = [self expectationWithDescription:@"count"];
    [_store countWithBlock:^(unsigned long count, NSError *errorOrNil) {
        XCTAssertEqual((unsigned long) 0, count, @"should have deleted all");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationCount fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];

}

//- (void) testBlErrors
//{
//    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:[KCSCollection collectionFromString:@"bl-errors" ofClass:[NSMutableDictionary class]] options:@{}];
//    XCTestExpectation* expectationQuery = [self expectationWithDescription:@"query"];
//    [store queryWithQuery:[KCSQuery query] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
//        XCTAssertNotNil(errorOrNil, @"should have an error");
//        KTAssertEqualsInt(errorOrNil.code, 550, @"should be a 550");
//        
//        NSDictionary* errorVals = errorOrNil.userInfo;
//        XCTAssertNotNil(errorVals[@"Kinvey.RequestId"], @"should have request id");
//        XCTAssertNotNil(errorVals[@"Kinvey.ExecutedHooks"], @"should have hooks");
//        
//        XCTAssertTrue([NSThread isMainThread]);
//        
//        [expectationQuery fulfill];
//    } withProgressBlock:^(NSArray *objects, double percentComplete) {
//        XCTAssertTrue([NSThread isMainThread]);
//    }];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//}

- (ASTTestClass*)makeObject:(NSString*)desc count:(int)count
{
    ASTTestClass *obj = [[ASTTestClass alloc] init];
    obj.objDescription = desc;
    obj.objCount = count;
    return obj;
}

- (ASTTestClass*)makeObject:(NSString*)desc count:(int)count objId:(NSString*)objId
{
    ASTTestClass *obj = [[ASTTestClass alloc] init];
    obj.objDescription = desc;
    obj.objCount = count;
    obj.objId = objId;
    return obj;
}

//- (void) testGroupBy
//{
//    NSMutableArray* baseObjs = [NSMutableArray array];
//    [baseObjs addObject:[self makeObject:@"one" count:10]];
//    [baseObjs addObject:[self makeObject:@"two" count:10]];
//    [baseObjs addObject:[self makeObject:@"two" count:10]];
//    XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
//    [_store saveObject:baseObjs
//   withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
//       XCTAssertNil(errorOrNil);
//       
//       XCTAssertTrue([NSThread isMainThread]);
//       
//       [expectationSave fulfill];
//   } withProgressBlock:^(NSArray *objects, double percentComplete) {
//       XCTAssertTrue([NSThread isMainThread]);
//   }];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//    
//    
//    XCTestExpectation* expectationGroup = [self expectationWithDescription:@"group"];
//    [_store group:[NSArray arrayWithObject:@"objDescription"] reduce:[KCSReduceFunction COUNT] completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
//        XCTAssertNil(errorOrNil, @"got error: %@", errorOrNil);
//        
//        NSNumber* value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"one", @"objDescription", nil]];
//        XCTAssertEqual([value intValue], 1, @"expecting one objects of 'one'");
//        
//        value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"two", @"objDescription", nil]];
//        XCTAssertEqual([value intValue], 2, @"expecting two objects of 'two'");
//        
//        XCTAssertTrue([NSThread isMainThread]);
//        
//        [expectationGroup fulfill];
//    } progressBlock:^(NSArray *objects, double percentComplete) {
//        XCTAssertTrue([NSThread isMainThread]);
//    }];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//    
//    XCTestExpectation* expectationGroup2 = [self expectationWithDescription:@"group2"];
//    [_store group:[NSArray arrayWithObject:@"objDescription"] reduce:[KCSReduceFunction SUM:@"objCount"] completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
//        XCTAssertNil(errorOrNil, @"got error: %@", errorOrNil);
//        
//        NSNumber* value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"one", @"objDescription", nil]];
//        XCTAssertEqual([value intValue],10, @"expecting one objects of 'one'");
//        
//        value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"two", @"objDescription", nil]];
//        XCTAssertEqual([value intValue], 20, @"expecting two objects of 'two'");
//        
//        XCTAssertTrue([NSThread isMainThread]);
//        
//        [expectationGroup2 fulfill];
//    } progressBlock:^(NSArray *objects, double percentComplete) {
//        XCTAssertTrue([NSThread isMainThread]);
//    }];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//}

//- (void) testGroupByWithCondition
//{
//    NSMutableArray* baseObjs = [NSMutableArray array];
//    [baseObjs addObject:[self makeObject:@"one" count:10]];
//    [baseObjs addObject:[self makeObject:@"two" count:10]];
//    [baseObjs addObject:[self makeObject:@"two" count:30]];
//    [baseObjs addObject:[self makeObject:@"two" count:70]];
//    [baseObjs addObject:[self makeObject:@"one" count:5]];
//    XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
//    [_store saveObject:baseObjs
//   withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
//       XCTAssertNil(errorOrNil);
//       
//       XCTAssertTrue([NSThread isMainThread]);
//       
//       [expectationSave fulfill];
//   }
//     withProgressBlock:^(NSArray *objects, double percentComplete) {
//         XCTAssertTrue([NSThread isMainThread]);
//     }];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//    
//    
//    XCTestExpectation* expectationGroup = [self expectationWithDescription:@"group"];
//    KCSQuery* condition = [KCSQuery queryOnField:@"objCount" usingConditional:kKCSGreaterThan forValue:[NSNumber numberWithInt:10]];
//    [_store group:[NSArray arrayWithObject:@"objDescription"] reduce:[KCSReduceFunction COUNT] condition:condition completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
//        XCTAssertNil(errorOrNil, @"got error: %@", errorOrNil);
//        
//        NSNumber* value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"one", @"objDescription", nil]];
//        XCTAssertEqual([value intValue], NSNotFound, @"expecting one objects of 'one'");
//        
//        value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"two", @"objDescription", nil]];
//        XCTAssertEqual([value intValue], 2, @"expecting two objects of 'two'");
//        
//        XCTAssertTrue([NSThread isMainThread]);
//        
//        [expectationGroup fulfill];
//    } progressBlock:^(NSArray *objects, double percentComplete) {
//        XCTAssertTrue([NSThread isMainThread]);
//    }];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//    
//    XCTestExpectation* expectationGroup2 = [self expectationWithDescription:@"group2"];
//    [_store group:[NSArray arrayWithObject:@"objDescription"] reduce:[KCSReduceFunction SUM:@"objCount"] condition:condition completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
//        XCTAssertNil(errorOrNil, @"got error: %@", errorOrNil);
//        
//        NSNumber* value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"one", @"objDescription", nil]];
//        XCTAssertEqual([value intValue], NSNotFound, @"expecting one objects of 'one'");
//        
//        value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"two", @"objDescription", nil]];
//        XCTAssertEqual([value intValue], 100, @"expecting two objects of 'two'");
//        
//        XCTAssertTrue([NSThread isMainThread]);
//        
//        [expectationGroup2 fulfill];
//    } progressBlock:^(NSArray *objects, double percentComplete) {
//        XCTAssertTrue([NSThread isMainThread]);
//    }];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//    
//}

- (void) testGroupByMultipleFields
{
    NSMutableArray* baseObjs = [NSMutableArray array];
    [baseObjs addObject:[self makeObject:@"one" count:10]];
    [baseObjs addObject:[self makeObject:@"one" count:10]];
    [baseObjs addObject:[self makeObject:@"two" count:10]];
    [baseObjs addObject:[self makeObject:@"two" count:30]];
    //    [baseObjs addObject:[self makeObject:@"two" count:70]];
    [baseObjs addObject:[self makeObject:@"one" count:5]];
    [baseObjs addObject:[self makeObject:@"two" count:70]];
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    [_store saveObject:baseObjs
   withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
       XCTAssertNil(errorOrNil);
       
       XCTAssertTrue([NSThread isMainThread]);
       
       [expectationSave fulfill];
   } withProgressBlock:^(NSArray *objects, double percentComplete) {
       XCTAssertTrue([NSThread isMainThread]);
   }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    
    __weak XCTestExpectation* expectationGroup = [self expectationWithDescription:@"group"];
    [_store group:[NSArray arrayWithObjects:@"objDescription", @"objCount", nil] reduce:[KCSReduceFunction COUNT] completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
        XCTAssertNil(errorOrNil, @"got error: %@", errorOrNil);
        
        NSNumber* value = [valuesOrNil reducedValueForFields:@{@"objDescription":@"one", @"objCount" :@10}];
        XCTAssertEqual([value intValue], 2, @"expecting two objects of 'one' & count == 0");
        
        value = [valuesOrNil reducedValueForFields:@{@"objDescription":@"two",@"objCount":@30}];
        XCTAssertEqual([value intValue], 1, @"expecting just one object of 'two', because this should bail after finding the first match of two");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationGroup fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak XCTestExpectation* expectationGroup2 = [self expectationWithDescription:@"group2"];
    KCSQuery* condition = [KCSQuery queryOnField:@"objCount" usingConditional:kKCSGreaterThanOrEqual forValue:@10];
    [_store group:@[@"objDescription", @"objCount"] reduce:[KCSReduceFunction SUM:@"objCount"] condition:condition completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
        XCTAssertNil(errorOrNil, @"got error: %@", errorOrNil);
        
        NSNumber* value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"one", @"objDescription", [NSNumber numberWithInt:10], @"objCount", nil]];
        XCTAssertEqual([value intValue], 20, @"expecting to have sumed objects of 'one' and count == 10");
        
        value = [valuesOrNil reducedValueForFields:@{@"objDescription" : @"two"}];
        XCTAssertTrue([value intValue] == 30 || [value intValue] == 70, @"expecting just the first obj of 'two'");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationGroup2 fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
}

//- (void) testLoadById
//{
//    NSMutableArray* baseObjs = [NSMutableArray array];
//    [baseObjs addObject:[self makeObject:@"one" count:10 objId:@"a1"]];
//    [baseObjs addObject:[self makeObject:@"one" count:10 objId:@"a2"]];
//    [baseObjs addObject:[self makeObject:@"two" count:10 objId:@"a3"]];
//    [baseObjs addObject:[self makeObject:@"two" count:30 objId:@"a4"]];
//    [baseObjs addObject:[self makeObject:@"two" count:70 objId:@"a5"]];
//    [baseObjs addObject:[self makeObject:@"one" count:5  objId:@"a6"]];
//    [baseObjs addObject:[self makeObject:@"two" count:70 objId:@"a7"]];
//    XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
//    [_store saveObject:baseObjs
//   withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
//       XCTAssertNil(errorOrNil);
//       
//       XCTAssertTrue([NSThread isMainThread]);
//       
//       [expectationSave fulfill];
//   } withProgressBlock:^(NSArray *objects, double percentComplete) {
//       XCTAssertTrue([NSThread isMainThread]);
//   }];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//    
//    XCTestExpectation* expectationLoad = [self expectationWithDescription:@"load"];
//    __block NSArray* objs = nil;
//    [_store loadObjectWithID:@"a6" withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
//        STAssertNoError;
//        objs = objectsOrNil;
//        XCTAssertNotNil(objs, @"expecting to load some objects");
//        XCTAssertEqual((int) [objs count], 1, @"should only load one object");
//        XCTAssertEqual((int) [[objs objectAtIndex:0] objCount], 5, @"expecting 6 from a6");
//        
//        XCTAssertTrue([NSThread isMainThread]);
//        
//        [expectationLoad fulfill];
//    } withProgressBlock:^(NSArray *objects, double percentComplete) {
//        XCTAssertTrue([NSThread isMainThread]);
//    }];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//
//   
//    
//    XCTestExpectation* expectationLoad2 = [self expectationWithDescription:@"load2"];
//    objs = nil;
//    [_store loadObjectWithID:[NSArray arrayWithObjects:@"a1",@"a2",@"a3", nil] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
//        STAssertNoError
//        objs = objectsOrNil;
//        XCTAssertNotNil(objs, @"expecting to load some objects");
//        XCTAssertEqual((int) [objs count], 3, @"should only load one object");
//        
//        XCTAssertTrue([NSThread isMainThread]);
//        
//        [expectationLoad2 fulfill];
//    } withProgressBlock:^(NSArray *objects, double percentComplete) {
//        XCTAssertTrue([NSThread isMainThread]);
//    }];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//}

//TODO: test progress as failure completion blocks;

- (void) testEmptyResponse
{
    __weak XCTestExpectation* expectationQuery = [self expectationWithDescription:@"query"];
    [_store queryWithQuery:[KCSQuery queryOnField:@"count" withExactMatchForValue:@"NEVER MATCH"] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        XCTAssertEqual((NSUInteger)0, objectsOrNil.count, @"should be empty array");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationQuery fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

//- (void) testStreamingResults
//{
//    NSMutableArray* baseObjs = [NSMutableArray array];
//    [baseObjs addObject:[self makeObject:@"one" count:10 objId:@"a1"]];
//    [baseObjs addObject:[self makeObject:@"one" count:10 objId:@"a2"]];
//    [baseObjs addObject:[self makeObject:@"two" count:10 objId:@"a3"]];
//    [baseObjs addObject:[self makeObject:@"two" count:30 objId:@"a4"]];
//    [baseObjs addObject:[self makeObject:@"two" count:70 objId:@"a5"]];
//    [baseObjs addObject:[self makeObject:@"one" count:5  objId:@"a6"]];
//    [baseObjs addObject:[self makeObject:@"two" count:70 objId:@"a7"]];
//    XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
//    [_store saveObject:baseObjs
//   withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
//       XCTAssertNil(errorOrNil);
//       
//       XCTAssertTrue([NSThread isMainThread]);
//       
//       [expectationSave fulfill];
//   } withProgressBlock:^(NSArray *objects, double percentComplete) {
//       XCTAssertTrue([NSThread isMainThread]);
//   }];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//    
//    XCTestExpectation* expectationQuery = [self expectationWithDescription:@"query"];
//    __block float done = -1;
//    __block NSArray* objs = nil;
//    [_store queryWithQuery:[KCSQuery query] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
//        STAssertNoError
//        objs = objectsOrNil;
//        XCTAssertNotNil(objs, @"expecting to load some objects");
//        
//        XCTAssertTrue([NSThread isMainThread]);
//        
//        [expectationQuery fulfill];
//    } withProgressBlock:^(NSArray *objects, double percentComplete) {
//        NSLog(@"testStreamingResults: percentcomplete:%f", percentComplete);
//        XCTAssertTrue(percentComplete > done, @"should be monotonically increasing");
//        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
//        done = percentComplete;
//        
//        XCTAssertNotNil(objects, @"should have objects");
//        XCTAssertTrue(objects.count >=1, @"should have at least object");
//        id obj = objects[0];
//        XCTAssertTrue([obj isKindOfClass:[ASTTestClass class]], @"class should be test class type");
//        
//        XCTAssertTrue([NSThread isMainThread]);
//    }];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//}

- (void) testProgressPerformance
{
    KCSQuery* planRoomQuery = [KCSQuery query];
    
    KCSQueryLimitModifier *limitModifier = [[KCSQueryLimitModifier alloc] initWithLimit:200];
    
    planRoomQuery.limitModifer = limitModifier;
    // planRoomQuery.skipModifier = skipModifier;
    
    KCSAppdataStore *planRoomStore = [KCSAppdataStore storeWithCollection:[KCSCollection userCollection] options:nil];
    
    __weak XCTestExpectation* expectationQuery = [self expectationWithDescription:@"query"];
    [planRoomStore queryWithQuery:planRoomQuery withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationQuery fulfill];
     } withProgressBlock:^(NSArray *objects, double percentComplete) {
         XCTAssertTrue([NSThread isMainThread]);
     }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
//    This code creates unbounded memory growth, and, the objects array is empty and that log prints 0.
//    percentComplete prints correct values.
//    
//    
//    This code also results in unbounded memory growth:
    
//    [planRoomStore queryWithQuery:planRoomQuery withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil)
//    {
//        completionHandler(nil, 100);
//    }
//     
//                withProgressBlock:^(NSArray *objects, double percentComplete)
//    {
//    }];
    
//    This code does not have the memory issues, but, of course, I am unable to track the progress of the request.
    
//    [planRoomStore queryWithQuery:planRoomQuery withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil)
//    {
//        completionHandler(nil, 100);
//    }
}

#pragma mark - Count

- (void) testCountWithQuery
{
    NSMutableArray* baseObjs = [NSMutableArray array];
    [baseObjs addObject:[self makeObject:@"one" count:10 objId:@"a1"]];
    [baseObjs addObject:[self makeObject:@"one" count:10 objId:@"a2"]];
    [baseObjs addObject:[self makeObject:@"two" count:10 objId:@"a3"]];
    [baseObjs addObject:[self makeObject:@"two" count:30 objId:@"a4"]];
    [baseObjs addObject:[self makeObject:@"two" count:70 objId:@"a5"]];
    [baseObjs addObject:[self makeObject:@"one" count:5  objId:@"a6"]];
    [baseObjs addObject:[self makeObject:@"two" count:70 objId:@"a7"]];
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    [_store saveObject:baseObjs
   withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
       XCTAssertNil(errorOrNil);
       
       XCTAssertTrue([NSThread isMainThread]);
       
       [expectationSave fulfill];
   } withProgressBlock:^(NSArray *objects, double percentComplete) {
       XCTAssertTrue([NSThread isMainThread]);
   }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak XCTestExpectation* expectationCount = [self expectationWithDescription:@"count"];
    KCSQuery* q = [KCSQuery queryOnField:@"objDescription" withExactMatchForValue:@"one"];
    [_store countWithQuery:q completion:^(unsigned long count, NSError *errorOrNil) {
        STAssertNoError
        unsigned long exp = 3;
        XCTAssertEqual(exp, count, @"expeting count");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationCount fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];

    __weak XCTestExpectation* expectationCount2 = [self expectationWithDescription:@"count2"];
    [q addQueryOnField:@"objCount" withExactMatchForValue:@(10)];
    [_store countWithQuery:q completion:^(unsigned long count, NSError *errorOrNil) {
        STAssertNoError
        unsigned long exp = 2;
        XCTAssertEqual(exp, count, @"expeting count");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationCount2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}


#pragma mark - User Collection

- (void) testUserCollectionMakesUsers
{
    __block NSArray* objs = nil;
    __weak XCTestExpectation* expectationQuery = [self expectationWithDescription:@"query"];
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:[KCSCollection userCollection] options:nil];
    [store queryWithQuery:[KCSQuery query] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        KTAssertCountAtLeast(1, objectsOrNil);
        
        XCTAssertTrue([NSThread isMainThread]);
        
        objs = objectsOrNil;
        
        [expectationQuery fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:60 handler:nil];
    
    
    for (KCSUser* u in objs) {
        XCTAssertTrue([u isKindOfClass:[KCSUser class]], @"is not a user.");
    }
    
}

@end
