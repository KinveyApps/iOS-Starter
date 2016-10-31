//
//  NSArray+KinveyAdditions.m
//  KinveyKit
//
//  Created by Michael Katz on 5/11/12.
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


#import "NSArray+KinveyAdditions.h"
#import "NSString+KinveyAdditions.h"

@implementation NSArray (KinveyAdditions)

- (NSString *)join:(NSString *)delimiter
{
    NSMutableString* string = [NSMutableString string];
    for (int i=0; i < self.count; i++) {
        if (i > 0) {
            [string appendFormat:@"%@%@", delimiter, self[i]];
        } else {
            [string appendFormat:@"%@", self[i]];
        }
    }
    return string;
}

+ (instancetype) wrapIfNotArray:(id)object
{
    // If we're given a class that is not an array, then we need to wrap the object
    // as an array so we do a single unified processing
    if ([object isKindOfClass:[NSArray class]]){
        return object;
    } else if ([object isKindOfClass:[NSSet class]]){
        return [object allObjects];
    } else if ([object isKindOfClass:[NSOrderedSet class]]){
        return [object array];
    } else {
        return object == nil? @[] : @[object];
    }
}

+ (instancetype) arrayWithObjectOrNil:(id) object
{
    return object == nil ? @[] : @[object];
}

+ (instancetype) arrayIfDictionary:(id)object
{
    if ([object isKindOfClass:[NSArray class]]){
        return (NSArray *)object;
    } else if ([(NSDictionary *)object count] == 0) {
            return @[];
        } else {
            return @[object];
        }
}

+ (instancetype) arrayWith:(NSUInteger)num copiesOf:(id<NSCopying>)val
{
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:num];
    for (int i=0; i<num; i++) {
        array[i] = [val copyWithZone:NULL];
    }
    return array;
}

- (instancetype) arrayByPercentEncoding
{
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:self.count];
    for (NSString* s in self) {
        [array addObject:[NSString stringByPercentEncodingString:s]];
    }
    return array;
}

@end
