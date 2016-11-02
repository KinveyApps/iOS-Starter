//
//  KNVDataStore.h
//  Kinvey
//
//  Created by Victor Barros on 2016-03-04.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KNVReadPolicy.h"
#import "KNVWritePolicy.h"

@class KNVQuery;
@protocol KNVPersistable;

NS_SWIFT_UNAVAILABLE("Please use 'DataStoreType' enum")
typedef NS_ENUM(NSUInteger, KNVDataStoreType) {
    KNVDataStoreTypeSync,
    KNVDataStoreTypeCache,
    KNVDataStoreTypeNetwork
};

#define KNVDataStoreHandler(T) void(^ _Nullable)(T, NSError* _Nullable)
#define KNVDataStoreHandler2(T1, T2) void(^ _Nullable)(T1, T2, NSError* _Nullable)

NS_SWIFT_UNAVAILABLE("Please use 'DataStore' class")
@interface KNVDataStore<T: NSObject<KNVPersistable>*> : NSObject

@property (nonatomic, assign) NSTimeInterval ttl;

+(instancetype _Nonnull)getInstance:(KNVDataStoreType)type
                           forClass:(Class _Nonnull)cls;

-(id<KNVRequest> _Nonnull)save:(T _Nonnull)persistable
             completionHandler:(KNVDataStoreHandler(T _Nullable))completionHandler;

-(id<KNVRequest> _Nonnull)save:(T _Nonnull)persistable
                  writePolicty:(KNVWritePolicy)writePolicy
             completionHandler:(KNVDataStoreHandler(T _Nullable))completionHandler;

-(id<KNVRequest> _Nonnull)find:(KNVDataStoreHandler(NSArray<T>* _Nullable))completionHandler;

-(id<KNVRequest> _Nonnull)find:(KNVQuery* _Nullable)query
             completionHandler:(KNVDataStoreHandler(NSArray<T>* _Nullable))completionHandler;

-(id<KNVRequest> _Nonnull)find:(KNVQuery* _Nullable)query
                    readPolicy:(KNVReadPolicy)readPolicy
             completionHandler:(KNVDataStoreHandler(NSArray<T>* _Nullable))completionHandler;

-(id<KNVRequest> _Nonnull)remove:(NSObject<KNVPersistable>* _Nonnull)persistable
               completionHandler:(KNVDataStoreHandler(NSUInteger))completionHandler;

-(id<KNVRequest> _Nonnull)remove:(NSObject<KNVPersistable>* _Nonnull)persistable
                     writePolicy:(KNVWritePolicy)writePolicy
               completionHandler:(KNVDataStoreHandler(NSUInteger))completionHandler;

-(id<KNVRequest> _Nonnull)removeById:(NSString* _Nonnull)objectId
                   completionHandler:(KNVDataStoreHandler(NSUInteger))completionHandler;

-(id<KNVRequest> _Nonnull)removeById:(NSString* _Nonnull)objectId
                         writePolicy:(KNVWritePolicy)writePolicy
                   completionHandler:(KNVDataStoreHandler(NSUInteger))completionHandler;

-(id<KNVRequest> _Nonnull)removeByIds:(NSArray<NSString*>* _Nonnull)ids
                    completionHandler:(KNVDataStoreHandler(NSUInteger))completionHandler;

-(id<KNVRequest> _Nonnull)removeByIds:(NSArray<NSString*>* _Nonnull)ids
                          writePolicy:(KNVWritePolicy)writePolicy
                    completionHandler:(KNVDataStoreHandler(NSUInteger))completionHandler;

-(id<KNVRequest> _Nonnull)removeAll:(KNVDataStoreHandler(NSUInteger))completionHandler;

-(id<KNVRequest> _Nonnull)removeAllWithWritePolicy:(KNVWritePolicy)writePolicy
                                 completionHandler:(KNVDataStoreHandler(NSUInteger))completionHandler;

-(id<KNVRequest> _Nonnull)removeWithQuery:(KNVQuery* _Nullable)query
                        completionHandler:(KNVDataStoreHandler(NSUInteger))completionHandler;

-(id<KNVRequest> _Nonnull)removeWithQuery:(KNVQuery* _Nullable)query
                              writePolicy:(KNVWritePolicy)writePolicy
                        completionHandler:(KNVDataStoreHandler(NSUInteger))completionHandler;

-(id<KNVRequest> _Nonnull)push:(KNVDataStoreHandler(NSUInteger))completionHandler;

-(id<KNVRequest> _Nonnull)pull:(KNVDataStoreHandler(NSArray<T>* _Nullable))completionHandler;

-(id<KNVRequest> _Nonnull)pullWithQuery:(KNVQuery* _Nullable)query
                      completionHandler:(KNVDataStoreHandler(NSArray<T>* _Nullable))completionHandler;

-(id<KNVRequest> _Nonnull)purge:(KNVDataStoreHandler(NSUInteger))completionHandler;

-(id<KNVRequest> _Nonnull)purgeWithQuery:(KNVQuery* _Nullable)query
                       completionHandler:(KNVDataStoreHandler(NSUInteger))completionHandler;

-(id<KNVRequest> _Nonnull)sync:(KNVDataStoreHandler2(NSUInteger, NSArray<T>* _Nullable))completionHandler;

-(id<KNVRequest> _Nonnull)syncWithQuery:(KNVQuery* _Nullable)query
                      completionHandler:(KNVDataStoreHandler2(NSUInteger, NSArray<T>* _Nullable))completionHandler;

@end
