//
//  KCSFacebookHelper.m
//  KinveyKit
//
//  Created by Michael Katz on 3/22/13.
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


#import "KCSFacebookHelper.h"

#import "KCSAppdataStore.h"
#import "KinveyEntity.h"

@implementation KCSFacebookHelper

+ (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val = [kv[1]
                         stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        params[kv[0]] = val;
    }
    return params;
}

+ (NSDictionary*) parseDeepLink:(NSURL*)url
{
    NSString* query = [url query];
    NSMutableDictionary* d = [NSMutableDictionary dictionary];
    NSDictionary* params = [self parseURLParams:query];
    if (params.count > 0) {
        NSString* targetURL = params[@"target_url"];
        if (targetURL != nil) {
            //target URL should be in the form:
            //http://baas.kinvey.com/rpc/:kid/:action/:id/:object/_objView.html
            // 0   /     1          / 2 / 3  /  4   / 5 /   6   / 7
            NSArray* subpieces = [targetURL pathComponents];
            if ([subpieces count] == 8) {
                // Check for the 'deeplink' parameter to check if this is one of
                NSString* action = subpieces[4];
                NSString* entityId = subpieces[5];
                NSString* objectType = subpieces[6];
                if (action != nil && entityId != nil && objectType != nil) {
                    d[KCSFacebookOGAction] = action;
                    d[KCSFacebookOGObjectType] = objectType;
                    d[KCSFacebookOGEntityId] = entityId;
                }
            }
        }
    }
    return [d copy];
}

+ (void) publishToOpenGraph:(NSString*)entityId action:(NSString*)action objectType:(NSString*)objectType optionalParams:(NSDictionary*)extraParams completion:(FacebookOGCompletionBlock)completionBlock
{
    NSParameterAssert(entityId != nil);
    
    if (entityId != nil && [entityId isKindOfClass:[NSString class]] == NO) {
        entityId = [entityId kinveyObjectId];
    }
    
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    KCSAppdataStore* store = [KCSAppdataStore storeWithOptions:@{KCSStoreKeyCollectionName : action,
                           KCSStoreKeyCollectionTemplateClass : [NSMutableDictionary class],
                              
                              }];
    dict[KCSEntityKeyId] = objectType;
    dict[KCSFacebookOGEntityId] = entityId;
    if (extraParams != nil) {
        [dict addEntriesFromDictionary:extraParams];
    }
    [store saveObject:dict withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        NSString* actionId = nil;
        if (objectsOrNil != nil && objectsOrNil.count > 0){
            actionId = objectsOrNil[0];
            if ([actionId isKindOfClass:[NSDictionary class]] == YES) {
                actionId = [(NSDictionary*)actionId objectForKey:@"id"];
            }
        }
        completionBlock(actionId, errorOrNil);
    } withProgressBlock:nil];
}

@end
