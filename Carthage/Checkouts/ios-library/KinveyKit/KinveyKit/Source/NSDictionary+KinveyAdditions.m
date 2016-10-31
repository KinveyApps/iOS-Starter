//
//  NSDictionary+KinveyAdditions.m
//  KinveyKit
//
//  Created by Michael Katz on 3/14/13.
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


#import "NSDictionary+KinveyAdditions.h"
#import "KinveyCoreInternal.h"
#import "KCSMutableOrderedDictionary.h"
#import "KCSObjectMapper.h"
#import "KCSFile.h"
#import "NSDate+ISO8601.h"
#import "KinveyUser.h"
#import "KinveyCollection.h"

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif

@interface KCSKinveyRef ()

-(id)proxyForJson;

@end

@interface KCSFile ()

-(id)proxyForJson;

@end

@implementation NSDictionary (KinveyAdditions)

- (instancetype) stripKeys:(NSArray*)keys
{
    NSMutableDictionary* copy = [self mutableCopy];
    for (NSString* key in keys) {
        if (copy[key]) {
            copy[key] = @"XXXXXXXXX";
        }
    }
    return copy;
}

- (instancetype) dictionaryByAddingDictionary:(NSDictionary*)dictionary
{
    NSMutableDictionary* md = [self mutableCopy];
    [md addEntriesFromDictionary:dictionary];
    return md;
}

- (NSString*) escapedJSON
{
    NSString* jsonStr = [self kcsJSONStringRepresentation:nil];
    return [NSString stringByPercentEncodingString:jsonStr];
}

-(NSString *)jsonString
{
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:[KCSMutableOrderedDictionary dictionaryWithDictionary:self]
                                                   options:0
                                                     error:&error];
    
    if (error) {
        [[NSException exceptionWithName:error.domain
                                 reason:error.localizedDescription ? error.localizedDescription : error.description
                               userInfo:error.userInfo] raise];
    }
    
    if (data) {
        return [[NSString alloc] initWithData:data
                                     encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

- (NSDictionary*) invert
{
    NSMutableDictionary* d = [NSMutableDictionary dictionaryWithCapacity:self.count];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            d[obj] = key;
        }
    }];
    return d;
}

-(NSString *)queryString
{
    NSMutableString* result = [NSMutableString string];
    for (NSString* key in self.allKeys) {
        [result appendFormat:@"%@=%@&", [NSString stringByPercentEncodingString:key], [NSString stringByPercentEncodingString:self[key]]];
    }
    if (result.length > 0) {
        [result deleteCharactersInRange:NSMakeRange(result.length - 1, 1)];
    }
    return result;
}

+(id)transformValue:(id)value
{
    if ([value isKindOfClass:[KCSKinveyRef class]]) {
        return [((KCSKinveyRef*) value) proxyForJson];
    } else if ([value isKindOfClass:[KCSFile class]]) {
        return [((KCSFile*) value) proxyForJson];
#if TARGET_OS_IOS
    } else if ([value isKindOfClass:[UIImage class]]) {
        return [NSNull null];
#endif
    } else if ([value isKindOfClass:[NSSet class]]) {
        return [self transformValue:((NSSet*) value).allObjects];
    } else if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary* dictionary = (NSDictionary*) value;
        NSMutableDictionary* result = [NSMutableDictionary dictionaryWithCapacity:dictionary.count];
        id newValue = nil;
        for (NSString* key in dictionary.allKeys) {
            newValue = [self transformValue:dictionary[key]];
            if (newValue) {
                result[key] = newValue;
            }
        }
        return result;
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray* array = (NSArray*) value;
        NSMutableArray* results = [NSMutableArray arrayWithCapacity:array.count];
        id newValue = nil;
        for (id oldValue in array) {
            newValue = [self transformValue:oldValue];
            if (newValue) {
                [results addObject:newValue];
            }
        }
        return results;
    } else if ([value isKindOfClass:[NSDate class]]) {
        return [NSString stringWithFormat:@"ISODate(\"%@\")", [value stringWithISO8601Encoding]];
    } else if ([value isKindOfClass:[KCSUser class]]) {
        KCSKinveyRef* ref = [[KCSKinveyRef alloc] init];
        ref.object = (KCSUser*) value;
        ref.collectionName = KCSUserCollectionName;
        value = [self transformValue:ref];
    }
    return value;
}

-(NSData *)kcsJSONDataRepresentation:(NSError *__autoreleasing *)_error
{
    NSMutableDictionary *dictionary = [self.class transformValue:self];
    
    NSError* error = nil;
    NSData* data = [NSJSONSerialization dataWithJSONObject:dictionary
                                                   options:0
                                                     error:&error];
    if (error && _error) {
        *_error = error;
    }
    return data;
}

-(NSString *)kcsJSONStringRepresentation:(NSError *__autoreleasing *)error
{
    NSData* data = [self kcsJSONDataRepresentation:error];
    if (data) {
        return [[NSString alloc] initWithData:data
                                     encoding:NSUTF8StringEncoding];
    }
    return nil;
}

@end
