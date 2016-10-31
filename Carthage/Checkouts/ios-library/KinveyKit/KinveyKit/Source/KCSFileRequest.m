//
//  KCSFileRequest.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-08-31.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import "KCSFileRequest.h"
#import "KCSRequest+Private.h"

@implementation KCSFileRequest

+(instancetype)requestWithFileOperation:(NSOperation<KCSFileOperation> *)fileOperation
{
    return [[self alloc] initWithFileOperation:fileOperation];
}

-(instancetype)initWithFileOperation:(NSOperation<KCSFileOperation> *)fileOperation
{
    self = [self init];
    if (self) {
        self.fileOperation = fileOperation;
    }
    return self;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        [self addObserver:self
               forKeyPath:@"fileOperation"
                  options:NSKeyValueObservingOptionNew
                  context:nil];
        [self addObserver:self
               forKeyPath:@"networkOperation"
                  options:NSKeyValueObservingOptionNew
                  context:nil];
    }
    return self;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self) {
        if ([keyPath isEqualToString:@"fileOperation"]) {
            if (self.networkOperation.isCancelled) {
                NSOperation<KCSFileOperation>* fileOperation = change[NSKeyValueChangeNewKey];
                [fileOperation cancel];
            }
        } else if ([keyPath isEqualToString:@"networkOperation"]) {
            if (self.fileOperation.isCancelled) {
                NSOperation<KCSNetworkOperation>* networkOperation = change[NSKeyValueChangeNewKey];
                [networkOperation cancel];
            }
        }
    }
}

-(void)dealloc
{
    [self removeObserver:self
              forKeyPath:@"fileOperation"];
    [self removeObserver:self
              forKeyPath:@"networkOperation"];
}

-(BOOL)isCancelled
{
    @synchronized(self) {
        return [super isCancelled] || self.fileOperation.isCancelled;
    }
}

-(void)cancel
{
    @synchronized(self) {
        self.fileOperation.completionBlock = nil;
        [self.fileOperation cancel];
        [super cancel];
    }
}

@end
