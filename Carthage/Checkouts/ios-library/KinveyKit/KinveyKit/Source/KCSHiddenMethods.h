//
//  KCSHiddenMethods.h
//  KinveyKit
//
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

#ifndef KinveyKit_KCSHiddenMethods_h
#define KinveyKit_KCSHiddenMethods_h

#import "KCSAppdataStore.h"
#import "KinveyCollection.h"
#import "KCSClient.h"
#import "KCSReduceFunction.h"
#import "KCSGroup.h"
#import "KinveyUser.h"
#import "KCSMetadata.h"
#import "KCSFileStore.h"
#import "KCSFile.h"
#import "KCSClientConfiguration.h"
#import "KCSObjectCache.h"
#import "KCSFileRequestManager.h"
#import "KCSHttpRequest.h"

#if TARGET_OS_IPHONE
#import "KCSPush.h"
#endif

NSDictionary* defaultBuilders();

@interface KCSQueryTTLModifier : NSObject
@property (nonatomic, strong) NSNumber* ttl;
- (instancetype) initWithTTL:(NSNumber*)ttl;
@end
@interface KCSQuery (KCSHiddenMethods)
@property (nonatomic, retain) NSArray* referenceFieldsToResolve;
@property (nonatomic, readwrite, copy) NSMutableDictionary *query;
@property (nonatomic, strong) KCSQueryTTLModifier* ttlModifier;
@end


@interface KCSCollection (KCSHiddenMethods)

- (NSString*) urlForEndpoint:(NSString*)endpoint;
- (NSString*) route;

@end

@interface KCSClient (KCSHiddenMethods)
@property (nonatomic, copy, readonly) NSString *rpcBaseURL;
@end

@interface KCSClientConfiguration (KCSHiddenMethods)
@property (nonatomic, copy) NSString* serviceHostname;
@end


@interface KCSReduceFunction (KCSHiddenMethods)
@property (nonatomic, readonly) BOOL buildsObjects;
@end


@interface KCSGroup (KCSHiddenMethods)
- (NSDictionary*) dictionaryValue;
@end

@interface KCSAppdataStore (KCSHiddenMethods)
+ (KCSObjectCache*) caches;
+(void)cancelAndWaitUntilAllOperationsAreFinished;
@end

@interface KCSFileRequestManager (KCSHiddenMethods)
+(void)cancelAndWaitUntilAllOperationsAreFinished;
@end

@interface KCSHttpRequest (KCSHiddenMethods)
+(void)cancelAndWaitUntilAllOperationsAreFinished;
@end

@interface KCSUser (KCSHiddenMethods)
@end

@interface KCSMetadata (KCSHiddenMethods)
- (NSDictionary*) aclValue;
- (NSDictionary*) kmdDict;
- (instancetype) initWithKMD:(NSDictionary*)kmd acl:(NSDictionary*)pACL;
@end

@interface KCSFileStore (KCSHiddenMethods)
+ (KCSRequest*)uploadKCSFile:(KCSFile*)file options:(NSDictionary*)options completionBlock:(KCSFileUploadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock;
+ (KCSRequest*)downloadKCSFile:(KCSFile*) file completionBlock:(KCSFileDownloadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock) progressBlock;
@end


#define KCSFileStoreTestExpries @"KCSFileStore.Test.Expires"
@interface KCSFile (KCSHiddenMethods)
@property (nonatomic, retain) NSURL* localURL;
@property (nonatomic, retain) NSData* data;
@property (nonatomic, retain) NSURL* remoteURL;
- (void) updateAfterUpload:(KCSFile*)newFile;
@end

#if TARGET_OS_IPHONE
@interface KCSPush (KCSHiddenMethods)
- (void) registerDeviceToken:(KCSSuccessBlock)completionBlock;
- (void) unRegisterDeviceToken:(KCSSuccessBlock)completionBlock;
@property (nonatomic, retain) id deviceToken;
@end
#endif

#endif
