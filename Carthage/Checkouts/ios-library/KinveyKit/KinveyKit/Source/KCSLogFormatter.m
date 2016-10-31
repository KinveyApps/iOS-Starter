//
//  KCSLogFormatter.m
//  KinveyKit
//
//  Created by Michael Katz on 9/19/13.
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


#import "KCSLogFormatter.h"
#import <libkern/OSAtomic.h>

#import "KinveyCoreInternal.h"

@interface KCSLogFormatter ()
{
    int atomicLoggerCount;
    NSDateFormatter *threadUnsafeDateFormatter;
}
@end

@implementation KCSLogFormatter

- (NSString *)stringFromDate:(NSDate *)date
{
    int32_t loggerCount = OSAtomicAdd32(0, &atomicLoggerCount);
    NSString* dateFormatString = @"yyyy-MM-dd HH:mm:ss:SSS";
    
    if (loggerCount <= 1)
    {
        // Single-threaded mode.
        
        if (threadUnsafeDateFormatter == nil)
        {
            threadUnsafeDateFormatter = [[NSDateFormatter alloc] init];
            [threadUnsafeDateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
            [threadUnsafeDateFormatter setDateFormat:dateFormatString];
        }
        
        return [threadUnsafeDateFormatter stringFromDate:date];
    }
    else
    {
        // Multi-threaded mode.
        // NSDateFormatter is NOT thread-safe.
        
        NSString *key = @"MyCustomFormatter_NSDateFormatter";
        
        NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
        NSDateFormatter *dateFormatter = [threadDictionary objectForKey:key];
        
        if (dateFormatter == nil)
        {
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
            [dateFormatter setDateFormat:dateFormatString];
            
            [threadDictionary setObject:dateFormatter forKey:key];
        }
        
        return [dateFormatter stringFromDate:date];
    }
}

- (NSString *)formatLogMessage:(KCS_DDLogMessage *)logMessage
{
    NSString *logLevel;
    switch (logMessage->logFlag)
    {
        case LOG_FLAG_FATAL  : logLevel = @"FATAL"; break;
        case LOG_FLAG_ERROR  : logLevel = @"ERROR"; break;
        case LOG_FLAG_WARN   : logLevel = @"WARN"; break;
        case LOG_FLAG_NOTICE : logLevel = @"NOTICE"; break;
        case LOG_FLAG_INFO   : logLevel = @"INFO"; break;
        case LOG_FLAG_DEBUG  : logLevel = @"DEBUG"; break;
    }
    
    NSString* context;
    switch (logMessage->logContext) {
        case KINVEY_KIT_LOG_CONTEXT     : context = @"KINVEYKIT"; break;
        case KCS_LOG_CONTEXT_NETWORK    : context = @"NETWORK"; break;
        case KCS_LOG_CONTEXT_DATA       : context = @"DATA"; break;
        case KCS_LOG_CONTEXT_TEST       : context = @"TEST"; break;
        case KCS_LOG_CONTEXT_FILESYSTEM : context = @"FILESYSTEM"; break;
        case KCS_LOG_CONTEXT_USER       : context = @"USER"; break;
    }
    
    NSString *dateAndTime = [self stringFromDate:(logMessage->timestamp)];
    
    NSString* logMsg = logMessage->logMsg;
    NSString* fname = [[[NSString stringWithUTF8String:logMessage->file] stringByDeletingPathExtension] lastPathComponent];
    return [NSString stringWithFormat:@"%@ %@:%d [%@ (%@)] %@", dateAndTime, fname, logMessage->lineNumber, logLevel, context, logMsg];
}

- (void)didAddToLogger:(id <KCS_DDLogger>)logger
{
    OSAtomicIncrement32(&atomicLoggerCount);
}
- (void)willRemoveFromLogger:(id <KCS_DDLogger>)logger
{
    OSAtomicDecrement32(&atomicLoggerCount);
}



@end
