//
//  KCSEntityDict.m
//  KinveyKit
//
//  Created by Brian Wilson on 10/21/11.
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


#import "KCSEntityDict.h"
#import "KCSLogManager.h"
#import "KinveyPersistable.h"

@implementation NSDictionary (KCSEntityDict)

- (NSDictionary *)hostToKinveyPropertyMapping
{
    return [NSDictionary dictionaryWithObjects:[self allKeys] forKeys:[self allKeys]];
}

+ (NSDictionary *)kinveyObjectBuilderOptions
{
    return @{KCS_USE_DESIGNATED_INITIALIZER_MAPPING_KEY : @(YES), KCS_IS_DYNAMIC_ENTITY: @(YES)};
}

+ (id)kinveyDesignatedInitializer:(NSDictionary*)jsonDocument
{
    return [NSMutableDictionary dictionary];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    KCSLogWarning(@"%d cannot setValue for %@", self, key);
}

@end
