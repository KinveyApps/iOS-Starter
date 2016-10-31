//
//  KCSReduceFunctionTests.m
//  KinveyKit
//
//  Created by Michael Katz on 5/21/12.
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


#import "KCSReduceFunctionTests.h"

#import <KinveyKit/KinveyKit.h>

#import "ASTTestClass.h"
#import "TestUtils.h"

@interface GroupTestClass : ASTTestClass
@property (nonatomic, retain) NSDictionary* objDict;
@end
@implementation GroupTestClass

- (NSDictionary *)hostToKinveyPropertyMapping
{
    NSMutableDictionary* d = [NSMutableDictionary dictionaryWithDictionary:[super hostToKinveyPropertyMapping]];
    [d setObject:@"objDict" forKey:@"objDict"];
    return d;
}

@end

@implementation KCSReduceFunctionTests

- (void) clearAll
{
    __block NSMutableArray* allObjs = [NSMutableArray array];
    __weak XCTestExpectation* expectationQuery = [self expectationWithDescription:@"query"];
    [store queryWithQuery:[KCSQuery query] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        
        XCTAssertTrue([NSThread isMainThread]);
        
        if (objectsOrNil != nil) {
            [allObjs addObjectsFromArray:objectsOrNil];
        }
        
        [expectationQuery fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
        NSLog(@"clear all query all = %f",percentComplete);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak XCTestExpectation* expectationRemove = [self expectationWithDescription:@"remove"];
    [store removeObject:allObjs
    withCompletionBlock:^(unsigned long count, NSError *errorOrNil) {
        XCTAssertNil(errorOrNil);
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationRemove fulfill];
    }
      withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
        NSLog(@"clear all delete = %f",percentComplete);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) setUp
{
    BOOL setup = [TestUtils setUpKinveyUnittestBackend:self];
    XCTAssertTrue(setup, @"should be up and running");
    
    KCSCollection* collection = [[KCSCollection alloc] init];
    collection.collectionName = [NSString stringWithFormat:@"testObjects%i", arc4random()];
    collection.objectTemplate = [ASTTestClass class];
    
    store = [KCSAppdataStore storeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:collection, KCSStoreKeyResource, nil]];
    
    //TODO: no need to clear all since it's a new collection each time[self clearAll];
    
    NSMutableArray* baseObjs = [NSMutableArray array];
    [baseObjs addObject:[self makeObject:@"one" count:10]];
    [baseObjs addObject:[self makeObject:@"two" count:10]];
    [baseObjs addObject:[self makeObject:@"two" count:10]];
    [baseObjs addObject:[self makeObject:@"math" count:2]];
    [baseObjs addObject:[self makeObject:@"math" count:100]];
    [baseObjs addObject:[self makeObject:@"math" count:-30]];
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    [store saveObject:baseObjs
  withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
      XCTAssertNil(errorOrNil);
      
      XCTAssertTrue([NSThread isMainThread]);
      
      [expectationSave fulfill];
  } withProgressBlock:^(NSArray *objects, double percentComplete) {
      XCTAssertTrue([NSThread isMainThread]);
  }];
    [self waitForExpectationsWithTimeout:30 handler:nil];

}

- (ASTTestClass*)makeObject:(NSString*)desc count:(int)count
{
    ASTTestClass *obj = [[GroupTestClass alloc] init];
    obj.objDescription = desc;
    obj.objCount = count;
    return obj;
}


- (void) testGroupByCOUNT
{
    __weak XCTestExpectation* expectationGroup = [self expectationWithDescription:@"group"];
    [store group:[NSArray arrayWithObject:@"objDescription"] reduce:[KCSReduceFunction COUNT] completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
        XCTAssertNil(errorOrNil, @"got error: %@", errorOrNil);
        
        NSNumber* value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"one", @"objDescription", nil]];
        XCTAssertEqual([value intValue], 1, @"expecting one objects of 'one'");
        
        value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"two", @"objDescription", nil]];
        XCTAssertEqual([value intValue], 2, @"expecting two objects of 'two'");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationGroup fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testGroupBySUM
{
    __weak XCTestExpectation* expectationGroup = [self expectationWithDescription:@"group"];
    [store group:[NSArray arrayWithObject:@"objDescription"] reduce:[KCSReduceFunction SUM:@"objCount"] completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
        XCTAssertNil(errorOrNil, @"got error: %@", errorOrNil);
        
        NSNumber* value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"one", @"objDescription", nil]];
        XCTAssertEqual([value intValue],10, @"expecting one objects of 'one'");
        
        value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"two", @"objDescription", nil]];
        XCTAssertEqual([value intValue], 20, @"expecting two objects of 'two'");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationGroup fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testGroupBySUMNonNumeric
{
    __weak XCTestExpectation* expectationGroup = [self expectationWithDescription:@"group"];
    [store group:[NSArray arrayWithObject:@"objDescription"] reduce:[KCSReduceFunction SUM:@"objDescription"] completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
        XCTAssertNil(errorOrNil, @"got error: %@", errorOrNil);
        
        NSNumber* value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"one", @"objDescription", nil]];
        XCTAssertEqual([value intValue],0, @"expecting 0 for a non-numeric");
        
        value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"two", @"objDescription", nil]];
        XCTAssertEqual([value intValue], 0, @"expecting 0 for a non-numeric");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationGroup fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testGroupByMIN
{
    __weak XCTestExpectation* expectationGroup = [self expectationWithDescription:@"group"];
    [store group:[NSArray arrayWithObject:@"objDescription"] reduce:[KCSReduceFunction MIN:@"objCount"] completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
        XCTAssertNil(errorOrNil, @"got error: %@", errorOrNil);
        
        NSNumber* value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"one", @"objDescription", nil]];
        XCTAssertEqual([value intValue],10, @"expecting 10 as the min for objects of 'one'");
        
        value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"math", @"objDescription", nil]];
        XCTAssertEqual([value intValue], -30, @"expecting 10 as the min for objects of 'math'");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationGroup fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}


- (void) testGroupByMAX
{
    __weak XCTestExpectation* expectationGroup = [self expectationWithDescription:@"group"];
    [store group:[NSArray arrayWithObject:@"objDescription"] reduce:[KCSReduceFunction MAX:@"objCount"] completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
        XCTAssertNil(errorOrNil, @"got error: %@", errorOrNil);
        
        NSNumber* value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"one", @"objDescription", nil]];
        XCTAssertEqual([value intValue],10, @"expecting 10 as the max for objects of 'one'");
        
        value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"math", @"objDescription", nil]];
        XCTAssertEqual([value intValue], 100, @"expecting 100 as the max for objects of 'math'");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationGroup fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testGroupByAverage
{
    __weak XCTestExpectation* expectationGroup = [self expectationWithDescription:@"group"];
    [store group:[NSArray arrayWithObject:@"objDescription"] reduce:[KCSReduceFunction AVERAGE:@"objCount"] completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
        XCTAssertNil(errorOrNil, @"got error: %@", errorOrNil);
        
        NSNumber* value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"one", @"objDescription", nil]];
        XCTAssertEqual([value intValue],10, @"expecting 10 as the avg for objects of 'one'");
        
        value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"math", @"objDescription", nil]];
        XCTAssertEqual([value intValue], 24, @"expecting 24 as the avg for objects of 'math'");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationGroup fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testGroupByObjectField
{
    GroupTestClass* t1 = (GroupTestClass*)[self makeObject:@"withDict" count:100];
    t1.objDict = @{@"food" : @"cherry"};
    GroupTestClass* t2 = (GroupTestClass*)[self makeObject:@"withDict" count:200];
    t2.objDict = @{@"food" : @"orange"};
    GroupTestClass* t3 = (GroupTestClass*)[self makeObject:@"withDict" count:200];
    t3.objDict = @{@"food" : @"orange", @"drink" : @"coffee"};

    NSArray* objs = @[t1,t2,t3];
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    [store saveObject:objs
  withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
      XCTAssertNil(errorOrNil);
      
      XCTAssertTrue([NSThread isMainThread]);
      
      [expectationSave fulfill];
  } withProgressBlock:^(NSArray *objects, double percentComplete) {
      XCTAssertTrue([NSThread isMainThread]);
  }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak XCTestExpectation* expectationGroup = [self expectationWithDescription:@"group"];
    [store group:@[@"objDict.food"] reduce:[KCSReduceFunction COUNT] completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
        STAssertNoError;
        NSNumber* value = [valuesOrNil reducedValueForFields:@{@"objDict.food" : @"orange"}];
        XCTAssertEqual([value intValue], 2, @"should be two oranges");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationGroup fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

//TODO: try sum for various types, string, etc


//TODO: fix this - need to build objects instead of dictionaries
- (void) noTestGroupObjByField
{
    __weak XCTestExpectation* expectationGroup = [self expectationWithDescription:@"group"];
    [store group:[NSArray arrayWithObject:@"objDescription"] reduce:[KCSReduceFunction AGGREGATE] completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
        XCTAssertNil(errorOrNil, @"got error: %@", errorOrNil);
        
        NSArray* value = [valuesOrNil reducedValueForFields:@{@"objDescription" : @"one"}];
        XCTAssertEqual([value[0] objectForKey:@""],10, @"expecting 10 as the min for objects of 'one'");
        
        value = [valuesOrNil reducedValueForFields:[NSDictionary dictionaryWithObjectsAndKeys:@"math", @"objDescription", nil]];
        XCTAssertEqual([value[0] objCount], -30, @"expecting 10 as the min for objects of 'math'");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationGroup fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

BOOL dosomething()
{
    return YES;
}

@end
