//
//  RootViewController.h
//  KitTest
//
//  Created by Brian Wilson on 11/16/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KCSViewController;
@class ImageViewController;

@interface RootViewController : UITabBarController

@property (retain) KCSViewController *viewController;
@property (retain) ImageViewController *imageViewController;

- (IBAction)switchViews:(id)sender;


@end
