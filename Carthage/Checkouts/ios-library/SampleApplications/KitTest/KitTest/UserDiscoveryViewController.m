//
//  UserDiscoveryViewController.m
//  KitTest
//
//  Created by Michael Katz on 7/16/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "UserDiscoveryViewController.h"
#import <KinveyKit/KinveyKit.h>

@interface UserDiscoveryViewController ()

@end

@implementation UserDiscoveryViewController
@synthesize resultsField;
@synthesize email;
@synthesize username;
@synthesize lastname;
@synthesize firstname;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Users";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [self setUsername:nil];
    [self setLastname:nil];
    [self setFirstname:nil];
    [self setResultsField:nil];
    [self setEmail:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [username release];
    [lastname release];
    [firstname release];
    [resultsField release];
    [email release];
    [super dealloc];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self lookup:nil];
    return YES;
}


- (IBAction)lookup:(id)sender {
    [self.view endEditing:YES];
    
    NSString* uname = username.text;
    NSString* fname = firstname.text;
    NSString* lname = lastname.text;
    NSString* ename = email.text;
    
    NSMutableDictionary* stuff = [NSMutableDictionary dictionaryWithCapacity:4];
    if (uname.length  > 0) {
        [stuff setValue:uname forKey:KCSUserAttributeUsername];
    }
    if (fname.length > 0) {
        [stuff setValue:fname forKey:KCSUserAttributeGivenname];
    }
    if (lname.length > 0) {
        [stuff setValue:lname forKey:KCSUserAttributeSurname];
    }
    if (ename.length >0) {
        [stuff setValue:ename forKey:KCSUserAttributeEmail];
    }
    
    [KCSUserDiscovery lookupUsersForFieldsAndValues:stuff completionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        if (errorOrNil) {
            self.resultsField.text = [NSString stringWithFormat:@"ERROR: %@", errorOrNil];
        } else {
            if (objectsOrNil.count == 0) {
                self.resultsField.text = @"No Matching Users found.";
            } else {
                self.resultsField.text = [objectsOrNil description];
            }
        }
    } progressBlock:^(NSArray *objects, double percentComplete) {
        
    }];
}
@end
