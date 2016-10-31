//
//  KCSReduceFunction.m
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


#import "KCSReduceFunction.h"

#define MAX_LENGTH 64
@interface KCSReduceFunction ()
@property (nonatomic, retain) NSString* outputField;
@property (nonatomic) BOOL buildsObjects;
@end

@implementation KCSReduceFunction

#pragma mark - Init

- (instancetype) initWithFunction:(NSString*)function field:(NSString*)field initial:(id)initialObj
{
    self = [super init];
    if (self) {
        _jsonRepresentation = function;
        _jsonInitValue = initialObj;
        _outputField = field;
        _buildsObjects = NO;
    }
    return self;
}

#pragma mark - functions
- (NSString *)JSONStringRepresentationForFunction:(NSArray*)fields {
    return [NSString stringWithFormat:_jsonRepresentation, [self outputValueName:fields], [self outputValueName:fields]];
}

- (NSDictionary *)JSONStringRepresentationForInitialValue:(NSArray*)fields {
    return @{[self outputValueName:fields] : _jsonInitValue};
}

- (NSString*)outputValueName:(NSArray*)fields {
    
    while ([fields containsObject:_outputField] && _outputField.length < MAX_LENGTH) {
        _outputField = [NSString stringWithFormat:@"_%@", _outputField];
    }
    return _outputField;
}

#pragma mark - Helper Constructors

+ (KCSReduceFunction*) COUNT
{
    return [[KCSReduceFunction alloc] initWithFunction:@"function(doc,out){ out.%@++;}" field:@"count" initial:@0];
}

+ (KCSReduceFunction*) SUM:(NSString *)fieldToSum
{
    NSString* function = [NSString stringWithFormat:@"function(doc,out){ out.%%@ = out.%%@ + doc.%@;}", fieldToSum];
    return [[KCSReduceFunction alloc] initWithFunction:function field:@"sum" initial:@0];
}

+ (KCSReduceFunction*) MIN:(NSString *)fieldToMin
{
    NSString* function = [NSString stringWithFormat:@"function(doc,out){ out.%%@ = Math.min(out.%%@, doc.%@);}", fieldToMin];
    return [[KCSReduceFunction alloc] initWithFunction:function field:@"min" initial:@"Infinity"];
}

+ (KCSReduceFunction*) MAX:(NSString*)fieldToMax
{
    NSString* function = [NSString stringWithFormat:@"function(doc,out){ out.%%@ = Math.max(out.%%@, doc.%@);}", fieldToMax];
    return [[KCSReduceFunction alloc] initWithFunction:function field:@"max" initial:@"-Infinity"];  
}

+ (KCSReduceFunction*) AVERAGE:(NSString*)fieldToAverage
{
    NSString* function = [NSString stringWithFormat:@"function(doc,out){ var count = (out._kcs_count == undefined) ? 0 : out._kcs_count; out.%%@ = (out.%%@ * count + doc.%@) / (count + 1); out._kcs_count = count+1;}", fieldToAverage];
    return [[KCSReduceFunction alloc] initWithFunction:function field:@"avg" initial:@0];
    
}

+ (KCSReduceFunction*) AGGREGATE
{
    NSString* function = [NSString stringWithFormat:@"function(doc,out){ out.%%@ = out.%%@.concat(doc)}"];
    KCSReduceFunction* reduceFunction = [[KCSReduceFunction alloc] initWithFunction:function field:@"objects" initial:@[]];
    reduceFunction.buildsObjects = YES;
    return reduceFunction;
}


@end
