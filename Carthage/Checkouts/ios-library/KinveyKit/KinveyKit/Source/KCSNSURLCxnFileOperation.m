//
//  KCSNSURLCxnFileOperation.m
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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
#pragma clang diagnostic ignored "-Wconversion"

#import "KCSNSURLCxnFileOperation.h"
#import "KinveyErrorCodes.h"
#import "KinveyCoreInternal.h"
#import "KinveyDataStoreInternal.h"
#import "KCSFileStore.h"

#define kBytesWritten @"bytesWritten"

@interface KCSNSURLCxnFileOperation ()
@property (nonatomic, retain) NSFileHandle* outputHandle;
@property (nonatomic, retain) NSURL* localURL;
@property (nonatomic) long long maxLength;
@property (nonatomic, retain) NSURLConnection* connection;
@property (nonatomic, strong) NSMutableURLRequest* request;
@property (nonatomic, retain) NSHTTPURLResponse* response;
@property (nonatomic, retain) NSMutableData* responseData;

@property (nonatomic, strong) NSError* error;
@property (nonatomic, strong) NSDictionary* returnVals;
@property (nonatomic) BOOL done;
@property (nonatomic, strong) id context;
@property (nonatomic) BOOL isUpload;
@end

@implementation KCSNSURLCxnFileOperation

- (NSFileHandle*) prepFile:(NSURL*)file error:(NSError **)error
{
    [KCSFileUtils touchFile:file];
    
    NSError* tempError = nil;
    NSFileHandle* handle = [NSFileHandle fileHandleForWritingToURL:file error:&tempError];
    if (tempError != nil) {
        handle = nil;
        if (error != NULL) {
            *error = [tempError updateWithMessage:@"Unable to write to intermediate file." domain:KCSFileStoreErrorDomain];
        }
    }
    return handle;
}


- (instancetype) initWithRequest:(NSMutableURLRequest*)request output:(NSURL*)fileURL context:(id)context
{
    self = [super init];
    if (self) {
        _request = request;
        _localURL = fileURL;
        _bytesWritten = 0;
        _context = context;
    }
    return self;
}


-(void)start {
    @autoreleasepool {
        [super start];
        
        if (_localURL) {
            //only do this for the downloads
            NSError* error = nil;
            _outputHandle = [self prepFile:self.localURL error:&error];
            if (_outputHandle == nil || error != nil) {
                [self complete:error];
                return;
            }
            
            NSNumber* alreadyWritten = (NSNumber*)self.context;
            if (alreadyWritten != nil) {
                //TODO: figure this one out
                unsigned long long written = [_outputHandle seekToEndOfFile];
                //unsigned long long written = [alreadyWritten unsignedLongLongValue];
                if ([alreadyWritten unsignedLongLongValue] == written) {
                    KCSLogInfo(KCS_LOG_CONTEXT_NETWORK, @"Download was already in progress. Resuming from byte %@.", alreadyWritten);
                    [self.request addValue:[NSString stringWithFormat:@"bytes=%llu-", written] forHTTPHeaderField:@"Range"];
                } else {
                    //if they don't match start from begining
                    [_outputHandle seekToFileOffset:0];
                }
            }
        } else {
            _isUpload = YES;
        }
#if !TARGET_OS_WATCH
        _connection = [[NSURLConnection alloc] initWithRequest:_request delegate:self startImmediately:NO];
        [_connection setDelegateQueue:[NSOperationQueue mainQueue]];
        [_connection start];
#endif
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


- (void) cancel
{
    [_connection cancel];
    [_outputHandle closeFile];
    NSError* error = [NSError errorWithDomain:@"UNIT TEST" code:700 userInfo:nil];
    
    self.error = error;

    [super cancel];
    self.finished = YES;
}

- (void) complete:(NSError*)error
{
    NSMutableDictionary* results = [NSMutableDictionary dictionary];
    setIfValNotNil(results[KCSFileMimeType], [self contentType]);
    setIfValNotNil(results[kBytesWritten], @(_bytesWritten));
    self.returnVals = [results copy];

    [_outputHandle closeFile];
    self.error = error;

    self.finished = YES;
}

#pragma mark - info

- (NSString*) contentType
{
    return self.request.allHTTPHeaderFields[kHeaderContentType];
}

- (BOOL) captureReponse
{
    return (_response && _response.statusCode >= 400) || _isUpload;
}

#pragma mark - delegate methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self complete:error];
}

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    KCSLogDebug(KCS_LOG_CONTEXT_NETWORK, @"GCS download response code: %ld",(long)[(NSHTTPURLResponse*)response statusCode]);
    
    _response = (NSHTTPURLResponse*)response;
    NSDictionary* headers =  [_response allHeaderFields];
    NSString* length = headers[kHeaderContentLength];
    _maxLength = [length longLongValue];
    
    if ([self captureReponse]) {
        _responseData = [NSMutableData data];
    }
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSInteger responseCode = self.response.statusCode;
    NSError* error = nil;
    if (responseCode >= 400) {
        NSString* errorStr = [[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding];
        ifNil(errorStr, @"");
        error = [NSError createKCSError:KCSFileStoreErrorDomain
                                   code:responseCode
                               userInfo:@{NSLocalizedDescriptionKey : @"Download from GCS Failed",
                                          NSLocalizedFailureReasonErrorKey : errorStr,
                                          NSURLErrorFailingURLErrorKey : self.request.URL}];
    }
    
    [self complete:error];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    KCSLogDebug(KCS_LOG_CONTEXT_NETWORK, @"downloaded %lu bytes from file service", (long)[data length]);
    
    if ([self captureReponse]) {
        //is an error just get the data locally
        [_responseData appendData:data];
    } else {
        //response is good, collect data
        [_outputHandle writeData:data];
        _bytesWritten += data.length;
        if (self.progressBlock) {
            NSUInteger downloadedAmount = [_outputHandle offsetInFile];
            //TODO: fix  or not?          _intermediateFile.length = downloadedAmount;
            
            double progress = (double)downloadedAmount / (double) _maxLength;
            _progressBlock(@[], progress, @{});
        }
    }
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    if (!_isUpload) {
        return;
    }
    
    _bytesWritten += bytesWritten;
    KCSLogDebug(KCS_LOG_CONTEXT_NETWORK, @"Uploaded %llu bytes (%ld / %ld)", _bytesWritten, (long)totalBytesWritten, (long)totalBytesExpectedToWrite);
    
    double progress = (double) totalBytesWritten / (double) totalBytesExpectedToWrite;
    if (_progressBlock) {
        _progressBlock(nil, progress, @{});
    }
}

@end

#pragma clang diagnostic pop
