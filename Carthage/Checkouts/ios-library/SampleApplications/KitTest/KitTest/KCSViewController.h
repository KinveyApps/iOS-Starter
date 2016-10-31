//
//  KCSViewController.h
//  KitTest
//
//  Created by Brian Wilson on 11/14/11.
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

@class KCSClient;
@class KitTestObject;
@class RootViewController;

@interface KCSViewController : UIViewController

// Kinvey Note: This is moving to be a Singleton in KinveyKit, so this code will not be necessary in the next release
@property (retain) KCSAppdataStore* testStore;
@property (retain) KitTestObject *testObject;
@property (readwrite) int collectionCount;
@property (readwrite) int currentTest;
@property (retain) KitTestObject *lastObject;

@property (retain) RootViewController *rootViewController;

// UI Stuff
@property BOOL viewShiftedForKeyboard;
@property NSTimeInterval keyboardSlideDuration;
@property CGFloat keyboardShiftAmount;


@property (retain, nonatomic) IBOutlet UILabel *lastName;
@property (retain, nonatomic) IBOutlet UILabel *lastCount;
@property (retain, nonatomic) IBOutlet UILabel *lastObjectId;
@property (retain, nonatomic) IBOutlet UILabel *currentCount;
@property (retain, nonatomic) IBOutlet UITextField *updatedName;
@property (retain, nonatomic) IBOutlet UITextField *updatedCount;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *networkActivity;


- (IBAction)refreshData:(id)sender;
- (IBAction)populateData:(id)sender;
- (IBAction)addEntry:(id)sender;
- (IBAction)updateEntry:(id)sender;
- (IBAction)deleteLast:(id)sender;
- (IBAction)flipView:(id)sender;

- (void)prepareDataForView;


@end
