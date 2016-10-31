//
//  KCSUser2+KinveyUserService+Private.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-04-06.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

@import Foundation;
#import "KCSUser2+KinveyUserService.h"

extern NSString* const kKCSMICRefreshTokenKey;
extern NSString* const kKCSMICRedirectURIKey;

@interface KCSUser2 ()

+(NSURL *)URLforLoginWithMICRedirectURI:(NSString *)redirectURI
                            isLoginPage:(BOOL)isLoginPage;

+(NSURL *)URLforLoginWithMICRedirectURI:(NSString *)redirectURI
                                 client:(id)client;

+(NSURL *)URLforLoginWithMICRedirectURI:(NSString *)redirectURI
                            isLoginPage:(BOOL)isLoginPage
                                 client:(id)client;

+(void)parseMICRedirectURI:(NSString *)redirectURI
                    forURL:(NSURL *)url
                    client:(id)client
       withCompletionBlock:(KCSUser2CompletionBlock)completionBlock;

+(void)oAuthTokenWithRefreshToken:(NSString*)refreshToken
                      redirectURI:(NSString*)redirectURI
                             sync:(BOOL)sync
                       completion:(KCSUser2CompletionBlock)completionBlock;

@end
