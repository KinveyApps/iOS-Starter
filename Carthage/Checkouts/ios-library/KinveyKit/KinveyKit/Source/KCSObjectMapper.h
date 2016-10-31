//
//  KCSObjectMapper.h
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

@import Foundation;
#import "KinveyPersistable.h"

@interface KCSKinveyRef : NSObject
@property (nonatomic, strong) id<KCSPersistable>object;
@property (nonatomic, copy) NSString* collectionName;
@end

@interface KCSSerializedObject : NSObject
@property (nonatomic, readonly) BOOL isPostRequest;
@property (nonatomic, readonly) NSString *objectId;
@property (strong, nonatomic, readonly) NSDictionary *dataToSerialize;
@property (strong, nonatomic, readonly) NSArray* resourcesToSave;
@property (strong, nonatomic, readonly) NSArray* referencesToSave;
@property (strong, nonatomic, readonly) id<KCSPersistable> handleToOriginalObject;
@property (nonatomic, strong) NSDictionary* userInfo;
- (void) restoreReferences:(KCSSerializedObject*)previousObject;
@end

@interface KCSObjectMapper : NSObject

+ (id)populateObject:(id)object withData: (NSDictionary *)data;
+ (id)populateExistingObject:(KCSSerializedObject*)serializedObject withNewData:(NSDictionary*)data;

+ (id)makeObjectOfType:(Class)objectClass
              withData: (NSDictionary *)data;

+ (id)makeObjectOfType:(Class)objectClass
              withData:(NSDictionary *)data
                object:(id*)obj;

+ (id)makeObjectOfType:(Class)objectClass
              withData: (NSDictionary *)data
withResourceDictionary:(NSMutableDictionary*)resources;

+ (id)makeObjectOfType:(Class)objectClass
              withData:(NSDictionary *)data
withResourceDictionary:(NSMutableDictionary*)resources
                object:(id*)obj;

+ (id)makeObjectWithResourcesOfType:(Class)objectClass withData:(NSDictionary *)data withResourceDictionary:(NSMutableDictionary*)resources;
+ (KCSSerializedObject *)makeKinveyDictionaryFromObject:(id)object error:(NSError**)error;
+ (KCSSerializedObject *)makeResourceEntityDictionaryFromObject:(id)object forCollection:(NSString*)collectionName error:(NSError**)error;

@end
