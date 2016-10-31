//
//  KCSPersistableDescription.h
//  KinveyKit
//
//  Created by Michael Katz on 1/29/14.
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


@import Foundation;

@protocol KCSPersistable;

@interface KCSReferenceDescription : NSObject
@property (nonatomic, copy) NSString* sourceField;
@property (nonatomic, copy) NSString* sourceProperty;
@property (nonatomic, copy) NSString* destinationCollection;

- (id<KCSPersistable>) destinationObjFromObj:(id<KCSPersistable>)sourceObj;
@end


@interface KCSPersistableDescription : NSObject

@property (nonatomic, copy, readonly) NSArray* references;

- (instancetype) initWithKinveyKit1Object:(id<KCSPersistable>)object collection:(NSString*)collection;

- (NSDictionary*) objectListFromObjects:(NSArray*)objects;

@end
