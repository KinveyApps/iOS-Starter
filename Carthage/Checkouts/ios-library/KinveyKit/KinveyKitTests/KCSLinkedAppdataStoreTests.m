//
//  KCSLinkedDataStoreTests.m
//  KinveyKit
//
//  Created by Michael Katz on 5/29/12.
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


#import "KCSLinkedAppdataStoreTests.h"

#import <KinveyKit/KinveyKit.h>

#import "KCSFile.h"
#import "KCSLinkedAppdataStore.h"

#import "ASTTestClass.h"

#import "TestUtils.h"
#import "KCSHiddenMethods.h"


@interface TSSMessage : NSObject <KCSPersistable>
@property (nonatomic, copy) NSString* objId;
@property (nonatomic, copy) NSMutableArray* recipients;
@end

@implementation TSSMessage

- (NSDictionary *)hostToKinveyPropertyMapping
{
    return @{@"objId":KCSEntityKeyId, @"recipients":@"recipients"};
}

+ (NSDictionary *)kinveyPropertyToCollectionMapping
{
    return @{@"recipients":KCSUserCollectionName};
}
@end

static NSString* _collectionName;

@interface LinkedTestClass : ASTTestClass
@property (nonatomic, retain) id resource;
@end

@implementation LinkedTestClass

- (NSDictionary *)hostToKinveyPropertyMapping
{
    NSDictionary *map = [super hostToKinveyPropertyMapping];
    NSMutableDictionary* newmap = [NSMutableDictionary dictionaryWithDictionary:map];
    newmap[@"resource"] = @"resource";
    return newmap;
}

+ (NSDictionary*) kinveyPropertyToCollectionMapping
{
    return @{@"resource" : KCSFileStoreCollectionName};
}

@end

@interface LinkedTestClassWithMeta : LinkedTestClass
@property (nonatomic, retain) KCSMetadata* meta;
@end
@implementation LinkedTestClassWithMeta

- (NSDictionary *)hostToKinveyPropertyMapping
{
    NSDictionary *map = [super hostToKinveyPropertyMapping];
    NSMutableDictionary* newmap = [NSMutableDictionary dictionaryWithDictionary:map];
    newmap[@"meta"] = KCSEntityKeyMetadata;
    return newmap;
}


@end

@interface UserRefTestClass : LinkedTestClass
@property (nonatomic, retain) KCSUser* auser;

@end

@implementation UserRefTestClass

- (NSDictionary *)hostToKinveyPropertyMapping
{
    NSDictionary *map = [super hostToKinveyPropertyMapping];
    NSMutableDictionary* newmap = [NSMutableDictionary dictionaryWithDictionary:map];
    [newmap setValue:@"auserK" forKey:@"auser"];
    return newmap;
}

- (NSArray *)referenceKinveyPropertiesOfObjectsToSave
{
    return @[@"auserK"];
}

+ (NSDictionary*) kinveyPropertyToCollectionMapping
{
    NSMutableDictionary* map = [[super kinveyPropertyToCollectionMapping] mutableCopy];
    [map addEntriesFromDictionary:@{ @"auserK" : KCSUserCollectionName}];
    return map;
}
@end

@interface ReffedTestClass : LinkedTestClass
@property (nonatomic, retain) LinkedTestClass* other;
@property (nonatomic, retain) NSArray* arrayOfOthers;
@property (nonatomic, retain) NSSet* setOfOthers;
@property (nonatomic, retain) ReffedTestClass* thisOther;
@end
@implementation ReffedTestClass
@synthesize other, arrayOfOthers;

- (NSDictionary *)hostToKinveyPropertyMapping
{
    NSDictionary *map = [super hostToKinveyPropertyMapping];
    NSMutableDictionary* newmap = [NSMutableDictionary dictionaryWithDictionary:map];
    [newmap setValue:@"otherK" forKey:@"other"];
    [newmap setValue:@"arrayOfOthersK" forKey:@"arrayOfOthers"];
    [newmap setValue:@"setOfOthersK" forKey:@"setOfOthers"];
    [newmap setValue:@"thisOtherK" forKey:@"thisOther"];
    return newmap;
}

- (NSArray *)referenceKinveyPropertiesOfObjectsToSave
{
    return @[@"otherK",@"arrayOfOthersK",@"setOfOthersK",@"thisOtherK"];
}

+ (NSDictionary*) kinveyPropertyToCollectionMapping
{
    NSMutableDictionary* map = [[super kinveyPropertyToCollectionMapping] mutableCopy];
    [map addEntriesFromDictionary:@{ @"otherK" : @"OtherCollection", @"arrayOfOthersK" : @"OtherCollection", @"setOfOthersK" : @"OtherCollection", @"thisOtherK" : _collectionName}];
    return map;
}

+ (NSDictionary *)kinveyObjectBuilderOptions
{
    return @{KCS_REFERENCE_MAP_KEY : @{@"arrayOfOthers" : [LinkedTestClass class], @"setOfOthers" : [LinkedTestClass class]}};
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%i>", self.objCount];
}
@end

@interface NestingRefClass : LinkedTestClass
@property (nonatomic, retain) ReffedTestClass* relatedObject;
@end
@implementation NestingRefClass
@synthesize relatedObject;

- (NSDictionary *)hostToKinveyPropertyMapping
{
    NSDictionary *map = [super hostToKinveyPropertyMapping];
    NSMutableDictionary* newmap = [NSMutableDictionary dictionaryWithDictionary:map];
    [newmap setValue:@"relatedObject" forKey:@"relatedObject"];
    return newmap;
}

- (NSArray *)referenceKinveyPropertiesOfObjectsToSave
{
    return @[@"relatedObject"];
}

+ (NSDictionary*) kinveyPropertyToCollectionMapping
{
    NSMutableDictionary* map = [[super kinveyPropertyToCollectionMapping] mutableCopy];
    [map addEntriesFromDictionary:@{ @"relatedObject" : @"NestedOtherCollection", @"relatedObject.otherK" : @"OtherCollection"}];
    return map;
}

@end

@interface NoSaveTestClass : LinkedTestClass
@property (nonatomic, retain) ReffedTestClass* relatedObject;
@end
@implementation NoSaveTestClass
@synthesize relatedObject;

- (NSDictionary *)hostToKinveyPropertyMapping
{
    NSDictionary *map = [super hostToKinveyPropertyMapping];
    NSMutableDictionary* newmap = [NSMutableDictionary dictionaryWithDictionary:map];
    [newmap setValue:@"relatedObject" forKey:@"relatedObject"];
    return newmap;
}

+ (NSDictionary*) kinveyPropertyToCollectionMapping
{
    NSMutableDictionary* map = [[super kinveyPropertyToCollectionMapping] mutableCopy];
    [map addEntriesFromDictionary:@{ @"relatedObject" : @"NestedOtherCollection", @"relatedObject.otherK" : @"OtherCollection"}];
    return map;
}

@end


@implementation KCSLinkedAppdataStoreTests


- (void) setUp
{
    BOOL loaded = [TestUtils setUpKinveyUnittestBackend:self];
    XCTAssertTrue(loaded, @"should be loaded");
    
    _collection = [[KCSCollection alloc] init];
    _collection.collectionName = [NSString stringWithFormat:@"testObjects%i", arc4random()];
    _collectionName =  _collection.collectionName;
    _collection.objectTemplate = [LinkedTestClass class];
}

- (UIImage*) makeImage
{
    UIGraphicsBeginImageContext(CGSizeMake(500, 500));
    UIBezierPath* path = [UIBezierPath bezierPathWithRect:CGRectMake(50, 50, 400, 400)];
    [[UIColor yellowColor] setFill];
    [path fill];
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void) testOneLinkedFile
{
    LinkedTestClass* obj = [[LinkedTestClass alloc] init];
    obj.objDescription = @"Yaaay!";
    obj.resource = [self makeImage];
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:_collection options:nil];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        LinkedTestClass* obj = objectsOrNil[0];
        XCTAssertNotNil(obj, @"should not be nil obj");
        XCTAssertNotNil(obj.resource, @"should still have an image");
        XCTAssertTrue([obj.resource isKindOfClass:[UIImage class]], @"Should still be an image");
        XCTAssertTrue([NSThread isMainThread]);
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testTwoFiles //TODO: check file name matches object
{
    LinkedTestClass* obj1 = [[LinkedTestClass alloc] init];
    obj1.objDescription = @"test two-1";
    obj1.resource = [self makeImage];
    
    LinkedTestClass* obj2 = [[LinkedTestClass alloc] init];
    obj2.objDescription = @"test two-2";
    obj2.resource = [self makeImage];
    
    NSMutableArray* progArray = [NSMutableArray array];
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:_collection options:nil];
    [store saveObject:[NSArray arrayWithObjects:obj1, obj2,  nil] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        XCTAssertEqual(2, (int) [objectsOrNil count], @"Should have saved two objects");
        XCTAssertTrue([NSThread isMainThread]);
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
        
        NSLog(@"-- %f",percentComplete);
        [progArray addObject:[NSNumber numberWithDouble:percentComplete]];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    for (int i = 1; i< progArray.count; i++) {
        XCTAssertTrue([progArray[i] doubleValue] >= [progArray[i-1] doubleValue], @"progress should be monotonically increasing");
        XCTAssertTrue([progArray[i] doubleValue] <= 1.0, @"progres should be 0 to 1");
    }
}

- (void) testLoad
{
    __block LinkedTestClass* obj = [[LinkedTestClass alloc] init];
    obj.objDescription = @"test load";
    obj.resource = [self makeImage];
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:_collection options:nil];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        LinkedTestClass* savedObj = [objectsOrNil objectAtIndex:0];
        XCTAssertNotNil(savedObj.resource, @"need a resource filled out");
        XCTAssertTrue([savedObj.resource isKindOfClass:[UIImage class]], @"expecting an UIImage out");
        XCTAssertTrue([NSThread isMainThread]);
        obj = [objectsOrNil objectAtIndex:0];
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak __block XCTestExpectation* expectationLoad = [self expectationWithDescription:@"load"];
    [store loadObjectWithID:obj.objId withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        //TODO
//        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        
        LinkedTestClass* loaded = [objectsOrNil objectAtIndex:0];
        //TODO
//        XCTAssertNotNil(loaded.resource, @"need a resource filled out");
//        XCTAssertTrue([loaded.resource isKindOfClass:[UIImage class]], @"expecting an UIImage out");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationLoad fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationLoad = nil;
    }];
}

- (void) testLoadCancel
{
    __block LinkedTestClass* obj = [[LinkedTestClass alloc] init];
    obj.objDescription = @"test load";
    obj.resource = [self makeImage];
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:_collection options:nil];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        LinkedTestClass* savedObj = [objectsOrNil objectAtIndex:0];
        XCTAssertNotNil(savedObj.resource, @"need a resource filled out");
        XCTAssertTrue([savedObj.resource isKindOfClass:[UIImage class]], @"expecting an UIImage out");
        XCTAssertTrue([NSThread isMainThread]);
        obj = [objectsOrNil objectAtIndex:0];
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak __block XCTestExpectation* expectationLoad = [self expectationWithDescription:@"load"];
    KCSRequest* request = [store loadObjectWithID:obj.objId
                              withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil)
    {
        XCTFail();
        
        [expectationLoad fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    
    XCTAssertFalse(request.isCancelled);
    
    request.cancellationBlock = ^{
        [expectationLoad fulfill];
    };
    
    [request cancel];
    
    XCTAssertTrue(request.isCancelled);
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationLoad = nil;
    }];
}

- (void) testLinkedFilePreservesObjectMetadata
{
    __block LinkedTestClassWithMeta* obj = [[LinkedTestClassWithMeta alloc] init];
    obj.objDescription = @"test load";
    obj.resource = [self makeImage];
    obj.meta = [[KCSMetadata alloc] init];
    [obj.meta setGloballyReadable:YES];
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:_collection options:nil];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        XCTAssertNil(errorOrNil, @"should not be any errors, %@", errorOrNil);
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        XCTAssertTrue([NSThread isMainThread]);
        
        obj = [objectsOrNil objectAtIndex:0];
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    KCSAppdataStore* metaStore = [KCSAppdataStore storeWithCollection:[KCSCollection fileMetadataCollection] options:nil];
    //NOTE: this is highly tied to the implmentation!, not necessary for this test
    NSString* fileId = [NSString stringWithFormat:@"%@-%@-%@",_collectionName,obj.objId,@"resource"];
    
    __weak XCTestExpectation* expectationLoad = [self expectationWithDescription:@"load"];
    
    [metaStore loadObjectWithID:fileId withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        //TODO
//        STAssertNoError;
//        KTAssertCount(1, objectsOrNil);
        KCSFile* thefile = objectsOrNil[0];
        KCSMetadata* filesMetadata = thefile.metadata;
        //TODO
//        XCTAssertNotNil(filesMetadata, @"Should have metadata");
//        XCTAssertTrue(filesMetadata.isGloballyReadable, @"Should have inherited global write");
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationLoad fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:nil];
}


- (void) testWithQuery
{
    __block LinkedTestClass* obj = [[LinkedTestClass alloc] init];
    obj.objDescription = @"test load";
    obj.resource = [self makeImage];
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:_collection options:nil];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        XCTAssertNil(errorOrNil, @"should not be any errors, %@", errorOrNil);
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        XCTAssertTrue([NSThread isMainThread]);
        
        obj = [objectsOrNil objectAtIndex:0];
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak XCTestExpectation* expectationQuery = [self expectationWithDescription:@"query"];
    [store queryWithQuery:[KCSQuery queryOnField:KCSEntityKeyId withExactMatchForValue:obj.kinveyObjectId] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        //TODO
//        XCTAssertNil(errorOrNil, @"should not be any errors, %@", errorOrNil);
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        
        LinkedTestClass* loaded = [objectsOrNil objectAtIndex:0];
        //TODO
//        XCTAssertNotNil(loaded.resource, @"need a resource filled out");
//        XCTAssertTrue([loaded.resource isKindOfClass:[UIImage class]], @"expecting an UIImage out");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationQuery fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
}
//TODO: TEST1000, TEST MAGNITUTDE DIFFERENCE

LinkedTestClass* randomTestClass(NSString* description)
{
    LinkedTestClass* ref = [[LinkedTestClass alloc] init];
    ref.objDescription = description;
    ref.objCount = arc4random();
    return ref;
}
#define TestClass(x) randomTestClass([NSString stringWithFormat:@"%s - %i",__PRETTY_FUNCTION__,x])


- (void) testSavingWithOneKinveyRef
{ 
    LinkedTestClass* ref = TestClass(0);
    
    ReffedTestClass* obj = [[ReffedTestClass alloc] init];
    obj.objDescription = @"Yaaay!";
    obj.other = ref;

    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    __block double done = -1;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        ReffedTestClass* ret = [objectsOrNil objectAtIndex:0];
        LinkedTestClass* newRef = ret.other;
        XCTAssertNotNil(newRef, @"should be a valid object");
        //TODO
//        XCTAssertEqual(newRef.objCount, ref.objCount, @"Should be the same object back");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingWithOneKinveyRef: percentcomplete:%f", percentComplete);
        XCTAssertTrue(percentComplete > done, @"should be monotonically increasing");
        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        done = percentComplete;
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak XCTestExpectation* expectationLoad = [self expectationWithDescription:@"load"];
    done = -1;
    
    [store loadObjectWithID:[obj kinveyObjectId] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        ReffedTestClass* ret = [objectsOrNil objectAtIndex:0];
        LinkedTestClass* newRef = ret.other;
        //TODO
//        XCTAssertEqual(newRef.objCount, ref.objCount, @"Should be the same object back");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationLoad fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingWithOneKinveyRef: percentcomplete:%f", percentComplete);
        XCTAssertTrue(percentComplete > done, @"should be monotonically increasing");
        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        done = percentComplete;
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testSavingWithArrayOfKivneyRef
{
    LinkedTestClass* ref1 = TestClass(1);
    LinkedTestClass* ref2 = TestClass(2);
    
    ReffedTestClass* obj = [[ReffedTestClass alloc] init];
    obj.objDescription = @"Save array of References";
    obj.arrayOfOthers = @[ref1, ref2];
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    __block double done = -1;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        ReffedTestClass* ret = [objectsOrNil objectAtIndex:0];
        LinkedTestClass* newRef = [ret.arrayOfOthers objectAtIndex:0];
        //TODO
//        XCTAssertEqual(newRef.objCount, ref1.objCount, @"Should be the same object back");
        newRef = [ret.arrayOfOthers objectAtIndex:1];
        //TODO
//        XCTAssertEqual(newRef.objCount, ref2.objCount, @"Should be the same object back");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingWithArrayOfKivneyRef: percentcomplete:%f", percentComplete);
        XCTAssertTrue(percentComplete > done, @"should be monotonically increasing");
        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        done = percentComplete;
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak XCTestExpectation* expectationLoad = [self expectationWithDescription:@"load"];
    done = -1;
    
    [store loadObjectWithID:[obj kinveyObjectId] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        ReffedTestClass* ret = [objectsOrNil objectAtIndex:0];
        XCTAssertEqual((int) [ret.arrayOfOthers count], (int)2, @"Should have two saved objects");
        LinkedTestClass* newRef = [ret.arrayOfOthers objectAtIndex:0];
        //TODO
//        XCTAssertEqual(newRef.objCount, ref1.objCount, @"Should be the same object back");
        newRef = [ret.arrayOfOthers objectAtIndex:1];
        //TODO
//        XCTAssertEqual(newRef.objCount, ref2.objCount, @"Should be the same object back");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationLoad fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingWithOneKinveyRef: percentcomplete:%f", percentComplete);
        XCTAssertTrue(percentComplete > done, @"should be monotonically increasing");
        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        done = percentComplete;
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testSavingArrayOfTopRefs
{
    LinkedTestClass* ref1 = TestClass(1);
    LinkedTestClass* ref2 = TestClass(2);
    LinkedTestClass* ref3 = TestClass(3);
    
    ReffedTestClass* obj1 = [[ReffedTestClass alloc] init];
    obj1.objDescription = @"Save array of arrays - 1";
    obj1.other = ref1;
    obj1.arrayOfOthers = @[ref2, ref3];
    obj1.objCount = 1;
    
    ReffedTestClass* obj2 = [[ReffedTestClass alloc] init];
    obj2.objDescription = @"Save array of arrays - 2";
    obj2.other = ref1;
    obj2.arrayOfOthers = @[ref2, ref3];
    obj2.objCount = 2;

    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    __block double done = -1;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    [store saveObject:@[obj1, obj2] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        XCTAssertEqual((int) [objectsOrNil count], (int) 2, @"should have saved two objects");
        XCTAssertTrue([objectsOrNil containsObject:obj1], @"should get our object back");
        XCTAssertTrue([objectsOrNil containsObject:obj2], @"should get our object back");

        ReffedTestClass* ret = obj1;
        LinkedTestClass* newRef = [ret.arrayOfOthers objectAtIndex:0];
        //TODO
//        XCTAssertEqual(newRef.objCount, ref2.objCount, @"Should be the same object back");
        newRef = [ret.arrayOfOthers objectAtIndex:1];
        //TODO
//        XCTAssertEqual(newRef.objCount, ref3.objCount, @"Should be the same object back");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        XCTAssertTrue(percentComplete >= done, @"should be monotonically increasing");
        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        done = percentComplete;
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];

    __weak XCTestExpectation* expectationLoad = [self expectationWithDescription:@"load"];
    done = -1;
    
    [store loadObjectWithID:@[[obj1 kinveyObjectId],[obj2 kinveyObjectId]] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        if (objectsOrNil.count > 0) {
            ReffedTestClass* ret = objectsOrNil[0];
            XCTAssertEqual((int) [ret.arrayOfOthers count], (int)2, @"Should have two saved objects");
            LinkedTestClass* newRef = ret.arrayOfOthers[0];
            XCTAssertEqual(newRef.objCount, ref2.objCount, @"Should be the same object back");
            newRef = [ret.arrayOfOthers objectAtIndex:1];
            XCTAssertEqual(newRef.objCount, ref3.objCount, @"Should be the same object back");
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationLoad fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingWithOneKinveyRef: percentcomplete:%f", percentComplete);
        XCTAssertTrue(percentComplete > done, @"should be monotonically increasing");
        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        done = percentComplete;
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];

}

- (void) testSavingWithSetOfKivneyRef
{
    LinkedTestClass* ref1 = TestClass(1);
    LinkedTestClass* ref2 = TestClass(2);
    
    ReffedTestClass* obj = [[ReffedTestClass alloc] init];
    obj.objDescription = @"Save array of References";
    obj.setOfOthers = [NSSet setWithArray:@[ref1, ref2]];
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    __block double done = -1;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        //TODO
//        ReffedTestClass* ret = [objectsOrNil objectAtIndex:0];
//        LinkedTestClass* newRef = [ret.setOfOthers anyObject];
//        XCTAssertTrue([newRef isKindOfClass:[LinkedTestClass class]], @"Should get a TestClass back");
//        XCTAssertTrue([newRef.objDescription hasPrefix:prefix], @"Should get our testclass back");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingWithArrayOfKivneyRef: percentcomplete:%f", percentComplete);
        XCTAssertTrue(percentComplete > done, @"should be monotonically increasing");
        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        done = percentComplete;
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak XCTestExpectation* expectationLoad = [self expectationWithDescription:@"load"];
    done = -1;
    
    [store loadObjectWithID:[obj kinveyObjectId] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        ReffedTestClass* ret = [objectsOrNil objectAtIndex:0];
        LinkedTestClass* newRef = [ret.setOfOthers anyObject];
        //TODO
//        XCTAssertTrue([newRef isKindOfClass:[LinkedTestClass class]], @"Should get a TestClass back");
//        XCTAssertTrue([newRef.objDescription hasPrefix:prefix], @"Should get our testclass back");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationLoad fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingWithOneKinveyRef: percentcomplete:%f", percentComplete);
        XCTAssertTrue(percentComplete > done, @"should be monotonically increasing");
        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        done = percentComplete;
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testRefsWithQuery
{
    LinkedTestClass* ref1 = TestClass(1);
    LinkedTestClass* ref2 = TestClass(2);
    LinkedTestClass* ref3 = TestClass(3);
    
    ReffedTestClass* obj1 = [[ReffedTestClass alloc] init];
    obj1.objDescription = @"Test with a query - 1";
    obj1.other = ref1;
    obj1.arrayOfOthers = @[ref2, [NSNull null]];
    
    ReffedTestClass* obj2 = [[ReffedTestClass alloc] init];
    obj2.objDescription = @"Test with a query - 2";
    obj2.other = ref1;
    obj2.arrayOfOthers = @[ref2, ref3];
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    __block double done = -1;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    [store saveObject:@[obj1, obj2] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        XCTAssertEqual((int) [objectsOrNil count], (int) 2, @"should have saved two objects");
        XCTAssertTrue([objectsOrNil containsObject:obj1], @"should get our object back");
        XCTAssertTrue([objectsOrNil containsObject:obj2], @"should get our object back");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        XCTAssertTrue(percentComplete >= done, @"should be monotonically increasing");
        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        done = percentComplete;
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak XCTestExpectation* expectationQuery = [self expectationWithDescription:@"query"];
    done = -1;
    
    KCSQuery* query = [KCSQuery queryOnField:@"objDescription" withRegex:@"^Test with.*1"];
    [store queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
//        XCTAssertEqual((int) [objectsOrNil count], (int) 1, @"should have loaded just one objects");
        
        XCTAssertTrue([NSThread isMainThread]);

        [expectationQuery fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        XCTAssertTrue(percentComplete > done, @"should be monotonically increasing");
        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        done = percentComplete;
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
};

- (void) testTwoAtSameLevel
{
    ReffedTestClass* obj1 = [[ReffedTestClass alloc] init];
    obj1.objDescription = @"Test with intradependence - 1";
    
    ReffedTestClass* obj2 = [[ReffedTestClass alloc] init];
    obj2.objDescription = @"Test with intradependence - 2";
    obj2.thisOther = obj1;

    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    __block double done = -1;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    [store saveObject:@[obj1,obj2] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        XCTAssertEqual((int) [objectsOrNil count], (int) 2, @"should have saved two objects");
        XCTAssertTrue([objectsOrNil containsObject:obj1], @"should get our object back");
        XCTAssertTrue([objectsOrNil containsObject:obj2], @"should get our object back");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        XCTAssertTrue(percentComplete >= done, @"should be monotonically increasing");
        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        done = percentComplete;
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
 
    
    __weak XCTestExpectation* expectationQuery = [self expectationWithDescription:@"query"];
    done = -1;
    
    KCSQuery* query = [KCSQuery query];
    [store queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        XCTAssertEqual((int) [objectsOrNil count], (int) 2, @"should have loaded just one objects");
        [objectsOrNil enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString* thisId = [obj objId];
            NSArray* arr = @[obj1.objId, obj2.objId];
            BOOL inArray = [arr containsObject:thisId];
            XCTAssertTrue(inArray, @"%@ should be in the return: %@",thisId, arr);
        }];
        //TODO
//        XCTAssertEqualObjects(obj2.thisOther.objId, obj1.objId, @"Should get back the original reference object");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationQuery fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        XCTAssertTrue(percentComplete > done, @"should be monotonically increasing");
        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        done = percentComplete;
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];

}

//same test as above, but in reverse order, so the owning object is saved before the contained object
- (void) testTwoAtSameLevelReverseOrder
{
    ReffedTestClass* obj1 = [[ReffedTestClass alloc] init];
    obj1.objDescription = @"Test with intradependence,rev - 1";
    
    ReffedTestClass* obj2 = [[ReffedTestClass alloc] init];
    obj2.objDescription = @"Test with intradependence,rev - 2";
    obj2.thisOther = obj1;
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    __block double done = -1;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    [store saveObject:@[obj2, obj1] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        XCTAssertEqual((int) [objectsOrNil count], (int) 2, @"should have saved two objects");
        XCTAssertTrue([objectsOrNil containsObject:obj1], @"should get our object back");
        XCTAssertTrue([objectsOrNil containsObject:obj2], @"should get our object back");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        XCTAssertTrue(percentComplete >= done, @"should be monotonically increasing");
        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        done = percentComplete;
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    
    __weak XCTestExpectation* expectationQuery = [self expectationWithDescription:@"query"];
    done = -1;
    
    KCSLinkedAppdataStore* store2 = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    KCSQuery* query = [KCSQuery queryOnField:@"objDescription" withRegex:@"^.*- 2"];
    [store2 queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        //TODO
//        XCTAssertEqual((int) [objectsOrNil count], (int) 1, @"should have loaded just one object");
        ReffedTestClass* newObj = objectsOrNil.count > 0 ? objectsOrNil[0] : nil;
        //TODO
//        XCTAssertEqualObjects(newObj.objId, obj2.objId, @"Should get back the right id");
        ReffedTestClass* ref = newObj.thisOther;
        //TODO
//        XCTAssertTrue([ref isKindOfClass:[ReffedTestClass class]], @"Should be a ref class");
//        XCTAssertEqualObjects(ref.objId, obj1.objId, @"should get back the right object");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationQuery fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        XCTAssertTrue(percentComplete >= done, @"should be monotonically increasing");
        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        done = percentComplete;
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
}

- (void) testCircularRefOne
{
    ReffedTestClass* obj1 = [[ReffedTestClass alloc] init];
    obj1.objDescription = @"Test circular - 1";
    obj1.objCount = 1;
    
    ReffedTestClass* obj2 = [[ReffedTestClass alloc] init];
    obj2.objDescription = @"Test circular - 2";
    obj2.thisOther = obj1;
    obj1.thisOther = obj2;
    obj2.objCount = 2;
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    __block double done = -1;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    [store saveObject:@[obj1] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        XCTAssertEqual((int) [objectsOrNil count], (int) 1, @"should have saved two objects");
        XCTAssertTrue([objectsOrNil containsObject:obj1], @"should get our object back");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        XCTAssertTrue(percentComplete > done, @"should be monotonically increasing");
        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        done = percentComplete;
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    
    __weak XCTestExpectation* expectationQuery = [self expectationWithDescription:@"query"];
    done = -1;
    
    KCSQuery* query = [KCSQuery query];
    [store queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
//        XCTAssertEqual((int) [objectsOrNil count], (int) 2, @"should have loaded just one objects");
        [objectsOrNil enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString* thisId = [obj objId];
            XCTAssertNotNil(obj1.objId);
//            XCTAssertNotNil(obj2.objId);
            NSArray* arr;
            if (obj1.objId && obj2.objId) {
                arr = @[obj1.objId, obj2.objId];
            } else {
                arr = nil;
            }
            BOOL inArray = [arr containsObject:thisId];
//            XCTAssertTrue(inArray, @"%@ should be in the return: %@",thisId, arr);
        }];
        XCTAssertEqualObjects(obj2.thisOther.objId, obj1.objId, @"Should get back the original reference object");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationQuery fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        XCTAssertTrue(percentComplete > done, @"should be monotonically increasing");
        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        done = percentComplete;
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testCircularRefArray
{
    ReffedTestClass* obj1 = [[ReffedTestClass alloc] init];
    obj1.objDescription = @"Test circular (array) - 1";
    obj1.objCount = 1;
    
    ReffedTestClass* obj2 = [[ReffedTestClass alloc] init];
    obj2.objDescription = @"Test circular (array) - 2";
    obj2.thisOther = obj1;
    obj1.thisOther = obj2;
    obj2.objCount = 2;
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    __block double done = -1;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    [store saveObject:@[obj1, obj2] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        XCTAssertEqual((int) [objectsOrNil count], (int) 2, @"should have saved two objects");
        XCTAssertTrue([objectsOrNil containsObject:obj1], @"should get our object back");
        XCTAssertTrue([objectsOrNil containsObject:obj2], @"should get our other object back");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        XCTAssertTrue(percentComplete >= done, @"should be monotonically increasing");
        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        done = percentComplete;
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    
    __weak XCTestExpectation* expectationQuery = [self expectationWithDescription:@"query"];
    done = -1;
    
    KCSQuery* query = [KCSQuery query];
    [store queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
//        XCTAssertEqual((int) [objectsOrNil count], (int) 2, @"should have loaded just one objects");
        [objectsOrNil enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString* thisId = [obj objId];
            NSArray* arr = @[obj1.objId, obj2.objId];
            BOOL inArray = [arr containsObject:thisId];
            XCTAssertTrue(inArray, @"%@ should be in the return: %@",thisId, arr);
            //TODO: 1->A, 2->A ==> 1->A, 2->A, not 1->A',2->A''obj1.thisOther = obj2, obj2.thisOther = obj1
        }];
//        XCTAssertEqualObjects(obj2.thisOther.objId, obj1.objId, @"Should get back the original reference object");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationQuery fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        XCTAssertTrue(percentComplete > done, @"should be monotonically increasing");
        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        done = percentComplete;
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testCircularRefArrayNoPost
{
    ReffedTestClass* obj1 = [[ReffedTestClass alloc] init];
    obj1.objDescription = @"Test circular (array) - 1";
    obj1.objCount = 1;
    obj1.objId = @"OBJECT1";
    
    ReffedTestClass* obj2 = [[ReffedTestClass alloc] init];
    obj2.objDescription = @"Test circular (array) - 2";
    obj2.thisOther = obj1;
    obj1.thisOther = obj2;
    obj2.objCount = 2;
    obj2.objId = @"OBJECT2";
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    __block double done = -1;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    [store saveObject:@[obj1, obj2] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        XCTAssertEqual((int) [objectsOrNil count], (int) 2, @"should have saved two objects");
        XCTAssertTrue([objectsOrNil containsObject:obj1], @"should get our object back");
        XCTAssertTrue([objectsOrNil containsObject:obj2], @"should get our other object back");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        XCTAssertTrue(percentComplete >= done, @"should be monotonically increasing");
        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        done = percentComplete;
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    
    __weak XCTestExpectation* expectationQuery = [self expectationWithDescription:@"query"];
    done = -1;
    
    KCSQuery* query = [KCSQuery query];
    [store queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        XCTAssertEqual((int) [objectsOrNil count], (int) 2, @"should have loaded just one objects");
        [objectsOrNil enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString* thisId = [obj objId];
            NSArray* arr = @[obj1.objId, obj2.objId];
            BOOL inArray = [arr containsObject:thisId];
            XCTAssertTrue(inArray, @"%@ should be in the return: %@",thisId, arr);
            //TODO: 1->A, 2->A ==> 1->A, 2->A, not 1->A',2->A''obj1.thisOther = obj2, obj2.thisOther = obj1
        }];
        XCTAssertEqualObjects(obj2.thisOther.objId, obj1.objId, @"Should get back the original reference object");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationQuery fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        XCTAssertTrue(percentComplete > done, @"should be monotonically increasing");
        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        done = percentComplete;
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testCircularChain
{
    ReffedTestClass* obj1 = [[ReffedTestClass alloc] init];
    obj1.objDescription = @"Test circular chain - 1";
    obj1.objCount = 1;
    
    ReffedTestClass* obj2 = [[ReffedTestClass alloc] init];
    obj2.objDescription = @"Test circular chain - 2";
    obj2.objCount = 2;
    
    ReffedTestClass* obj3 = [[ReffedTestClass alloc] init];
    obj3.objDescription = @"Test circular chain - 3";
    obj3.objCount = 3;

    ReffedTestClass* obj4 = [[ReffedTestClass alloc] init];
    obj4.objDescription = @"Test circular chain - 4";
    obj4.objCount = 4;
    
    obj1.thisOther = obj2;
    obj2.thisOther = obj3;
    obj3.thisOther = obj4;
    obj4.thisOther = obj1;

    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    __block double done = -1;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    [store saveObject:@[obj1] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        XCTAssertEqual((int) [objectsOrNil count], (int) 1, @"should have saved two objects");
        XCTAssertTrue([objectsOrNil containsObject:obj1], @"should get our object back");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        XCTAssertTrue(percentComplete > done, @"should be monotonically increasing");
        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        done = percentComplete;
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    
    __weak XCTestExpectation* expectationQuery = [self expectationWithDescription:@"query"];
    done = -1;
    
    KCSQuery* query = [KCSQuery query];
    [query addSortModifier:[[KCSQuerySortModifier alloc] initWithField:@"objCount" inDirection:kKCSAscending]];
    [store queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
//        XCTAssertEqual((int) [objectsOrNil count], (int) 4, @"should have loaded all four objects");
        ReffedTestClass* prime1 = objectsOrNil.count > 0 ? objectsOrNil[0] : nil;
        ReffedTestClass* prime2 = objectsOrNil.count > 1 ? objectsOrNil[1] : nil;
        ReffedTestClass* prime3 = objectsOrNil.count > 2 ? objectsOrNil[2] : nil;
        ReffedTestClass* prime4 = objectsOrNil.count > 3 ? objectsOrNil[3] : nil;
//        XCTAssertEqualObjects(prime1.thisOther.objId, prime2.objId, @"Should get back the original reference object");
        XCTAssertEqualObjects(prime2.thisOther.objId, prime3.objId, @"Should get back the original reference object");
        XCTAssertEqualObjects(prime3.thisOther.objId, prime4.objId, @"Should get back the original reference object");
//        XCTAssertEqualObjects(prime4.thisOther.objId, prime1.objId, @"Should get back the original reference object");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationQuery fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingArrayOfTopRefs: percentcomplete:%f", percentComplete);
        XCTAssertTrue(percentComplete > done, @"should be monotonically increasing");
        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        done = percentComplete;
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testNestedReferences
{
    NestingRefClass* obj1 = [[NestingRefClass alloc] init];
    obj1.objCount = 1;
    obj1.objDescription = @"testNestedReferences : Top Object";
    
    ReffedTestClass* obj2 = [[ReffedTestClass alloc] init];
    obj2.objCount = 2;
    obj2.objDescription = @"testNestedReferences : Middle Object";
    obj1.relatedObject = obj2;
    
    LinkedTestClass* obj3 = [[LinkedTestClass alloc] init];
    obj3.objCount = 3;
    obj3.objDescription = @"testNestedReferences : Bottom Object";
    obj2.other = obj3;
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    __block double done = -1;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[NestingRefClass class]] options:nil];
    [store saveObject:obj1 withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        NestingRefClass* ret = [objectsOrNil objectAtIndex:0];
        ReffedTestClass* newRef = ret.relatedObject;
//        XCTAssertEqual(newRef.objCount, obj2.objCount, @"Should be the same object back");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingWithOneKinveyRef: percentcomplete:%f", percentComplete);
        XCTAssertTrue(percentComplete > done, @"should be monotonically increasing");
        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        done = percentComplete;
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak XCTestExpectation* expectationLoad = [self expectationWithDescription:@"load"];
    done = -1;

    [store loadObjectWithID:[obj1 kinveyObjectId] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        NestingRefClass* ret = [objectsOrNil objectAtIndex:0];
        ReffedTestClass* newRef = ret.relatedObject;
//        XCTAssertEqual(newRef.objCount, obj2.objCount, @"Should be the same object back");
//        XCTAssertNotEqual((id) newRef, (id) [NSNull null]);
        LinkedTestClass* bottomRef = newRef != [NSNull null] ? newRef.other : nil;
//        XCTAssertEqual(bottomRef.objCount, obj3.objCount, @"Should be the same object back");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationLoad fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingWithOneKinveyRef: percentcomplete:%f", percentComplete);
        XCTAssertTrue(percentComplete > done, @"should be monotonically increasing");
        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        done = percentComplete;
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];

    
}

- (void) testQueryHasRef
{
    NestingRefClass* obj1 = [[NestingRefClass alloc] init];
    obj1.objCount = 1;
    obj1.objDescription = @"testNestedReferences : Top Object";
    
    ReffedTestClass* obj2 = [[ReffedTestClass alloc] init];
    obj2.objCount = 2;
    obj2.objDescription = @"testNestedReferences : Middle Object";
    obj1.relatedObject = obj2;
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    __block double done = -1;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[NestingRefClass class]] options:nil];
    [store saveObject:obj1 withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        NestingRefClass* ret = objectsOrNil[0];
        ReffedTestClass* newRef = ret.relatedObject;
//        XCTAssertEqual(newRef.objCount, obj2.objCount, @"Should be the same object back");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingWithOneKinveyRef: percentcomplete:%f", percentComplete);
        XCTAssertTrue(percentComplete > done, @"should be monotonically increasing");
        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        done = percentComplete;
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
//    XCTestExpectation* expectationQuery = [self expectationWithDescription:@"query"];

//    KCSQuery *query = [KCSQuery queryOnField:@"relatedObject._id" withExactMatchForValue:obj2];
//    
//    [store queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
//        STAssertNoError
//        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
//        NestingRefClass* ret = objectsOrNil[0];
//        ReffedTestClass* newRef = ret.relatedObject;
//        XCTAssertEqual(newRef.objCount, obj2.objCount, @"Should be the same object back");
//        
//        XCTAssertTrue([NSThread isMainThread]);
//        
//        [expectationQuery fulfill];
//    } withProgressBlock:^(NSArray *objects, double percentComplete) {
//        XCTAssertTrue([NSThread isMainThread]);
//    }];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
}
//TODO: note different objs
//TODO: 1->A, 2->A ==> 1->A, 2->A, not 1->A',2->A''

- (void) testUserAssociation
{
    UserRefTestClass* obj = [[UserRefTestClass alloc] init];
    obj.objCount = -3000;
    obj.objDescription = @"auser that knows about another user";
    obj.auser = [KCSUser activeUser];
    
    XCTAssertNotNil(obj.auser, @"should have a nonnull user");
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[UserRefTestClass class]] options:nil];
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        UserRefTestClass* ret = [objectsOrNil objectAtIndex:0];
        KCSUser* retUser = ret.auser;
        XCTAssertTrue([retUser isKindOfClass:[KCSUser class]], @"should be a user");
        XCTAssertEqualObjects([retUser username],[KCSUser activeUser].username, @"usernames should match");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

#pragma mark graph

- (void) testThatNonRecursiveGeneratesError
{
    NoSaveTestClass* t = [[NoSaveTestClass alloc] init];
    t.objDescription = @"nnn";
    t.objCount = 10;
    
    ReffedTestClass* r = [[ReffedTestClass alloc] init];
    r.objDescription = @"r";
    r.objCount = 700;
    t.relatedObject = r;
    
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    __block double done = -1;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[NoSaveTestClass class]] options:nil];
    [store saveObject:t withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        XCTAssertNotNil(errorOrNil, @"should have an error");
        XCTAssertEqual((int)errorOrNil.code, (int)KCSReferenceNoIdSetError, @"expecting no id error");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingWithOneKinveyRef: percentcomplete:%f", percentComplete);
        XCTAssertTrue(percentComplete > done, @"should be monotonically increasing");
        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        done = percentComplete;
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testThatNonRecursiveGoodWithIdDoesNotSave
{
    NoSaveTestClass* t = [[NoSaveTestClass alloc] init];
    t.objDescription = @"nnn";
    t.objCount = 10;
    
    ReffedTestClass* r1 = [[ReffedTestClass alloc] init];
    r1.objDescription = @"r";
    r1.objCount = 710;
    r1.objId = @"testThatNonRecursiveGoodWithIdDoesNotSave";
    t.relatedObject = r1;
    
    
    //--- presave an object with a different count but same id as our reference. The test for not save will make sure that the ref object does not
    //revert to the known object in the backend
    ReffedTestClass* r2 = [[ReffedTestClass alloc] init];
    r2.objDescription = @"r";
    r2.objCount = 9000;
    r2.objId = @"testThatNonRecursiveGoodWithIdDoesNotSave";

    NSString* refClass = @"NestedOtherCollection";
    KCSCollection* refCollection = [KCSCollection collectionFromString:refClass ofClass:[ReffedTestClass class]];
    KCSLinkedAppdataStore* refStore = [KCSLinkedAppdataStore storeWithCollection:refCollection options:nil];
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    [refStore saveObject:r2 withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    
    
    //now test the save doesn't error but also doesn't save
    __weak XCTestExpectation* expectationSave2 = [self expectationWithDescription:@"save2"];
    __block double done = -1;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[NoSaveTestClass class]] options:nil];
    [store saveObject:t withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        STAssertObjects(1);
        NoSaveTestClass* tb = objectsOrNil[0];
        ReffedTestClass* rb = tb.relatedObject;
        XCTAssertNotNil(rb, @"good object");
        XCTAssertEqual((int)rb.objCount, (int)710, @"should match orig value, not saved");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave2 fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingWithOneKinveyRef: percentcomplete:%f", percentComplete);
        XCTAssertTrue(percentComplete > done, @"should be monotonically increasing");
        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        done = percentComplete;
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testBrokenReference
{
    LinkedTestClass* ref = TestClass(0);
    
    ReffedTestClass* obj = [[ReffedTestClass alloc] init];
    obj.objDescription = @"Yaaay!";
    obj.other = ref;
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    __block double done = -1;
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:[KCSCollection collectionFromString:_collection.collectionName ofClass:[ReffedTestClass class]] options:nil];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        ReffedTestClass* ret = [objectsOrNil objectAtIndex:0];
        LinkedTestClass* newRef = ret.other;
//        XCTAssertEqual(newRef.objCount, ref.objCount, @"Should be the same object back");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingWithOneKinveyRef: percentcomplete:%f", percentComplete);
        XCTAssertTrue(percentComplete > done, @"should be monotonically increasing");
        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        done = percentComplete;
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak XCTestExpectation* expectationRemove = [self expectationWithDescription:@"remove"];
    done = -1;
    
    KCSAppdataStore* otherStore = [KCSAppdataStore storeWithCollection:[KCSCollection collectionFromString:@"OtherCollection" ofClass:[LinkedTestClass class]] options:nil];
    [otherStore removeObject:ref withCompletionBlock:^(unsigned long count, NSError *errorOrNil) {
//        STAssertNoError;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationRemove fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    
    __weak XCTestExpectation* expectationLoad = [self expectationWithDescription:@"load"];
    [store loadObjectWithID:[obj kinveyObjectId] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        ReffedTestClass* ret = [objectsOrNil objectAtIndex:0];
        LinkedTestClass* newRef = ret.other;
//        XCTAssertNil(newRef, @"should be nil");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationLoad fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"testSavingWithOneKinveyRef: percentcomplete:%f", percentComplete);
        XCTAssertTrue(percentComplete > done, @"should be monotonically increasing");
        XCTAssertTrue(percentComplete <= 1.0, @"should be less than equal 1");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        done = percentComplete;
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testBrokenFile
{
    LinkedTestClass* obj = [[LinkedTestClass alloc] init];
    obj.objDescription = @"Yaaay!";
    obj.resource = [self makeImage];
    
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:_collection options:nil];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        XCTAssertNotNil(objectsOrNil, @"should have gotten back the objects");
        LinkedTestClass* obj = objectsOrNil[0];
        XCTAssertNotNil(obj, @"should not be nil obj");
        XCTAssertNotNil(obj.resource, @"should still have an image");
        XCTAssertTrue([obj.resource isKindOfClass:[UIImage class]], @"Should still be an image");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak XCTestExpectation* expectationLoad = [self expectationWithDescription:@"load"];
    __block NSString* imageId = nil;
    KCSAppdataStore* noRefStore = [KCSAppdataStore storeWithCollection:_collection options:nil];
    [noRefStore loadObjectWithID:obj.objId withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        STAssertObjects(1);
        LinkedTestClass* foo = objectsOrNil[0];
        NSDictionary* resourceDict = foo.resource;
        imageId = resourceDict[@"_id"];
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationLoad fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];

    XCTAssertNotNil(imageId, @"Should have an image id");
    
    __weak XCTestExpectation* expectationDelete = [self expectationWithDescription:@"delete"];
    [KCSFileStore deleteFile:imageId completionBlock:^(unsigned long count, NSError *errorOrNil) {
        //TODO
//        STAssertNoError;
//        KTAssertEqualsInt(count, 1, @"Should be one deletion");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDelete fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak XCTestExpectation* expectationLoad2 = [self expectationWithDescription:@"load2"];
    [store loadObjectWithID:obj.objId withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        XCTAssertNotNil(errorOrNil, @"should be an error");
        KTAssertEqualsInt(errorOrNil.code, 404, @"file not found");
        XCTAssertEqualObjects(errorOrNil.domain, KCSFileStoreErrorDomain, @"should be a file error");
        STAssertObjects(1);
        LinkedTestClass* o = objectsOrNil[0];
        XCTAssertNil(o.resource, @"should be nilled");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationLoad2 fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

// *** TODO: *** reminder to check why this test case is causing crashes
//
//- (void) testQueryAll
//{
//    KCSQuery* findSenders = [KCSQuery queryOnField:@"recipients._id" usingConditional:kKCSAll forValue:@[[KCSUser activeUser].userId]];
//    
//    KCSCollection* collection = [KCSCollection collectionFromString:@"inbox" ofClass:[TSSMessage class]];
//    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithOptions:@{KCSStoreKeyResource: collection,
//                                                                             KCSStoreKeyCachePolicy: @(KCSCachePolicyNetworkFirst)}];
//    
//    TSSMessage* message = [[TSSMessage alloc] init];
//    message.recipients = [@[@{@"_type":@"KinveyRef",@"collection":@"user",@"_id":[KCSUser activeUser].userId},
//                           @{@"_type":@"KinveyRef",@"collection":@"user",@"_id":@"XXA"}] mutableCopy];
//    self.done = NO;
//    [store saveObject:message withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
//        STAssertNoError;
//        self.done = YES;
//    } withProgressBlock:nil];
//    [self poll];
//    
//    self.done = NO;
//    [store queryWithQuery:findSenders withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
//        STAssertNoError;
//        self.done = YES;
//    } withProgressBlock:nil];
//    [self poll];
//}

@end
