//
//  KCSCachedStore.m
//  KinveyKit
//
//  Created by Michael Katz on 5/10/12.
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


#import "KCSCachedStore.h"

#import "KCSHiddenMethods.h"

NSString* const KCSStoreKeyOfflineUpdateEnabled = @"offline.enabled";

@interface KCSAppdataStore (KCSCachedStore)
- (instancetype)initWithAuth: (KCSAuthHandler *)auth;
- (KCSCollection*) backingCollection;
@property (nonatomic) BOOL offlineUpdateEnabled;
@end


@interface KCSCachedStore () {
}
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation KCSCachedStore
#pragma clang diagnostic pop

#pragma mark - Cache Policy

static KCSCachePolicy sDefaultCachePolicy = KCSCachePolicyNone;

+ (KCSCachePolicy) defaultCachePolicy
{
    return sDefaultCachePolicy;
}

+ (void) setDefaultCachePolicy:(KCSCachePolicy)cachePolicy
{
    sDefaultCachePolicy = cachePolicy;
}

#pragma mark - import / export

- (void) import:(NSArray*)jsonObjects
{
    [self importCache:jsonObjects];
}

-(void)importCache:(NSArray *)jsonObjects
{
    [[KCSAppdataStore caches] jsonImport:jsonObjects route:[self.backingCollection route] collection:self.backingCollection.collectionName];
}

- (NSArray*) exportCache
{
    return [[KCSAppdataStore caches] jsonExport:[self.backingCollection route] collection:self.backingCollection.collectionName];
}

+ (void)clearCaches
{
    [[KCSAppdataStore caches] clear];
}
@end

