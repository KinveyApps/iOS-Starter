//
//  KCSMutipleRequest.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-08-28.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import "KCSMultipleRequest.h"

@interface KCSMultipleRequest ()

@property (strong) NSMutableArray* requests;

@end

@implementation KCSMultipleRequest

-(instancetype)init
{
    self = [super init];
    if (self) {
        self.requests = [NSMutableArray array];
    }
    return self;
}

-(void)addRequest:(KCSRequest *)request
{
    @synchronized(self) {
        if (self.isCancelled) {
            [request cancel];
        }
        [self.requests addObject:request];
    }
}

-(BOOL)isCancelled
{
    @synchronized(self) {
        BOOL cancelled = NO;
        if (self.requests.count > 0) {
            cancelled = ((KCSRequest*) self.requests.firstObject).cancelled;
            for (KCSRequest* request in self.requests) {
                cancelled &= request.cancelled;
            }
        }
        return cancelled;
    }
}

-(void)cancel
{
    @synchronized(self) {
        for (KCSRequest* request in self.requests) {
            [request cancel];
        }
        [super cancel];
    }
}

@end
