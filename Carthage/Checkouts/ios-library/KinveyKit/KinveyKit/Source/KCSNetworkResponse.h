//
//  KCSNetworkResponse.h
//  KinveyKit
//
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


@import Foundation;

@interface KCSNetworkResponse : NSObject
@property (nonatomic) NSInteger code;
@property (atomic, copy) NSData* jsonData;
@property (nonatomic, copy) NSDictionary* headers;
@property (nonatomic, copy) NSURL* originalURL;
@property (nonatomic, assign) BOOL skipValidation;

+ (instancetype) MockResponseWith:(NSInteger)code data:(id)data;

- (BOOL) isKCSError;
- (NSError*) errorObject;
- (NSString*) stringValue;
- (id) jsonObject KCS_DEPRECATED(--use jsonObjectError: instead, 1.31.1);
- (id) jsonObjectError:(NSError**)error;
- (NSString*) requestId;

@end
