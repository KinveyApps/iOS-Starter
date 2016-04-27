//
//  AppDelegate.m
//  BookshelfObjC
//
//  Created by Victor Barros on 2016-03-03.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import "AppDelegate.h"
#import "DetailViewController.h"

@import Kinvey;
#import "BookshelfObjC-Swift.h"

@import SVProgressHUD;

@interface AppDelegate () <UISplitViewControllerDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[KNVClient sharedClient] initializeWithAppKey:@"appKey"
                                         appSecret:@"appSecret"];
    
    // Override point for customization after application launch.
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
    navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
    splitViewController.delegate = self;
    
    if ([[KNVClient sharedClient] activeUser]) {
        //do nothing
    } else {
        [SVProgressHUD show];
        [KNVUser existsWithUsername:@"test"
                  completionHandler:^(BOOL exists, NSError * _Nullable error)
        {
            if (exists) {
                [KNVUser loginWithUsername:@"test"
                                  password:@"test"
                         completionHandler:^(KNVUser * _Nullable user, NSError * _Nullable error)
                {
                    [SVProgressHUD dismiss];
                    if ([[KNVClient sharedClient] activeUser]) {
                        //do nothing
                    } else {
                        //do something!
                    }
                }];
            } else {
                [KNVUser signupWithUsername:@"test"
                                   password:@"test"
                          completionHandler:^(KNVUser * _Nullable user, NSError * _Nullable error)
                 {
                     [SVProgressHUD dismiss];
                     if ([[KNVClient sharedClient] activeUser]) {
                         //do nothing
                     } else {
                         //do something!
                     }
                 }];
            }
        }];
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Split view

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    if ([secondaryViewController isKindOfClass:[UINavigationController class]] && [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:[DetailViewController class]] && ([(DetailViewController *)[(UINavigationController *)secondaryViewController topViewController] book] == nil)) {
        // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
        return YES;
    } else {
        return NO;
    }
}

@end
