//
//  LinkedResourceViewController.h
//  KitTest
//
//  Created by Michael Katz on 6/22/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LinkedResourceViewController : UIViewController
@property (retain, nonatomic) IBOutlet UIImageView *im1_1;
@property (retain, nonatomic) IBOutlet UIImageView *im1_2;
@property (retain, nonatomic) IBOutlet UIImageView *im1_3;
@property (retain, nonatomic) IBOutlet UIImageView *im2_1;
@property (retain, nonatomic) IBOutlet UIImageView *im2_2;
@property (retain, nonatomic) IBOutlet UIImageView *im2_3;
@property (retain, nonatomic) IBOutlet UIImageView *im3_1;
@property (retain, nonatomic) IBOutlet UIImageView *im3_2;
@property (retain, nonatomic) IBOutlet UIImageView *im3_3;
- (IBAction)save:(id)sender;
- (IBAction)clear:(id)sender;
- (IBAction)load:(id)sender;
@property (retain, nonatomic) IBOutlet UIProgressView *progressView;

@end
