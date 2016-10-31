//
//  ViewController.h
//  KitTest
//
//  Created by Michael Katz on 9/7/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
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

@interface KinveyRefViewController : UIViewController
@property (retain, nonatomic) IBOutlet UIButton *one;
@property (retain, nonatomic) IBOutlet UIButton *two;
@property (retain, nonatomic) IBOutlet UIButton *three;
@property (retain, nonatomic) IBOutlet UIButton *four;
@property (retain, nonatomic) IBOutlet UIButton *a;
@property (retain, nonatomic) IBOutlet UIButton *b;
@property (retain, nonatomic) IBOutlet UIButton *c;
@property (retain, nonatomic) IBOutlet UIButton *d;
- (IBAction)save:(id)sender;
@property (retain, nonatomic) IBOutlet UIButton *load;
- (IBAction)doOne:(id)sender;
- (IBAction)load:(id)sender;
- (IBAction)doTwo:(id)sender;
- (IBAction)doThree:(id)sender;
- (IBAction)doFour:(id)sender;
- (IBAction)doA:(id)sender;
- (IBAction)doB:(id)sender;
- (IBAction)doD:(id)sender;

- (IBAction)doC:(id)sender;

- (IBAction)clear:(id)sender;
@end
