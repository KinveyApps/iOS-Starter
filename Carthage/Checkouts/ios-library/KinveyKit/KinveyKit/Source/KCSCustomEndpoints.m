//
//  KCSCustomEndpoints.m
//  KinveyKit
//
//  Created by Michael Katz on 5/30/13.
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


#import "KCSCustomEndpoints.h"

#import "KinveyUser.h"

#import "KCSHttpRequest.h"
#import "KCSNetworkResponse.h"
#import "KCSRequest+Private.h"
#import "KinveyErrorCodes.h"

@implementation KCSCustomEndpoints

+(KCSRequest*)callEndpoint:(NSString*)endpoint
                    params:(NSDictionary*)params
           completionBlock:(KCSCustomEndpointBlock)completionBlock
{
    NSParameterAssert(endpoint);
    NSParameterAssert(completionBlock);
    SWITCH_TO_MAIN_THREAD_CUSTOM_ENDPOINT_BLOCK(completionBlock);
    if (![KCSUser activeUser]) {
        NSString* reason = @"Active User is `nil`. Log-in before calling custom endpoints";
        NSError* error = [NSError errorWithDomain:KCSErrorDomain
                                             code:0
                                         userInfo:@{NSLocalizedDescriptionKey : reason,
                                                    NSLocalizedFailureReasonErrorKey : reason,
                                                    NSLocalizedRecoverySuggestionErrorKey : reason}];
        completionBlock(nil, error);
    }
    
    KCSHttpRequest* request = [KCSHttpRequest requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            id jsonObject;
            if (error) {
                jsonObject = nil;
            } else {
                jsonObject = [response jsonObjectError:nil];
            }
            completionBlock(jsonObject, error);
        });
    }
                                                        route:KCSRESTRouteRPC
                                                      options:@{KCSRequestLogMethod}
                                                  credentials:[KCSUser activeUser]];
    request.method = KCSRESTMethodPOST;
    request.path = @[@"custom",endpoint];
    
    ifNil(params, @{});
    
    NSError* error = nil;
    NSData* data = [NSJSONSerialization dataWithJSONObject:params
                                                   options:0
                                                     error:&error];
    if (!data) {
        [[NSException exceptionWithName:NSInvalidArgumentException reason:error.localizedFailureReason userInfo:nil] raise];
    }
    
    request.body = params;
    return [KCSRequest requestWithNetworkOperation:[request start]];
}

@end
