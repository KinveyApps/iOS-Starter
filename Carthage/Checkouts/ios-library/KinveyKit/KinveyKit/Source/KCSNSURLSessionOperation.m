;//
//  KCSNSURLSessionOperation.m
//  KinveyKit
//
//  Created by Michael Katz on 9/11/13.
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

#import "KCSNSURLSessionOperation.h"
#import "KCSClient.h"
#import "KinveyCoreInternal.h"
#import "KCSURLProtocol.h"

#define CANCELLED_PROPERTY_KEY @"cancelled"

@interface KCSNSURLSessionOperation () <NSURLSessionDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSMutableURLRequest* request;
@property (nonatomic, strong) NSMutableData* downloadedData;
@property (nonatomic, strong) NSURLSessionDataTask* dataTask;
@property (nonatomic) long long expectedLength;
@property (nonatomic) BOOL done;
@property (nonatomic, getter=isCancelled, setter=setCancelled:) BOOL cancelled;
@property (nonatomic, strong) KCSNetworkResponse* response;
@property (nonatomic, strong) NSError* error;
@property (nonatomic, strong) NSURLSession* session;
@property (nonatomic, assign) dispatch_once_t sessionOnceToken;

@end

@implementation KCSNSURLSessionOperation

@synthesize cancelled = _cancelled;

- (NSURLSession*) session
{
    dispatch_once(&_sessionOnceToken, ^{
        NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.protocolClasses = [KCSURLProtocol protocolClasses];
        config.URLCache = [[NSURLCache alloc] initWithMemoryCapacity:0
                                                        diskCapacity:0
                                                            diskPath:nil];
        self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    });
    return _session;
}


- (instancetype) initWithRequest:(NSMutableURLRequest*) request
{
    self = [super init];
    if (self) {
        _request = request;
        _progressBlock = nil;
        
        self.response = [[KCSNetworkResponse alloc] init];
        self.dataTask = [[self session] dataTaskWithRequest:self.request];
        [self.dataTask setTaskDescription:self.clientRequestId];
    }
    return self;
}

-(void)start {
    if (self.isCancelled) {
        return;
    }
    
    @autoreleasepool {
        [super start];
        
        self.downloadedData = [NSMutableData data];
        [self.dataTask resume];
    }
}

- (void)setFinished:(BOOL)isFinished
{
    [self willChangeValueForKey:@"isFinished"];
    _done = isFinished;
    [self didChangeValueForKey:@"isFinished"];
}

- (BOOL)isFinished
{
    return ([self isCancelled] ? YES : _done);
}

-(BOOL)isExecuting
{
    return YES;
}

- (BOOL)isReady
{
    return YES;
}

-(BOOL)isAsynchronous
{
    return YES;
}

-(BOOL)isCancelled
{
    return _cancelled;
}

-(void)setCancelled:(BOOL)cancelled
{
    [self willChangeValueForKey:CANCELLED_PROPERTY_KEY];
    _cancelled = cancelled;
    [self didChangeValueForKey:CANCELLED_PROPERTY_KEY];
}

-(void)cancel
{
    self.cancelled = YES;
    [self.dataTask cancel];
    [super cancel];
}

- (void) complete:(NSError*) error
{
    if (!self.isCancelled) {
        self.response.jsonData = self.downloadedData;
    }
    self.error = error;
    self.finished = YES;
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask
{
    
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    NSTHREAD_IS_NOT_MAIN_THREAD;
    [self.downloadedData appendData:data];
    if (self.progressBlock) {
        id partial = self.response.code <= 300 ? data : nil;
        self.progressBlock(partial, self.downloadedData.length / (double) _expectedLength);
    }

}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    NSTHREAD_IS_NOT_MAIN_THREAD;
    NSHTTPURLResponse* hresponse = (NSHTTPURLResponse*) response;
    //TODO strip headers?
    KCSLogInfo(KCS_LOG_CONTEXT_NETWORK, @"received response: %ld %@ (KinveyKit ID %@)", (long)hresponse.statusCode, hresponse.allHeaderFields, self.clientRequestId);
    
    self.response.code = hresponse.statusCode;
    self.response.headers = hresponse.allHeaderFields;
    
    _expectedLength = response.expectedContentLength;
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse *))completionHandler
{
    NSTHREAD_IS_NOT_MAIN_THREAD;
    completionHandler(NULL);
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    NSTHREAD_IS_NOT_MAIN_THREAD;
    self.error = error;
    [self complete:error];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    NSTHREAD_IS_NOT_MAIN_THREAD;
    [session finishTasksAndInvalidate];
    
    [self complete:error];
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
}

@end
