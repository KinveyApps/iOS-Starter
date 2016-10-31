//
//  KCSOfflineUpdate.m
//  KinveyKit
//
//  Created by Michael Katz on 11/12/13.
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

#if TARGET_OS_IPHONE
@import UIKit;
#endif

#import "KCSOfflineUpdate.h"
#import "KinveyCoreInternal.h"
#import "KinveyDataStoreInternal.h"
#import "KCSReachability.h"
#import "KCSEntityPersistence.h"
#import "KinveyUser.h"
#import "KCSDBTools.h"
#import "KinveyErrorCodes.h"
#import "KinveyPersistable.h"

#define DELEGATEMETHOD(m) if (_delegate != nil && [_delegate respondsToSelector:@selector(m)])

@interface KCSOfflineUpdate ()
@property (nonatomic, weak) KCSEntityPersistence* persitence;
@property (nonatomic, weak) KCSObjectCache* cache;
@property (atomic) BOOL drainInProgress;
@end

@implementation KCSOfflineUpdate

- (id) initWithCache:(KCSObjectCache*)cache peristenceLayer:(KCSEntityPersistence*)persitence
{
    self = [super init];
    if (self) {
        _persitence = persitence;
        _cache = cache;
    }
    return self;
}

- (void)dealloc
{
    [self stop];
}

- (void) start
{
#if !TARGET_OS_WATCH
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reach:) name:KCSReachabilityChangedNotification object:nil];
#endif
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:KCSActiveUserChangedNotification object:nil];
#if TARGET_OS_IPHONE && !TARGET_OS_WATCH
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(foreground:) name:UIApplicationDidBecomeActiveNotification object:nil];
#endif
    [self drainQueue];
}

- (void) stop
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#if !TARGET_OS_WATCH
- (void)reach:(NSNotification*)note
{
    KCSReachability* reachability = note.object;
    if (reachability.isReachable) {
        [self drainQueue];
    }
}

- (void)foreground:(NSNotification*)note
{
    KCSReachability* reachability = [KCSClient sharedClient].kinveyReachability;
    if (reachability.isReachable) {
        [self drainQueue];
    }
}
#endif

- (void) userUpdated:(NSNotification*)note
{
    if ([KCSUser activeUser] != nil) {
        [self drainQueue];
    }
}

- (void)hadASucessfulConnection
{
    //TODO    dispatch_async(dispatch_get_main_queue(), ^{, holding off b/c of multiple calls to this on launch/success
        [self drainQueue];
    //    });
}

- (NSUInteger) count
{
    return [self.persitence unsavedCount];
}

- (void) drainQueue
{
    if (_delegate && [KCSUser activeUser] != nil && self.drainInProgress == NO) {
        self.drainInProgress = YES;
        NSArray* unsavedEntities = [self.persitence unsavedEntities];
        for (NSDictionary* d in unsavedEntities) {
            NSString* method = d[@"method"];
            if ([method isEqualToString:KCSRESTMethodDELETE]) {
                [self processDelete:d];
            } else {
                [self processSave:d];
            }
        }
        self.drainInProgress = NO;
    }
}

- (void)setDelegate:(id<KCSOfflineUpdateDelegate>)delegate
{
    _delegate = delegate;
    [self start];
}

#pragma mark - Saves
- (void) processSave:(NSDictionary*)saveInfo
{
    NSString* objId = saveInfo[KCSEntityKeyId];
    NSString* route = saveInfo[@"route"];
    NSString* collection = saveInfo[@"collection"];
    NSDate* lastSaveTime = saveInfo[@"time"];
    NSString* method = saveInfo[@"method"];
    
    
    BOOL shouldSave = YES;
    DELEGATEMETHOD(shouldSaveObject:inCollection:lastAttemptedSaveTime:) {
        shouldSave = [_delegate shouldSaveObject:objId inCollection:collection lastAttemptedSaveTime:lastSaveTime];
    }
    
    NSDictionary* headers = saveInfo[@"headers"];
    
    if (shouldSave == YES) {
        NSMutableDictionary* entity = [NSMutableDictionary dictionaryWithDictionary:saveInfo[@"obj"]];
        if ([KCSDBTools isKCSMongoObjectId:objId]) {
            [entity removeObjectForKey:KCSEntityKeyId];
        }
        [self save:objId
            entity:entity
             route:route
        collection:collection
           headers:headers
            method:method];
    } else {
        [self.persitence removeUnsavedEntity:objId
                                       route:route
                                  collection:collection
                                     headers:headers];
    }
}

- (NSDictionary*) optionsFromHeaders:(NSDictionary*)headers
{
    NSMutableDictionary* options = [NSMutableDictionary dictionary];
    if (self.useMock) {
        options[KCSRequestOptionUseMock] = @YES;
    }
    if (headers[KCSRequestOptionClientMethod]) {
        options[KCSRequestOptionClientMethod] = headers[KCSRequestOptionClientMethod];
    }
    return options;
}


- (void) save:(NSString*)objId entity:(NSDictionary*)entity route:(NSString*)route collection:(NSString*)collection headers:(NSDictionary*)headers method:(NSString*)method
{
    DELEGATEMETHOD(willSaveObject:inCollection:) {
        [_delegate willSaveObject:entity[KCSEntityKeyId] inCollection:collection];
    }
    
    id credentials = [KCSUser activeUser];
    if (!credentials) {
        NSError* error = [NSError createKCSError:KCSAppDataErrorDomain code:KCSDeniedError userInfo:@{KCSEntityKeyId : objId, NSLocalizedDescriptionKey : NSLocalizedString(@"Could not save object because there is no active user.",nil)}];
        [self addObject:entity route:route collection:collection headers:headers method:method error:error];
    }
    
    NSDictionary* options = [self optionsFromHeaders:headers];
    KCSHttpRequest* request = [KCSHttpRequest requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {
        if (!error) {
            NSDictionary* updatedEntity = [response jsonObjectError:&error];
            if (error) {
                [self addObject:entity route:route collection:collection headers:headers method:method error:error];
            } else {
                [self.persitence removeUnsavedEntity:objId
                                               route:route
                                          collection:collection
                                             headers:headers];
                
                [self.cache updateCacheForObject:objId withEntity:updatedEntity atRoute:route collection:collection];
                DELEGATEMETHOD(didSaveObject:inCollection:) {
                    [_delegate didSaveObject:objId inCollection:collection];
                }
            }
        } else {
            [self addObject:entity route:route collection:collection headers:headers method:method error:error];
        }
    }
                                                        route:route
                                                      options:options
                                                  credentials:credentials];
    BOOL isPost = [method isEqualToString:KCSRESTMethodPOST];
    BOOL isTempObjId = [KCSDBTools isKCSMongoObjectId:objId];
    if (isPost && (objId == nil || isTempObjId)) {
        request.path = @[collection];
    } else {
        if (isPost) {
            method = KCSRESTMethodPUT;
        }
        request.path = @[collection, objId];
    }
    request.method = method;
    request.headers = headers;
    request.body = entity;
    [request start];
}

#pragma mark - deletes
- (void) processDelete:(NSDictionary*)saveInfo
{
    NSString* objId = saveInfo[KCSEntityKeyId];
    NSString* route = saveInfo[@"route"];
    NSString* collection = saveInfo[@"collection"];
    NSDate* lastSaveTime = saveInfo[@"time"];
    NSString* method = saveInfo[@"method"];
    
    
    BOOL shouldDelete = YES;
    DELEGATEMETHOD(shouldDeleteObject:inCollection:lastAttemptedDeleteTime:) {
        shouldDelete = [_delegate shouldDeleteObject:objId inCollection:collection lastAttemptedDeleteTime:lastSaveTime];
    }
    
    NSDictionary* headers = saveInfo[@"headers"];
    
    if (shouldDelete == YES) {
        NSDictionary* entity = saveInfo[@"obj"];
        [self delete:objId entity:entity route:route collection:collection headers:headers method:method];
    } else {
        [self.persitence removeUnsavedEntity:objId
                                       route:route
                                  collection:collection
                                     headers:headers];
    }
}

//TODO: support delete by query
- (void) delete:(NSString*)objId entity:(NSDictionary*)entity route:(NSString*)route collection:(NSString*)collection headers:(NSDictionary*)headers method:(NSString*)method
{
    DELEGATEMETHOD(willDeleteObject:inCollection:) {
        [_delegate willDeleteObject:objId inCollection:collection];
    }
    
    id credentials = [KCSUser activeUser];
    if (!credentials) {
        NSError* error = [NSError createKCSError:KCSAppDataErrorDomain code:KCSDeniedError userInfo:@{KCSEntityKeyId : objId, NSLocalizedDescriptionKey : NSLocalizedString(@"Could not delete object because there is no active user.",nil)}];
        [self addObject:entity route:route collection:collection headers:headers method:method error:error];
    }
    
    NSDictionary* options = [self optionsFromHeaders:headers];
    KCSHttpRequest* request = [KCSHttpRequest requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {
        if (!error) {
            [self.persitence removeUnsavedEntity:objId
                                           route:route
                                      collection:collection
                                         headers:headers];
            [self.cache deleteObject:objId route:route collection:collection];
            DELEGATEMETHOD(didDeleteObject:inCollection:) {
                [_delegate didDeleteObject:objId inCollection:collection];
            }
        } else {
            [self addObject:entity route:route collection:collection headers:headers method:method error:error];
        }
    }
                                                        route:route
                                                      options:options
                                                  credentials:credentials];
    if ([objId hasPrefix:@"?"]) {
        //is a query delete
        request.path = @[collection];
        request.queryString = objId;
    } else {
        request.path = @[collection, objId];
    }

    request.method = method;
    request.headers = headers;
    request.body = @{};
    [request start];
}

#pragma mark - objects
- (NSString*) addObject:(NSDictionary*)entity route:(NSString*)route collection:(NSString*)collection headers:(NSDictionary*)headers method:(NSString*)method error:(NSError*)error
{
    BOOL shouldEnqueue = YES;
    NSString* _id = [entity isKindOfClass:[NSString class]] ? entity : entity[KCSEntityKeyId];
    DELEGATEMETHOD(shouldEnqueueObject:inCollection:onError:) { //TODO: test
        shouldEnqueue = [_delegate shouldEnqueueObject:_id inCollection:collection onError:error];
    }
    
    NSString* newid = nil;
    if (shouldEnqueue) {
        if ([method isEqualToString:KCSRESTMethodDELETE]) {
            BOOL added = [self.persitence addUnsavedDelete:_id route:route collection:collection method:method headers:headers];
            if (added) {
                DELEGATEMETHOD(didEnqueueObject:inCollection:) {
                    [_delegate didEnqueueObject:_id inCollection:collection];
                }
            }
        } else {
            newid = [self.persitence addUnsavedEntity:entity route:route collection:collection method:method headers:headers];
            if (newid != nil) {
                DELEGATEMETHOD(didEnqueueObject:inCollection:) {
                    [_delegate didEnqueueObject:newid inCollection:collection];
                }
            }
        }
       
    }
    return newid;
}

- (BOOL) removeObject:(id)object objKey:(NSString*)key route:(NSString*)route collection:(NSString*)collection headers:(NSDictionary*)headers method:(NSString*)method error:(NSError*)error
{
    BOOL shouldEnqueue = YES;
    DELEGATEMETHOD(shouldEnqueueObject:inCollection:onError:) {
        shouldEnqueue = [_delegate shouldEnqueueObject:object inCollection:collection onError:error];
    }
    
    BOOL added = NO;
    if (shouldEnqueue) {
        added = [self.persitence addUnsavedDelete:key route:route collection:collection method:method headers:headers];
        if (added) {
            DELEGATEMETHOD(didEnqueueObject:inCollection:) {
                [_delegate didEnqueueObject:key inCollection:collection];
            }
        }
    }
    return added;
}

@end
