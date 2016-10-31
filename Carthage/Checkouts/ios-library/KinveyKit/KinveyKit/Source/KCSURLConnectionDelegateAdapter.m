//
//  KCSURLConnectionDelegate.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-04-02.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import "KCSURLConnectionDelegateAdapter.h"

@interface KCSURLConnectionDelegateAdapter ()

@property (nonatomic, strong) NSURLResponse* response;
@property (nonatomic, strong) NSMutableData* data;
@property (nonatomic, strong) NSError* error;

@end

@implementation KCSURLConnectionDelegateAdapter

-(NSURLRequest *)connection:(NSURLConnection *)connection
            willSendRequest:(NSURLRequest *)request
           redirectResponse:(NSURLResponse *)response
{
    if (self.connectionWillSendRequestRedirectResponse) {
        return self.connectionWillSendRequestRedirectResponse(connection, request, response);
    }
    
    return request;
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.response = response;
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (!self.data) {
        self.data = [NSMutableData dataWithCapacity:4096];
    }
    [self.data appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (self.completionBlock) {
        self.completionBlock(self.response, self.data, self.error);
    }
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (self.completionBlock) {
        self.completionBlock(self.response, self.data, self.error);
    }
}

@end
