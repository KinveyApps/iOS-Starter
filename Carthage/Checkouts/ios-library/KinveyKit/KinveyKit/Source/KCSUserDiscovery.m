//
//  KCSUserDiscovery.m
//  KinveyKit
//
//  Created by Michael Katz on 7/13/12.
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


#import "KCSUserDiscovery.h"
#import "KCSHiddenMethods.h"
#import "KCSObjectCache.h"

#import "KinveyCoreInternal.h"
#import "KinveyDataStoreInternal.h"
#import "KCSRequest+Private.h"

@implementation KCSUserDiscovery

+(KCSRequest*)lookupUsersForFieldsAndValues:(NSDictionary*)fieldMatchDictionary
                            completionBlock:(KCSCompletionBlock)completionBlock
                              progressBlock:(KCSProgressBlock)progressBlock
{
    SWITCH_TO_MAIN_THREAD_COMPLETION_BLOCK(completionBlock);
    SWITCH_TO_MAIN_THREAD_PROGRESS_BLOCK(progressBlock);
    KCSHttpRequest* request = [KCSHttpRequest requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {
        if (error) {
            completionBlock(nil, error);
        } else {
            id responseObj = [response jsonObjectError:&error];
            if (error) {
                completionBlock(nil, error);
            } else {
                NSArray* jsonArray = [NSArray wrapIfNotArray:responseObj];
                NSUInteger itemCount = jsonArray.count;
                
                NSMutableArray* returnObjects = [NSMutableArray arrayWithCapacity:itemCount];
                for (NSDictionary* jsonDict in jsonArray) {
                    id newobj = [[KCSAppdataStore caches].dataModel objectFromCollection:KCSUserCollectionName data:jsonDict];
                    if (newobj) {
                        [returnObjects addObject:newobj];
                    }
                }
                
                completionBlock(returnObjects, nil);
            }
        }
    }
                                                        route:KCSRESTRouteUser
                                                      options:@{KCSRequestLogMethod}
                                                  credentials:[KCSUser activeUser]];
    request.method = KCSRESTMethodPOST;
    request.path = @[@"_lookup"];
    request.body = fieldMatchDictionary;
    request.progress = ^(id intermediateData, double progress) {
        if (progressBlock != nil) {
            progressBlock(@[], progress);
        }
    };
    return [KCSRequest requestWithNetworkOperation:[request start]];
}

@end
