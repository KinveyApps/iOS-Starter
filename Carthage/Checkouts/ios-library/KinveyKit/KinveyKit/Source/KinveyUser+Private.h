//
//  KCSUserT.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-04-06.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import "KinveyUser.h"

@interface KCSUser()

@property (nonatomic, strong) NSMutableDictionary *userAttributes;

#if TARGET_OS_IOS

+(NSURL *)URLforLoginWithMICRedirectURI:(NSString *)redirectURI
                                 client:(id)client;

+(void)parseMICRedirectURI:(NSString *)redirectURI
                    forURL:(NSURL *)url
                    client:(id)client
       withCompletionBlock:(KCSUserCompletionBlock)completionBlock;

#endif

@end
