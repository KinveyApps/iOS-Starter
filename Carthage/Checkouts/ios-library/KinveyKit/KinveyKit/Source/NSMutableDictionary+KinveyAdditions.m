//
//  NSMutableDictionary+KinveyAdditions.m
//  KinveyKit
//
//  Created by Michael Katz on 10/9/12.
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

#import "NSMutableDictionary+KinveyAdditions.h"

@implementation NSMutableDictionary (KinveyAdditions)

- (id) popObjectForKey:(id) key
{
    id obj = [self objectForKey:key];
    if (obj) {
        [self removeObjectForKey:key];
    }
    return obj;
}

- (void) append:(NSString*)appendant ontoKeySet:(NSArray*)keys recursive:(BOOL) recursive
{
    NSMutableArray* keysToRemove = [NSMutableArray arrayWithCapacity:self.count];
    NSMutableDictionary* objectsToAdd = [NSMutableDictionary dictionaryWithCapacity:self.count];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString* newKey = key;
        if ([keys containsObject:key]) {
            //found one
            newKey = [key stringByAppendingString:appendant];
            [keysToRemove addObject:key];
            [objectsToAdd setObject:obj forKey:newKey];
        }
        if (recursive) {
            if ([obj isKindOfClass:[NSDictionary class]]) {
                NSMutableDictionary* mobj = [obj mutableCopy];
                [mobj append:appendant ontoKeySet:keys recursive:recursive];
                [keysToRemove addObject:key];
                [objectsToAdd setObject:mobj forKey:newKey];
            } else if ([obj isKindOfClass:[NSArray class]]) {
                NSMutableArray* marray = [obj mutableCopy];
                for (id arrayObj in obj) {
                    if ([arrayObj isKindOfClass:[NSDictionary class]]) {
                        NSMutableDictionary* mobj = [arrayObj mutableCopy];
                        [mobj append:appendant ontoKeySet:keys recursive:recursive];
                        [marray replaceObjectAtIndex:[obj indexOfObject:arrayObj] withObject:mobj];
                    }
                }
                [keysToRemove addObject:key];
                [objectsToAdd setObject:marray forKey:newKey];
            }
        }
        
    }];
    [self removeObjectsForKeys:keysToRemove];
    [self addEntriesFromDictionary:objectsToAdd];
}

@end
