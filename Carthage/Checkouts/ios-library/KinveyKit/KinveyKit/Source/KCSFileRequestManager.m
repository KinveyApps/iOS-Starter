//
//  KCSFileRequest.m
//  KinveyKit
//
//  Created by Michael Katz on 9/24/13.
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


#import "KCSFileRequestManager.h"
#import "KCSCLient.h"
#import "KinveyCoreInternal.h"
#import "KinveyFileStoreInteral.h"

#import "KCSNSURLCxnFileOperation.h"
#import "KCSNSURLSessionFileOperation.h"
#import "KCSMockFileOperation.h"

@interface KCSFileRequestManager ()
//@property (nonatomic, copy) StreamCompletionBlock completionBlock;
//@property (nonatomic, copy) KCSProgressBlock2 progressBlock;

//@property (nonatomic, retain) NSFileHandle* outputHandle;

@property (nonatomic) BOOL useMock;

@end

@implementation KCSFileRequestManager

static NSOperationQueue* queue;

+ (void)initialize
{
    queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 4;
    [queue setName:@"com.kinvey.KinveyKit.FileRequestQueue"];
}

- (NSOperation<KCSFileOperation>*)downloadStream:(KCSFile*)intermediate
                                         fromURL:(NSURL*)url
                             alreadyWrittenBytes:(NSNumber*)alreadyWritten
                            requestConfiguration:(KCSRequestConfiguration*)requestConfiguration
                                 completionBlock:(StreamCompletionBlock)completionBlock
                                   progressBlock:(KCSProgressBlock2)progressBlock
{
    SWITCH_TO_MAIN_THREAD_PROGRESS_BLOCK2(progressBlock);
    
    //    self.completionBlock = completionBlock;

//    NSError* error = nil;
//    _outputHandle = [self prepFile:intermediate error:&error];
//    if (_outputHandle == nil || error != nil) {
//        completionBlock(NO, @{}, error);
//        return nil;
//    }
    
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    
    if (requestConfiguration.timeout > 0) {
        request.timeoutInterval = requestConfiguration.timeout;
    } else {
        request.timeoutInterval = [KCSClient sharedClient].connectionTimeout;
    }
    
    [request setHTTPMethod:KCSRESTMethodGET];
    
//    if (alreadyWritten != nil) {
//        //TODO: figure this one out
//        //        unsigned long long written = [_outputHandle seekToEndOfFile];
//        unsigned long long written = [alreadyWritten unsignedLongLongValue];
//        if ([alreadyWritten unsignedLongLongValue] == written) {
//            KCSLogInfo(KCS_LOG_CONTEXT_NETWORK, @"Download was already in progress. Resuming from byte %@.", alreadyWritten);
//            [request addValue:[NSString stringWithFormat:@"bytes=%llu-", written] forHTTPHeaderField:@"Range"];
////        } else {
////            //if they don't match start from begining
////            [_outputHandle seekToFileOffset:0];
//        }
//    }
    
    KCSLogInfo(KCS_LOG_CONTEXT_NETWORK, @"File Download: %@ %@", request.HTTPMethod, request.URL);

    NSOperation<KCSFileOperation>* op = nil;


//    if (_useMock == YES) {
//        op = [[KCSMockFileOperation alloc] initWithRequest:request];
//    } else {
//        
        if ([KCSPlatformUtils supportsNSURLSession]) {
            op = [[KCSNSURLSessionFileOperation alloc] initWithRequest:request output:intermediate.localURL context:alreadyWritten];
        } else {
            op = [[KCSNSURLCxnFileOperation alloc] initWithRequest:request output:intermediate.localURL context:alreadyWritten];
        }
    //    }

//    
    @weakify(op);
    op.completionBlock = ^() {
        @strongify(op);
        completionBlock(YES, op.returnVals, op.error);
    };
    op.progressBlock = ^(NSArray *objects, double percentComplete, NSDictionary* additionalContext) {
        if (progressBlock) {
            progressBlock(@[intermediate], percentComplete, additionalContext);
        }
    };
    
    [queue addOperation:op];
    return op;
}

- (NSOperation<KCSFileOperation>*)uploadStream:(NSInputStream*)stream
                                        length:(NSUInteger)length
                                   contentType:(NSString*)contentType
                                         toURL:(NSURL*)url
                               requiredHeaders:(NSDictionary*)requiredHeaders
                          requestConfiguration:(KCSRequestConfiguration*)requestConfiguration
                               completionBlock:(StreamCompletionBlock)completionBlock
                                 progressBlock:(KCSProgressBlock2)progressBlock
{
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    
    if (requestConfiguration.timeout > 0) {
        request.timeoutInterval = requestConfiguration.timeout;
    } else {
        request.timeoutInterval = [KCSClient sharedClient].connectionTimeout;
    }
    
    [request setHTTPMethod:KCSRESTMethodPUT];
    [request setHTTPBodyStream:stream];
    
    
    NSMutableDictionary* headers = [NSMutableDictionary dictionaryWithDictionary:requiredHeaders];
    headers[@"Content-Length"] = [@(length) stringValue];
    headers[@"Content-Type"] = contentType;
    [request setAllHTTPHeaderFields:headers];
    
    KCSLogInfo(KCS_LOG_CONTEXT_NETWORK, @"File Upload: %@ %@", request.HTTPMethod, request.URL);
    
    NSOperation<KCSFileOperation>* op = nil;
    
    
    //    if (_useMock == YES) {
    //        op = [[KCSMockFileOperation alloc] initWithRequest:request];
    //    } else {
    //
    if ([KCSPlatformUtils supportsNSURLSession]) {
        op = [[KCSNSURLSessionFileOperation alloc] initWithRequest:request output:nil context:nil];
    } else {
        op = [[KCSNSURLCxnFileOperation alloc] initWithRequest:request output:nil context:nil];
    }
  
    @weakify(op);
    op.completionBlock = ^() {
        @strongify(op);
        long long bytesWritten = op.bytesWritten;
        if (![@(bytesWritten) isEqualToNumber:@(length)]) {
            KCSLogError(KCS_LOG_CONTEXT_NETWORK, @"Only %lld bytes written", bytesWritten);
        }
        completionBlock(YES, op.returnVals, op.error);
    };
    op.progressBlock = ^(NSArray *objects, double percentComplete, NSDictionary* additionalContext) {
        if (progressBlock) {
            progressBlock(@[], percentComplete, additionalContext);
        }
    };
    
    [queue addOperation:op];
    return op;
}

+(void)cancelAndWaitUntilAllOperationsAreFinished
{
    [queue cancelAllOperations];
    [queue waitUntilAllOperationsAreFinished];
}

@end
