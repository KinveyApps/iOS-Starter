//
//  KCSAppDelegate.h
//  KitTest
//
//  Created by Brian Wilson on 11/14/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <KinveyKit/KinveyKit.h>
@class ImageViewController;
@class KCSViewController;
@class RootViewController;
@class KCSClient;

@interface KCSAppDelegate : UIResponder <UIApplicationDelegate, KCSPersistableDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) KCSViewController *viewController;
@property (strong, nonatomic) ImageViewController *imageViewController;
@property (strong, nonatomic) RootViewController *rootViewController;

@property (retain) KCSClient *kinvey;

@end
