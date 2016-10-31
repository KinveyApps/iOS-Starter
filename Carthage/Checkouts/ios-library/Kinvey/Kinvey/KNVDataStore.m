//
//  KNVDataStore.m
//  Kinvey
//
//  Created by Victor Barros on 2016-03-04.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import "KNVDataStore.h"
#import "KNVClient+Internal.h"
#import "KNVError.h"

@interface KNVDataStore ()

@property KNVDataStoreType type;
@property KNVClient* client;
@property Class<KNVPersistable> cls;

@property id<__KNVSync>sync;
@property id<__KNVCache>cache;

@property KNVWritePolicy writePolicy;
@property KNVReadPolicy readPolicy;

@end

#define KNV_PERSISTABLE NSObject<KNVPersistable>*

#define KNV_DISPATCH_ASYNC_MAIN_QUEUE(R, completionHandler) \
^(R obj, NSError * _Nullable error) { \
    if (!completionHandler) return; \
    dispatch_async(dispatch_get_main_queue(), ^{ \
        completionHandler(obj, error); \
    }); \
}

#define KNV_DISPATCH_ASYNC_MAIN_QUEUE_2(R1, R2, completionHandler) \
^(R1 obj1, R2 obj2, NSError * _Nullable error) { \
    if (!completionHandler) return; \
    dispatch_async(dispatch_get_main_queue(), ^{ \
        completionHandler(obj1, obj2, error); \
    }); \
}

#define KNV_CHECK_DATA_STORE_TYPE(T, R) \
if (self.type != KNVDataStoreTypeSync) { \
    KNV_DISPATCH_ASYNC_MAIN_QUEUE(T, completionHandler)(R, [KNVError InvalidStoreType]); \
    return [__KNVLocalRequest new]; \
}

#define KNV_CHECK_DATA_STORE_TYPE_2(T1, R1, T2, R2) \
if (self.type != KNVDataStoreTypeSync) { \
    KNV_DISPATCH_ASYNC_MAIN_QUEUE_2(T1, T2, completionHandler)(R1, R2, [KNVError InvalidStoreType]); \
    return [__KNVLocalRequest new]; \
}

#define KNV_QUERY(query) [__KNVQuery query:query ? query : [KNVQuery new] persistableType:self.cls]

@implementation KNVDataStore

+(instancetype)getInstance:(KNVDataStoreType)type
                  forClass:(Class<KNVPersistable>)cls
{
    return [[KNVDataStore alloc] initWithType:type
                                     forClass:cls
                                       client:[KNVClient sharedClient]];
}

+(instancetype)getInstance:(KNVDataStoreType)type
                  forClass:(Class<KNVPersistable>)cls
                    client:(KNVClient*)client
{
    return [[KNVDataStore alloc] initWithType:type
                                     forClass:cls
                                       client:client];
}

-(instancetype)init
{
    NSString* reason = @"Please use the 'getInstance' class method";
    @throw [NSException exceptionWithName:NSInvalidArgumentException
                                   reason:reason
                                 userInfo:@{NSLocalizedDescriptionKey : reason,
                                            NSLocalizedFailureReasonErrorKey : reason}];
}

-(instancetype)initWithType:(KNVDataStoreType)type
                   forClass:(Class<KNVPersistable>)cls
                     client:(KNVClient*)client
{
    self = [super init];
    if (self) {
        self.type = type;
        switch (type) {
            case KNVDataStoreTypeCache:
                self.readPolicy = KNVReadPolicyBoth;
                self.writePolicy = KNVWritePolicyLocalThenNetwork;
                break;
            case KNVDataStoreTypeNetwork:
                self.readPolicy = KNVReadPolicyForceNetwork;
                self.writePolicy = KNVWritePolicyForceNetwork;
                break;
            case KNVDataStoreTypeSync:
                self.readPolicy = KNVReadPolicyForceLocal;
                self.writePolicy = KNVWritePolicyForceLocal;
                break;
        }
        self.cls = cls;
        self.client = client;
//        self.cache = [client.client.cacheManager cache:[cls kinveyCollectionName]];
//        self.sync = [client.client.syncManager sync:[cls kinveyCollectionName]];
    }
    return self;
}

-(void)setTtl:(NSTimeInterval)ttl
{
    _ttl = ttl;
    self.cache.ttl = ttl;
}

-(id<KNVRequest>)save:(KNV_PERSISTABLE)persistable
    completionHandler:(KNVDataStoreHandler(KNV_PERSISTABLE))completionHandler
{
    return [self save:persistable
         writePolicty:self.writePolicy
    completionHandler:completionHandler];
}

-(id<KNVRequest>)find:(KNVDataStoreHandler(NSArray<KNV_PERSISTABLE>*))completionHandler
{
    return [self find:nil
    completionHandler:completionHandler];
}

-(id<KNVRequest>)find:(KNVQuery *)query
    completionHandler:(KNVDataStoreHandler(NSArray<KNV_PERSISTABLE>*))completionHandler
{
    return [self find:query
           readPolicy:self.readPolicy
    completionHandler:completionHandler];
}

-(id<KNVRequest>)remove:(KNV_PERSISTABLE)persistable
      completionHandler:(KNVDataStoreHandler(NSUInteger))completionHandler
{
    return [self remove:persistable
            writePolicy:self.writePolicy
      completionHandler:completionHandler];
}

-(id<KNVRequest>)removeAll:(KNVDataStoreHandler(NSUInteger))completionHandler
{
    return [self removeWithQuery:nil
               completionHandler:completionHandler];
}

-(id<KNVRequest>)removeAllWithWritePolicy:(KNVWritePolicy)writePolicy
                        completionHandler:(KNVDataStoreHandler(NSUInteger))completionHandler
{
    return [self removeWithQuery:nil
                     writePolicy:writePolicy
               completionHandler:completionHandler];
}

-(id<KNVRequest>)removeWithQuery:(KNVQuery*)query
               completionHandler:(KNVDataStoreHandler(NSUInteger))completionHandler
{
    return [self removeWithQuery:query
                     writePolicy:self.writePolicy
               completionHandler:completionHandler];
}

-(id<KNVRequest>)pull:(KNVDataStoreHandler(NSArray<KNV_PERSISTABLE>* _Nullable))completionHandler
{
    return [self pullWithQuery:nil
             completionHandler:completionHandler];
}

-(id<KNVRequest>)purge:(KNVDataStoreHandler(NSUInteger))completionHandler
{
    return [self purgeWithQuery:nil
              completionHandler:completionHandler];
}

-(id<KNVRequest>)sync:(KNVDataStoreHandler2(NSUInteger, NSArray<KNV_PERSISTABLE>*))completionHandler
{
    return [self syncWithQuery:nil
             completionHandler:completionHandler];
}

-(id<KNVRequest>)syncWithQuery:(KNVQuery*)query
             completionHandler:(KNVDataStoreHandler2(NSUInteger, NSArray<KNV_PERSISTABLE>*))completionHandler
{
    KNV_CHECK_DATA_STORE_TYPE_2(NSUInteger, 0, NSArray<KNV_PERSISTABLE>*, nil)
    
    __KNVMultiRequest *requests = [__KNVMultiRequest new];
    id<KNVRequest> request = [self push:^(NSUInteger count, NSError * _Nullable error) {
        if (!error) {
            id<KNVRequest> request = [self pullWithQuery:query
                                       completionHandler:^(NSArray * _Nullable results, NSError * _Nullable error)
            {
                if (completionHandler) completionHandler(count, results, error);
            }];
            [requests addRequest:(id<KNVRequest>)request];
        } else {
            if (completionHandler) completionHandler(count, nil, error);
        }
    }];
    [requests addRequest:(id<KNVRequest>)request];
    return requests;
}

@end
