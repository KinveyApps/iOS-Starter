//
//  KCSLogManager.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/11/12.
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


#import "KCSLogManager.h"
#import "KCSClient.h"
#import "KCSClientConfiguration+KCSInternal.h"

enum {
    kKCSDebugChannelID = 1,
    kKCSTraceChannelID = 2,
    kKCSWarningChannelID = 3,
    kKCSErrorChannelID = 4,
    kKCSNetworkChannelID = 5,
    kKCSForcedChannelID = 6,
    kKCSCacheChannelID = 7
};

@interface KCSLogChannel : NSObject

+ (KCSLogChannel *)channelForKey:(NSString *)key;
+ (NSDictionary *)channels;

- (instancetype)initWithDisplayString: (NSString *)displayString channelID:(NSInteger)channelID;
@property (strong, readonly, nonatomic) NSString *displayString;
@property (readonly, nonatomic) NSInteger channelID;

@end

@implementation KCSLogChannel

- (instancetype)initWithDisplayString:(NSString *)displayString channelID:(NSInteger)channelID
{
    self = [super init];
    if (self){
        _displayString = displayString;
        _channelID = channelID;
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    return ([self.displayString isEqualToString:[(KCSLogChannel *)object displayString]] &&
            self.channelID == [(KCSLogChannel *)object channelID]);
    
}

+ (NSDictionary *)channels
{
    static NSDictionary *channels;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        channels = @{
        @"kNetworkChannel" : [[KCSLogChannel alloc] initWithDisplayString:@"[Network]" channelID:kKCSNetworkChannelID],
        @"kDebugChannel" : [[KCSLogChannel alloc] initWithDisplayString:@"[DEBUG]" channelID:kKCSDebugChannelID],
        @"kTraceChannel" : [[KCSLogChannel alloc] initWithDisplayString:@"[Trace]" channelID:kKCSTraceChannelID],
        @"kWarningChannel" : [[KCSLogChannel alloc] initWithDisplayString:@"[WARN]" channelID:kKCSWarningChannelID],
        @"kErrorChannel" : [[KCSLogChannel alloc] initWithDisplayString:@"[ERROR]" channelID:kKCSErrorChannelID],
        @"kForcedChannel" : [[KCSLogChannel alloc] initWithDisplayString:@"[ERROR]" channelID:kKCSForcedChannelID],
        @"kCacheChannel" : [[KCSLogChannel alloc] initWithDisplayString:@"[CACHE]" channelID:kKCSCacheChannelID]
        };
    });
    
    return channels;
}

+ (KCSLogChannel *)channelForKey:(NSString *)key
{
    return [[KCSLogChannel channels] objectForKey:key];
}

@end

@interface KCSLogManager ()
@property (strong, nonatomic) NSDictionary *loggingState;
@property (strong, nonatomic) id<KCSLogSink> logSink;
@end

@implementation KCSLogManager

- (instancetype)init
{
    self = [super init];
    if (self){}
    return self;
}

+ (KCSLogManager *)sharedLogManager
{
    static KCSLogManager *sKCSLogManager;
    // This can be called on any thread, so we synchronise.  We only do this in
    // the sKCSLogManager case because, once sKCSLogManager goes non-nil, it can
    // never go nil again.
    
    if (sKCSLogManager == nil) {
        @synchronized (self) {
            sKCSLogManager = [[KCSLogManager alloc] init];
            assert(sKCSLogManager != nil);
        }
        
        // Need to seed logging here, all off
        [sKCSLogManager configureLoggingWithNetworkEnabled:NO
                                              debugEnabled:NO
                                              traceEnabled:NO
                                            warningEnabled:NO
                                              errorEnabled:NO];
    }
    
    return sKCSLogManager;
}

+ (void) setLogSink:(id<KCSLogSink>)sink
{
    [self sharedLogManager].logSink = sink;
}


+ (KCSLogChannel *)kNetworkChannel
{
    return [KCSLogChannel channelForKey:@"kNetworkChannel"];
}

+ (KCSLogChannel *)kCacheChannel
{
    return [KCSLogChannel channelForKey:@"kCacheChannel"];
}

+ (KCSLogChannel *)kDebugChannel
{
    return [KCSLogChannel channelForKey:@"kDebugChannel"];
}

+ (KCSLogChannel *)kTraceChannel
{
    return [KCSLogChannel channelForKey:@"kTraceChannel"];
}

+ (KCSLogChannel *)kWarningChannel
{
    return [KCSLogChannel channelForKey:@"kWarningChannel"];
}

+ (KCSLogChannel *)kErrorChannel
{
    return [KCSLogChannel channelForKey:@"kErrorChannel"];
}

+ (KCSLogChannel *)kForcedChannel
{
    return [KCSLogChannel channelForKey:@"kForcedChannel"];
}


- (void) log:(NSString*)message
{
    if (self.logSink == nil) {
        //NSLog handles synchronization issues
        NSLog(@"%@", message);
    } else {
        [self.logSink log:message];
    }
}

- (void)logChannel: (KCSLogChannel *)channel file:(char *)sourceFile lineNumber: (int)lineNumber withFormat:(NSString *)format, ...
{
    BOOL channelIsEnabled = [(NSNumber *)[self.loggingState objectForKey:@(channel.channelID)] boolValue];
    
    // If the channel is not enabled we don't do anything here, ALWAYS log the forced channel
    if (channelIsEnabled || channel.channelID == kKCSForcedChannelID){
        va_list ap;
        NSString *print,*file;
        va_start(ap,format);
        file=[[NSString alloc] initWithBytes:sourceFile
                                      length:strlen(sourceFile)
                                    encoding:NSUTF8StringEncoding];
        print = [[NSString alloc] initWithFormat:format arguments:ap];
        va_end(ap);
        if ([print length] > 1500) {
            print = [[print substringToIndex:1500] stringByAppendingString:@"...(truncated)"];
        }
        
        [self log:[NSString stringWithFormat:@"%s:%d %@ %@",[[file lastPathComponent] UTF8String],
              lineNumber, channel.displayString, print]];
    }
}

- (void)configureLoggingWithNetworkEnabled:(BOOL)networkIsEnabled
                              debugEnabled:(BOOL)debugIsEnabled
                              traceEnabled:(BOOL)traceIsEnabled
                            warningEnabled:(BOOL)warningIsEnabled
                              errorEnabled:(BOOL)errorIsEnabled
{
    self.loggingState = @{
    @([[KCSLogManager kNetworkChannel] channelID]) : @(networkIsEnabled),
    @([[KCSLogManager kDebugChannel] channelID]) : @(debugIsEnabled),
    @([[KCSLogManager kTraceChannel] channelID]) : @(traceIsEnabled),
    @([[KCSLogManager kWarningChannel] channelID]) : @(warningIsEnabled),
    @([[KCSLogManager kErrorChannel] channelID]) : @(errorIsEnabled),
    @([[KCSLogManager kCacheChannel] channelID]) : @(traceIsEnabled)
    };
    
    static dispatch_once_t onceToken;
    if (onceToken) {
        int newlevel = 0;
        if (networkIsEnabled) {
            newlevel = MAX(newlevel, 4);
        }
        if (debugIsEnabled) {
            newlevel = MAX(newlevel, 5);
        }
        if (traceIsEnabled) {
            newlevel = MAX(newlevel, 5);
        }
        if (warningIsEnabled) {
            newlevel = MAX(newlevel, 2);
        }
        if (errorIsEnabled) {
            newlevel = MAX(newlevel, 1);
        }
        [[KCSClient sharedClient].configuration setLoglevel:newlevel];
    }
    dispatch_once(&onceToken, ^{});
}

- (BOOL)networkLogging
{
    NSNumber* networkkey = @([[KCSLogManager kNetworkChannel] channelID]);
    return [self.loggingState[networkkey] boolValue];
}

@end
