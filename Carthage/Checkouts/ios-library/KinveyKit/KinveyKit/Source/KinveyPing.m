//
//  KinveyPing.m
//  KinveyKit
//
//  Created by Brian Wilson on 11/30/11.
//  Copyright (c) 2011-2015 Kinvey. All rights reserved.
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


#import "KinveyPing.h"

#import "KCSPing2.h"

@implementation KCSPingResult

@synthesize description = _description;

- (instancetype) initWithDescription:(NSString *)description withResult:(BOOL)result
{
    self = [super init];
    if (self){
        _description = [description copy];
        _pingWasSuccessful=result;
    }
    return self;
}

@end

@implementation KCSPing

+ (void)pingKinveyWithBlock: (KCSPingBlock)completionAction
{
    SWITCH_TO_MAIN_THREAD_PING_BLOCK(completionAction);
    [KCSPing2 pingKinveyWithBlock:^(NSDictionary *appInfo, NSError *error) {
        BOOL didSucceed = (error == nil || appInfo != nil);
        NSString* description;
        if (didSucceed){
            description = [NSString stringWithFormat:@"Kinvey Service is alive, version: %@, response: %@",
                           appInfo[KCS_PING_KINVEY_VERSION], appInfo[KCS_PING_APP_NAME]];
        } else {
            description = [NSString stringWithFormat:@"%@, %@, %@", error.localizedDescription, error.localizedFailureReason, error.localizedRecoveryOptions];
        }
        
        completionAction([[KCSPingResult alloc] initWithDescription:description withResult:didSucceed]);

    }];

}

@end
