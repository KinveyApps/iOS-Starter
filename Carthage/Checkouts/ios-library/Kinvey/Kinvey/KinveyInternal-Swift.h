//
//  KinveyInternal-Swift.h
//  Kinvey
//
//  Created by Victor Barros on 2016-03-01.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Kinvey/Kinvey-Swift.h>

@class __KNVCacheManager;

@interface NSString ()

-(NSDate* _Nullable)toDate;

@end

@interface KNVRealmEntitySchema : NSObject

+(NSString* _Nullable)realmClassNameForClass:(Class _Nonnull)cls;

@end

@protocol KNVPendingOperation

@property (nonatomic, readonly, copy) NSString * _Nullable objectId;

- (NSURLRequest * _Nonnull)buildRequest;

@end

@protocol __KNVSync

@property (nonatomic, copy) NSString * _Nonnull persistenceId;
@property (nonatomic, copy) NSString * _Nonnull collectionName;

- (null_unspecified instancetype)initWithPersistenceId:(NSString * _Nonnull)persistenceId
                                        collectionName:(NSString * _Nonnull)collectionName;

- (id <KNVPendingOperation> _Nonnull)createPendingOperation:(NSURLRequest * _Null_unspecified)request
                                                   objectId:(NSString * _Nullable)objectId;

- (void)savePendingOperation:(id <KNVPendingOperation> _Nonnull)pendingOperation;
- (NSArray<id <KNVPendingOperation>> * _Nonnull)pendingOperations;
- (NSArray<id <KNVPendingOperation>> * _Nonnull)pendingOperations:(NSString * _Nullable)objectId;
- (void)removePendingOperation:(id <KNVPendingOperation> _Nonnull)pendingOperation;
- (void)removeAllPendingOperations;
- (void)removeAllPendingOperations:(NSString * _Nullable)objectId;

@end

@protocol __KNVCache

@property (nonatomic, copy) NSString * _Nonnull persistenceId;
@property (nonatomic, copy) NSString * _Nonnull collectionName;
@property (nonatomic) NSTimeInterval ttl;

- (void)saveEntity:(NSDictionary<NSString *, id> * _Nonnull)entity;
- (void)saveEntities:(NSArray<NSDictionary<NSString *, id> *> * _Nonnull)entities;
- (NSDictionary<NSString *, id> * _Nullable)findEntity:(NSString * _Nonnull)objectId;
- (NSArray<NSDictionary<NSString *, id> *> * _Nonnull)findEntityByQuery:(KNVQuery * _Nonnull)query;
- (NSDictionary<NSString *, NSString *> * _Nonnull)findIdsLmtsByQuery:(KNVQuery * _Nonnull)query;
- (NSArray<NSDictionary<NSString *, id> *> * _Nonnull)findAll;
- (NSUInteger)count;
- (BOOL)removeEntity:(NSDictionary<NSString *, id> * _Nonnull)entity;
- (NSUInteger)removeEntitiesByQuery:(KNVQuery * _Nonnull)query;
- (void)removeAllEntities;

@end

@interface __KNVSyncManager : NSObject

- (id <__KNVSync> _Nonnull)sync:(NSString * _Nonnull)collectionName;

@end

@interface __KNVCacheManager : NSObject

- (id <__KNVCache> _Nonnull)cache:(NSString * _Nullable)collectionName;

@end

@interface __KNVClient (Kinvey)

@property (nonatomic, readonly, strong) __KNVCacheManager * _Null_unspecified cacheManager;
@property (nonatomic, readonly, strong) __KNVSyncManager * _Null_unspecified syncManager;

@end

@interface __KNVOperation : NSObject
@end

@interface __KNVReadOperation : __KNVOperation

- (id <KNVRequest> _Nonnull)execute:(void (^ _Nullable)(id _Nullable, NSError * _Nullable))completionHandler;

@end

@interface __KNVWriteOperation : __KNVOperation

- (id <KNVRequest> _Nonnull)execute:(void (^ _Nullable)(id _Nullable, NSError * _Nullable))completionHandler;

@end

@interface __KNVError : NSObject

+ (NSError * _Nonnull)ObjectIdMissing;
+ (NSError * _Nonnull)InvalidResponse;
+ (NSError * _Nonnull)NoActiveUser;
+ (NSError * _Nonnull)RequestCancelled;
+ (NSError * _Nonnull)InvalidStoreType;

+ (NSError * _Nonnull)buildUnknownError:(NSString * _Nonnull)error;
+ (NSError * _Nonnull)buildUnknownJsonError:(NSDictionary<NSString *, id> * _Nonnull)json;

@end

@interface __KNVLocalRequest : NSObject <KNVRequest>

@property (nonatomic, readonly) BOOL executing;
@property (nonatomic, readonly) BOOL cancelled;

- (void)cancel;

@end

@interface __KNVMultiRequest : NSObject <KNVRequest>

@property (nonatomic, readonly) BOOL executing;
@property (nonatomic, readonly) BOOL cancelled;

- (void)addRequest:(id <KNVRequest> _Nonnull)request;
- (void)cancel;
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;

@end

@interface __KNVObjCRuntime : NSObject

+ (NSArray<NSString *> * _Nullable)propertyNamesForTypeInClass:(Class _Nonnull)cls type:(Class _Nonnull)type;
+ (Class _Nullable)typeForPropertyName:(Class _Nonnull)cls propertyName:(NSString * _Nonnull)propertyName;

@end
