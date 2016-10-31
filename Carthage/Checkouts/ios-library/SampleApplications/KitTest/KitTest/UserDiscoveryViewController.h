//
//  UserDiscoveryViewController.h
//  KitTest
//
//  Created by Michael Katz on 7/16/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserDiscoveryViewController : UIViewController <UITextFieldDelegate>
@property (retain, nonatomic) IBOutlet UITextField *email;
@property (retain, nonatomic) IBOutlet UITextField *username;
@property (retain, nonatomic) IBOutlet UITextField *lastname;
@property (retain, nonatomic) IBOutlet UITextField *firstname;
- (IBAction)lookup:(id)sender;
@property (retain, nonatomic) IBOutlet UITextView *resultsField;

@end
