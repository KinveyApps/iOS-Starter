//
//  KCSLogManager.h
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

@import Foundation;
#import "KCSLogSink.h"

// Convenience Macros
#define KCSLog(channel,format,...) \
[[KCSLogManager sharedLogManager] logChannel:(channel) file:__FILE__ lineNumber:__LINE__ \
withFormat:(format),##__VA_ARGS__]

#define KCSLogNetwork(format,...) \
[[KCSLogManager sharedLogManager] logChannel:[KCSLogManager kNetworkChannel] file:__FILE__ lineNumber:__LINE__ \
withFormat:(format),##__VA_ARGS__]

#undef KCSLogDebug
#define KCSLogDebug(format,...) \
[[KCSLogManager sharedLogManager] logChannel:[KCSLogManager kDebugChannel] file:__FILE__ lineNumber:__LINE__ \
withFormat:(format),##__VA_ARGS__]

#define KCSLogTrace(format,...) \
[[KCSLogManager sharedLogManager] logChannel:[KCSLogManager kTraceChannel] file:__FILE__ lineNumber:__LINE__ \
withFormat:(format),##__VA_ARGS__]

#define KCSLogWarning(format,...) \
[[KCSLogManager sharedLogManager] logChannel:[KCSLogManager kWarningChannel] file:__FILE__ lineNumber:__LINE__ \
withFormat:(format),##__VA_ARGS__]

//-------------------------------- Error Handling

#ifdef NEVER //BUILD_FOR_UNIT_TEST
#define KCSLogError(format,...) \
 if ([KCSLogManager sharedLogManager].suppressErrorToExceptionOnTest == YES) { \
   [[KCSLogManager sharedLogManager] logChannel:[KCSLogManager kErrorChannel] file:__FILE__ lineNumber:__LINE__ withFormat:(format), ##__VA_ARGS__]; \
 } else { \
     NSAssert(NO, format, ##__VA_ARGS__); \
 }

#define KCSLogNSError(msg, err) \
if (err) { \
    NSAssert(NO, @"%@; error: (%@) ", msg, err); \
}

#else

#undef KCSLogError
#define KCSLogError(format,...) \
[[KCSLogManager sharedLogManager] logChannel:[KCSLogManager kErrorChannel] file:__FILE__ lineNumber:__LINE__ withFormat:(format), ##__VA_ARGS__]

#undef KCSLogNSError
#define KCSLogNSError(msg, err) \
if (err) { \
[[KCSLogManager sharedLogManager] logChannel:[KCSLogManager kErrorChannel] file:__FILE__ lineNumber:__LINE__ withFormat:(@"%@; error: (%@) "), msg, err]; \
}
#endif
//--------------------------------

#define KCSLogCache(format,...) \
[[KCSLogManager sharedLogManager] logChannel:[KCSLogManager kCacheChannel] file:__FILE__ lineNumber:__LINE__ \
withFormat:(format),##__VA_ARGS__]

#define KCSLogForced(format,...) \
[[KCSLogManager sharedLogManager] logChannel:[KCSLogManager kForcedChannel] file:__FILE__ lineNumber:__LINE__ \
withFormat:(format),##__VA_ARGS__]

#define KCSLogRequestId(format,...) \
[[KCSLogManager sharedLogManager] logChannel:[KCSLogManager kNetworkChannel] file:__FILE__ lineNumber:__LINE__ \
withFormat:(format),##__VA_ARGS__]

@class KCSLogChannel;

@interface KCSLogManager : NSObject

+ (KCSLogManager *)sharedLogManager;
+ (void) setLogSink:(id<KCSLogSink>)sink;

+ (KCSLogChannel *)kNetworkChannel;
+ (KCSLogChannel *)kDebugChannel;
+ (KCSLogChannel *)kTraceChannel;
+ (KCSLogChannel *)kWarningChannel;
+ (KCSLogChannel *)kErrorChannel;
+ (KCSLogChannel *)kForcedChannel;
+ (KCSLogChannel *)kCacheChannel;

- (void)logChannel: (KCSLogChannel *)channel file:(char *)sourceFile lineNumber: (int)lineNumber withFormat:(NSString *)format, ...;

- (void)configureLoggingWithNetworkEnabled: (BOOL)networkIsEnabled
                              debugEnabled: (BOOL)debugIsEnabled
                              traceEnabled: (BOOL)traceIsEnabled
                            warningEnabled: (BOOL)warningIsEnabled
                              errorEnabled: (BOOL)errorIsEnabled;

- (BOOL) networkLogging;

@property (nonatomic) BOOL suppressErrorToExceptionOnTest;

@end
