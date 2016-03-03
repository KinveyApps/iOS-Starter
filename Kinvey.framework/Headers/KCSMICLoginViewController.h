//
//  KCSMICViewController.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-06-16.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

@import UIKit;
#import "KinveyUser.h"

@interface KCSMICLoginViewController : UIViewController

@property (nonatomic, strong) id client;

-(instancetype)initWithRedirectURI:(NSString*)redirectURI
               withCompletionBlock:(KCSUserCompletionBlock)completionBlock;

-(instancetype)initWithRedirectURI:(NSString*)redirectURI
                           timeout:(NSTimeInterval)timeout
               withCompletionBlock:(KCSUserCompletionBlock)completionBlock;

@end
