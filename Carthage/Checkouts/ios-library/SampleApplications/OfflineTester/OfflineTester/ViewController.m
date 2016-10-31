//
//  ViewController.m
//  OfflineTester
//
//  Created by Michael Katz on 8/16/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "ViewController.h"
#import <KinveyKit/KinveyKit.h>

@interface ViewController ()
{
    KCSAppdataStore* _store;
}
@end

@implementation ViewController
@synthesize nSavesLabel;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    KCSCollection* c = [KCSCollection collectionFromString:@"saveNames" ofClass:[KCSEntityDict class]];
    _store = [[KCSAppdataStore storeWithCollection:c options:@{KCSStoreKeyUniqueOfflineSaveIdentifier : @"x", KCSStoreKeyOfflineSaveDelegate : self}] retain];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self update];
}

- (void)viewDidUnload
{
    [self setNSavesLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)dealloc {
    [nSavesLabel release];
    [super dealloc];
}

#pragma mark -

- (void) update
{
    nSavesLabel.text = [NSString stringWithFormat:@"# Saves Enqueued: %d", [_store numberOfPendingSaves]];
}

- (IBAction)addSave:(id)sender
{
    KCSEntityDict* d = [[KCSEntityDict alloc] init];
    [_store saveObject:d withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        [self update];
    } withProgressBlock:nil];
    [self update];
}

#pragma mark -
- (void)didSave:(id<KCSPersistable>)entity
{
    [self update];
}
@end
