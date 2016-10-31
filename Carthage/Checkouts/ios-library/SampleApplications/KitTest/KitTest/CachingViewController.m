//
//  CachingViewController.m
//  KitTest
//
//  Created by Michael Katz on 5/16/12.
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

#import "CachingViewController.h"

#import <KinveyKit/KinveyKit.h>

#import "KitTestObject.h"

@interface CachingViewController ()
@property (nonatomic, retain) KCSCachedStore* store;
@property (nonatomic, retain) id objects;
@end

@implementation CachingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Caching";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    // Custom initialization
    KCSCollection *collection = [KCSCollection collectionFromString:@"test_objects" ofClass:[KitTestObject class]];
    
    self.store = [KCSCachedStore storeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:KCSCachePolicyNone], KCSStoreKeyCachePolicy, collection, KCSStoreKeyResource, nil]];
    self.queryButton.titleLabel.adjustsFontSizeToFitWidth = YES;
}

- (void)viewDidUnload
{
    [self setCountLabel:nil];
    [self setCachePolicy:nil];
    [self setProgressView:nil];
    [self setNameSwitch:nil];
    [self setTableView:nil];
    [self setQueryButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [_countLabel release];
    [_cachePolicy release];
    [_progressView release];
    [_nameSwitch release];
    [_tableView release];
    [_queryButton release];
    [super dealloc];
}

- (IBAction)performQuery:(id)sender {
    KCSCachePolicy policy = self.cachePolicy.selectedSegmentIndex;
    self.progressView.progress = 0.;
    if (self.nameSwitch.on) {
        [self.store group:[NSArray arrayWithObject:@"name"] reduce:[KCSReduceFunction COUNT] condition:nil completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
            self.objects = valuesOrNil;
            [self.tableView reloadData];
        } progressBlock:^(NSArray *objects, double percentComplete) {
            self.progressView.progress = percentComplete;
        } cachePolicy:policy];
    } else {
        [self.store queryWithQuery:[KCSQuery query] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
            self.countLabel.text = [NSString stringWithFormat:@"%d",[objectsOrNil count]];
            self.objects = objectsOrNil;
            [self.tableView reloadData];
        } withProgressBlock:^(NSArray *objects, double percentComplete) {
            self.progressView.progress = percentComplete; 
        } cachePolicy:policy];
    }
}

- (IBAction)selectPolicy:(id)sender {
}

- (IBAction)groupByName:(id)sender {
    self.queryButton.titleLabel.text = ((UISwitch*)sender).on ? @"Do Group" : @"Do Query";
}

#pragma mark - Table View
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.objects isKindOfClass:[NSArray class]] ? 1 : [[self.objects fieldsAndValues] count];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.objects isKindOfClass:[NSArray class]] ? [self.objects count] : 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.objects isKindOfClass:[NSArray class]] ? nil : [[[self.objects fieldsAndValues] objectAtIndex:section] objectForKey:@"name"];
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* reuseId = @"CELL_REUSE";
    UITableViewCell* cell = [tv dequeueReusableCellWithIdentifier:reuseId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseId];
    }
    if ([self.objects isKindOfClass:[NSArray class]]) {
        KitTestObject* obj = [self.objects objectAtIndex:indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@:%i", obj.name, obj.count];
    } else {
        KCSGroup* group = self.objects;
        NSNumber* count = [[[group fieldsAndValues] objectAtIndex:indexPath.section] objectForKey:[group returnValueKey]];
        cell.textLabel.text = [NSString stringWithFormat:@"Count = %@", count];
    }
    return cell;
}
@end
