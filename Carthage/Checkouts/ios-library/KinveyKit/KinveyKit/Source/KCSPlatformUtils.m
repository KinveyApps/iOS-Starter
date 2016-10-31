//
//  KCSPlatformUtils.m
//  KinveyKit
//
//  Created by Michael Katz on 7/30/13.
//  Copyright (c) 2015 Kinvey. All rights reserved.
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


#import "KCSPlatformUtils.h"

#if TARGET_OS_IPHONE
@import UIKit;
#endif

// For hardware platform information
#include <sys/types.h>
#include <sys/sysctl.h>

@implementation KCSPlatformUtils


+ (BOOL) supportsNSURLSession
{
    static BOOL supports;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
         supports = NSClassFromString(@"NSURLSession") != nil;
    });
    return supports;
}

+ (BOOL) supportsResumeData
{
    return [self supportsNSURLSession];
}

+ (BOOL) supportsVendorID
{
#if TARGET_OS_IPHONE && !TARGET_OS_WATCH
    return [[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)];
#else
    return NO;
#endif
}

// From: http://www.cocos2d-iphone.org/forum/topic/21923
// NB: This is not 100% awesome and needs cleaned up
+ (NSString *) platform {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    NSString *platform = @"unknown";
    char *machine = malloc(size);
    if (machine) {
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        platform = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];
        free(machine);
    }
    return platform;
}


+ (NSString*) platformString
{
#if TARGET_OS_IPHONE && !TARGET_OS_WATCH
    UIDevice* device = [UIDevice currentDevice];
    return [NSString stringWithFormat:@"%@/%@ %@ %@", device.model, [self platform], device.systemName, device.systemVersion];
#else
    return [NSString stringWithFormat:@"%@", [self platform]];
#endif
}


@end
