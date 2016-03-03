//
//  KNVDataStore.h
//  Kinvey
//
//  Created by Victor Barros on 2016-02-23.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KNVRequest.h"

@protocol KNVPersistable;
@class KNVQuery;

#define KNVObjectCompletionHandler(T) void (^ _Nullable)(T _Nullable object, NSError* _Nullable error)
#define KNVArrayCompletionHandler(T) void (^ _Nullable)(NSArray<T>* _Nullable results, NSError* _Nullable error)

@interface KNVDataStore<T : NSObject<KNVPersistable>*> : NSObject

-(id<KNVRequest> _Nonnull)findById:(NSString* _Nonnull)objectId
                 completionHandler:(KNVObjectCompletionHandler(T))completionHandler;

-(id<KNVRequest> _Nonnull)find:(KNVArrayCompletionHandler(T))completionHandler;

-(id<KNVRequest> _Nonnull)find:(KNVQuery* _Nonnull)query
             completionHandler:(KNVArrayCompletionHandler(T))completionHandler;

@end
