//
//  KCSMetadataTests.m
//  KinveyKit
//
//  Created by Michael Katz on 6/25/12.
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


#import "KCSMetadataTests.h"
#import <KinveyKit/KinveyKit.h>

#import "TestUtils.h"
#import "ASTTestClass.h"
@interface KCSMetadataTests ()
@end

@implementation KCSMetadataTests

- (void) setUp
{
    [TestUtils setUpKinveyUnittestBackend:self];
    
}

- (void) testKinveyMetadata
{
    KCSCollection* collection = [KCSCollection collectionFromString:@"testmetadata" ofClass:[ASTTestClass class]];
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:collection options:nil];
    __block ASTTestClass* obj = [[ASTTestClass alloc] init];
    obj.objDescription = @"testKinveyMetdata";
    obj.objCount = 100;
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        XCTAssertNil(errorOrNil, @"Should not have gotten error: %@", errorOrNil);
        
        XCTAssertTrue([NSThread isMainThread]);
        
        if (objectsOrNil.count > 0) {
            obj = [objectsOrNil objectAtIndex:0];
        } else {
            obj = nil;
        }
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    XCTAssertNotNil(obj.meta, @"Should have had metadata popuplated");
    XCTAssertNotNil([obj.meta lastModifiedTime], @"shoul have a lmt");
    XCTAssertEqualObjects([obj.meta creatorId], [[KCSUser activeUser] kinveyObjectId], @"this user should be the creator");
    
    [obj.meta.readers addObjectsFromArray:@[@"me!"]];
    
    __weak XCTestExpectation* expectationSave2 = [self expectationWithDescription:@"save2"];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        XCTAssertNil(errorOrNil, @"Should not have gotten error: %@", errorOrNil);
        
        XCTAssertTrue([NSThread isMainThread]);
        
        if (objectsOrNil.count > 0) {
            obj = [objectsOrNil objectAtIndex:0];
        } else {
            obj = nil;
        }
        
        [expectationSave2 fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    NSArray* readers = obj.meta.readers;
    XCTAssertEqual((int)1, (int) [readers count], @"should have one reader");
    XCTAssertEqualObjects(@"me!", [readers objectAtIndex:0], @"expecting set object");
}


- (void) testGloballyReadable
{
    KCSCollection* collection = [KCSCollection collectionFromString:@"testmetadata" ofClass:[ASTTestClass class]];
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:collection options:nil];
    __block ASTTestClass* obj = [[ASTTestClass alloc] init];
    obj.objDescription = @"testGloballyReadable";
    obj.objCount = __LINE__;
    obj.meta = [[KCSMetadata alloc] init];
    [obj.meta setGloballyReadable:NO];
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        XCTAssertNil(errorOrNil, @"Should not have gotten error: %@", errorOrNil);
        
        XCTAssertTrue([NSThread isMainThread]);
        
        obj = [objectsOrNil objectAtIndex:0];
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];

    XCTAssertNotNil([obj.meta lastModifiedTime], @"shoul have a lmt");
    XCTAssertNotNil([obj.meta creationTime], @"shoul have an ect");
    XCTAssertEqualObjects([obj.meta lastModifiedTime], [obj.meta creationTime], @"creation and ect should be the same time");
    XCTAssertEqualObjects([obj.meta creatorId], [[KCSUser activeUser] kinveyObjectId], @"this user should be the creator");
    XCTAssertFalse([obj.meta isGloballyReadable], @"expecting to have set that value");
    
    [obj.meta setGloballyReadable:NO];
    __weak XCTestExpectation* expectationSave2 = [self expectationWithDescription:@"save2"];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        XCTAssertNil(errorOrNil, @"Should not have gotten error: %@", errorOrNil);
        
        XCTAssertTrue([NSThread isMainThread]);
        
        if (objectsOrNil.count > 0) {
            obj = [objectsOrNil objectAtIndex:0];
        } else {
            obj = nil;
        }
        [expectationSave2 fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    XCTAssertNotNil([obj.meta lastModifiedTime], @"shoul have a lmt");
    XCTAssertNotNil([obj.meta creationTime], @"shoul have an ect");
    XCTAssertTrue([[obj.meta lastModifiedTime] compare:[obj.meta creationTime]] == NSOrderedDescending, @"lmt should be newer than ect");
    XCTAssertEqualObjects([obj.meta creatorId], [[KCSUser activeUser] kinveyObjectId], @"this user should be the creator");
    XCTAssertFalse([obj.meta isGloballyReadable], @"expecting to have set that value");
    
    __weak XCTestExpectation* expectationCreate = [self expectationWithDescription:@"create"];
    [KCSUser createAutogeneratedUser:nil completion:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
        STAssertNoError
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationCreate fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];

    __weak XCTestExpectation* expectationLoad = [self expectationWithDescription:@"load"];
    [store loadObjectWithID:obj.kinveyObjectId withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        XCTAssertNotNil(errorOrNil, @"Should have gotten an error");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationLoad fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
}


- (void) testNewReadersWriters
{
    KCSCollection* collection = [KCSCollection collectionFromString:@"testmetadata" ofClass:[ASTTestClass class]];
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:collection options:nil];
    __block ASTTestClass* obj = [[ASTTestClass alloc] init];
    obj.objDescription = @"testKinveyMetdata";
    obj.objCount = 100;
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    XCTAssertNotNil(obj.meta, @"Should have had metadata popuplated");
    
    [obj.meta.writers addObject:@"Tom"];
    [obj.meta.readers addObject:@"Bill"];
    
    __weak XCTestExpectation* expectationSave2 = [self expectationWithDescription:@"save2"];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave2 fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    NSArray* writers = [obj.meta writers];
    XCTAssertEqual((int)1, (int) [writers count], @"should have one reader");
    XCTAssertEqualObjects(@"Tom", writers[0], @"expecting set object");
    XCTAssertEqualObjects(@"Bill", obj.meta.readers[0], @"expecting set object");
}

- (void) testArchiving
{
    KCSCollection* collection = [KCSCollection collectionFromString:@"testmetadata" ofClass:[ASTTestClass class]];
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:collection options:nil];
    __block ASTTestClass* obj = [[ASTTestClass alloc] init];
    obj.objDescription = @"testGloballyReadable";
    obj.objCount = __LINE__;
    obj.meta = [[KCSMetadata alloc] init];
    [obj.meta setGloballyReadable:NO];
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        XCTAssertNil(errorOrNil, @"Should not have gotten error: %@", errorOrNil);
        
        XCTAssertTrue([NSThread isMainThread]);
        
        obj = [objectsOrNil objectAtIndex:0];
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];

    NSData* metadata = [NSKeyedArchiver archivedDataWithRootObject:obj.meta];
    KCSMetadata* restored = [NSKeyedUnarchiver unarchiveObjectWithData:metadata];
    XCTAssertEqualObjects(obj.meta, restored, @"Should be archived correctly");
}

- (void) testCopy
{
    
    KCSCollection* collection = [KCSCollection collectionFromString:@"testmetadata" ofClass:[ASTTestClass class]];
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:collection options:nil];
    __block ASTTestClass* obj = [[ASTTestClass alloc] init];
    obj.objDescription = @"testGloballyReadable";
    obj.objCount = __LINE__;
    obj.meta = [[KCSMetadata alloc] init];
    [obj.meta setGloballyReadable:NO];
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        XCTAssertNil(errorOrNil, @"Should not have gotten error: %@", errorOrNil);
        
        XCTAssertTrue([NSThread isMainThread]);
        
        obj = [objectsOrNil objectAtIndex:0];
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    KCSMetadata* o1 = obj.meta;
    KCSMetadata* o2 = [o1 copy];
    
    XCTAssertEqualObjects(o1, o2, @"equals should equal");
    XCTAssertFalse(o1 == o2, @"should be different pointers");
    
}

@end
