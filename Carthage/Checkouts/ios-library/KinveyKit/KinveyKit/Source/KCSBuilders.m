//
//  KCSBuilders.m
//  KinveyKit
//
//  Created by Michael Katz on 8/23/12.
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


#import "KCSBuilders.h"

#import "CLLocation+Kinvey.h"

@implementation KCSAttributedStringBuilder
+ (id)JSONCompatabileValueForObject:(id)object
{
    return [(NSAttributedString*)object string];
}
+ (id) objectForJSONObject:(id)object
{
    if ([object isKindOfClass:[NSAttributedString class]]) {
        return object;
    } else if ([object isKindOfClass:[NSString class]]) {
        
        return [[NSAttributedString alloc] initWithString:object];
    }
    return [NSNull null];
}
@end
@implementation KCSMAttributedStringBuilder
+ (id) objectForJSONObject:(id)object
{
    if ([object isKindOfClass:[NSAttributedString class]]) {
        return object;
    } else if ([object isKindOfClass:[NSString class]]) {
        
        return [[NSMutableAttributedString alloc] initWithString:object];
    }
    return [NSNull null];
}
@end

#import "NSDate+ISO8601.h"
@implementation KCSDateBuilder
+ (id) JSONCompatabileValueForObject:(id)object
{
    return [NSString stringWithFormat:@"ISODate(%c%@%c)", '"', [object stringWithISO8601Encoding], '"'];
}
+ (id) objectForJSONObject:(id)object
{
    if ([object isKindOfClass:[NSDate class]]) {
        return object;
    } else if ([object isKindOfClass:[NSString class]]) {
        NSString *tmp = [(NSString *)object stringByReplacingOccurrencesOfString:@"ISODate(\"" withString:@""];
        tmp = [tmp stringByReplacingOccurrencesOfString:@"\")" withString:@""];
        NSDate *date = [NSDate dateFromISO8601EncodedString:tmp];
        return date;
    }
    return [NSNull null];
}
@end

@implementation KCSSetBuilder
+ (id)JSONCompatabileValueForObject:(id)object
{
    return [(NSSet*)object allObjects];
}
+ (id) objectForJSONObject:(id)object
{
    if ([object isKindOfClass:[NSSet class]]) {
        return object;
    } else if ([object isKindOfClass:[NSArray class]]) {
        return [NSSet setWithArray:object];
    }
    return [NSNull null];
}
@end
@implementation KCSMSetBuilder
+ (id) objectForJSONObject:(id)object
{
    if ([object isKindOfClass:[NSSet class]]) {
        return object;
    } else if ([object isKindOfClass:[NSArray class]]) {
        return [NSMutableSet setWithArray:object];
    }
    return [NSNull null];
}
@end

@implementation KCSOrderedSetBuilder
+ (id)JSONCompatabileValueForObject:(id)object
{
    return [(NSOrderedSet*)object array];
}
+ (id) objectForJSONObject:(id)object
{
    if ([object isKindOfClass:[NSOrderedSet class]]) {
        return object;
    } else if ([object isKindOfClass:[NSArray class]]) {
        return [NSOrderedSet orderedSetWithArray:object];
    } else if ([object isKindOfClass:[NSSet class]]) {
        return [NSOrderedSet orderedSetWithSet:object];
    }
    return [NSNull null];
}
@end
@implementation KCSMOrderedSetBuilder
+ (id) objectForJSONObject:(id)object
{
    if ([object isKindOfClass:[NSOrderedSet class]]) {
        return object;
    } else if ([object isKindOfClass:[NSArray class]]) {
        return [NSMutableOrderedSet orderedSetWithArray:object];
    } else if ([object isKindOfClass:[NSSet class]]) {
        return [NSMutableOrderedSet orderedSetWithSet:object];
    }
    return [NSNull null];
}
@end

@implementation KCSCLLocationBuilder

+ (id)JSONCompatabileValueForObject:(id)object
{
    return [(CLLocation*)object kinveyValue];
}
+ (id) objectForJSONObject:(id)object
{
    if ([object isKindOfClass:[CLLocation class]]) {
        return object;
    } else if ([object isKindOfClass:[NSArray class]]) {
        return [CLLocation locationFromKinveyValue:object];
    } 
    return [NSNull null];
}

@end

@implementation KCSURLBuilder

+ (id) JSONCompatabileValueForObject:(id)object
{
    return [(NSURL*)object absoluteString];
}

+ (id) objectForJSONObject:(id)object
{
    NSURL* url = [NSURL URLWithString:object];
    return url ? url : [NSNull null];
}

@end

@implementation KCSBuilders

@end
