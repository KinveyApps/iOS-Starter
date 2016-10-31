//
//  KCSMICRequest2.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-08-26.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import "KCSHttpRequest.h"

@interface KCSMICRequest2 : KCSHttpRequest

+(instancetype)requestWithRedirectURI:(NSString *)redirectURI
                           completion:(KCSRequestCompletionBlock)completion;

@end
