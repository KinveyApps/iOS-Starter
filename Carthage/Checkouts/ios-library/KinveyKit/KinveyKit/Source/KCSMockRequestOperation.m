//
//  KCSMockRequestOperation.m
//  KinveyKit
//
//  Created by Michael Katz on 8/23/13.
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

#import "KCSMockRequestOperation.h"
#import "KCSMockServer.h"

@interface KCSMockRequestOperation ()
@property (nonatomic, strong) NSMutableURLRequest* request;
@property (nonatomic) BOOL done;
@property (nonatomic, strong) KCSNetworkResponse* response;
@property (nonatomic, strong) NSError* error;
@end

@implementation KCSMockRequestOperation

- (instancetype)initWithRequest:(NSMutableURLRequest *)request
{
    self = [super init];
    if (self) {
        _request = request;
    }
    return self;
}


-(void)start {
    @autoreleasepool {
        [super start];
        [self resolveRequest];
    }
}


- (void) resolveRequest
{
    self.error = [[KCSMockServer sharedServer] errorForRequest:self.request];
    if (!self.error) {
        self.response = [[KCSMockServer sharedServer] responseForRequest:self.request];
    }
    self.finished = YES;
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


@end
