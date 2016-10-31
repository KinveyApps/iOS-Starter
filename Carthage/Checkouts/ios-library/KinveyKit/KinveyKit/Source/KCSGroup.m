//
//  KCSGroup.m
//  KinveyKit
//
//  Created by Michael Katz on 5/21/12.
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


#import "KCSGroup.h"
@interface KCSGroup () {
@private
    NSArray* _array;
    NSString* _key;
    NSArray* _queriedFields;
}

@end

@implementation KCSGroup

- (instancetype) initWithJsonArray:(NSArray*)jsonData valueKey:(NSString*)key queriedFields:(NSArray*)fields;
{
    self = [super init];
    if (self) {
        _array = [jsonData copy];
       
        if (fields.count == 0) {
            NSMutableArray* fieldValues = [NSMutableArray array];
            for (NSDictionary* d in jsonData) {
                NSMutableArray* keys = [[d allKeys] mutableCopy];
                [keys removeObject:key];
                [fieldValues addObjectsFromArray:keys];
            }
            _queriedFields = [NSArray arrayWithArray:fieldValues];
        } else {
            _queriedFields = [NSArray arrayWithArray:fields];
        }
        _key = [key copy];
    }
    return self;
}

- (NSDictionary*) dictionaryValue
{
    return @{@"aray":_array,@"key":_key, @"fields":_queriedFields};
}

- (NSArray*) fieldsAndValues
{
    return _array;
}

- (NSString*) returnValueKey
{
    return _key;
}

- (id) reducedValueForFields:(NSDictionary*)fields
{
    __block NSNumber* number = @(NSNotFound);
    [self enumerateWithBlock:^(NSArray *fieldValues, id value, NSUInteger idx, BOOL *stop) {
        BOOL found = NO;
        for (NSString* field in [fields allKeys]) {
            if ([_queriedFields containsObject:field] && [fieldValues[[_queriedFields indexOfObject:field]] isEqual:fields[field]]) {
                found = YES;
            } else {
                found = NO;
                break;
            }
        }
        if (found) {
            *stop = YES;
            number = value;
        }
    }];
    return number;
}

- (void) enumerateWithBlock:(void (^)(NSArray* fieldValues, id value, NSUInteger idx, BOOL *stop))block
{
    [_array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary* result = obj;
        NSMutableArray* fieldValues = [NSMutableArray arrayWithCapacity:result.count - 1];
        for (NSString* field in _queriedFields) {
            [fieldValues addObject:[result objectForKey:field]];
        }
        block([NSArray arrayWithArray:fieldValues], [result objectForKey:_key], idx, stop);
    }];
}

@end
