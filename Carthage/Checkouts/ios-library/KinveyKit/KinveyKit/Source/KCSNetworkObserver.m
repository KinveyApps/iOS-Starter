//
//  KCSNetworkObserver.m
//  KinveyKit
//
//  Created by Michael Katz on 10/3/13.
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


#import "KCSNetworkObserver.h"
#import "KinveyCoreInternal.h"

KCS_CONST_IMPL KCSNetworkConnectionDidStart = @"KCSNetworkConnectionDidStart";
KCS_CONST_IMPL KCSNetworkConnectionDidEnd = @"KCSNetworkConnectionDidEnd";

@interface KCSNetworkObserver ()
@property (atomic) NSUInteger openConnections;
@end

@implementation KCSNetworkObserver

+ (instancetype) sharedObserver
{
    static KCSNetworkObserver* observer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        observer = [[KCSNetworkObserver alloc] init];
    });
    return observer;
}

- (void) connectionStart
{
    @synchronized(self) {
        _openConnections++;
        if (_openConnections == 1) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSNotification* note = [NSNotification notificationWithName:KCSNetworkConnectionDidStart object:nil];
                [[NSNotificationCenter defaultCenter] postNotification:note];
            });
        }
    }
}

- (void) connectionEnd
{
    @synchronized(self) {
        _openConnections--;
        if (_openConnections == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSNotification* note = [NSNotification notificationWithName:KCSNetworkConnectionDidEnd object:nil];
                [[NSNotificationCenter defaultCenter] postNotification:note];
            });
        }

    }
}

@end
