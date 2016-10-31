//
//  KCSDBTools.m
//  KinveyKit
//
//  Created by Michael Katz on 11/19/13.
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


#import "KCSDBTools.h"

#import <CommonCrypto/CommonDigest.h>

#define KCSMongoTemporaryObjectId @"temp_"

static uint counter;

void md5(NSString* s, unsigned char* result)
{
    const char *cStr = [s UTF8String];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), result ); // This is the md5 call
}


@implementation KCSDBTools

+ (void)initialize
{
    [super initialize];
    counter = arc4random();
}

+(BOOL)isKCSMongoObjectId:(NSString*)objectId
{
    return [objectId hasPrefix:KCSMongoTemporaryObjectId];
}

#if TARGET_OS_IPHONE

+ (NSString*) KCSMongoObjectId
{
    time_t timestamp = (time_t) [[NSDate date] timeIntervalSince1970];
    NSString *hostName = [[NSProcessInfo processInfo] hostName];
    unsigned char hostbytes[16];
    md5(hostName, hostbytes);
    int pid = getpid();
    @synchronized (self) {
        counter = (counter + 1) % 16777216;
    }
    NSString* s = [NSString stringWithFormat:
                   @"%@%08lx%02x%02x%02x%04x%06x",
                   KCSMongoTemporaryObjectId, timestamp, hostbytes[0], hostbytes[1], hostbytes[2],
                   pid, counter];
    return s;
}

#else

+ (NSString*) KCSMongoObjectId
{
    int timestamp = (int) [[NSDate date] timeIntervalSince1970];
    NSString *hostName = [[NSProcessInfo processInfo] hostName];
    unsigned char hostbytes[16];
    md5(hostName, hostbytes);
    int pid = getpid();
    counter = (counter + 1) % 16777216;
    NSString* s = [NSString stringWithFormat:
                   @"%@%08x%02x%02x%02x%04x%06x",
                   KCSMongoTemporaryObjectId, timestamp, hostbytes[0], hostbytes[1], hostbytes[2],
                   pid, counter];
    return s;
}

#endif

@end
