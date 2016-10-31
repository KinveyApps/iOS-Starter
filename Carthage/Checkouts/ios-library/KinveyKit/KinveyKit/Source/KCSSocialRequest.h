//
//  KCSSocialRequest.h
//  KinveyKit
//
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
#import "KCSHttpRequest.h"

@interface KCSSocialRequest : NSObject
@property (nonatomic, copy) KCSRequestCompletionBlock completionBlock;

- (instancetype) initWithApiKey:(NSString*)apiKey secret:(NSString*)secretKey url:(NSString*)url httpMethod:(NSString*)method;
- (instancetype) initWithApiKey:(NSString*)apiKey secret:(NSString*)secretKey token:(NSString*)token tokenSecret:(NSString*)tokenSecret additionalKeys:(NSDictionary*)additionalKeys url:(NSString*)url httpMethod:(NSString*)method;
- (instancetype) initWithApiKey:(NSString*)apiKey secret:(NSString*)secretKey token:(NSString*)token tokenSecret:(NSString*)tokenSecret additionalKeys:(NSDictionary*)additionalKeys body:(NSData*)bodyData url:(NSString*)url httpMethod:(NSString*)method;

- (id<KCSNetworkOperation>) start;



@end
