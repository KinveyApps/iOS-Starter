//
//  KCSRequest2.h
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

#import "KCSHttpRequest.h"
#import "KNVClient.h"
#import <Kinvey/Kinvey-Swift.h>

@interface KCSHttpRequest ()

@property (nonatomic) BOOL useMock;
@property (nonatomic, copy) KCSRequestCompletionBlock completionBlock;
@property (nonatomic, copy) NSString* contentType;
@property (nonatomic, weak) id<KCSCredentials> credentials;
@property (nonatomic, retain) NSString* route;
@property (nonatomic, copy) NSDictionary* options;
@property (nonatomic, strong) KNVClient* client;

+(NSMutableURLRequest *)requestForURL:(NSURL *)url
                               client:(id)client;

@end
