//
//  KCSAppdataStore.m
//  KinveyKit
//
//  Created by Brian Wilson on 5/1/12.
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

#import "KCSAppdataStore.h"

#import "KCSObjectCache.h"
#import "EXTScope.h"
#import "DataStoreOperation.h"
#import "KCSDataStoreOperationRequest.h"

@interface KCSBackgroundAppdataStore()
@end

@implementation KCSAppdataStore

static NSOperationQueue* queue;

+ (void)initialize
{
    queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 5;
    [queue setName:@"com.kinvey.KinveyKit.DataStoreQueue"];
}

+ (KCSObjectCache*)caches
{
    static KCSObjectCache* sDataCaches;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sDataCaches = [[KCSObjectCache alloc] init];
    });
    return sDataCaches;
}

+ (instancetype) storeWithCollection:(KCSCollection*)collection options:(NSDictionary*)options;
{
    return [super storeWithCollection:collection options:options];
}

+ (instancetype)storeWithCollection:(KCSCollection*)collection authHandler:(KCSAuthHandler *)authHandler withOptions: (NSDictionary *)options
{
    return [super storeWithCollection:collection authHandler:authHandler withOptions:options];
}

-(KCSRequest*)loadObjectWithID:(id)objectID
           withCompletionBlock:(KCSCompletionBlock)completionBlock
             withProgressBlock:(KCSProgressBlock)progressBlock;
{
    SWITCH_TO_MAIN_THREAD_COMPLETION_BLOCK(completionBlock);
    SWITCH_TO_MAIN_THREAD_PROGRESS_BLOCK(progressBlock);
    if (objectID == nil) {
        [[NSException exceptionWithName:NSInvalidArgumentException reason:@"objectId is `nil`." userInfo:nil] raise];
    }
    
    DataStoreOperation* op = [[DataStoreOperation alloc] init];
    KCSDataStoreOperationRequest* request = [KCSDataStoreOperationRequest requestWithDataStoreOperation:op];
    @weakify(op);
    op.block = ^{
        request.request = [super loadObjectWithID:objectID withCompletionBlock:^(NSArray* obj, NSError* error) {
            completionBlock(obj, error);
            @strongify(op);
            op.finished = YES;
        } withProgressBlock:progressBlock];
    };
    [queue addOperation:op];
    return request;
}

-(KCSRequest*)queryWithQuery:(id)query
         withCompletionBlock:(KCSCompletionBlock)completionBlock
           withProgressBlock:(KCSProgressBlock)progressBlock
{
    SWITCH_TO_MAIN_THREAD_COMPLETION_BLOCK(completionBlock);
    SWITCH_TO_MAIN_THREAD_PROGRESS_BLOCK(progressBlock);
    DataStoreOperation* op = [[DataStoreOperation alloc] init];
    KCSDataStoreOperationRequest* request = [KCSDataStoreOperationRequest requestWithDataStoreOperation:op];
    @weakify(op);
    op.block = ^{
        request.request = [super queryWithQuery:query withCompletionBlock:^(NSArray* obj, NSError* error){
            completionBlock(obj, error);
            @strongify(op);
            op.finished = YES;
        } withProgressBlock:progressBlock];
    };
    [queue addOperation:op];
    return request;
}

-(KCSRequest*)group:(id)fieldOrFields
             reduce:(KCSReduceFunction *)function
          condition:(KCSQuery *)condition
    completionBlock:(KCSGroupCompletionBlock)completionBlock
      progressBlock:(KCSProgressBlock)progressBlock
{
    SWITCH_TO_MAIN_THREAD_GROUP_COMPLETION_BLOCK(completionBlock);
    SWITCH_TO_MAIN_THREAD_PROGRESS_BLOCK(progressBlock);
    DataStoreOperation* op = [[DataStoreOperation alloc] init];
    KCSDataStoreOperationRequest* request = [KCSDataStoreOperationRequest requestWithDataStoreOperation:op];
    @weakify(op);
    op.block = ^{
        request.request = [super group:fieldOrFields
                                reduce:function
                             condition:condition
                       completionBlock:^(KCSGroup* valuesOrNil, NSError* errorOrNil)
        {
            completionBlock(valuesOrNil, errorOrNil);
            @strongify(op);
            op.finished = YES;
        } progressBlock:progressBlock];
    };
    [queue addOperation:op];
    return request;
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

-(KCSRequest*)saveObject:(id)object
     withCompletionBlock:(KCSCompletionBlock)completionBlock
       withProgressBlock:(KCSProgressBlock)progressBlock
{
    SWITCH_TO_MAIN_THREAD_COMPLETION_BLOCK(completionBlock);
    SWITCH_TO_MAIN_THREAD_PROGRESS_BLOCK(progressBlock);
    DataStoreOperation* op = [[DataStoreOperation alloc] init];
    KCSDataStoreOperationRequest* request = [KCSDataStoreOperationRequest requestWithDataStoreOperation:op];
    @weakify(op);
    op.block = ^{
        request.request = [super saveObject:object
                        withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil)
        {
            completionBlock(objectsOrNil, errorOrNil);
            @strongify(op);
            op.finished = YES;
        } withProgressBlock:progressBlock];
    };
    [queue addOperation:op];
    return request;
}

-(KCSRequest*)removeObject:(id)object
       withCompletionBlock:(KCSCountBlock)completionBlock
         withProgressBlock:(KCSProgressBlock)progressBlock
{
    SWITCH_TO_MAIN_THREAD_COUNT_BLOCK(completionBlock);
    SWITCH_TO_MAIN_THREAD_PROGRESS_BLOCK(progressBlock);
    DataStoreOperation* op = [[DataStoreOperation alloc] init];
    KCSDataStoreOperationRequest* request = [KCSDataStoreOperationRequest requestWithDataStoreOperation:op];
    @weakify(op);
    op.block = ^{
        request.request = [super removeObject:object withCompletionBlock:^(unsigned long count, NSError *errorOrNil) {
            completionBlock(count, errorOrNil);
            @strongify(op);
            op.finished = YES;
       } withProgressBlock:progressBlock];
    };
    [queue addOperation:op];
    return request;
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
    SWITCH_TO_MAIN_THREAD_COUNT_BLOCK(countBlock);
    DataStoreOperation* op = [[DataStoreOperation alloc] init];
    KCSDataStoreOperationRequest* request = [KCSDataStoreOperationRequest requestWithDataStoreOperation:op];
    @weakify(op);
    op.block = ^{
        request.request = [super countWithQuery:query
                                     completion:^(unsigned long count, NSError *errorOrNil)
        {
            countBlock(count, errorOrNil);
            @strongify(op);
            op.finished = YES;
        }];
    };
    [queue addOperation:op];
    return request;
}

+(void)cancelAndWaitUntilAllOperationsAreFinished
{
    [queue cancelAllOperations];
    if (queue.operationCount > 0) {
        for (NSOperation* op in queue.operations) {
            if ([op isKindOfClass:[DataStoreOperation class]]) {
                ((DataStoreOperation*) op).finished = YES;
            }
        }
    }
    [queue waitUntilAllOperationsAreFinished];
}

@end
