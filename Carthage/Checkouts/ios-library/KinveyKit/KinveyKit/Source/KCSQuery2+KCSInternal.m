//
//  KCSQuery2+KCSInternal.m
//  KinveyKit
//
//  Created by Michael Katz on 8/19/13.
//  Copyright (c) 2015 Kinvey. All rights reserved.
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


#import "KCSQuery2+KCSInternal.h"
#import "NSString+KinveyAdditions.h"

@interface KCSQuery2 ()
- (NSString*) queryString:(BOOL)escape;
@property (nonatomic, retain) NSMutableDictionary* internalRepresentation;
@end

@implementation KCSQuery2 (KCSInternal)

- (NSString*) keyString
{
    NSString* ir = [self queryString:NO];
    return ir.sha1;
}

//TODO: cleanup
- (BOOL) isAllQuery
{
    return self.internalRepresentation.count == 0;
}

//- (NSPredicate*) predicate
//{
//    NSPredicate* predicate = nil;
//    if ([self isAllQuery]) {
//        predicate = [NSPredicate predicateWithValue:YES];
//    }
//    return predicate;
//}

@end
