//
//  NSString+KinveyAdditions.m
//  SampleApp
//
//  Created by Brian Wilson on 10/25/11.
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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"

#import "NSString+KinveyAdditions.h"
#import "NSURL+KinveyAdditions.h"
#import <CommonCrypto/CommonDigest.h>

static inline NSString *NSStringCCHashFunction(unsigned char *(function)(const void *data, CC_LONG len, unsigned char *md), CC_LONG digestLength, NSString *string)
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[digestLength];
    
    function(data.bytes, (CC_LONG) data.length, digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:digestLength * 2];
    
    for (int i = 0; i < digestLength; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return output;
}

@implementation NSString (KinveyAdditions)

- (NSURL *)URLByAppendingQueryString:(NSString *)queryString
{
    if ([queryString length] == 0) {
        return [NSURL URLWithString:self];
    }
    
    NSString *URLString = [NSString stringWithFormat:@"%@%@%@", self,
                           [self rangeOfString:@"?"].length > 0 ? @"&" : @"?", queryString];
    
    return [NSURL URLWithString:URLString];
}

// Or:

- (NSString *)stringByAppendingQueryString:(NSString *)queryString {
    if (![queryString length]) {
        return self;
    }
    // rangeOfString returns an NSRange, which is {location/length}, so
    // if .length > 0, then we've found a '?' somewhere in the string so
    // we need to append the next string with a '&'
    NSString* prefix = [self rangeOfString:@"?"].length > 0 ? @"&" : @"?";
    if ([queryString hasPrefix:@"?"] || [queryString hasPrefix:@"&"]) {
        prefix = @"";
    }
    return [NSString stringWithFormat:@"%@%@%@", self,
            prefix, queryString];
}

+ (NSString *)stringByPercentEncodingString:(NSString *)string
{
    NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                                    (CFStringRef) string,
                                                                                                    NULL,
                                                                                                    (CFStringRef) @"!*'();:@&=+$,/?%#[]{}",
                                                                                                    kCFStringEncodingUTF8));
    return encodedString;
}

- (NSString *)stringByAppendingStringWithPercentEncoding:(NSString *)string;
{
    return [self stringByAppendingString:[NSString stringByPercentEncodingString:string]];
}

- (BOOL) containsStringCaseInsensitive:(NSString*)substring
{
    return [self rangeOfString:substring options:NSCaseInsensitiveSearch].location != NSNotFound;
}

+ (instancetype) UUID
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString* str = nil;
    if (uuid){
        str = [self stringWithString:CFBridgingRelease(CFUUIDCreateString(NULL, uuid))];
        CFRelease(uuid);
    }
    return str;
}

- (NSString *)sha1
{
    return NSStringCCHashFunction(CC_SHA1, CC_SHA1_DIGEST_LENGTH, self);
}

@end

#pragma clang diagnostic pop
