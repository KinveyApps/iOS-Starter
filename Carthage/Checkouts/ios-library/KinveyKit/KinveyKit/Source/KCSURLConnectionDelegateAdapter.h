//
//  KCSURLConnectionDelegate.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-04-02.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

@import Foundation;

@interface KCSURLConnectionDelegateAdapter : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, copy) NSURLRequest* (^connectionWillSendRequestRedirectResponse)(NSURLConnection* connection, NSURLRequest* request, NSURLResponse* response);
@property (nonatomic, copy) void (^completionBlock)(NSURLResponse *response, NSData *data, NSError *error);

@end
