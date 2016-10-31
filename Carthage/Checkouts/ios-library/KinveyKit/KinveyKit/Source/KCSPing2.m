//
//  KCSPing2.m
//  KinveyKit
//
//  Created by Michael Katz on 9/11/13.
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


#import "KCSPing2.h"
#import "KinveyCoreInternal.h"
#import "KCSRequest+Private.h"

KCS_CONST_IMPL KCS_PING_KINVEY_VERSION = @"kinveyVersion";
KCS_CONST_IMPL KCS_PING_APP_NAME = @"appName";

#define kVersionKey @"version"
#define kAppnameKey @"appName"

@implementation KCSPing2

+(KCSRequest*)pingKinveyWithBlock:(KCSPingBlock2)completion
{
    SWITCH_TO_MAIN_THREAD_PING_BLOCK2(completion);
    KCSHttpRequest* request = [KCSHttpRequest requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {
        NSDictionary* appInfo = nil;
        if (!error) {
            if ([response isKCSError]) {
                error = [response errorObject];
            } else {
                response.skipValidation = YES;
                NSDictionary* responseVal = [response jsonObjectError:&error];
                if (responseVal) {
                    NSString* version = responseVal[kVersionKey] ? responseVal[kVersionKey] : @"";
                    NSString* appname = responseVal[kAppnameKey] ? responseVal[kAppnameKey] : @"";
                    appInfo = @{KCS_PING_KINVEY_VERSION : version,
                                KCS_PING_APP_NAME : appname};
                }
            }
        }
        completion(appInfo, error);
    }
                            
                                                        route:KCSRESTRouteAppdata
                                                      options:@{KCSRequestLogMethod}
                                                  credentials:[KCSClient2 sharedClient]];
    request.path = @[@""];
    return [KCSRequest requestWithNetworkOperation:[request start]];
}

@end
