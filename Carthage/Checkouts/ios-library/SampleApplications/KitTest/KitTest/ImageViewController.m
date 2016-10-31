//
//  ImageViewController.m
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


#import "ImageViewController.h"
#import "RootViewController.h"

@implementation ImageViewController

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Image";
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.imageName.text = @"kinvey_image.png";
    
    
    //    [blob blobDelegate:self saveData:data  toBlob:@"kinvey_image.png"];
    
    
    //    [blob blobDelegate:self deleteBlog:@"kinvey_image.png"];

}


- (void)viewDidUnload
{
    [self setOurImage:nil];
    [self setImageName:nil];
    [self setImageState:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [_ourImage release];
    [_imageName release];
    [_imageState release];
    [super dealloc];
}

- (IBAction)uploadImage:(id)sender
{
    // Do File API here
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"metal_kinvey_1280x800" ofType:@"png"];  
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    
    [KCSFileStore uploadData:data options:@{KCSFileId : self.imageName.text, KCSFileFileName : self.imageName.text} completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        if (!error) {
            self.imageState.text = @"Image sent to Kinvey!";
            [self refreshImage:self];
        } else {
            NSLog(@"BLOB Failed with error: %@ (%@)", error, [error userInfo]);
            NSString *errMsg = [NSString stringWithFormat:@"FAILED with error %d", [error code]];
            self.imageState.text = errMsg;
        }
    } progressBlock:nil];
}

- (IBAction)deleteImage:(id)sender
{
    [KCSFileStore deleteFile:self.imageName.text completionBlock:^(unsigned long count, NSError *error) {
        if (!error) {
            self.imageState.text = @"Image deleted from Kinvey";
            [self.ourImage setHidden:YES];
        } else {
            NSLog(@"BLOB Failed with error: %@ (%@)", error, [error userInfo]);
            NSString *errMsg = [NSString stringWithFormat:@"FAILED with error %d", [error code]];
            self.imageState.text = errMsg;
        }
    }];
}

- (IBAction)refreshImage:(id)sender
{
    [KCSFileStore downloadData:self.imageName.text completionBlock:^(NSArray *downloadedResources, NSError *error) {
        if (!error) {
            NSData *imageData = [downloadedResources[0] data];
            _ourImage.image = [UIImage imageWithData:imageData];
            [self.ourImage setHidden:NO];
            self.imageState.text = @"Image from Kinvey";
        } else {
            NSLog(@"BLOB Failed with error: %@ (%@)", error, [error userInfo]);
            NSString *errMsg = [NSString stringWithFormat:@"FAILED with error %d", [error code]];
            self.imageState.text = errMsg;
        }
    } progressBlock:nil];
}

- (IBAction)flipView:(id)sender
{
    return [self.rootViewController switchViews:sender];
}
@end
