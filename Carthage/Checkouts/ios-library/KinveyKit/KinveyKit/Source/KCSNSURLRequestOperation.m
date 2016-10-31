//
//  KCSNSURLRequestOperation.m
//  KinveyKit
//
//  Created by Michael Katz on 8/20/13.
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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"

#import "KCSNSURLRequestOperation.h"
#import "KCSClient.h"
#import "KinveyCoreInternal.h"

@interface KCSNSURLRequestOperation () <NSURLConnectionDataDelegate, NSURLConnectionDataDelegate>
@property (nonatomic, strong) NSMutableURLRequest* request;
@property (nonatomic, strong) NSMutableData* downloadedData;
@property (nonatomic, strong) NSURLConnection* connection;
@property (nonatomic) long long expectedLength;
@property (nonatomic) BOOL done;
@property (nonatomic, strong) KCSNetworkResponse* response;
@property (nonatomic, strong) NSError* error;
@end

@implementation KCSNSURLRequestOperation

- (instancetype) initWithRequest:(NSMutableURLRequest*) request
{
    self = [super init];
    if (self) {
        _request = request;
        _progressBlock = nil;
    }
    return self;
}

-(void)start {
    @autoreleasepool {
        [super start];
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        
        self.downloadedData = [NSMutableData data];
        self.response = [[KCSNetworkResponse alloc] init];
#if !TARGET_OS_WATCH
        _connection = [[NSURLConnection alloc] initWithRequest:_request delegate:self startImmediately:NO];
        // [connection setDelegateQueue:[NSOperationQueue currentQueue]];
        [_connection scheduleInRunLoop:runLoop forMode:NSRunLoopCommonModes];
        [_connection start];
#endif
        [runLoop run];
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

- (void) complete:(NSError*) error
{
    self.response.jsonData = self.downloadedData;
    self.error = error;
    self.finished = YES;
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse* hresponse = (NSHTTPURLResponse*) response;
    //TODO strip headers?
    KCSLogInfo(KCS_LOG_CONTEXT_NETWORK, @"received response: %ld %@", (long)hresponse.statusCode, hresponse.allHeaderFields);

    self.expectedLength = response.expectedContentLength;
    
    self.response.code = hresponse.statusCode;
    self.response.headers = hresponse.allHeaderFields;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self complete:error];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.downloadedData appendData:data];
    if (self.progressBlock) {
        self.progressBlock(self.downloadedData, self.downloadedData.length / (double) _expectedLength);
    }
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    //TODO: is an error
    NSError* error = nil;
    [self complete:error];
}

@end

#pragma clang diagnostic pop
