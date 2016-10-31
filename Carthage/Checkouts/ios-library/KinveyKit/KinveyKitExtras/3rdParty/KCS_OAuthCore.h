//
//  OAuthCore.h
//
//  Created by Loren Brichter on 6/9/10.
//  Copyright 2010 Loren Brichter. All rights reserved.
//
// Modified 2012 Kinvey, Inc.

#import <Foundation/Foundation.h>

extern NSString *KCS_OAuthorizationHeader(NSURL *url,
									  NSString *method, 
									  NSData *body, 
									  NSString *_oAuthConsumerKey, 
									  NSString *_oAuthConsumerSecret, 
									  NSString *_oAuthToken, 
									  NSString *_oAuthTokenSecret,
                                      NSDictionary* additionalOAuthKeys);

