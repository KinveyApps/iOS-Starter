//
//  LinkedResourceViewController.m
//  KitTest
//
//  Created by Michael Katz on 6/22/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "LinkedResourceViewController.h"
#import <KinveyKit/KinveyKit.h>

#define randf (float)arc4random()/RAND_MAX

@interface ThreeImage : NSObject <KCSPersistable>

@property (nonatomic, retain) UIImage* image1;
@property (nonatomic, retain) UIImage* image2;
@property (nonatomic, retain) UIImage* image3;
@property (nonatomic, retain) NSString* objectId;
@end
@implementation ThreeImage
@synthesize image1, image2, image3;
@synthesize objectId;


- (NSDictionary *)hostToKinveyPropertyMapping
{
    return [NSDictionary dictionaryWithObjectsAndKeys:KCSEntityKeyId, @"objectId", @"image1", @"image1", @"image2", @"image2", @"image3", @"image3", nil];
}


@end

@interface LinkedResourceViewController ()

@end

@implementation LinkedResourceViewController
@synthesize progressView;
@synthesize im1_1;
@synthesize im1_2;
@synthesize im1_3;
@synthesize im2_1;
@synthesize im2_2;
@synthesize im2_3;
@synthesize im3_1;
@synthesize im3_2;
@synthesize im3_3;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Linked Resources";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
//    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
//    [self.view addGestureRecognizer:tap];
    [im1_1 addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)]];
    [im1_2 addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)]];
    [im1_3 addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)]];
    [im2_1 addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)]];
    [im2_2 addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)]];
    [im2_3 addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)]];
    [im3_1 addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)]];
    [im3_2 addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)]];
    [im3_3 addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)]];
    
}

- (void)viewDidUnload
{
    [self setIm1_1:nil];
    [self setIm1_2:nil];
    [self setIm1_3:nil];
    [self setIm2_1:nil];
    [self setIm2_2:nil];
    [self setIm2_3:nil];
    [self setIm3_1:nil];
    [self setIm3_2:nil];
    [self setIm3_3:nil];
    [self setProgressView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [im1_1 release];
    [im1_2 release];
    [im1_3 release];
    [im2_1 release];
    [im2_2 release];
    [im2_3 release];
    [im3_1 release];
    [im3_2 release];
    [im3_3 release];
    [progressView release];
    [super dealloc];
}
- (IBAction)save:(id)sender 
{
    progressView.progress = 0;
    
    KCSCollection* collection = [KCSCollection collectionFromString:@"linkedTest" ofClass:[ThreeImage class]];
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:collection options:nil];
    
    ThreeImage* one = [[[ThreeImage alloc] init] autorelease];
    one.objectId = @"object1";
    one.image1 = im1_1.image;
    one.image2 = im1_2.image;
    one.image3 = im1_3.image;
    
    ThreeImage* two = [[[ThreeImage alloc] init] autorelease];
    two.objectId = @"object2";
    two.image1 = im2_1.image;
    two.image2 = im2_2.image;
    two.image3 = im2_3.image;
    
    ThreeImage* three = [[[ThreeImage alloc] init] autorelease];
    three.objectId = @"object3";
    three.image1 = im3_1.image;
    three.image2 = im3_2.image;
    three.image3 = im3_3.image;
    
    [store saveObject:[NSArray arrayWithObjects:one, two, three, nil] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        NSLog(@"yay");
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"progress");
        progressView.progress = percentComplete;
    }];
}

- (IBAction)clear:(id)sender 
{
    im1_1.image = nil;
    im1_2.image = nil;
    im1_3.image = nil;
    im2_1.image = nil;
    im2_2.image = nil;
    im2_3.image = nil;
    im3_1.image = nil;
    im3_2.image = nil;
    im3_3.image = nil;
}

- (IBAction)load:(id)sender 
{
    progressView.progress = 0;
    KCSCollection* collection = [KCSCollection collectionFromString:@"linkedTest" ofClass:[ThreeImage class]];
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:collection options:nil];

    [store loadObjectWithID:[NSArray arrayWithObjects:@"object1", @"object2", @"object3", nil] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        NSLog(@"loaded, yay"); 
        for (ThreeImage* obj in objectsOrNil) {
            if ([obj.objectId isEqualToString:@"object1"] ) {
                im1_1.image = obj.image1;
                im1_2.image = obj.image2;
                im1_3.image = obj.image3;
            } else if ([obj.objectId isEqualToString:@"object2"] ) {
                im2_1.image = obj.image1;
                im2_2.image = obj.image2;
                im2_3.image = obj.image3;
            } else if ([obj.objectId isEqualToString:@"object3"] ) {
                im3_1.image = obj.image1;
                im3_2.image = obj.image2;
                im3_3.image = obj.image3;
            }
        }
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"load progress, yay");
        progressView.progress = percentComplete;
    }];
}

- (void)tap:(UITapGestureRecognizer*)tap 
{
    UIImageView* imview = (UIImageView*) [tap view];
    CGRect r = imview.bounds;
    UIGraphicsBeginImageContext(r.size);
    CGContextRef g = UIGraphicsGetCurrentContext();
    
    UIColor* randColor = [UIColor colorWithRed:randf green:randf blue:randf alpha:1.0];
    CGContextSetFillColorWithColor(g, randColor.CGColor);
    CGContextFillRect(g, r);
    UIImage* im = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    imview.image = im;
}
@end
