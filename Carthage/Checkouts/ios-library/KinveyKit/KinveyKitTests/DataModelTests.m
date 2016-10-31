//
//  DataModelTests.m
//  KinveyKit
//
//  Created by Michael Katz on 1/29/14.
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


#import "KCSTestCase.h"

#import "KinveyKit.h"
#import "KinveyDataStoreInternal.h"

#import "TestUtils2.h"

@interface TC : NSObject <KCSPersistable>
@property (nonatomic, retain) NSDictionary* dRef;
@property (nonatomic, retain) TC* enemy;
@property (nonatomic, retain) NSMutableArray* friends;
@property (nonatomic, weak) TC* this;
@property (nonatomic, retain) NSSet* setRef;
@property (nonatomic, retain) NSMutableOrderedSet* oSetRef;
@property (nonatomic, retain) NSArray* arrOfDicts;
@end

@implementation TC

- (NSDictionary *)hostToKinveyPropertyMapping
{
    return @{@"dRef":@"dRefF",@"enemy":@"enemyF",@"friends":@"friendsF",@"setRef":@"setRefF",@"oSetRef":@"oSetRefF",@"arrOfDicts":@"arrOfDictsF"};
}

+ (NSDictionary *)kinveyPropertyToCollectionMapping
{
    return @{@"enemyF":@"c",@"friendsF":@"c",@"dRefF.theRef":@"dc",@"dRefF.innerD.theRef":@"dc2",@"setRefF":@"sc",@"oSetRefF":@"sc",@"arrOfDictsF.d":@"dc"};
}

//+ (NSDictionary *)kinveyObjectBuilderOptions
//{
//    
//}
@end


@interface ARef : NSObject <KCSPersistable>
@property (nonatomic, retain) id nextRef;
@end

@interface BRef : NSObject <KCSPersistable>
@end

@implementation ARef

- (NSDictionary *)hostToKinveyPropertyMapping
{
    return @{@"nextRef":@"nextRefF"};
}
+ (NSDictionary *)kinveyPropertyToCollectionMapping
{
    return @{@"nextRefF":@"BCollection"};
}
@end


@implementation BRef
@end

@interface DataModelTests : KCSTestCase

@end

@implementation DataModelTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

KK2(update tests with KCSPersistable2 objects)

- (void)testRefs
{
    TC* obj = [[TC alloc] init];
    KCSPersistableDescription* descr = [[KCSPersistableDescription alloc] initWithKinveyKit1Object:obj collection:@"c"];
    XCTAssertNotNil(descr, @"Should have a description");
    
    NSArray* refs = descr.references;
    XCTAssertNotNil(refs, @"refs");
    KTAssertCount(7, refs);
}

- (void) testObjectGraphEmpty
{
    TC* obj = [[TC alloc] init];
    KCSPersistableDescription* descr = [[KCSPersistableDescription alloc] initWithKinveyKit1Object:obj collection:@"c"];
    NSDictionary* graph = [descr objectListFromObjects:@[]];
    
    KTAssertCount(0, graph);
}

- (void) testGraphOneObj
{
    TC* obj = [[TC alloc] init];
    KCSPersistableDescription* descr = [[KCSPersistableDescription alloc] initWithKinveyKit1Object:obj collection:@"c"];
    NSDictionary* graph = [descr objectListFromObjects:@[obj]];
    
    KTAssertCount(1, graph);
    id recoveredObj = [graph[@"c"] anyObject];
    XCTAssertEqualObjects(recoveredObj, obj, @"should get back original");
}

- (void) testGraphMultipleObj
{
    TC* obj1 = [[TC alloc] init];
    TC* obj2 = [[TC alloc] init];
    TC* obj3 = [[TC alloc] init];

    KCSPersistableDescription* descr = [[KCSPersistableDescription alloc] initWithKinveyKit1Object:obj1 collection:@"c"];
    NSDictionary* graph = [descr objectListFromObjects:@[obj1,obj2,obj3]];
    
    KTAssertCount(1, graph);
    NSSet* recoverdObjs = graph[@"c"];
    KTAssertCount(3, recoverdObjs);
    
    XCTAssertTrue([recoverdObjs containsObject:obj1], @"should get back original");
    XCTAssertTrue([recoverdObjs containsObject:obj2], @"should get back original");
    XCTAssertTrue([recoverdObjs containsObject:obj3], @"should get back original");
}

- (void) testGraphMultipleObjOneToOneSameCollection
{
    TC* obj1 = [[TC alloc] init];
    TC* obj2 = [[TC alloc] init];
    TC* obj3 = [[TC alloc] init];
    
    obj1.enemy = obj3;
    obj2.enemy = obj3;
    obj3.enemy = obj1;
    
    KCSPersistableDescription* descr = [[KCSPersistableDescription alloc] initWithKinveyKit1Object:obj1 collection:@"c"];
    NSDictionary* graph = [descr objectListFromObjects:@[obj1,obj2,obj3]];
    
    KTAssertCount(1, graph);
    NSSet* recoverdObjs = graph[@"c"];
    KTAssertCount(3, recoverdObjs);
    
    XCTAssertTrue([recoverdObjs containsObject:obj1], @"should get back original");
    XCTAssertTrue([recoverdObjs containsObject:obj2], @"should get back original");
    XCTAssertTrue([recoverdObjs containsObject:obj3], @"should get back original");
}

//- (void) testGraphMultipleObjOneToManySameCollection
//{
//    TC* obj1 = [[TC alloc] init];
//    TC* obj2 = [[TC alloc] init];
//    TC* obj3 = [[TC alloc] init];
//    
//    obj1.enemy = obj3;
//    obj2.enemy = obj3;
//    obj3.enemy = obj1;
//    
//    obj1.friends = [@[obj2,obj3] mutableCopy];
//    obj2.friends = [@[obj1] mutableCopy];
//    obj3.friends = [@[obj1,obj2] mutableCopy];
//    
//    KCSPersistableDescription* descr = [[KCSPersistableDescription alloc] initWithKinveyKit1Object:obj1 collection:@"c"];
//    NSDictionary* graph = [descr objectListFromObjects:@[obj1,obj2,obj3]];
//    
//    KTAssertCount(1, graph);
//    NSSet* recoverdObjs = graph[@"c"];
//    KTAssertCount(3, recoverdObjs);
//    
//    XCTAssertTrue([recoverdObjs containsObject:obj1], @"should get back original");
//    XCTAssertTrue([recoverdObjs containsObject:obj2], @"should get back original");
//    XCTAssertTrue([recoverdObjs containsObject:obj3], @"should get back original");
//}

//- (void) testGraphMultipleObjSelfRef
//{
//    TC* obj1 = [[TC alloc] init];
//    TC* obj2 = [[TC alloc] init];
//    TC* obj3 = [[TC alloc] init];
//    
//    obj1.enemy = obj3;
//    obj2.enemy = obj3;
//    obj3.enemy = obj1;
//    
//    obj1.friends = [@[obj2,obj3] mutableCopy];
//    obj2.friends = [@[obj1] mutableCopy];
//    obj3.friends = [@[obj1,obj2] mutableCopy];
//    
//    obj1.this = obj1;
//    obj2.this = obj2;
//    obj3.this = obj3;
//    
//    KCSPersistableDescription* descr = [[KCSPersistableDescription alloc] initWithKinveyKit1Object:obj1 collection:@"c"];
//    NSDictionary* graph = [descr objectListFromObjects:@[obj1,obj2,obj3]];
//    
//    KTAssertCount(1, graph);
//    NSSet* recoverdObjs = graph[@"c"];
//    KTAssertCount(3, recoverdObjs);
//    
//    XCTAssertTrue([recoverdObjs containsObject:obj1], @"should get back original");
//    XCTAssertTrue([recoverdObjs containsObject:obj2], @"should get back original");
//    XCTAssertTrue([recoverdObjs containsObject:obj3], @"should get back original");
//}

//- (void) testRefInDictionary
//{
//    TC* obj1 = [[TC alloc] init];
//    TC* obj2 = [[TC alloc] init];
//    TC* obj3 = [[TC alloc] init];
//    
//    obj1.enemy = obj3;
//    obj2.enemy = obj3;
//    obj3.enemy = obj1;
//    
//    obj1.friends = [@[obj2,obj3] mutableCopy];
//    obj2.friends = [@[obj1] mutableCopy];
//    obj3.friends = [@[obj1,obj2] mutableCopy];
//    
//    obj1.this = obj1;
//    obj2.this = obj2;
//    obj3.this = obj3;
//    
//    TC* ref = [[TC alloc] init];
//    obj1.dRef = @{@"theRef":ref};
//    
//    KCSPersistableDescription* descr = [[KCSPersistableDescription alloc] initWithKinveyKit1Object:obj1 collection:@"c"];
//    NSDictionary* graph = [descr objectListFromObjects:@[obj1,obj2,obj3]];
//    
//    KTAssertCount(2, graph);
//    NSSet* recoverdObjs = graph[@"c"];
//    KTAssertCount(3, recoverdObjs);
//    
//    NSSet* refObjs = graph[@"dc"];
//    KTAssertCount(1, refObjs);
//    
//    XCTAssertTrue([recoverdObjs containsObject:obj1], @"should get back original");
//    XCTAssertTrue([recoverdObjs containsObject:obj2], @"should get back original");
//    XCTAssertTrue([recoverdObjs containsObject:obj3], @"should get back original");
//    
//    XCTAssertTrue([refObjs containsObject:ref], @"should have the ref in the second collection");
//}

//- (void) testRefInDictionaryTwoLevels
//{
//    TC* obj1 = [[TC alloc] init];
//    TC* obj2 = [[TC alloc] init];
//    TC* obj3 = [[TC alloc] init];
//    
//    obj1.enemy = obj3;
//    obj2.enemy = obj3;
//    obj3.enemy = obj1;
//    
//    obj1.friends = [@[obj2,obj3] mutableCopy];
//    obj2.friends = [@[obj1] mutableCopy];
//    obj3.friends = [@[obj1,obj2] mutableCopy];
//    
//    obj1.this = obj1;
//    obj2.this = obj2;
//    obj3.this = obj3;
//    
//    TC* ref = [[TC alloc] init];
//    TC* innerRef = [[TC alloc] init];
//    obj1.dRef = @{@"theRef":ref,@"innerD":@{@"theRef":innerRef}};
//    
//    KCSPersistableDescription* descr = [[KCSPersistableDescription alloc] initWithKinveyKit1Object:obj1 collection:@"c"];
//    NSDictionary* graph = [descr objectListFromObjects:@[obj1,obj2,obj3]];
//    KTAssertCount(3, graph);
//    
//    NSSet* recoverdObjs = graph[@"c"];
//    KTAssertCount(3, recoverdObjs);
//    
//    NSSet* refObjs = graph[@"dc"];
//    KTAssertCount(1, refObjs);
//
//    NSSet* refObjs2 = graph[@"dc2"];
//    KTAssertCount(1, refObjs);
//
//    
//    XCTAssertTrue([recoverdObjs containsObject:obj1], @"should get back original");
//    XCTAssertTrue([recoverdObjs containsObject:obj2], @"should get back original");
//    XCTAssertTrue([recoverdObjs containsObject:obj3], @"should get back original");
//    
//    XCTAssertTrue([refObjs containsObject:ref], @"should have the ref in the second collection");
//    XCTAssertTrue([refObjs2 containsObject:innerRef], @"should have the ref in the third collection");
//}

//- (void) testRefInSet
//{
//    TC* obj1 = [[TC alloc] init];
//    TC* obj2 = [[TC alloc] init];
//    TC* obj3 = [[TC alloc] init];
//    
//    obj1.enemy = obj3;
//    obj2.enemy = obj3;
//    obj3.enemy = obj1;
//    
//    obj1.friends = [@[obj2,obj3] mutableCopy];
//    obj2.friends = [@[obj1] mutableCopy];
//    obj3.friends = [@[obj1,obj2] mutableCopy];
//    
//    obj1.this = obj1;
//    obj2.this = obj2;
//    obj3.this = obj3;
//    
//    TC* ref = [[TC alloc] init];
//    TC* innerRef = [[TC alloc] init];
//    obj1.dRef = @{@"theRef":ref,@"innerD":@{@"theRef":innerRef}};
//    
//    obj1.setRef = [NSSet setWithObjects:ref, innerRef, nil];
//    
//    KCSPersistableDescription* descr = [[KCSPersistableDescription alloc] initWithKinveyKit1Object:obj1 collection:@"c"];
//    NSDictionary* graph = [descr objectListFromObjects:@[obj1,obj2,obj3]];
//    KTAssertCount(4, graph);
//    
//    NSSet* recoverdObjs = graph[@"c"];
//    KTAssertCount(3, recoverdObjs);
//    
//    NSSet* refObjs = graph[@"dc"];
//    KTAssertCount(1, refObjs);
//    
//    NSSet* refObjs2 = graph[@"dc2"];
//    KTAssertCount(1, refObjs)
//    
//    NSSet* setObjs = graph[@"sc"];
//    KTAssertCount(2, setObjs);
//    
//    XCTAssertTrue([recoverdObjs containsObject:obj1], @"should get back original");
//    XCTAssertTrue([recoverdObjs containsObject:obj2], @"should get back original");
//    XCTAssertTrue([recoverdObjs containsObject:obj3], @"should get back original");
//    
//    XCTAssertTrue([refObjs containsObject:ref], @"should have the ref in the second collection");
//    XCTAssertTrue([refObjs2 containsObject:innerRef], @"should have the ref in the third collection");
//    XCTAssertTrue([setObjs containsObject:ref], @"Should have ref in the set collection");
//    XCTAssertTrue([setObjs containsObject:innerRef], @"Should have ref in the set collection");
//}

//- (void) testRefInOrderedSet
//{
//    TC* obj1 = [[TC alloc] init];
//    TC* obj2 = [[TC alloc] init];
//    TC* obj3 = [[TC alloc] init];
//    
//    obj1.enemy = obj3;
//    obj2.enemy = obj3;
//    obj3.enemy = obj1;
//    
//    obj1.friends = [@[obj2,obj3] mutableCopy];
//    obj2.friends = [@[obj1] mutableCopy];
//    obj3.friends = [@[obj1,obj2] mutableCopy];
//    
//    obj1.this = obj1;
//    obj2.this = obj2;
//    obj3.this = obj3;
//    
//    TC* ref = [[TC alloc] init];
//    TC* innerRef = [[TC alloc] init];
//    obj1.dRef = @{@"theRef":ref,@"innerD":@{@"theRef":innerRef}};
//    
//    obj1.setRef = [NSSet setWithObjects:ref, innerRef, nil];
//    obj2.oSetRef = [NSMutableOrderedSet orderedSetWithObjects:obj1, obj2, obj3, nil];
//    
//    KCSPersistableDescription* descr = [[KCSPersistableDescription alloc] initWithKinveyKit1Object:obj1 collection:@"c"];
//    NSDictionary* graph = [descr objectListFromObjects:@[obj1,obj2,obj3]];
//    KTAssertCount(4, graph);
//    
//    NSSet* recoverdObjs = graph[@"c"];
//    KTAssertCount(3, recoverdObjs);
//    
//    NSSet* refObjs = graph[@"dc"];
//    KTAssertCount(1, refObjs);
//    
//    NSSet* refObjs2 = graph[@"dc2"];
//    KTAssertCount(1, refObjs)
//    
//    NSSet* setObjs = graph[@"sc"];
//    KTAssertCount(5, setObjs);
//    
//    XCTAssertTrue([recoverdObjs containsObject:obj1], @"should get back original");
//    XCTAssertTrue([recoverdObjs containsObject:obj2], @"should get back original");
//    XCTAssertTrue([recoverdObjs containsObject:obj3], @"should get back original");
//    
//    XCTAssertTrue([refObjs containsObject:ref], @"should have the ref in the second collection");
//    XCTAssertTrue([refObjs2 containsObject:innerRef], @"should have the ref in the third collection");
//
//    XCTAssertTrue([setObjs containsObject:ref], @"Should have ref in the set collection");
//    XCTAssertTrue([setObjs containsObject:innerRef], @"Should have ref in the set collection");
//    XCTAssertTrue([setObjs containsObject:obj1],  @"Should have ref in the set collection");
//    XCTAssertTrue([setObjs containsObject:obj2],  @"Should have ref in the set collection");
//    XCTAssertTrue([setObjs containsObject:obj3],  @"Should have ref in the set collection");
//}

//- (void) testRefInArrayInDictionary
//{
//    TC* obj1 = [[TC alloc] init];
//    TC* obj2 = [[TC alloc] init];
//    TC* obj3 = [[TC alloc] init];
//    
//    obj1.enemy = obj3;
//    obj2.enemy = obj3;
//    obj3.enemy = obj1;
//    
//    obj1.friends = [@[obj2,obj3] mutableCopy];
//    obj2.friends = [@[obj1] mutableCopy];
//    obj3.friends = [@[obj1,obj2] mutableCopy];
//    
//    obj1.this = obj1;
//    obj2.this = obj2;
//    obj3.this = obj3;
//    
//    TC* ref = [[TC alloc] init];
//    TC* a1 = [[TC alloc] init];
//    TC* a2 = [[TC alloc] init];
//    obj1.dRef = @{@"theRef":ref,@"innerD":@{@"theRef":@[a1,a2]}};
//    
//    KCSPersistableDescription* descr = [[KCSPersistableDescription alloc] initWithKinveyKit1Object:obj1 collection:@"c"];
//    NSDictionary* graph = [descr objectListFromObjects:@[obj1,obj2,obj3]];
//    KTAssertCount(3, graph);
//    
//    NSSet* recoverdObjs = graph[@"c"];
//    KTAssertCount(3, recoverdObjs);
//    
//    NSSet* refObjs = graph[@"dc"];
//    KTAssertCount(1, refObjs);
//    NSSet* refObjs2 = graph[@"dc2"];
//    KTAssertCount(2, refObjs2);
//    
//    XCTAssertTrue([recoverdObjs containsObject:obj1], @"should get back original");
//    XCTAssertTrue([recoverdObjs containsObject:obj2], @"should get back original");
//    XCTAssertTrue([recoverdObjs containsObject:obj3], @"should get back original");
//    
//    XCTAssertTrue([refObjs containsObject:ref], @"should have the ref in the second collection");
//    XCTAssertTrue([refObjs2 containsObject:a1], @"should have the ref in the dict array collection");
//    XCTAssertTrue([refObjs2 containsObject:a2], @"should have the ref in the dict array collection");
//}

//- (void) testRefDictionaryInArray
//{
//    TC* obj1 = [[TC alloc] init];
//    TC* a1 = [[TC alloc] init];
//    TC* a2 = [[TC alloc] init];
//    
//    obj1.arrOfDicts = @[@{@"d":a1},@{@"d":a2}];
//    
//    KCSPersistableDescription* descr = [[KCSPersistableDescription alloc] initWithKinveyKit1Object:obj1 collection:@"c"];
//    NSDictionary* graph = [descr objectListFromObjects:@[obj1]];
//    KTAssertCount(2, graph);
//    
//    NSSet* recoverdObjs = graph[@"c"];
//    KTAssertCount(1, recoverdObjs);
//    
//    NSSet* refObjs = graph[@"dc"];
//    KTAssertCount(2, refObjs);
//    
//    XCTAssertTrue([recoverdObjs containsObject:obj1], @"should get back original");
//    
//    XCTAssertTrue([refObjs containsObject:a1], @"should have the ref in the second collection");
//    XCTAssertTrue([refObjs containsObject:a2], @"should have the ref in the second collection");
//}

//- (void) testTwoLevelRef
//{
//    TC* lvl1 = [[TC alloc] init];
//    ARef* lvl2 = [[ARef alloc] init];
//    BRef* lvl3 = [[BRef alloc] init];
//    
//    lvl1.setRef = [NSSet setWithObjects:lvl2, nil];
//    lvl2.nextRef = lvl3;
//    
//    KCSPersistableDescription* descr = [[KCSPersistableDescription alloc] initWithKinveyKit1Object:lvl1 collection:@"c"];
//    NSDictionary* graph = [descr objectListFromObjects:@[lvl1]];
//    KTAssertCount(3, graph);
//    
//    NSSet* recoverdObjs = graph[@"c"];
//    KTAssertCount(1, recoverdObjs);
//    
//    NSSet* lvl1Objs = graph[@"sc"];
//    KTAssertCount(1, lvl1Objs);
//
//    NSSet* lvl2Objs = graph[@"BCollection"];
//    KTAssertCount(1, lvl2Objs)
//    
//    XCTAssertTrue([recoverdObjs containsObject:lvl1], @"should get back original");
//    
//    XCTAssertTrue([lvl1Objs containsObject:lvl2], @"should have the ref in the second collection");
//    XCTAssertTrue([lvl2Objs containsObject:lvl3], @"should have the ref in the third collection");
//}

//- (void) testRefToUserCollection
//{
//    KTNIY
//}
//
//- (void) testUserHasRef
//{
//    KTNIY
//}
//
//- (void) testRefToFile
//{
//    KTNIY
//}
//
//- (void) testFileHasRef
//{
//    KTNIY
//}
@end
