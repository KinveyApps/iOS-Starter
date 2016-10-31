//
//  KCSDataStore.m
//  KinveyKit
//
//  Created by Michael Katz on 5/23/13.
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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
#pragma clang diagnostic ignored "-W#warnings"

#import "KCSDataStore.h"
#import "KinveyCollection.h"
#import "KinveyCoreInternal.h"
#import "KinveyDataStoreInternal.h"
#import "KCSRequest+Private.h"
#import "KCSFileStore.h"
#import "KinveyUser.h"
#import "KinveyPersistable.h"

#define kKCSMaxReturnSize 10000


@interface KCSDataStore ()
@property (nonatomic, copy) NSString* collectionName;
@property (nonatomic, retain) NSString* route;
@property (nonatomic) BOOL cacheEnabled;
@end

@implementation KCSDataStore

- (instancetype) initWithCollection:(NSString*)collection
{
    NSParameterAssert(collection);
    
    self = [super init];
    if (self) {
        KK2(Have collection object supply these and get rid of cln names?)
        _collectionName = collection;
        if ([_collectionName isEqualToString:KCSUserCollectionName]) {
            _route = KCSRESTRouteUser;
        } else if ([_collectionName isEqualToString:KCSFileStoreCollectionName]) {
            _route = KCSRESTRouteBlob;
        } else {
            _route = KCSRESTRouteAppdata;
        }
    }
    return self;
}

#pragma mark - READ

-(KCSRequest*)getAll:(KCSDataStoreCompletion)completion
{
    return [self query:nil options:@{KCSRequestLogMethod} completion:completion];
}

-(KCSRequest*)query:(KCSQuery2*)query
            options:(NSDictionary*)options
         completion:(KCSDataStoreCompletion)completion
{
    NSParameterAssert(completion);
    SWITCH_TO_MAIN_THREAD_DATA_STORE_BLOCK(completion);
    if (self.collectionName == nil) {
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:@"No collection set in data store" userInfo:nil] raise];
    }
    
    NSDictionary* reqOptions = @{KCSRequestLogMethod}; //start here and add what params are passed in
    reqOptions = [reqOptions dictionaryByAddingDictionary:options];
    
    KCSHttpRequest* request = [KCSHttpRequest requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {
        if (error) {
            completion(nil, error);
        } else {
            NSArray* elements = [response jsonObjectError:&error];
            if (error) {
                completion(nil, error);
            } else {
                if ([elements count] == kKCSMaxReturnSize) {
                    KCSLogForcedWarn(KCS_LOG_CONTEXT_DATA, @"Results returned exactly %d items. This is the server limit, so there may more entities that match the query. Try again with a more specific query or use limit and skip modifiers to get all the data.", kKCSMaxReturnSize);
                }
                completion(elements, nil);
            }
        }
    }
                                                        route:KCSRESTRouteAppdata
                                                      options:reqOptions
                                                  credentials:[KCSUser activeUser]];
    request.path = @[_collectionName];
    request.queryString = [query escapedQueryString];
    return [KCSRequest requestWithNetworkOperation:[request start]];
}

#pragma mark - Count

-(KCSRequest*)countAll:(KCSDataStoreCountCompletion)completion
{
    KCS_BREAK
    return nil;
}

-(KCSRequest*)countQuery:(KCSQuery2*)query
              completion:(KCSDataStoreCountCompletion)completion
{
    KCS_BREAK
    return nil;
}

#pragma mark - Deletion

-(KCSRequest*)deleteEntity:(NSString*)_id
                completion:(KCSDataStoreCountCompletion)completion;
{
    KCSDataStoreObjectCompletion objCompletion = nil;
    if (completion) {
        objCompletion = ^(NSDictionary* responseDict, NSError* error) {
            NSUInteger count = 0;
            if (responseDict) {
                count = [responseDict[@"count"] unsignedIntegerValue];
            }
            completion(count, error);
        };
    }
    return [self deleteEntity:_id
             deleteCompletion:objCompletion];
}

-(KCSRequest*)deleteEntity:(NSString*)_id
          deleteCompletion:(KCSDataStoreObjectCompletion)completion
{
    if (!_id) {
        NSError* error = [NSError createKCSErrorWithReason:[NSString stringWithFormat:@"%@ is nil", KCSEntityKeyId]];
        completion(0, error);
        return nil;
    }
    SWITCH_TO_MAIN_THREAD_DATA_STORE_OBJECT_BLOCK(completion);
    
    KCSHttpRequest* request = [KCSHttpRequest requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {
        NSDictionary* responseDict = nil;
        if (!error) {
            response.skipValidation = YES;
            responseDict = [response jsonObjectError:&error];
        }
        completion(responseDict, error);
    }
                                                        route:self.route
                                                      options:@{KCSRequestLogMethod}
                                                  credentials:[KCSUser activeUser]];
    request.path = @[self.collectionName, _id];
    request.method = KCSRESTMethodDELETE;
    return [KCSRequest requestWithNetworkOperation:[request start]];
}

-(KCSRequest*)deleteByQuery:(KCSQuery2*)query
                 completion:(KCSDataStoreCountCompletion)completion
{
    KCSDataStoreObjectCompletion objCompletion = nil;
    if (completion) {
        objCompletion = ^(NSDictionary* responseDict, NSError* error) {
            NSUInteger count = 0;
            if (responseDict) {
                count = [responseDict[@"count"] unsignedIntegerValue];
            }
            completion(count, error);
        };
    }
    return [self deleteByQuery:query
              deleteCompletion:objCompletion];
}

-(KCSRequest*)deleteByQuery:(KCSQuery2*)query
           deleteCompletion:(KCSDataStoreObjectCompletion)completion
{
    SWITCH_TO_MAIN_THREAD_DATA_STORE_OBJECT_BLOCK(completion);
    if (!query) [[NSException exceptionWithName:NSInvalidArgumentException reason:@"query is nil" userInfo:nil] raise];
    
    KCSHttpRequest* request = [KCSHttpRequest requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {
        NSDictionary* responseDict = nil;
        if (!error) {
            response.skipValidation = YES;
            responseDict = [response jsonObjectError:&error];
        }
        completion(responseDict, error);
    }
                                                        route:self.route
                                                      options:@{KCSRequestLogMethod}
                                                  credentials:[KCSUser activeUser]];
    request.path = @[self.collectionName];
    request.queryString = [query escapedQueryString];
    request.method = KCSRESTMethodDELETE;
    return [KCSRequest requestWithNetworkOperation:[request start]];
}

#pragma mark - Save

- (id<KCSDataOperation>)saveObjects:(NSArray*)objectsToSave options:(NSDictionary*)options completion:(KCSDataStoreCompletion)completion
{
    NSParameterAssert(objectsToSave);
    NSParameterAssert(completion);
    
    if (objectsToSave.count == 0) {
#warning TODO KCSTrivialOperation
    }
    
    NSMutableDictionary* fullOptions = [NSMutableDictionary dictionaryWithDictionary:options];
    setIfEmpty(fullOptions, KCSRequestOptionClientMethod, KCSRequestOptionClientMethod);

    KCSPersistableDescription* descr = [[KCSPersistableDescription alloc] initWithKinveyKit1Object:objectsToSave[0] collection:self.collectionName];
    [descr objectListFromObjects:objectsToSave];
    
    //TODO I don't known why this method was not returning anything. Legacy code???
    return nil;
}

- (void) saveObjects:(NSArray*)objectsToSave completion:(KCSDataStoreCompletion)completion
{
    id<KCSDataOperation> op = [self saveObjects:objectsToSave options:@{KCSRequestLogMethod} completion:completion];
    [op start];
}

@end

#pragma clang diagnostic pop
