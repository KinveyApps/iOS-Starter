//
//  KCSBackgroundAppdataStore.m
//  KinveyKit
//
//  Created by Michael Katz on 1/9/14.
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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"

#import "KCSBackgroundAppdataStore.h"

#import "KCSAppdataStore.h"

#import "KCSLogManager.h"
#import "KinveyErrorCodes.h"
#import "KCSErrorUtilities.h"
#import "NSArray+KinveyAdditions.h"
#import "KCSObjectMapper.h"
#import "KCSHiddenMethods.h"
#import "KCSSaveGraph.h"
#import "KCSObjectCache.h"
#import "KCSHttpRequest.h"
#import "NSError+KinveyKit.h"
#import "KCSClient+KinveyDataStore.h"
#import "KinveyDataStore.h"
#import "KCSNetworkResponse.h"
#import "KCSNetworkOperation.h"

#import "KCSCachedStore.h"
#import "KCSAppdataStore.h"
#import "KCSDataModel.h"
#import "EXTScope.h"
#import "NSString+KinveyAdditions.h"
#import "KCSRequest+Private.h"
#import "KCSMultipleRequest.h"
#import "KCSPrivateBlockDefs.h"

#define KCSSTORE_VALIDATE_PRECONDITION KCSSTORE_VALIDATE_PRECONDITION_RETURN()

#define KCSSTORE_VALIDATE_PRECONDITION_RETURN(x) BOOL okayToProceed = [self validatePreconditionsAndSendErrorTo:completionBlock]; \
if (okayToProceed == NO) { \
return x; \
}

#define KCS_OBJECT_LIMIT 10000
#define KCS_OBJECT_IDS_PER_QUERY 200

@interface KCSBackgroundAppdataStore () {
    KCSSaveGraph* _previousProgress;
    NSString* _title;
}

@property (nonatomic) BOOL treatSingleFailureAsGroupFailure;
@property (nonatomic) BOOL offlineUpdateEnabled;
@property (nonatomic, readwrite) KCSCachePolicy cachePolicy;
@property (nonatomic, strong) KCSCollection *backingCollection;
@property (nonatomic, strong) dispatch_queue_t queue;

- (id) manufactureNewObject:(NSDictionary*)jsonDict resourcesOrNil:(NSMutableDictionary*)resources;

@end

@implementation KCSBackgroundAppdataStore

#pragma mark - Initialization

- (instancetype)init
{
    return [self initWithAuth:nil];
}

- (instancetype)initWithAuth: (KCSAuthHandler *)auth
{
    self = [super init];
    if (self) {
        _treatSingleFailureAsGroupFailure = YES;
        _cachePolicy = [KCSCachedStore defaultCachePolicy];
        _title = nil;
        _queue = dispatch_queue_create("com.kinvey.KCSBackgroundAppdataStore", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

+ (instancetype)store
{
    return [self storeWithOptions:nil];
}

+ (instancetype) storeWithOptions: (NSDictionary *)options
{
    return  [self storeWithCollection:nil options:options];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
+ (instancetype) storeWithAuthHandler: (KCSAuthHandler *)authHandler withOptions: (NSDictionary *)options
#pragma clang diagnostic pop
{
    return [self storeWithCollection:nil options:options];
}

+ (instancetype) storeWithCollection:(KCSCollection*)collection options:(NSDictionary*)options
{
    
    if (options == nil) {
        options = @{ KCSStoreKeyResource : collection };
    } else {
        options = [NSMutableDictionary dictionaryWithDictionary:options];
        if (collection) {
            [options setValue:collection forKey:KCSStoreKeyResource];
        }
    }
    KCSAppdataStore* store = [[self alloc] init];
    [store configureWithOptions:options];
    return store;
}

+ (instancetype) storeWithCollection:(KCSCollection*)collection authHandler:(KCSAuthHandler *)authHandler withOptions: (NSDictionary *)options
{
    return [self storeWithCollection:collection options:options];
}

- (BOOL)configureWithOptions: (NSDictionary *)options
{
    ifNil(options, @{});
    // Configure
    KCSCollection* collection = [options objectForKey:KCSStoreKeyResource];
    if (collection == nil) {
        NSString* collectionName = [options objectForKey:KCSStoreKeyCollectionName];
        if (collectionName != nil) {
            Class objectClass = [options objectForKey:KCSStoreKeyCollectionTemplateClass];
            if (objectClass == nil) {
                objectClass = [NSMutableDictionary class];
            }
            collection = [KCSCollection collectionFromString:collectionName ofClass:objectClass];
        }
    }
    self.backingCollection = collection;
    //        NSString* queueId = [options valueForKey:KCSStoreKeyUniqueOfflineSaveIdentifier];
    //        if (queueId == nil)
    //            queueId = [self description];
    //        //        _saveQueue = [KCSSaveQueue saveQueueForCollection:self.backingCollection uniqueIdentifier:queueId];
    //        self.cache2 = [[KCSObjectCache alloc] init]; //TODO: use persistence key
    //
    //        _offlineSaveEnabled = [options valueForKey:KCSStoreKeyUniqueOfflineSaveIdentifier] != nil;
    //
    //        //TODO: use delegate in c2
    //        id del = [options valueForKey:KCSStoreKeyOfflineSaveDelegate];
    //#warning        _saveQueue.delegate = del;
    
    
    _previousProgress = [options objectForKey:KCSStoreKeyOngoingProgress];
    _title = [options objectForKey:KCSStoreKeyTitle];
    
    KCSCachePolicy cachePolicy = (options[KCSStoreKeyCachePolicy] == nil) ? [KCSCachedStore defaultCachePolicy] : [options[KCSStoreKeyCachePolicy] intValue];
    self.cachePolicy = cachePolicy;
    [[[KCSAppdataStore caches] dataModel] setClass:self.backingCollection.objectTemplate forCollection:self.backingCollection.collectionName];
    
    self.offlineUpdateEnabled = [options[KCSStoreKeyOfflineUpdateEnabled] boolValue];
    
    
    if (self.backingCollection == nil) {
        [[NSException exceptionWithName:NSInvalidArgumentException reason:@"Collection cannot be nil" userInfo:options] raise];
    }
    
    // Even if nothing happened we return YES (as it's not a failure)
    return YES;
}

#pragma mark - Block Making
- (NSError*) noCollectionError
{
    NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"This store is not associated with a resource."
                                                                       withFailureReason:@"Store's collection is nil"
                                                                  withRecoverySuggestion:@"Create a store with KCSCollection object for  'kKCSStoreKeyResource'."
                                                                     withRecoveryOptions:nil];
    return [NSError errorWithDomain:KCSAppDataErrorDomain code:KCSNotFoundError userInfo:userInfo];
}

- (BOOL) validatePreconditionsAndSendErrorTo:(void(^)(id objs, NSError* error))completionBlock
{
    if (completionBlock == nil) {
        return NO;
    }
    
    BOOL okay = YES;
    KCSCollection* collection = self.backingCollection;
    if (collection == nil) {
        completionBlock(nil, [self noCollectionError]);
    }
    return okay;
}

#pragma mark - Querying/Fetching
//for overriding by subclasses (simpler than strategy, for now)
-(id)manufactureNewObject:(NSDictionary*)jsonDict
           resourcesOrNil:(NSMutableDictionary*)resources
{
    return [KCSObjectMapper makeObjectOfType:self.backingCollection.objectTemplate withData:jsonDict];
}

-(id)manufactureNewObject:(NSDictionary*)jsonDict
           resourcesOrNil:(NSMutableDictionary*)resources
                   object:(id*)obj
{
    return [KCSObjectMapper makeObjectOfType:self.backingCollection.objectTemplate
                                    withData:jsonDict
                      withResourceDictionary:resources
                                      object:obj];
}

- (NSString*) getObjIdFromObject:(id)object completionBlock:(KCSCompletionBlock)completionBlock
{
    NSString* theId = nil;
    if ([object isKindOfClass:[NSString class]]) {
        theId = object;
    } else if ([object conformsToProtocol:@protocol(KCSPersistable)]) {
        theId = [object kinveyObjectId];
        if (theId == nil) {
            NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Invalid object ID."
                                                                               withFailureReason:@"Object id cannot be empty."
                                                                          withRecoverySuggestion:nil
                                                                             withRecoveryOptions:nil];
            NSError* error = [NSError errorWithDomain:KCSAppDataErrorDomain code:KCSInvalidArgumentError userInfo:userInfo];
            completionBlock(nil, error);
        }
    } else {
        NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Invalid object ID."
                                                                           withFailureReason:@"Object id must be a NSString."
                                                                      withRecoverySuggestion:nil
                                                                         withRecoveryOptions:nil];
        NSError* error = [NSError errorWithDomain:KCSAppDataErrorDomain code:KCSInvalidArgumentError userInfo:userInfo];
        completionBlock(nil, error);
    }
    return theId;
}

-(void)handleLoadResponse:(KCSNetworkResponse*)response
                    error:(NSError*)error
          completionBlock:(KCSCompletionBlock)completionBlock
{
    [self handleLoadResponse:response
                       error:error
             completionBlock:completionBlock
               requestObject:nil];
}

-(BOOL)isMutableObject:(id)object
{
    if (object) {
        if ([object isKindOfClass:[NSDictionary class]]) {
            return [object isKindOfClass:[NSMutableDictionary class]];
        } else if ([object isKindOfClass:[NSArray class]]) {
            return [object isKindOfClass:[NSMutableArray class]];
        }
    }
    return NO;
}

-(void)handleLoadResponse:(KCSNetworkResponse*)response
                    error:(NSError*)error
          completionBlock:(KCSCompletionBlock)completionBlock
            requestObject:(id)requestObject
{
    if (response) NSAssert(![NSThread isMainThread], @"%s should not run in the main thread", __FUNCTION__);
    if (error) {
        completionBlock(nil, error);
    } else {
        NSDictionary* jsonResponse = [response jsonObjectError:&error];
        if (error) {
            completionBlock(nil, error);
        } else {
            NSArray* jsonArray = [NSArray wrapIfNotArray:jsonResponse];
            NSUInteger itemCount = jsonArray.count;
            if (itemCount == 0) {
                completionBlock(@[], nil);
            } else if (itemCount == KCS_OBJECT_LIMIT) {
                KCSLogWarning(@"Returned exactly %i objects. This is the Kinvey limit for a query, and there may actually be more results. If this is the case use the limit & skip modifiers on `KCSQuery` to page through the results.", KCS_OBJECT_LIMIT);
            }
            __block NSUInteger completedCount = 0;
            __block NSError* resourceError = nil;
            NSMutableArray* returnObjects = [NSMutableArray arrayWithCapacity:itemCount];
            for (NSDictionary* jsonDict in jsonArray) {
                NSMutableDictionary* resources = [NSMutableDictionary dictionary];
                id newobj = [self manufactureNewObject:jsonDict resourcesOrNil:resources object:[self isMutableObject:requestObject] ? &requestObject : nil];
                [returnObjects addObject:newobj];
                NSUInteger resourceCount = resources.count;
                if ( resourceCount > 0 ) {
                    //need to load the resources
                    __block NSUInteger completedResourceCount = 0;
                    [resources enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                        [KCSFileStore downloadKCSFile:obj completionBlock:^(NSArray *downloadedResources, NSError *error) {
                            completedResourceCount++;
                            if (error != nil) {
                                resourceError = error;
                            }
                            if (downloadedResources != nil && downloadedResources.count > 0) {
                                KCSFile* downloadedFile = downloadedResources[0];
                                id loadedResource = [downloadedFile resolvedObject];
                                [newobj setValue:loadedResource forKey:key];
                            } else {
                                //set nil for the resource
                                [newobj setValue:nil forKey:key];
                            }
                            if (completedResourceCount == resourceCount) {
                                //all resources loaded
                                completedCount++;
                                if (completedCount == itemCount) {
                                    completionBlock(returnObjects, resourceError);
                                }
                            }
                        } progressBlock:^(NSArray *objects, double percentComplete) {
                            //TODO: sub progress
                        }];
                    }];
                } else {
                    //no linked resources
                    completedCount++;
                    if (completedCount == itemCount) {
                        completionBlock(returnObjects, resourceError);
                    }
                }
            }
        }
    }
}

- (NSString*)refStr
{
    return nil;
}

-(KCSRequest*)loadByIds:(NSArray*)objectIDs
                   skip:(NSUInteger)skip
                results:(NSMutableArray*)results
               requests:(KCSMultipleRequest*)requests
    withCompletionBlock:(KCSCompletionBlock)completionBlock
      withProgressBlock:(KCSProgressBlock)progressBlock
{
    KCSQuery* query = [self queryForObjects:objectIDs skip:skip];
    return [self doQueryWithQuery:query
              withCompletionBlock:^(NSArray *objects, NSError *errorOrNil)
    {
        if (objects) {
            [results addObjectsFromArray:objects];
        }
        if (errorOrNil) {
            completionBlock(results, errorOrNil);
        } else {
            NSUInteger next = MIN(skip + KCS_OBJECT_IDS_PER_QUERY, objectIDs.count);
            if (next < objectIDs.count) {
                if (progressBlock) {
                    progressBlock(results, (double) results.count / (double) objectIDs.count);
                }
                KCSRequest* request = [self loadByIds:objectIDs
                                                 skip:next
                                              results:results
                                             requests:requests
                                  withCompletionBlock:completionBlock
                                    withProgressBlock:progressBlock];
                [requests addRequest:request];
            } else {
                completionBlock(results, errorOrNil);
            }
        }
    } withProgressBlock:nil];
}

-(KCSRequest*)doLoadObjectWithID:(id)objectID
             withCompletionBlock:(KCSCompletionBlock)completionBlock
               withProgressBlock:(KCSProgressBlock)progressBlock;
{
    KCSSTORE_VALIDATE_PRECONDITION_RETURN(nil)
    
    if ([objectID isKindOfClass:[NSArray class]]) {
        if ([objectID containsObject:@""]) {
            NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Invalid object ID."
                                                                               withFailureReason:@"Object id cannot be empty."
                                                                          withRecoverySuggestion:nil
                                                                             withRecoveryOptions:nil];
            NSError* error = [NSError errorWithDomain:KCSAppDataErrorDomain code:KCSInvalidArgumentError userInfo:userInfo];
            completionBlock(nil, error);
            return nil;
        }
        
        NSArray* objectIDs = (NSArray*) objectID;
        if (objectIDs.count > KCS_OBJECT_IDS_PER_QUERY) { //have to splitted in many calls
            KCSMultipleRequest* requests = [KCSMultipleRequest new];
            KCSRequest* request = [self loadByIds:objectIDs
                                             skip:0
                                          results:[NSMutableArray arrayWithCapacity:objectIDs.count]
                                         requests:requests
                              withCompletionBlock:completionBlock
                                withProgressBlock:progressBlock];
            [requests addRequest:request];
            return requests;
        } else { //single call
            KCSQuery* query = [KCSQuery queryOnField:KCSEntityKeyId usingConditional:kKCSIn forValue:objectIDs];
            return [self doQueryWithQuery:query
                      withCompletionBlock:completionBlock
                        withProgressBlock:progressBlock];
        }
    } else {
        NSString* _id = [self getObjIdFromObject:objectID completionBlock:completionBlock];
        if (_id) {
            if ([_id isEqualToString:@""]) {
                NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Invalid object ID."
                                                                                   withFailureReason:@"Object id cannot be empty."
                                                                              withRecoverySuggestion:nil
                                                                                 withRecoveryOptions:nil];
                NSError* error = [NSError errorWithDomain:KCSAppDataErrorDomain code:KCSInvalidArgumentError userInfo:userInfo];
                completionBlock(nil, error);
                return nil;
            } else {
                NSString* route = [self.backingCollection route];
                
                KCSHttpRequest* request = [KCSHttpRequest requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {
                    [self handleLoadResponse:response
                                       error:error
                             completionBlock:completionBlock
                               requestObject:objectID];
                }
                                                                    route:route
                                                                  options:@{KCSRequestLogMethod}
                                                              credentials:[KCSUser activeUser]];
                if (route == KCSRESTRouteAppdata) {
                    request.path = @[self.backingCollection.collectionName, _id];
                } else {
                    request.path = @[_id];
                }
                request.queryString = [self refStr];
                
                request.progress = ^(id data, double progress){
                    if (progressBlock != nil) {
                        progressBlock(nil, progress);
                    }
                };
                return [KCSRequest requestWithNetworkOperation:[request start]];
            }
        } else {
            NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Invalid object ID."
                                                                               withFailureReason:@"Object id cannot be empty."
                                                                          withRecoverySuggestion:nil
                                                                             withRecoveryOptions:nil];
            NSError* error = [NSError errorWithDomain:KCSAppDataErrorDomain code:KCSInvalidArgumentError userInfo:userInfo];
            completionBlock(nil, error);
            return nil;
        }
    }
}


-(KCSRequest*)loadEntityFromNetwork:(id)objectIDs
                withCompletionBlock:(KCSCompletionBlock)completionBlock
                  withProgressBlock:(KCSProgressBlock)progressBlock
                             policy:(KCSCachePolicy)cachePolicy
{
    return [self doLoadObjectWithID:objectIDs
                withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil)
    {
        if ([[errorOrNil domain] isEqualToString:NSURLErrorDomain]  && cachePolicy == KCSCachePolicyNetworkFirst) {
            NSArray* objs = [[KCSAppdataStore caches] pullIds:objectIDs route:[self.backingCollection route] collection:self.backingCollection.collectionName];
            [self completeLoad:objs withCompletionBlock:completionBlock];
        } else {
            [self cacheObjects:objectIDs results:objectsOrNil error:errorOrNil policy:cachePolicy];
            if (completionBlock) completionBlock(objectsOrNil, errorOrNil);
        }
    } withProgressBlock:progressBlock];
}

- (void) completeLoad:(id)obj withCompletionBlock:(KCSCompletionBlock)completionBlock
{
    NSError* error = (obj == nil) ? createCacheError(@"Load query not in cache" ) : nil;
    if (completionBlock) completionBlock(obj, error);
}

-(KCSRequest*)loadObjectWithID:(id)objectID
           withCompletionBlock:(KCSCompletionBlock)completionBlock
             withProgressBlock:(KCSProgressBlock)progressBlock
                   cachePolicy:(KCSCachePolicy)cachePolicy
{
    SWITCH_TO_MAIN_THREAD_COMPLETION_BLOCK(completionBlock);
    SWITCH_TO_MAIN_THREAD_PROGRESS_BLOCK(progressBlock);
    if (objectID == nil) {
        [[NSException exceptionWithName:NSInvalidArgumentException reason:@"objectId is `nil`." userInfo:nil] raise];
    }
    
    //    NSArray* keys = [NSArray wrapIfNotArray:objectID];
    //Hold on the to the object first, in case the cache is cleared during this process
    NSArray* objs = [[KCSAppdataStore caches] pullIds:objectID route:[self.backingCollection route] collection:self.backingCollection.collectionName];
    if ([self shouldCallNetworkFirst:objs cachePolicy:cachePolicy] == YES) {
        return [self loadEntityFromNetwork:objectID
                       withCompletionBlock:completionBlock
                         withProgressBlock:progressBlock
                                    policy:cachePolicy];
    } else {
        [self completeLoad:objs withCompletionBlock:completionBlock];
        if ([self shouldUpdateInBackground:cachePolicy] == YES) {
            KCSMultipleRequest* requests = [[KCSMultipleRequest alloc] init];
            dispatch_async(self.queue, ^{
                //TODO: this is to keep this operation alive now that this method is called on a background thread.
                KK2(use a series of dependent operation blocks)
                KK2(should this use silent bg updates ever? - maybe everything should have a notification that the client can ignore)

                KCSRequest* request = [self loadEntityFromNetwork:objectID
                                              withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil)
                {
                    if ([self shouldIssueCallbackOnBackgroundQuery:cachePolicy] == YES) {
                       completionBlock(objectsOrNil, errorOrNil);
                    }
                }
                                                withProgressBlock:nil
                                                           policy:cachePolicy];
                [requests addRequest:request];
            });
            return requests;
        } else {
            return nil;
        }
    }
}

-(KCSRequest*)loadObjectWithID:(id)objectID
           withCompletionBlock:(KCSCompletionBlock)completionBlock
             withProgressBlock:(KCSProgressBlock)progressBlock
{
    SWITCH_TO_MAIN_THREAD_COMPLETION_BLOCK(completionBlock);
    SWITCH_TO_MAIN_THREAD_PROGRESS_BLOCK(progressBlock);
    return [self loadObjectWithID:objectID
              withCompletionBlock:completionBlock
                withProgressBlock:progressBlock
                      cachePolicy:self.cachePolicy];
}

#pragma mark - Querying
- (KCSQuery*) modifyQuery:(KCSQuery*)query
{
    return query;
}


-(KCSRequest*)doDeltaQueryWithQuery:(KCSQuery*)query
                withCompletionBlock:(KCSDeltaResponseBlock)completionBlock
{
    
    KCSSTORE_VALIDATE_PRECONDITION_RETURN(nil)
    KCSCollection* collection = self.backingCollection;
    NSString* route = [collection route];
    
    KCSHttpRequest* request = [KCSHttpRequest requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {
        NSDictionary* jsonResponse = [response jsonObjectError:&error];
        if (error) {
            completionBlock(nil, error);
        } else {
            NSArray* jsonArray = [NSArray wrapIfNotArray:jsonResponse];
            NSMutableDictionary* retVal = [NSMutableDictionary dictionaryWithCapacity:jsonArray.count];
            for (NSDictionary* jsonDict in jsonArray){
                retVal[jsonDict[@"_id"]] = jsonDict[@"_kmd"][@"lmt"];
            }
            completionBlock(retVal, error);
        }
    }
                                                        route:route
                                                      options:@{KCSRequestLogMethod}
                                                  credentials:[KCSUser activeUser]];
    if (route == KCSRESTRouteAppdata) {
        request.path = @[collection.collectionName];
    } else {
        request.path = @[];
    }
    
    NSString* queryString = [[self modifyQuery:query] parameterStringRepresentation];
    queryString = [queryString stringByAppendingQueryString:@"fields=_id,_kmd"];
    request.queryString = [queryString stringByAppendingQueryString:@"tls=true"];
    
    return [KCSRequest requestWithNetworkOperation:[request start]];
}

-(KCSRequest*)doQueryWithQuery:(KCSQuery*)query
           withCompletionBlock:(KCSCompletionBlock)completionBlock
             withProgressBlock:(KCSProgressBlock)progressBlock
{
    KCSSTORE_VALIDATE_PRECONDITION_RETURN(nil)
    KCSCollection* collection = self.backingCollection;
    NSString* route = [collection route];
    
    KCSHttpRequest* request = [KCSHttpRequest requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {
        [self handleLoadResponse:response error:error completionBlock:completionBlock];
    }
                                                        route:route
                                                      options:@{KCSRequestLogMethod}
                                                  credentials:[KCSUser activeUser]];
    if (route == KCSRESTRouteAppdata) {
        request.path = @[collection.collectionName];
    } else {
        request.path = @[];
    }
    
    NSString* queryString = [[self modifyQuery:query] parameterStringRepresentation];
    request.queryString = [queryString stringByAppendingQueryString:@"tls=true"];
    
    request.progress = ^(id data, double progress){
        if (progressBlock != nil) {
            progressBlock(nil, progress);
        }
    };
    
    return [KCSRequest requestWithNetworkOperation:[request start]];
}

NSError* createCacheError(NSString* message)
{
    NSDictionary* userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:message
                                                                       withFailureReason:@"The specified query could not be found in the cache"
                                                                  withRecoverySuggestion:@"Resend query with cache policy that allows network connectivity"
                                                                     withRecoveryOptions:nil];
    return [NSError errorWithDomain:KCSAppDataErrorDomain code:KCSNotFoundError userInfo:userInfo];
}

- (BOOL) shouldCallNetworkFirst:(id)cachedResult cachePolicy:(KCSCachePolicy)cachePolicy
{
    return cachePolicy == KCSCachePolicyNone ||
           cachePolicy == KCSCachePolicyNetworkFirst ||
           (cachePolicy != KCSCachePolicyLocalOnly && (cachedResult == nil ||
                                                       ([cachedResult isKindOfClass:[NSArray class]] && [cachedResult count] == 0)));
}

- (BOOL) shouldUpdateInBackground:(KCSCachePolicy)cachePolicy
{
    return cachePolicy == KCSCachePolicyLocalFirst || cachePolicy == KCSCachePolicyBoth;
}

- (BOOL) shouldIssueCallbackOnBackgroundQuery:(KCSCachePolicy)cachePolicy
{
    return cachePolicy == KCSCachePolicyBoth;
}

//TODO: should differentiate between ref error and main q error
- (void) cacheQuery:(KCSQuery*)query value:(id)objectsOrNil error:(NSError*)errorOrNil policy:(KCSCachePolicy)cachePolicy
{
    DBAssert([query isKindOfClass:[KCSQuery class]], @"should be a query");
    if ((errorOrNil != nil && ([[errorOrNil domain] isEqualToString:KCSNetworkErrorDomain] == NO || [[errorOrNil domain] isEqualToString:KCSFileStoreErrorDomain] == NO)) ||
        (objectsOrNil == nil && errorOrNil == nil)) {
        //remove the object from the cache, if it exists if the there was an error or return nil, but not if there was a network error (keep using the cached value)
        BOOL removed = [[KCSAppdataStore caches] removeQuery:[KCSQuery2 queryWithQuery1:query] route:[self.backingCollection route] collection:self.backingCollection.collectionName];
        if (!removed) {
            KCSLogError(@"Error clearing query '%@' from cache:", query);
        }
    } else if (objectsOrNil != nil) {
        [[KCSAppdataStore caches] setObjects:objectsOrNil forQuery:[KCSQuery2 queryWithQuery1:query] route:[self.backingCollection route] collection:self.backingCollection.collectionName persist:YES];
    }
}

- (void) cacheObjects:(NSArray*)ids results:(id)objectsOrNil error:(NSError*)errorOrNil policy:(KCSCachePolicy)cachePolicy
{
    if ((errorOrNil != nil &&  ([[errorOrNil domain] isEqualToString:KCSNetworkErrorDomain] == NO || [[errorOrNil domain] isEqualToString:KCSFileStoreErrorDomain] == NO))  ||
        (objectsOrNil == nil && errorOrNil == nil)) {
        //remove the object from the cache, if it exists if the there was an error or return nil, but not if there was a network error (keep using the cached value)
        [[KCSAppdataStore caches] deleteObjects:[NSArray wrapIfNotArray:ids] route:[self.backingCollection route] collection:self.backingCollection.collectionName];
    } else if (objectsOrNil != nil) {
        [[KCSAppdataStore caches] addObjects:objectsOrNil route:[self.backingCollection route] collection:self.backingCollection.collectionName];
    }
}

-(KCSRequest*)queryNetwork:(id)query
       withCompletionBlock:(KCSCompletionBlock)completionBlock
         withProgressBlock:(KCSProgressBlock)progressBlock
                    policy:(KCSCachePolicy)cachePolicy
{
    return [self queryNetwork:query
          withCompletionBlock:completionBlock
            withProgressBlock:progressBlock
                       policy:cachePolicy
                   cacheBlock:^(KCSQuery *query, NSArray *objectsOrNil, NSError *errorOrNil)
    {
        if (cachePolicy != KCSCachePolicyNone) {
            [self cacheQuery:query value:objectsOrNil error:errorOrNil policy:cachePolicy];
        }
    }];
}

-(KCSRequest*)queryNetwork:(id)query
       withCompletionBlock:(KCSCompletionBlock)completionBlock
         withProgressBlock:(KCSProgressBlock)progressBlock
                    policy:(KCSCachePolicy)cachePolicy
                cacheBlock:(void(^)(KCSQuery* query, NSArray *objectsOrNil, NSError *errorOrNil))cacheBlock
{
    
     return [self doQueryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
             if ([[errorOrNil domain] isEqualToString:NSURLErrorDomain] && cachePolicy == KCSCachePolicyNetworkFirst) {
                 id obj = [[KCSAppdataStore caches] pullQuery:[KCSQuery2 queryWithQuery1:query] route:[self.backingCollection route] collection:self.backingCollection.collectionName];
                 [self completeQuery:obj withCompletionBlock:completionBlock];
             } else {
                 if (cacheBlock) {
                     cacheBlock(query, objectsOrNil, errorOrNil);
                 }
                 completionBlock(objectsOrNil, errorOrNil);
             }
         
    } withProgressBlock: progressBlock];
}

-(KCSRequest*)completeDeltaQuery:(KCSQuery*)query
                         withSet:(NSArray*)deltaSet
             withCompletionBlock:(KCSCompletionBlock)completionBlock
               withProgressBlock:(KCSProgressBlock)progressBlock
{
    return [self loadObjectWithID:deltaSet
              withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil)
    {
        id obj = [[KCSAppdataStore caches] pullQuery:[KCSQuery2 queryWithQuery1:query] route:[self.backingCollection route] collection:self.backingCollection.collectionName];
        [self completeQuery:obj withCompletionBlock:completionBlock];
    } withProgressBlock: progressBlock];
}

- (void) completeQuery:(NSArray*)objs withCompletionBlock:(KCSCompletionBlock)completionBlock
{
    NSError* error = (objs == nil) ? createCacheError(@"Query not in cache") : nil;
    if (completionBlock) completionBlock(objs, error);
}

-(KCSRequest*)queryWithQuery:(id)query
        requestConfiguration:(KCSRequestConfiguration *)requestConfiguration
         withCompletionBlock:(KCSCompletionBlock)completionBlock
           withProgressBlock:(KCSProgressBlock)progressBlock
                 cachePolicy:(KCSCachePolicy)cachePolicy
{
    //Hold on the to the object first, in case the cache is cleared during this process
    id obj;
    BOOL noneCachePolicy = cachePolicy == KCSCachePolicyNone;
    if (noneCachePolicy) {
        obj = nil;
    } else {
        obj = [[KCSAppdataStore caches] pullQuery:[KCSQuery2 queryWithQuery1:query] route:[self.backingCollection route] collection:self.backingCollection.collectionName];
    }
    if (self.cacheUpdatePolicy == KCSCacheUpdatePolicyLoadIncremental) {
        if (obj && [obj count] > 0) { //exists in cache
            KCSMultipleRequest* requests = [KCSMultipleRequest new];
            KCSRequest* request = [self doDeltaQueryWithQuery:query
                                          withCompletionBlock:^(NSMutableDictionary *objectsOrNil, NSError *errorOrNil)
            { //get IDs from backend
                NSArray* deltaSet = [[KCSAppdataStore caches] computeDelta:[KCSQuery2 queryWithQuery1:query]
                                                                     route:[self.backingCollection route]
                                                                collection:self.backingCollection.collectionName
                                                             referenceObjs:objectsOrNil];
                KCSRequest* request = [self completeDeltaQuery:query
                                                       withSet:deltaSet
                                           withCompletionBlock:completionBlock
                                             withProgressBlock:progressBlock];
                [requests addRequest:request];
            }];
            [requests addRequest:request];
            return requests;
        }
    }
    if (noneCachePolicy || [self shouldCallNetworkFirst:obj cachePolicy:cachePolicy]) {
        return [self queryNetwork:query
              withCompletionBlock:completionBlock
                withProgressBlock:progressBlock
                           policy:cachePolicy];
        
    } else {
        [self completeQuery:obj withCompletionBlock:completionBlock];
        if ([self shouldUpdateInBackground:cachePolicy]) {
            KCSMultipleRequest* requests = [[KCSMultipleRequest alloc] init];
            dispatch_async(self.queue, ^{
                //TODO: this is to keep this operation alive now that this method is called on a background thread.
                KK2(use a series of dependent operation blocks)
                KK2(should this use silent bg updates ever? - maybe everything should have a notification that the client can ignore)
                
                KCSRequest* request = [self queryNetwork:query
                                     withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil)
                {
                    if ([self shouldIssueCallbackOnBackgroundQuery:cachePolicy]) {
                        completionBlock(objectsOrNil, errorOrNil);
                    }
                }
                                              withProgressBlock:nil
                                                         policy:cachePolicy
                                                     cacheBlock:^(KCSQuery *query, NSArray *objectsOrNil, NSError *errorOrNil)
                {
                    if (cachePolicy != KCSCachePolicyNone && ![errorOrNil.domain isEqualToString:NSURLErrorDomain]) {
                        [self cacheQuery:query value:objectsOrNil error:errorOrNil policy:cachePolicy];
                    }
                }];
                [requests addRequest:request];
            });
            return requests;
        } else {
            return nil;
        }
    }
}

-(KCSRequest*)queryWithQuery:(id)query
        requestConfiguration:(KCSRequestConfiguration *)requestConfiguration
         withCompletionBlock:(KCSCompletionBlock)completionBlock
           withProgressBlock:(KCSProgressBlock)progressBlock
{
    SWITCH_TO_MAIN_THREAD_COMPLETION_BLOCK(completionBlock);
    SWITCH_TO_MAIN_THREAD_PROGRESS_BLOCK(progressBlock);
    return [self queryWithQuery:query
           requestConfiguration:requestConfiguration
            withCompletionBlock:completionBlock
              withProgressBlock:progressBlock
                    cachePolicy:self.cachePolicy];
}

-(KCSRequest*)queryWithQuery:(id)query
         withCompletionBlock:(KCSCompletionBlock)completionBlock
           withProgressBlock:(KCSProgressBlock)progressBlock
                 cachePolicy:(KCSCachePolicy)cachePolicy
{
    SWITCH_TO_MAIN_THREAD_COMPLETION_BLOCK(completionBlock);
    SWITCH_TO_MAIN_THREAD_PROGRESS_BLOCK(progressBlock);
    return [self queryWithQuery:query
           requestConfiguration:nil
            withCompletionBlock:completionBlock
              withProgressBlock:progressBlock
                    cachePolicy:cachePolicy];
}

-(KCSRequest*)queryWithQuery:(id)query
         withCompletionBlock:(KCSCompletionBlock)completionBlock
           withProgressBlock:(KCSProgressBlock)progressBlock
{
    SWITCH_TO_MAIN_THREAD_COMPLETION_BLOCK(completionBlock);
    SWITCH_TO_MAIN_THREAD_PROGRESS_BLOCK(progressBlock);
    return [self queryWithQuery:query
           requestConfiguration:nil
            withCompletionBlock:completionBlock
              withProgressBlock:progressBlock
                    cachePolicy:self.cachePolicy];
}

-(KCSQuery*)queryForObjects:(NSArray*)objects
                       skip:(NSUInteger)skip
{
    NSArray* ids;
    if ([objects.firstObject isKindOfClass:[NSString class]]) {
        //input is _id array
        if (objects.count > KCS_OBJECT_IDS_PER_QUERY) {
            NSUInteger nextChunk = objects.count - skip;
            ids = [objects subarrayWithRange:NSMakeRange(skip, MIN(nextChunk, KCS_OBJECT_IDS_PER_QUERY))];
        } else {
            ids = objects;
        }
    } else if ([objects.firstObject conformsToProtocol:@protocol(KCSPersistable)] == YES) {
        //input is object array?
        NSUInteger nextChunk = objects.count - skip;
        NSUInteger count = MIN(nextChunk, KCS_OBJECT_IDS_PER_QUERY);
        NSMutableArray* _ids = [NSMutableArray arrayWithCapacity:count];
        if (objects.count > KCS_OBJECT_IDS_PER_QUERY) {
            objects = [objects subarrayWithRange:NSMakeRange(skip, count)];
        }
        for (NSObject<KCSPersistable>* obj in objects) {
            [_ids addObject:[obj kinveyObjectId]];
        }
        ids = _ids;
    } else {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"input is not a homogenous array of id strings or objects" userInfo:nil];
    }
    
    return [KCSQuery queryOnField:KCSEntityKeyId usingConditional:kKCSIn forValue:ids];
}

#pragma mark - grouping

- (void) handleGroupResponse:(KCSNetworkResponse*)response key:(NSString*)key fields:(NSArray*)fields buildsObjects:(BOOL)buildsObjects completionBlock:(KCSGroupCompletionBlock)completionBlock
{
    NSError* error = nil;
    NSObject* jsonData = [response jsonObjectError:&error];
    if (error) {
        completionBlock(nil, error);
    } else {
        NSArray *jsonArray = nil;
        
        if ([jsonData isKindOfClass:[NSArray class]]){
            jsonArray = (NSArray *)jsonData;
        } else {
            if ([(NSDictionary *)jsonData count] == 0){
                jsonArray = [NSArray array];
            } else {
                jsonArray = @[jsonData];
            }
        }
        
        if (buildsObjects == YES) {
            NSMutableArray* newArray = [NSMutableArray arrayWithCapacity:jsonArray.count];
            for (NSDictionary* d in jsonArray) {
                NSMutableDictionary* newDictionary = [d mutableCopy];
                NSArray* objectDicts = [d objectForKey:key];
                NSMutableArray* returnObjects = [NSMutableArray arrayWithCapacity:objectDicts.count];
                for (NSDictionary* objDict in objectDicts) {
                    NSMutableDictionary* resources = [NSMutableDictionary dictionary];
                    id newobj = [self manufactureNewObject:objDict resourcesOrNil:resources];
                    [returnObjects addObject:newobj];
                }
                [newDictionary setObject:returnObjects forKey:key];
                [newArray addObject:newDictionary];
            }
            jsonArray = [NSArray arrayWithArray:newArray];
        }
        
        KCSGroup* group = [[KCSGroup alloc] initWithJsonArray:jsonArray valueKey:key queriedFields:fields];
        
        completionBlock(group, nil);
    }
}

-(KCSRequest*)doGroup:(id)fieldOrFields
               reduce:(KCSReduceFunction *)function
            condition:(KCSQuery *)condition
      completionBlock:(KCSGroupCompletionBlock)completionBlock
        progressBlock:(KCSProgressBlock)progressBlock
{
    BOOL okayToProceed = [self validatePreconditionsAndSendErrorTo:completionBlock];
    if (okayToProceed == NO) {
        return nil;
    }
    
    KCSCollection* collection = self.backingCollection;
    NSString* route = [collection route];
    
    NSArray* fields = [NSArray wrapIfNotArray:fieldOrFields];
    NSMutableDictionary *body = [NSMutableDictionary dictionaryWithCapacity:4];
    NSMutableDictionary *keys = [NSMutableDictionary dictionaryWithCapacity:[fields count]];
    for (NSString* field in fields) {
        [keys setObject:[NSNumber numberWithBool:YES] forKey:field];
    }
    [body setObject:keys forKey:@"key"];
    [body setObject:[function JSONStringRepresentationForInitialValue:fields] forKey:@"initial"];
    [body setObject:[function JSONStringRepresentationForFunction:fields] forKey:@"reduce"];
    [body setObject:[NSDictionary dictionary] forKey:@"finalize"];
    
    if (condition != nil) {
        [body setObject:[condition query] forKey:@"condition"];
    }
    
    KCSHttpRequest* request = [KCSHttpRequest requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {
        if (error) {
            completionBlock(nil, error);
        } else {
            [self handleGroupResponse:response
                                  key:[function outputValueName:fields]
                               fields:fields
                        buildsObjects:[function buildsObjects]
                      completionBlock:completionBlock];
        }
    }
                                                        route:route
                                                      options:@{KCSRequestLogMethod}
                                                  credentials:[KCSUser activeUser]];
    if (route == KCSRESTRouteAppdata && collection.collectionName) {
        request.path = @[collection.collectionName, @"_group"];
    } else {
        request.path = @[@"_group"];
    }
    
    request.body = body;
    request.method = KCSRESTMethodPOST;
    request.progress = ^(id data, double progress){
        if (progressBlock != nil) {
            progressBlock(nil, progress);
        }
    };
    return [KCSRequest requestWithNetworkOperation:[request start]];
}

-(KCSRequest*)group:(id)fieldOrFields
             reduce:(KCSReduceFunction *)function
    completionBlock:(KCSGroupCompletionBlock)completionBlock
      progressBlock:(KCSProgressBlock)progressBlock
{
    SWITCH_TO_MAIN_THREAD_GROUP_COMPLETION_BLOCK(completionBlock);
    SWITCH_TO_MAIN_THREAD_PROGRESS_BLOCK(progressBlock);
    return [self group:fieldOrFields
                reduce:function
             condition:[KCSQuery query]
       completionBlock:completionBlock
         progressBlock:progressBlock];
}

- (void) cacheGrouping:(NSArray*)fields reduce:(KCSReduceFunction *)function condition:(KCSQuery *)condition results:(KCSGroup*)objectsOrNil error:(NSError*)errorOrNil policy:(KCSCachePolicy)cachePolicy
{
    //TODO: reinstate GROUP caching?
    
    //    if ((errorOrNil != nil && [[errorOrNil domain] isEqualToString:KCSNetworkErrorDomain] == NO) || (objectsOrNil == nil && errorOrNil == nil)) {
    //        //remove the object from the cache, if it exists if the there was an error or return nil, but not if there was a network error (keep using the cached value)
    //        [_cache removeGroup:fields reduce:function condition:condition];
    //    } else if (objectsOrNil != nil) {
    //        [_cache setResults:objectsOrNil forGroup:fields reduce:function condition:condition];
    //    }
    //
}

-(KCSRequest*)groupNetwork:(NSArray *)fields
                    reduce:(KCSReduceFunction *)function
                 condition:(KCSQuery *)condition
           completionBlock:(KCSGroupCompletionBlock)completionBlock
             progressBlock:(KCSProgressBlock)progressBlock
                    policy:(KCSCachePolicy)cachePolicy
{
    return [self doGroup:fields
                  reduce:function
               condition:condition
         completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil)
    {
        [self cacheGrouping:fields reduce:function condition:condition results:valuesOrNil error:errorOrNil policy:cachePolicy ];
        if (completionBlock) completionBlock(valuesOrNil, errorOrNil);
    } progressBlock:progressBlock];
}

- (void) completeGroup:(id)obj withCompletionBlock:(KCSGroupCompletionBlock)completionBlock
{
    NSError* error = (obj == nil) ? createCacheError(@"Grouping query not in cache") : nil;
    if (completionBlock) completionBlock(obj, error);
}

-(KCSRequest*)group:(id)fieldOrFields
             reduce:(KCSReduceFunction *)function
          condition:(KCSQuery *)condition
    completionBlock:(KCSGroupCompletionBlock)completionBlock
      progressBlock:(KCSProgressBlock)progressBlock
        cachePolicy:(KCSCachePolicy)cachePolicy
{
    NSArray* fields = [NSArray wrapIfNotArray:fieldOrFields];
    //TODO:
    //    KCSCacheKey* key = [[[KCSCacheKey alloc] initWithFields:fields reduce:function condition:condition] autorelease];
    id obj = nil; // [_cache objectForKey:key]; //Hold on the to the object first, in case the cache is cleared during this process
    if ([self shouldCallNetworkFirst:obj cachePolicy:cachePolicy] == YES) {
        return [self groupNetwork:fields
                           reduce:function
                        condition:condition
                  completionBlock:completionBlock
                    progressBlock:progressBlock policy:cachePolicy];
    } else {
        [self completeGroup:obj withCompletionBlock:completionBlock];
        if ([self shouldUpdateInBackground:cachePolicy] == YES) {
            KCSMultipleRequest* requests = [[KCSMultipleRequest alloc] init];
            dispatch_async(self.queue, ^{
                //TODO: this is to keep this operation alive now that this method is called on a background thread.
                KK2(use a series of dependent operation blocks)
                KK2(should this use silent bg updates ever? - maybe everything should have a notification that the client can ignore)

                KCSRequest* request = [self groupNetwork:fields
                                                  reduce:function
                                               condition:condition
                                         completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil)
                {
                    if ([self shouldIssueCallbackOnBackgroundQuery:cachePolicy] == YES) {
                       completionBlock(valuesOrNil, errorOrNil);
                    }
                }
                                           progressBlock:nil
                                                  policy:cachePolicy];
                [requests addRequest:request];
            });
            return requests;
        } else {
            return nil;
        }
    }
}

-(KCSRequest*)group:(id)fieldOrFields
             reduce:(KCSReduceFunction *)function
          condition:(KCSQuery *)condition
    completionBlock:(KCSGroupCompletionBlock)completionBlock
      progressBlock:(KCSProgressBlock)progressBlock
{
    SWITCH_TO_MAIN_THREAD_GROUP_COMPLETION_BLOCK(completionBlock);
    SWITCH_TO_MAIN_THREAD_PROGRESS_BLOCK(progressBlock);
    return [self group:fieldOrFields
                reduce:function
             condition:condition
       completionBlock:completionBlock
         progressBlock:progressBlock
           cachePolicy:self.cachePolicy];
}


#pragma mark - Adding/Updating
- (BOOL) isNoNetworkError:(NSError*)error
{
    BOOL isNetworkError = NO;
    if ([[error domain] isEqualToString:KCSNetworkErrorDomain]) { //KCSNetworkErrorDomain
        NSError* underlying = [error userInfo][NSUnderlyingErrorKey];
        if (underlying) {
            //not sure what kind this is, so try again later
            //error objects should have an underlying eror when coming from KCSRequest
            return [self isNoNetworkError:underlying];
        }
    } else if ([[error domain] isEqualToString:NSURLErrorDomain]) {
        switch (error.code) {
#if !TARGET_OS_WATCH
            case kCFURLErrorUnknown:
            case kCFURLErrorTimedOut:
            case kCFURLErrorNotConnectedToInternet:
            case kCFURLErrorDNSLookupFailed:
                KCSLogNetwork(@"Got a network error (%d) on save, adding to queue.");
                isNetworkError = YES;
                break;
#endif
            default:
                KCSLogNetwork(@"Got a network error (%d) on save, but NOT queueing.", error.code);
        }
        //TODO: ios7 background update on timer if can't resend
    }
    return isNetworkError;
}

- (BOOL) shouldEnqueue:(NSError*)error
{
    return self.offlineUpdateEnabled && [KCSAppdataStore caches].offlineUpdateEnabled && [self isNoNetworkError:error] == YES;
}

-(KCSRequest*)saveMainEntity:(KCSSerializedObject*)serializedObj
        requestConfiguration:(KCSRequestConfiguration*)requestConfiguration
                    progress:(KCSSaveGraph*)progress
         withCompletionBlock:(KCSCompletionBlock)completionBlock
           withProgressBlock:(KCSProgressBlock)progressBlock
{
    BOOL isPostRequest = serializedObj.isPostRequest;
    
    //Step 3: save entity
    KCSCollection* collection = self.backingCollection;
    NSString* route = [collection route];
    __block KCSHttpRequest* request = [KCSHttpRequest requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {
        if (error) {
            if ([self shouldEnqueue:error] == YES) {
                //enqueue save
                
                NSString* _id = [[KCSAppdataStore caches] addUnsavedObject:serializedObj.handleToOriginalObject
                                                                    entity:serializedObj.dataToSerialize
                                                                     route:[self.backingCollection route]
                                                                collection:self.backingCollection.collectionName
                                                                    method:(isPostRequest ? KCSRESTMethodPOST : KCSRESTMethodPUT)
                                                                   headers:request.urlRequest.allHTTPHeaderFields
                                                                     error:error];
                
                if (_id != nil) {
                    error = [error updateWithInfo:@{KCS_ERROR_UNSAVED_OBJECT_IDS_KEY : @[_id]}];
                }
            }
            completionBlock(nil, error);
        } else {
            NSDictionary* jsonResponse = [response jsonObjectError:&error];
            if (error) {
                completionBlock(nil, error);
            } else {
                NSArray* arr = nil;
                if (jsonResponse != nil && serializedObj != nil) {
                    id newObj = [KCSObjectMapper populateExistingObject:serializedObj withNewData:jsonResponse];
                    arr = @[newObj];
                }
                completionBlock(arr, nil);
            }
        }
    }
                                                        route:route
                                                      options:@{KCSRequestLogMethod}
                                                  credentials:[KCSUser activeUser]
                                         requestConfiguration:requestConfiguration];
    NSString *objectId = serializedObj.objectId;
    NSDictionary *dictionaryToMap = serializedObj.dataToSerialize;
    
    request.method = (isPostRequest) ? KCSRESTMethodPOST : KCSRESTMethodPUT;
    
    NSArray* path = (route == KCSRESTRouteAppdata) ? @[collection.collectionName] : @[];
    if (objectId) {
        path = [path arrayByAddingObject:objectId];
    }
    request.path = path;
    request.body = dictionaryToMap;
    
    id objKey = [[serializedObj userInfo] objectForKey:@"entityProgress"];
    request.progress = ^(id data, double progress){
        [objKey setPc:progress];
        if (progressBlock != nil) {
            progressBlock(@[], progress);
        }
    };
    return [KCSRequest requestWithNetworkOperation:[request start]];
}

-(KCSRequest*)saveEntityWithResources:(KCSSerializedObject*)so
                 requestConfiguration:(KCSRequestConfiguration*)requestConfiguration
                             progress:(KCSSaveGraph*)progress
                  withCompletionBlock:(KCSCompletionBlock)completionBlock
                    withProgressBlock:(KCSProgressBlock)progressBlock
{
    //just go right on to main entity here sine this store does not do resources
    return [self saveMainEntity:so
           requestConfiguration:requestConfiguration
                       progress:progress
            withCompletionBlock:completionBlock
              withProgressBlock:progressBlock];
}

- (KCSSerializedObject*) makeSO:(id<KCSPersistable>)object error:(NSError**)error
{
    return [KCSObjectMapper makeKinveyDictionaryFromObject:object error:error];
}

- (void)  saveEntity:(id<KCSPersistable>)objToSave
requestConfiguration:(KCSRequestConfiguration*)requestConfiguration
       progressGraph:(KCSSaveGraph*)progress
            requests:(KCSMultipleRequest*)requests
         doSaveBlock:(KCSCompletionBlock)doSaveblock
   alreadySavedBlock:(KCSCompletionWrapperBlock_t)alreadySavedBlock
   withProgressBlock:(KCSProgressBlock)progressBlock
{
    //Step 0: Serialize Object
    NSError* error = nil;
    KCSSerializedObject* so = [self makeSO:objToSave error:&error];
    if (so == nil && error) {
        doSaveblock(@[], error);
        return;
    }
    id objKey = [progress markEntity:so];
    __weak id saveGraph = objKey;
    DBAssert(objKey != nil, @"should have a valid obj key here");
    NSString* cname = self.backingCollection.collectionName;
    [objKey ifNotLoaded:^{
        KCSRequest* request = [self saveEntityWithResources:so
                                       requestConfiguration:requestConfiguration
                                                   progress:progress
                                        withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil)
        {
            [objKey finished:objectsOrNil error:errorOrNil];
            [objKey doAfterWaitingResaves:^{
                doSaveblock(objectsOrNil, errorOrNil);
            }];
        }
                    withProgressBlock:progressBlock];
        [requests addRequest:request];
    }
    otherwiseWhenLoaded:alreadySavedBlock
andResaveAfterReferencesSaved:^{
    KCSSerializedObject* soPrime = [KCSObjectMapper makeResourceEntityDictionaryFromObject:objToSave forCollection:cname error:NULL]; //TODO: figure out if this is needed?
    [soPrime restoreReferences:so];
    KCSRequest* request = [self saveMainEntity:soPrime
                          requestConfiguration:requestConfiguration
                                      progress:progress
                           withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil)
    {
        [saveGraph resaveComplete];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        //TODO: as above
    }];
    [requests addRequest:request];
}];
}

-(KCSRequest*)saveObject:(id)object
     withCompletionBlock:(KCSCompletionBlock)completionBlock
       withProgressBlock:(KCSProgressBlock)progressBlock
{
    SWITCH_TO_MAIN_THREAD_COMPLETION_BLOCK(completionBlock);
    SWITCH_TO_MAIN_THREAD_PROGRESS_BLOCK(progressBlock);
    return [self saveObject:object
       requestConfiguration:nil
        withCompletionBlock:completionBlock
          withProgressBlock:progressBlock];
}

-(KCSRequest*)saveObject:(id)object
    requestConfiguration:(KCSRequestConfiguration*)requestConfiguration
     withCompletionBlock:(KCSCompletionBlock)completionBlock
       withProgressBlock:(KCSProgressBlock)progressBlock
{
    KCSSTORE_VALIDATE_PRECONDITION_RETURN(nil)
    
    SWITCH_TO_MAIN_THREAD_COMPLETION_BLOCK(completionBlock);
    SWITCH_TO_MAIN_THREAD_PROGRESS_BLOCK(progressBlock);
    
    NSArray* objectsToSave = [NSArray wrapIfNotArray:object];
    NSUInteger totalItemCount = [objectsToSave count];
    
    if (totalItemCount == 0) {
        //TODO: does this need an error?
        if (completionBlock) completionBlock(@[], nil);
    }
    
    __block int completedItemCount = 0;
    NSMutableArray* completedObjects = [NSMutableArray arrayWithCapacity:totalItemCount];
    
    KCSSaveGraph* progress = _previousProgress == nil ? [[KCSSaveGraph alloc] initWithEntityCount:totalItemCount] : _previousProgress;
    
    __block NSError* topError = nil;
    __block BOOL done = NO;
    KCSMultipleRequest* requests = [[KCSMultipleRequest alloc] init];
    [objectsToSave enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        //Step 0: Serialize Object
        [self saveEntity:obj
    requestConfiguration:requestConfiguration
           progressGraph:progress
                requests:requests
             doSaveBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
                 if (done) {
                     //don't do the completion blocks for all the objects if its previously finished
                     return;
                 }
                 if (errorOrNil != nil) {
                     topError = errorOrNil;
                 }
                 if (objectsOrNil != nil) {
                     [completedObjects addObjectsFromArray:objectsOrNil];
                 }
                 completedItemCount++;
                 BOOL shouldStop = errorOrNil != nil && self.treatSingleFailureAsGroupFailure;
                 if (completedItemCount == totalItemCount || shouldStop) {
                     done = YES;
                     completionBlock(topError ? nil : completedObjects, topError);
                 }
                 
             }
       alreadySavedBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
           if (done) {
               //don't do the completion blocks for all the objects if its previously finished
               return;
           }
           [completedObjects addObjectsFromArray:objectsOrNil];
           completedItemCount++;
           if (completedItemCount == totalItemCount) {
               done = YES;
               completionBlock(completedObjects, topError);
           }
       }
       withProgressBlock:progressBlock];
    }];
    return requests;
}

#pragma mark - Removing
-(KCSRequest*)removeObject:(id)object
       withCompletionBlock:(KCSCountBlock)completionBlock
         withProgressBlock:(KCSProgressBlock)progressBlock
{
    SWITCH_TO_MAIN_THREAD_COUNT_BLOCK(completionBlock);
    SWITCH_TO_MAIN_THREAD_PROGRESS_BLOCK(progressBlock);
    return [self removeObject:object
         requestConfiguration:nil
          withCompletionBlock:completionBlock
            withProgressBlock:progressBlock];
}

-(KCSRequest*)removeObject:(id)object
      requestConfiguration:(KCSRequestConfiguration *)requestConfiguration
       withCompletionBlock:(KCSCountBlock)completionBlock
         withProgressBlock:(KCSProgressBlock)progressBlock
{
    KCSDeletionBlock deletionBlock = nil;
    if (completionBlock) {
        deletionBlock = ^(NSDictionary* deletionDictOrNil, NSError* errorOrNil) {
            unsigned long count = 0;
            id countNumber = deletionDictOrNil[@"count"];
            if (countNumber && [countNumber isKindOfClass:[NSNumber class]]) {
                count = ((NSNumber*) countNumber).unsignedLongValue;
            }
            completionBlock(count, errorOrNil);
        };
    }
    return [self removeObject:object
         requestConfiguration:requestConfiguration
            withDeletionBlock:deletionBlock
            withProgressBlock:progressBlock];
}

-(KCSRequest*)removeObject:(id)object
         withDeletionBlock:(KCSDeletionBlock)completionBlock
         withProgressBlock:(KCSProgressBlock)progressBlock
{
    return [self removeObject:object
         requestConfiguration:nil
            withDeletionBlock:completionBlock
            withProgressBlock:progressBlock];
}

-(KCSRequest*)removeObject:(id)object
      requestConfiguration:(KCSRequestConfiguration *)requestConfiguration
         withDeletionBlock:(KCSDeletionBlock)completionBlock
         withProgressBlock:(KCSProgressBlock)progressBlock
{
    SWITCH_TO_MAIN_THREAD_DELETION_BLOCK(completionBlock);
    SWITCH_TO_MAIN_THREAD_PROGRESS_BLOCK(progressBlock);
    BOOL okayToProceed = [self validatePreconditionsAndSendErrorTo:^(id objs, NSError *error) {
        if (completionBlock) completionBlock(0, error);
    }];
    if (okayToProceed == NO) {
        return nil;
    }
    
    NSArray* objects = nil;
    if ([object isKindOfClass:[NSArray class]]) {
        //input is an array
        objects = object;
        if (objects.count == 0) {
            if (completionBlock) completionBlock(0, nil);
            return nil;
        }
        object = [self queryForObjects:objects skip:0];
    } else if ([object isKindOfClass:[NSString class]] || [object isKindOfClass:[KCSQuery class]]) {
        //do this since all objs are KCSPersistables
        object = object;
    } else if ([object conformsToProtocol:@protocol(KCSPersistable)]) {
        //if its just a single object get the _id
        object = [object kinveyObjectId];
    }
    
    KCSDataStore* store2 = [[KCSDataStore alloc] initWithCollection:self.backingCollection.collectionName];
    
    id<KCSNetworkOperation> op = nil;
    KCSMultipleRequest* requests = [[KCSMultipleRequest alloc] init];
    if ([object isKindOfClass:[KCSQuery class]]) {
        op = [self deleteByQueryForStore:store2
                                   query:object
                          responseObject:nil
                                     ids:objects
                                requests:requests
                              completion:completionBlock];
    } else {
        op = [store2 deleteEntity:object
                 deleteCompletion:completionBlock].networkOperation;
    }
    if (progressBlock) {
        op.progressBlock = ^(id data, double progress) {
            progressBlock(nil, progress);
        };
    }
    [requests addRequest:[KCSRequest requestWithNetworkOperation:op]];
    return requests;
}

-(NSOperation<KCSNetworkOperation>*)deleteByQueryForStore:(KCSDataStore*)store
                                                    query:(KCSQuery*)query
                                           responseObject:(NSMutableDictionary*)_object //an accumulative number to keep track of how many objects were deleted successfully
                                                      ids:(NSArray*)ids
                                                 requests:(KCSMultipleRequest*)requests
                                               completion:(KCSDeletionBlock)completionBlock
{
    __block NSMutableDictionary* object = _object;
    KCSQuery2* query2 = [KCSQuery2 queryWithQuery1:query];
    return [store deleteByQuery:query2
               deleteCompletion:^(NSDictionary *_object, NSError *error)
    {
        id count = object[@"count"];
        if (_object) {
            if (!object) {
                object = [NSMutableDictionary dictionary];
            }
            [object addEntriesFromDictionary:_object];
            NSUInteger countValue = 0;
            if (count && [count isKindOfClass:[NSNumber class]]) {
                countValue = [count unsignedIntegerValue];
            }
            id _count = _object[@"count"];
            if (_count && [_count isKindOfClass:[NSNumber class]]) {
                count = @(countValue + [_count unsignedIntegerValue]);
                object[@"count"] = count;
            }
        }
        if (error) {
            if ([self shouldEnqueue:error]) {
                //enqueue save
                id errorValue = [[KCSAppdataStore caches] addUnsavedDeleteQuery:query2 route:[self.backingCollection route] collection:self.backingCollection.collectionName method:KCSRESTMethodDELETE headers:@{KCSRequestLogMethod} error:error];
                
                if (errorValue != nil) {
                    error = [error updateWithInfo:@{KCS_ERROR_UNSAVED_OBJECT_IDS_KEY : @[errorValue]}];
                }
            }
            completionBlock(object, error);
        } else {
            if (count && [count isKindOfClass:[NSNumber class]] && [count unsignedIntegerValue] < ids.count) {
                id<KCSNetworkOperation> op = [self deleteByQueryForStore:store
                                                                   query:[self queryForObjects:ids skip:[count unsignedIntegerValue]]
                                                          responseObject:object
                                                                     ids:ids
                                                                requests:requests
                                                              completion:completionBlock];
                [requests addRequest:[KCSRequest requestWithNetworkOperation:op]];
            } else {
                completionBlock(object, nil);
            }
        }
    }].networkOperation;
}

#pragma mark - Information
-(KCSRequest*)countWithBlock:(KCSCountBlock)countBlock
{
    SWITCH_TO_MAIN_THREAD_COUNT_BLOCK(countBlock);
    return [self countWithQuery:nil
                     completion:countBlock];
}

-(KCSRequest*)countWithQuery:(KCSQuery*)query
                  completion:(KCSCountBlock)countBlock
{
    SWITCH_TO_MAIN_THREAD_COUNT_BLOCK(countBlock)
    if (countBlock == nil) {
        return nil;
    } else if (self.backingCollection == nil) {
        countBlock(0, [self noCollectionError]);
        return nil;
    }
    
    KCSCollection* collection = self.backingCollection;
    NSString* route = [collection route];
    KCSHttpRequest* request = [KCSHttpRequest requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {
        if (error) {
            countBlock(0, error);
        } else {
            response.skipValidation = YES;
            NSDictionary *jsonResponse = [response jsonObjectError:&error];
            if (error) {
                countBlock(0, error);
            } else {
                NSNumber* val = jsonResponse[@"count"];
                countBlock([val unsignedLongValue], nil);
            }
        }
    }
                                                        route:route
                                                      options:@{KCSRequestLogMethod}
                                                  credentials:[KCSUser activeUser]];
    
    NSString* queryString = query != nil ? [query parameterStringRepresentation] : @"";
    request.queryString = queryString;
    if (route == KCSRESTRouteAppdata) {
        request.path = @[collection.collectionName, @"_count"];
    } else {
        request.path = @[@"_count"];
    }
    return [KCSRequest requestWithNetworkOperation:[request start]];
}

@end

#pragma clang diagnostic pop
