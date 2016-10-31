//
//  KCSDataModel.m
//  KinveyKit
//
//  Created by Michael Katz on 10/28/13.
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

#import "KCSDataModel.h"
#import "KCSClient.h"
#import "KinveyCoreInternal.h"
#import "KinveyUser.h"
#import "KinveyCollection.h"
#import "KCSObjectMapper.h"

@interface KCSDataModel ()
@property (nonatomic, strong) NSMutableDictionary* collectionMap;
@end

@implementation KCSDataModel

- (id)init
{
    self = [super init];
    if (self) {
        _collectionMap = [NSMutableDictionary dictionary];
        [self setClass:[KCSUser class]
         forCollection:KCSUserCollectionName];
    }
    return self;
}

- (void) setClass:(Class)class forCollection:(NSString*)collection
{
    if (class == nil || collection == nil) {
        KCSLogError(KCS_LOG_CONTEXT_DATA, @"Setting nil class (%@) or collection (%@) into data model", class, collection);
        return;
    }
    
    if (_collectionMap[collection] != nil && [_collectionMap[collection]  isEqual:class] == NO) {
        //TODO: make this robust - either ignore, overwrite, or make configurable
        NSAssert(NO, @"More than one class defined for a collection");
    }
    _collectionMap[collection] = class;
}

- (id<KCSPersistable>) objectFromCollection:(NSString*)collection data:(NSDictionary*)entity
{
    if (!entity) return nil;
    Class class = _collectionMap[collection];
    if (!class) {
        KCSLogWarn(KCS_LOG_CONTEXT_DATA, @"No class registered for collection '%@', using NSMutableDictionary.", collection);
        class = [NSMutableDictionary class];
    }
    return [KCSObjectMapper makeObjectOfType:class withData:entity];
}

- (void) updateObject:(id<KCSPersistable>)object withEntity:(NSDictionary*)entity atRoute:(NSString*)route collection:(NSString*)collection
{
    [KCSObjectMapper populateObject:object withData:entity];
}


- (NSDictionary*) jsonEntityForObject:(id<KCSPersistable>)object route:(NSString*)route collection:(NSString*)collection
{
    if (!_collectionMap[collection]) {
        _collectionMap[collection] = [object class];
    }
    
    NSError* error = nil;
    KCSSerializedObject* obj = [KCSObjectMapper makeKinveyDictionaryFromObject:object error:&error];
    KCSLogNSError(KCS_LOG_CONTEXT_DATA, error);
    return obj.dataToSerialize;
}

@end
