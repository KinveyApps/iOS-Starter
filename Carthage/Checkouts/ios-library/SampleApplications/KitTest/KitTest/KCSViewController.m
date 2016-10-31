//
//  KCSViewController.m
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

#import "KitTestObject.h"
#import "KCSViewController.h"
#import "RootViewController.h"




@implementation KCSViewController

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Basic";
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.testObject = [[[KitTestObject alloc] init] autorelease];
    
    self.testObject.name  = @"Kinvey Test 1";
    self.testObject.count = 1;
    
    self.currentTest = 0;
    
    ///////////////////////////
    // START OF KINVEY CODE
    //////////////////////////
    self.collectionCount = 0; // Indicate 0 items @ kinvey
    
    self.testStore = nil;
    
    ///////////////////////////
    // END OF KINVEY CODE
    //////////////////////////
    
}

- (void)viewDidUnload
{
    [self setLastName:nil];
    [self setLastCount:nil];
    [self setLastObjectId:nil];
    [self setCurrentCount:nil];
    self.updatedCount = nil;
    self.updatedName = nil;
    [self setNetworkActivity:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [_testObject release];
    [_lastObject release];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self prepareDataForView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UIKeyboardWillShowNotification
                                                  object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UIKeyboardWillHideNotification
                                                  object: nil];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


///////////////////////////
// START OF KINVEY CODE
//////////////////////////

// Make the keyboard display properly
- (void) shiftViewUpForKeyboard: (NSNotification*) theNotification;
{
    CGRect keyboardFrame;
    NSDictionary* userInfo = theNotification.userInfo;
    self.keyboardSlideDuration = [[userInfo objectForKey: UIKeyboardAnimationDurationUserInfoKey] floatValue];
    keyboardFrame = [[userInfo objectForKey: UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    
    UIInterfaceOrientation theStatusBarOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if UIInterfaceOrientationIsLandscape(theStatusBarOrientation)
        self.keyboardShiftAmount = keyboardFrame.size.width;
    else 
        self.keyboardShiftAmount = keyboardFrame.size.height;
    
    [UIView beginAnimations: @"ShiftUp" context: nil];
    [UIView setAnimationDuration: self.keyboardSlideDuration];
    self.view.center = CGPointMake( self.view.center.x, self.view.center.y - self.keyboardShiftAmount);
    [UIView commitAnimations];
    self.viewShiftedForKeyboard = TRUE;
}

//------------------

- (void) shiftViewDownAfterKeyboard;
{
    if (self.viewShiftedForKeyboard)
    {
        [UIView beginAnimations: @"ShiftUp" context: nil];
        [UIView setAnimationDuration: self.keyboardSlideDuration];
        self.view.center = CGPointMake( self.view.center.x, self.view.center.y + self.keyboardShiftAmount);
        [UIView commitAnimations];
        self.viewShiftedForKeyboard = FALSE;
    }
}

- (void) fetchAll
{
    // Update the last entity
    KCSQuery *q = [KCSQuery query];
    KCSQuerySortModifier *sm = [[KCSQuerySortModifier alloc] initWithField:@"_id" inDirection:kKCSDescending];
    [q addSortModifier:sm];
    [sm release];
    [self.testStore queryWithQuery:q withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        if (errorOrNil) {
            NSLog(@"Fetch Failed: %@", errorOrNil);
            [self.networkActivity stopAnimating];
        } else {
            NSLog(@"Fetch succeeded: %@", objectsOrNil);
            [self.networkActivity stopAnimating];                    
            
            _lastObject = [[objectsOrNil lastObject] retain];
            
            self.lastName.text = [_lastObject name];
            self.lastCount.text = [NSString stringWithFormat:@"%d", [_lastObject count]];
            self.lastObjectId.text = [_lastObject objectId];
        }
    } withProgressBlock:nil];
}

- (void)refreshAllFields
{
    // Update the count
    [self.testStore countWithBlock:^(unsigned long count, NSError *errorOrNil) {
        if (errorOrNil) {
            NSLog(@"Information Operation failed: %@", errorOrNil);
            [self.networkActivity stopAnimating]; 
        } else {
            NSLog(@"Information Operation succeeded: %lu", count);
            self.currentCount.text = [NSString stringWithFormat:@"%ld", count];
            
            [self fetchAll];
        }
    }];
}

- (void)dealloc {
    [_lastName release];
    [_lastCount release];
    [_lastObjectId release];
    [_currentCount release];
    [_updatedName release];
    [_updatedCount release];
    [_networkActivity release];
    [super dealloc];
}
- (IBAction)refreshData:(id)sender {
    
    [self.networkActivity startAnimating];
    [self refreshAllFields];
}

- (void) saveTestObject
{
    [self.testStore saveObject:self.testObject withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        if (errorOrNil) {
            NSLog(@"Persist failed: %@", errorOrNil);
            [self.networkActivity stopAnimating];
        } else {
            NSLog(@"Persist Succeeded: %@", objectsOrNil);
            [self refreshAllFields];
        }
    } withProgressBlock:nil];
}

- (IBAction)populateData:(id)sender {
    NSLog(@"Populating Data");
    [self.networkActivity startAnimating];
    [self saveTestObject];
}

- (void)persistNewValues: (BOOL)isUpdate
{
    NSLog(@"persisting new data");
    [self.networkActivity startAnimating];
    KitTestObject *test = [[KitTestObject alloc] init];
    
    test.name = self.updatedName.text;
    test.count = [self.updatedCount.text integerValue];
    
    if (isUpdate){
        // Having a legit object id causes an update instead of a new value
        test.objectId = self.lastObject.objectId;
    }
    [self saveTestObject];
    
}

- (IBAction)addEntry:(id)sender {
    [self persistNewValues:NO];
}

- (IBAction)updateEntry:(id)sender {
    [self persistNewValues:YES];
}

- (IBAction)deleteLast:(id)sender {
    [self.networkActivity startAnimating];
    [self.testStore removeObject:self.lastObject withCompletionBlock:^(unsigned long count, NSError *errorOrNil) {
        if (errorOrNil) {
            NSLog(@"Delete failed: %@", errorOrNil);
            [self.networkActivity stopAnimating];
        } else {
            NSLog(@"Delete Succeeded: %lu", count);
            [self refreshAllFields];
        }
    } withProgressBlock:nil];
}

- (IBAction)flipView:(id)sender {
    return [self.rootViewController switchViews:sender];
}

// Make the Keyboard go away
- (BOOL)textFieldShouldReturn: (UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)prepareDataForView
{
    if (self.testStore == nil){
        KCSCollection *collection = [KCSCollection collectionFromString:@"test_objects" ofClass:[KitTestObject class]];
        
        self.testStore = [KCSCachedStore storeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:KCSCachePolicyNone], KCSStoreKeyCachePolicy, collection, KCSStoreKeyResource, nil]];
        
        [self saveTestObject];
        [self.networkActivity startAnimating];
    }    
}


@end
