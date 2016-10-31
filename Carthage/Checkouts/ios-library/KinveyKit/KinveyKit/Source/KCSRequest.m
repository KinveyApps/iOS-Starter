//
//  KCSRequest.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-08-26.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import "KCSRequest.h"
#import "KCSRequest+Private.h"

@implementation KCSRequest

+(instancetype)requestWithNetworkOperation:(NSOperation<KCSNetworkOperation>*)networkOperation
{
    return [[self alloc] initWithNetworkOperation:networkOperation];
}

-(instancetype)initWithNetworkOperation:(NSOperation<KCSNetworkOperation>*)networkOperation
{
    self = [super init];
    if (self) {
        self.networkOperation = networkOperation;
    }
    return self;
}

-(BOOL)isCancelled
{
    @synchronized(self) {
        return self._cancelled || self.networkOperation.isCancelled;
    }
}

-(void)cancel
{
    @synchronized(self) {
        self.networkOperation.completionBlock = nil;
        [self.networkOperation cancel];
        self._cancelled = YES;
        if (self.cancellationBlock) {
            if ([NSThread isMainThread]) {
                self.cancellationBlock();
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.cancellationBlock();
                });
            }
        }
    }
}

@end
