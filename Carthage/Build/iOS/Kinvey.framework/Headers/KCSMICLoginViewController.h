//
//  KCSMICViewController.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-06-16.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#if TARGET_OS_IOS

@import UIKit;
#import "KinveyUser.h"

@interface KCSMICLoginViewController : UIViewController

@property (nonatomic, strong) id _Nonnull client;
@property (nonatomic, strong) NSString* _Nullable micApiVersion;

-(instancetype _Nonnull)initWithRedirectURI:(NSString* _Nonnull)redirectURI
                        withCompletionBlock:(KCSUserCompletionBlock _Nonnull)completionBlock;

-(instancetype _Nonnull)initWithRedirectURI:(NSString* _Nonnull)redirectURI
                                    timeout:(NSTimeInterval)timeout
                        withCompletionBlock:(KCSUserCompletionBlock _Nonnull)completionBlock;

@end

#endif
