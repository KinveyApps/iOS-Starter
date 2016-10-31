//
//  KCSClientConfiguration+KCSInternal.h
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

#import "KCSClientConfiguration.h"

KK2(expose & document levels);
KCS_CONSTANT KCS_LOG_LEVEL;
KCS_CONSTANT KCS_LOG_ADDITIONAL_LOGGERS;

#define KCSConfigValueBOOL(key) [[KCSClient2 sharedClient].configuration.options[key] boolValue]

@interface KCSClientConfiguration (KCSInternal)

- (NSString*) baseURL;

- (int) loglevel;
- (void) setLoglevel:(int)level;
- (void) applyConfiguration;

/*! Protocol used to connect to the backend server. Default value: "https". Valid values: "https" or "http" */
@property (nonatomic, copy) NSString* hostProtocol;

/*! Domain host used to connect to the backend server. Default value: "kinvey.com". Sample values: "mydomain.com" */
@property (nonatomic, copy) NSString* hostDomain;

/*! Port used to connect to the backend server Default value: "" (empty string). Sample values: "8080" or ":8080". */
@property (nonatomic, copy) NSString* hostPort;

@end
