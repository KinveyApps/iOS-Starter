//
//  DataStoreOperation.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-08-31.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import "DataStoreOperation.h"

@implementation DataStoreOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

- (void)start
{
    [self setExecuting:YES];
    if (!self.isCancelled) {
        _block();
    }
}

- (BOOL)isConcurrent
{
    return NO;
}

- (BOOL)isReady
{
    return YES;
}

- (void)setFinished:(BOOL)finished
{
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing
{
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isExecuting
{
    return _executing;
}

- (BOOL)isFinished
{
    return _finished;
}

@end
