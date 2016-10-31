//
//  KinveyKitEntityTests.m
//  KinveyKit
//
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


#import "KinveyKitEntityTests.h"
#import "TestUtils.h"

#import "KinveyEntity.h"

#import "KCSObjectMapper.h"

#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>
#import "CLLocation+Kinvey.h"
#import "KinveyErrorCodes.h"
#import "KCSLogManager.h"
#import "KCSFile.h"
#import "KCSFileStore.h"

@interface HS1789 : NSObject <KCSPersistable>
@property (nonatomic, copy) NSMutableSet* users;
@property (nonatomic, strong) NSArray* location;
@property (nonatomic, strong) NSString* entityId;
@property (nonatomic, strong) KCSMetadata* metadata;
@property (nonatomic, strong) NSString* name;
@end

@implementation HS1789

- (NSDictionary *)hostToKinveyPropertyMapping
{
    return @{
             @"name" : @"name",
             @"metadata" : KCSEntityKeyMetadata,
             @"entityId" : KCSEntityKeyId,
             @"location" : KCSEntityKeyGeolocation,
             @"users" : @"users",
             };
}

+ (NSDictionary*) kinveyPropertyToCollectionMapping
{
    return @{@"users": KCSUserCollectionName};
}

+ (NSDictionary *)kinveyObjectBuilderOptions
{
    return @{ KCS_REFERENCE_MAP_KEY : @{ @"users" : [KCSUser class]}};
}

@end

@interface TestObject : NSObject <KCSPersistable>

@property (nonatomic, retain) NSString *testId;
@property (nonatomic, retain) NSString *testParam1;
@property (nonatomic, retain) NSNumber *testParam2;
@property (nonatomic, retain) NSDate* dateParam;
@property (nonatomic, retain) NSSet* setParam;
@property (nonatomic, retain) NSOrderedSet* oSetParam;
@property (nonatomic, retain) NSMutableAttributedString* asParam;
@property (nonatomic, retain) CLLocation* locParam;
@property (nonatomic, retain) UIImage* image;
@property (nonatomic, retain) KCSFile* fileRef;
@end

@implementation TestObject

- (NSDictionary *)hostToKinveyPropertyMapping
{
    return @{@"testId" : KCSEntityKeyId,
             @"testParam1" : @"testParam1i",
             @"testParam2" : @"testParam2i",
             @"setParam"   : @"setParam",
             @"dateParam" : @"dateParam",
             @"oSetParam" : @"oSetParam",
             @"asParam" : @"asParam",
             @"locParam" : @"locParam",
             @"image" : @"image",
             @"fileRef" : @"fileRef"};
}

+ (NSDictionary *)kinveyPropertyToCollectionMapping
{
    return @{@"image" : KCSFileStoreCollectionName, @"fileRef" : KCSFileStoreCollectionName};
}
@end

@interface BrokenHostMappingObj : NSObject <KCSPersistable>

@end

@implementation BrokenHostMappingObj
- (NSDictionary *)hostToKinveyPropertyMapping
{
    static NSDictionary* mapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mapping = @{@"objectId" : KCSEntityKeyId};
                    });
        return mapping;
}

@end

@implementation KinveyKitEntityTests

- (void) testTypesSerialize
{
    TestObject* t = [[TestObject alloc] init];
    t.testId = @"idX";
    t.testParam1 = @"p1";
    t.testParam2 = @1.245;
    t.dateParam = [NSDate dateWithTimeIntervalSince1970:0];
    t.setParam = [NSSet setWithArray:@[@"2",@"1",@7]];
    t.oSetParam = [NSOrderedSet orderedSetWithArray:@[@"2",@"1",@7]];
    NSMutableAttributedString* s  = [[NSMutableAttributedString alloc] initWithString:@"abcdef"];
    [s setAttributes:@{@"myattr" : @"x"} range:NSMakeRange(1, 2)];
    t.asParam = s;
    t.locParam = [[CLLocation alloc] initWithLatitude:10 longitude:130];
    
    KCSSerializedObject* so = [KCSObjectMapper makeKinveyDictionaryFromObject:t error:NULL];
    XCTAssertNotNil(so, @"should not have a nil object");
    
    NSDictionary* d = [so dataToSerialize];
    XCTAssertNotNil(d, @"should not have a nil dictionary");
    XCTAssertEqual([d count], (NSUInteger) 8, @"should have 8 params");
    
    XCTAssertEqualObjects([d objectForKey:KCSEntityKeyId], @"idX", @"should have set the id");
    XCTAssertEqualObjects([d objectForKey:@"testParam1i"],  @"p1", @"should have set the string");
    XCTAssertEqualObjects([d objectForKey:@"testParam2i"],  @1.245, @"should have set the number");
    XCTAssertEqualObjects([d objectForKey:@"dateParam"],   @"ISODate(\"1970-01-01T00:00:00.000Z\")", @"should have set the date");
    NSArray* a = @[@"2",@"1",@7];
    XCTAssertEqualObjects([d objectForKey:@"setParam"],    a, @"should have set the set");
    XCTAssertEqualObjects([d objectForKey:@"oSetParam"],   a, @"should have set the ordered set");
    XCTAssertEqualObjects([d objectForKey:@"asParam"],   @"abcdef", @"should have set the ordered set");
    a = @[@130,@10];
    XCTAssertEqualObjects([d objectForKey:@"locParam"], a, @"should have set cllocation");
}

- (void) testTypesDeserialize
{
    NSDictionary* data = @{ KCSEntityKeyId : @"idX",
                            @"testParam1i" : @"p1",
                            @"testParam2i" : @1.245,
                            @"dateParam"   : @"ISODate(\"1970-01-01T00:00:00.000Z\")",
                            @"setParam"    : @[@"2",@"1",@7],
                            @"oSetParam"   : @[@"2",@"1",@7],
                            @"asParam"     : @"abcedf",
                            @"locParam"    : @[@100,@-30]};
    TestObject* out = [KCSObjectMapper makeObjectOfType:[TestObject class] withData:data];
    
    XCTAssertNotNil(out, @"Should not be nil");
    
    NSArray* a = @[@"2",@"1",@7];
    XCTAssertTrue([out.setParam isKindOfClass:[NSSet class]], @"should be a NSSet");
    XCTAssertEqualObjects(out.setParam,  [NSSet setWithArray:a], @"NSSets should be equal");
    XCTAssertTrue([out.oSetParam isKindOfClass:[NSOrderedSet class]], @"should be a NSOrderedSet");
    XCTAssertEqualObjects(out.oSetParam,  [NSOrderedSet orderedSetWithArray:a], @"NSOrderedSets should be equal");
    XCTAssertTrue([out.dateParam isKindOfClass:[NSDate class]], @"should be a NSOrderedSet");
    XCTAssertEqualObjects(out.dateParam,  [NSDate dateWithTimeIntervalSince1970:0], @"NSOrderedSets should be equal");
    XCTAssertTrue([out.asParam isKindOfClass:[NSMutableAttributedString class]], @"should be a NSOrderedSet");
    a = @[@100,@-30];
    XCTAssertEqualObjects([out.locParam kinveyValue] , a, @"should be matching CLLocation");
}

- (void) testLinkedRefOldStyle
{
    NSDictionary* data = @{ KCSEntityKeyId : @"idX",
                            @"testParam1i" : @"p1",
                            @"testParam2i" : @1.245,
                            @"dateParam"   : @"ISODate(\"1970-01-01T00:00:00.000Z\")",
                            @"setParam"    : @[@"2",@"1",@7],
                            @"oSetParam"   : @[@"2",@"1",@7],
                            @"asParam"     : @"abcedf",
                            @"locParam"    : @[@100,@-30],
                            @"image"       : @{
                                @"_loc" : @"OfflineSave-linked1-photo.png",
                                @"_mime-type" : @"image/png",
                                @"_type" : @"resource"
                            }};
    TestObject* out = [KCSObjectMapper makeObjectOfType:[TestObject class] withData:data];
    
    XCTAssertNotNil(out, @"Should not be nil");
    id im = out.image;
    XCTAssertNotNil(im, @"image should be valid");
    XCTAssertTrue([im isKindOfClass:[NSDictionary class]], @"should be a dictionary");
    
    NSMutableDictionary* resources = [NSMutableDictionary dictionary];
    TestObject* out2 = [KCSObjectMapper makeObjectWithResourcesOfType:[TestObject class] withData:data withResourceDictionary:resources];

    XCTAssertNotNil(out2, @"Should not be nil");
    id im2 = out2.image;
    XCTAssertNil(im2, @"image should be nil");
    XCTAssertEqual((int) 1, (int) resources.count, @"should have a resource to load");

    KCSFile* imgRef = resources[@"image"];
    XCTAssertNotNil(imgRef, @"should have an image value");
    XCTAssertEqualObjects(imgRef.filename, @"OfflineSave-linked1-photo.png", @"ids should match");
}

- (void) testLinkedFile
{
    NSDictionary* data = @{ KCSEntityKeyId : @"idX",
                            @"testParam1i" : @"p1",
                            @"testParam2i" : @1.245,
                            @"dateParam"   : @"ISODate(\"1970-01-01T00:00:00.000Z\")",
                            @"setParam"    : @[@"2",@"1",@7],
                            @"oSetParam"   : @[@"2",@"1",@7],
                            @"asParam"     : @"abcedf",
                            @"locParam"    : @[@100,@-30],
                            @"image"       : @{
                                    @"_downloadURL" : @"http://images.com/OfflineSave-linked1-photo.png",
                                    @"_mimeType" : @"image/png",
                                    @"_id" : @"special-image-id",
                                    @"_type" : @"KinveyFile"
                                    }};
    TestObject* out = [KCSObjectMapper makeObjectOfType:[TestObject class] withData:data];
    
    XCTAssertNotNil(out, @"Should not be nil");
    id im = out.image;
    XCTAssertNotNil(im, @"image should be valid");
    XCTAssertTrue([im isKindOfClass:[NSDictionary class]], @"should be a dictionary");
    
    NSMutableDictionary* resources = [NSMutableDictionary dictionary];
    TestObject* out2 = [KCSObjectMapper makeObjectWithResourcesOfType:[TestObject class] withData:data withResourceDictionary:resources];
    
    XCTAssertNotNil(out2, @"Should not be nil");
    id im2 = out2.image;
    XCTAssertNil(im2, @"image should be nil");
    XCTAssertEqual((int) 1, (int) resources.count, @"should have a resource to load");
    
    KCSFile* imgRef = resources[@"image"];
    XCTAssertNotNil(imgRef, @"should have an image value");
    XCTAssertEqualObjects(imgRef.fileId, @"special-image-id", @"ids should match");
    XCTAssertEqualObjects(imgRef.remoteURL, [NSURL URLWithString:@"http://images.com/OfflineSave-linked1-photo.png"], @"urls should match");
}

- (void) testLinkedFileOrMetdata
{
    TestObject* obj = [[TestObject alloc] init];
    obj.image = [UIImage new];
    obj.fileRef = [[KCSFile alloc] init];
    obj.fileRef.length = 1001;
    obj.fileRef.mimeType = @"foo/bar";
    obj.testId = @"ABC";
    

    NSError* error = nil;
    KCSSerializedObject* metaObj = [KCSObjectMapper makeResourceEntityDictionaryFromObject:obj forCollection:@"TestObjects" error:&error];
    STAssertNoError_

    NSDictionary* jsonData = metaObj.dataToSerialize;
    id ifile = jsonData[@"image"];
    id ffile = jsonData[@"fileRef"];
    
    XCTAssertNotNil(ifile, @"");
    XCTAssertTrue([ifile isKindOfClass:[KCSFile class]], @"");
    XCTAssertNotNil(ffile, @"");
    XCTAssertTrue([ffile isKindOfClass:[KCSFile class]], @"");
    KTAssertCount(2, metaObj.resourcesToSave);
    
    NSData* serialized = [NSJSONSerialization dataWithJSONObject:jsonData
                                                         options:0
                                                           error:nil];
    id deserialized = [NSJSONSerialization JSONObjectWithData:serialized
                                                      options:NSJSONReadingMutableContainers
                                                        error:nil];
    
    NSMutableDictionary* resources = [NSMutableDictionary dictionary];
    TestObject* made = [KCSObjectMapper makeObjectWithResourcesOfType:[TestObject class] withData:deserialized withResourceDictionary:resources];
    
    KTAssertCount(1, resources);
    
    KCSFile* madeFile = made.fileRef;
    XCTAssertNotNil(madeFile, @"should be valid");
}

- (void) testBrokenPropMap
{
    [KCSLogManager sharedLogManager].suppressErrorToExceptionOnTest = YES;
    
    BrokenHostMappingObj* obj = [[BrokenHostMappingObj alloc] init];
    NSError* error = nil;
    KCSSerializedObject* d = [KCSObjectMapper makeKinveyDictionaryFromObject:obj error:&error];
    XCTAssertNil(d, @"should be nil");
    XCTAssertNotNil(error, @"Should have an error");
    XCTAssertEqual((int)KCSInvalidKCSPersistableError, (int) error.code, @"should make a invalid persistable error");

    [KCSLogManager sharedLogManager].suppressErrorToExceptionOnTest = NO;
}

- (void) testPopulateExistingDoesntKillResources
{
    TestObject* obj = [[TestObject alloc] init];
    obj.image = [UIImage new];
    obj.testId = @"12345";
    
    NSDictionary* newData = @{KCSEntityKeyId : obj.testId, @"image" : @{@"_type":@"KinveyFile", @"_id":@"TestObjects-12345-image"}};
    
    NSError* error = nil;
    KCSSerializedObject* o = [KCSObjectMapper makeResourceEntityDictionaryFromObject:obj forCollection:@"TestObjects" error:&error];
    XCTAssertNil(error, @"should serialize correctly");
    XCTAssertNotNil(o.resourcesToSave, @"Should have resources");
    KTAssertCount(1, o.resourcesToSave);
    
    [KCSObjectMapper populateExistingObject:o withNewData:newData];
    
    XCTAssertNotNil(obj.testId, @"should not nil id");
    UIImage* resolvedImage = obj.image;
    XCTAssertNotNil(resolvedImage, @"should still be an image");
    XCTAssertTrue([resolvedImage isKindOfClass:[UIImage class]], @"still an image");
}

//Test for addObject to set 'nil' values into a set
//needs the BL onPostSave hooks
- (void) testHS1789
{
    
    BOOL setup = [TestUtils setUpKinveyUnittestBackend:self];
    XCTAssertTrue(setup, @"Should be set-up");

    
    HS1789* newFlat = [[HS1789 alloc] init];
    newFlat.name = @"Roberto";
    KCSAppdataStore* store = [KCSLinkedAppdataStore storeWithOptions:@{ KCSStoreKeyCollectionName : @"HS1789", KCSStoreKeyCollectionTemplateClass : [HS1789 class]}];
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    [store saveObject:newFlat withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        STAssertObjects(1);
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationSave fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testNoEmptyIds_HS2676
{
    TestObject* to = [[TestObject alloc] init];
    to.testParam1 = @"A";
    to.testId = @"";
    
    KCSSerializedObject* so = [KCSObjectMapper makeKinveyDictionaryFromObject:to error:NULL];
    XCTAssertNotNil(so, @"should not have a nil object");
    
    NSDictionary* d = [so dataToSerialize];
    XCTAssertNotNil(d, @"should not have a nil dictionary");

    XCTAssertNil(d[@"_id"], @"should not have an id");
    XCTAssertNotNil(d[@"testParam1i"], @"should have the param");
    
    XCTAssertNil(so.objectId, @"should have no obj id");
}

@end


