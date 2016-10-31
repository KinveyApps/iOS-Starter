//
//  ASTTestClass.m
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


#import "ASTTestClass.h"
#import <KinveyKit/KinveyKit.h>

@implementation ASTTestClass

- (instancetype) init
{
    self = [super init];
    if (self) {
        _date = [NSDate date];
    }
    return self;
}

- (NSDictionary *)hostToKinveyPropertyMapping
{
    return @{@"objId" : KCSEntityKeyId,
                @"meta" : KCSEntityKeyMetadata,
                @"objCount" : @"objCount",
                @"objDescription" : @"objDescription",
                @"date" : @"date"};
}

- (NSUInteger)hash
{
    return [_objId hash];
}

- (BOOL)isEqual:(id)object
{
    if (self == object) return YES;
    if (object == [NSNull null]) return NO;
    ASTTestClass* o = object;
    BOOL classSame = [[self class] isEqual:[object class]];
    BOOL objSame = (_objId == nil || o.objId == nil) ? [super isEqual:object] : [_objId isEqual:o.objId];
    return  classSame && objSame;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [self init];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder setValue:@"objID" forKey:@"objID"];
    [aCoder setValue:@"date" forKey:@"date"];
}

- (NSString *)description
{
    return @"A";
}

-(id)valueForUndefinedKey:(NSString *)key
{
    return nil;
}

@end
