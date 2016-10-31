//
//  MainViewController.h
//  AppLifecycleTest
//
//  Created by Michael Katz on 5/15/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "FlipsideViewController.h"

@interface MainViewController : UIViewController <FlipsideViewControllerDelegate>

@property (strong, nonatomic) UIPopoverController *flipsidePopoverController;
@property (retain, nonatomic) IBOutlet UIImageView *blobImageView;

- (IBAction)showInfo:(id)sender;
- (IBAction)downloadBlob:(id)sender;

@end
