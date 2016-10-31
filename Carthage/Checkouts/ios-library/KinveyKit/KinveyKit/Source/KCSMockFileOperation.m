//
//  KCSMockFileOperation.m
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


#import "KCSMockFileOperation.h"

#import "KinveyCoreInternal.h"
#import "KinveyDataStoreInternal.h"


@interface KCSMockFileOperation ()
//TODO: cleanup outputhandle from thing - this should probably be the fname!
//@property (nonatomic, retain) NSFileHandle* outputHandle;
@property (nonatomic) long long maxLength;
@property (nonatomic, retain) NSURLSession* session;
@property (nonatomic, retain) NSURLSessionDownloadTask* task;
@property (nonatomic, strong) NSURLRequest* request;
@property (nonatomic, retain) NSHTTPURLResponse* response;
//@property (nonatomic, retain) NSMutableData* responseData;
@property (nonatomic, strong) NSError* error;
@property (nonatomic, strong) NSDictionary* returnVals;
@property (nonatomic) BOOL done;
@end

@implementation KCSMockFileOperation


- (instancetype) initWithRequest:(NSURLRequest*)request output:(NSFileHandle*)fileHandle context:(id)context
{
    self = [super init];
    if (self) {
        _request = request;
        //        _outputHandle = fileHandle;
        _bytesWritten = 0;
        
        //#if BUILD_FOR_UNIT_TEST
        //    lastRequest = self;
        //#endif
    }
    return self;
}


-(void)start {
    @autoreleasepool {
        [super start];
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        
        
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


//- (void) cancel
//{
//    [_connection cancel];
//    [_outputHandle closeFile];
//    NSError* error = [NSError errorWithDomain:@"UNIT TEST" code:700 userInfo:nil];
//
//    NSMutableDictionary* returnVals = [NSMutableDictionary dictionary];
//    setIfValNotNil(returnVals[KCSFileMimeType], _serverContentType);
//    _completionBlock(NO, returnVals, error);
//}

- (void) complete:(NSError*)error
{
    if (_response && _response.statusCode >= 400) {
        //is an error just get the data locally
        //TODO: handle this!!  [_responseData appendData:data];
    }
    
    NSMutableDictionary* results = [NSMutableDictionary dictionary];
    //TODO: fix this    setIfValNotNil(results[KCSFileMimeType], [self contentType]);
    setIfValNotNil(results[kBytesWritten], @(_bytesWritten));
    self.returnVals = [results copy];
    //SET finished _completionBlock(NO, returnVals, error);
    
    self.finished = YES;
}


@end
