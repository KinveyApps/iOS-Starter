//
//  ImageViewController.h
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

#import <UIKit/UIKit.h>
#import <KinveyKit/KinveyKit.h>

@class RootViewController;

@interface ImageViewController : UIViewController
@property (retain) KCSClient *kinveyClient;
@property (retain, nonatomic) IBOutlet UIImageView *ourImage;
@property (retain, nonatomic) IBOutlet UILabel *imageName;
@property (retain, nonatomic) IBOutlet UILabel *imageState;

@property (retain) RootViewController *rootViewController;

- (IBAction)uploadImage:(id)sender;
- (IBAction)deleteImage:(id)sender;
- (IBAction)refreshImage:(id)sender;
- (IBAction)flipView:(id)sender;

@end
