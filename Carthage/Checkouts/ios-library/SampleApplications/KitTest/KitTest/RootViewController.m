//
//  RootViewController.m
//  KitTest
//
//  Created by Brian Wilson on 11/16/11.
//  Copyright (c) 2011-2013 Kinvey. All rights reserved.
//
// This software is licensed to you under the Kinvey terms of service located at
// http://www.kinvey.com/terms-of-use. By downloading, accessing and/or using this
// software, you hereby accept such terms of service  (and any agreement referenced
// therein) and agree that you have read, understand and agree to be bound by such
// terms of service and are of legal age to agree to such terms with Kinvey.
//
// This software contains valuable confidential and proprietary information of
// KINVEY, INC and is subject to applicable licensing agreements.
// Unauthorized reproduction, transmission or distribution of this file and its
// contents is a violation of applicable laws.
//


#import "RootViewController.h"
#import "ImageViewController.h"
#import "KCSViewController.h"

@implementation RootViewController

@synthesize imageViewController=_imageViewController;
@synthesize viewController=_viewController;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)switchViews:(id)sender
{
    
//    if (self.yellowViewController == nil)
//    {
//        YellowViewController *yellowController = [[YellowViewController alloc]
//                                                  initWithNibName:@"YellowView" bundle:nil];
//        self.yellowViewController = yellowController;
//        [yellowController release];
//    }
    
    [UIView beginAnimations:@"View Flip" context:nil];
    [UIView setAnimationDuration:1.25];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    
    UIViewController *coming = nil;
    UIViewController *going = nil;
    UIViewAnimationTransition transition;
    
    if (self.imageViewController.view.superview == nil) 
    {   
        coming = self.imageViewController;
        going = self.viewController;
        transition = UIViewAnimationTransitionFlipFromLeft;
    }
    else
    {
        coming = self.viewController;
        going = self.imageViewController;
        transition = UIViewAnimationTransitionFlipFromRight;
    }
    
    [UIView setAnimationTransition: transition forView:self.view cache:YES];
    [coming viewWillAppear:YES];
    [going viewWillDisappear:YES];
    [going.view removeFromSuperview];
    [self.view insertSubview: coming.view atIndex:0];
    [going viewDidDisappear:YES];
    [coming viewDidAppear:YES];
    
    [UIView commitAnimations];
    
}


@end
