//
//  ViewController.m
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

#import "KinveyRefViewController.h"
@interface LeftObj : NSObject <KCSPersistable>
@property (nonatomic, retain) NSString* objId;
@property (nonatomic, retain) NSArray* rightObjs;
@end

@interface RightObj : NSObject <KCSPersistable>
@property (nonatomic, retain) NSString* objId;
@property (nonatomic, retain) NSArray* leftObjs;
@end
@implementation RightObj

- (NSDictionary *)hostToKinveyPropertyMapping
{
    return @{@"objId" : KCSEntityKeyId, @"leftObjs" : @"leftObj"};
}
+ (NSDictionary *)kinveyPropertyToCollectionMapping
{
    return @{ @"leftObj" : @"LeftCollection" };
}
+ (NSDictionary *)kinveyObjectBuilderOptions
{
    return @{KCS_REFERENCE_MAP_KEY : @{@"leftObjs" : [LeftObj class]}};
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@>",self.objId];
}
@end


@implementation LeftObj

- (NSDictionary *)hostToKinveyPropertyMapping
{
    return @{@"objId" : KCSEntityKeyId, @"rightObjs" : @"rightObj"};
}
+ (NSDictionary *)kinveyPropertyToCollectionMapping
{
    return @{ @"rightObj" : @"RightCollection" };
}
+ (NSDictionary *)kinveyObjectBuilderOptions
{
    return @{KCS_REFERENCE_MAP_KEY : @{@"rightObjs" : [RightObj class]}};
}
- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@>",self.objId];
}
@end

@interface KinveyRefViewController () {
    NSMutableSet* _leftSide;
    NSMutableSet* _rightSide;
}

@end

@implementation KinveyRefViewController
@synthesize load;
@synthesize one;
@synthesize two;
@synthesize three;
@synthesize four;
@synthesize a;
@synthesize b;
@synthesize c;
@synthesize d;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"KinveyRef";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _leftSide = [[NSMutableSet set] retain];
    _rightSide = [[NSMutableSet set] retain];
}

- (void)viewDidUnload
{
    [_leftSide release], _leftSide = nil;
    [_rightSide release], _rightSide = nil;
    [self setOne:nil];
    [self setTwo:nil];
    [self setThree:nil];
    [self setFour:nil];
    [self setA:nil];
    [self setB:nil];
    [self setC:nil];
    [self setD:nil];
    [self setLoad:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [_leftSide release], _leftSide = nil;
    [_rightSide release], _rightSide = nil;

    [one release];
    [two release];
    [three release];
    [four release];
    [a release];
    [b release];
    [c release];
    [d release];
    [load release];
    [super dealloc];
}

- (id)leftObj:(NSString*)i
{
    LeftObj* l= [[[LeftObj alloc] init] autorelease];
    l.objId = i;
    l.rightObjs = @[];
    return l;
}
- (id)rightObj:(NSString*)i
{
    RightObj* r = [[[RightObj alloc] init] autorelease];
    r.objId = i;
    r.leftObjs = @[];
    return r;
}


- (IBAction)save:(id)sender {
    LeftObj* One = [self leftObj:@"1"];
    LeftObj* Two = [self leftObj:@"2"];
    LeftObj* Three = [self leftObj:@"3"];
    LeftObj* Four = [self leftObj:@"4"];
    RightObj* A = [self rightObj:@"A"];
    RightObj* B = [self rightObj:@"B"];
    RightObj* C = [self rightObj:@"C"];
    RightObj* D = [self rightObj:@"D"];
    
    NSMutableArray* arrR = [NSMutableArray arrayWithCapacity:4];
    for (UIButton* bu in _rightSide) {
        if (bu == a) {
            [arrR addObject:A];
        } else if (bu == b) {
            [arrR addObject:B];
        } else if (bu == c) {
            [arrR addObject:C];
        } else if (bu == d) {
            [arrR addObject:D];
        }
    }
    NSMutableArray* arrL = [NSMutableArray arrayWithCapacity:4];
    for (UIButton* bu in _leftSide) {
        if (bu == one) {
            [arrL addObject:One];
            One.rightObjs = arrR;
        } else if (bu == two) {
            [arrL addObject:Two];
            Two.rightObjs = arrR;
        } else if (bu == three) {
            [arrL addObject:Three];
            Three.rightObjs = arrR;
        } else if (bu == four) {
            [arrL addObject:Four];
            Four.rightObjs = arrR;
        }
    }


    if ([_rightSide containsObject:a]) {
        A.leftObjs = arrL;
    }
    if ([_rightSide containsObject:b]) {
        B.leftObjs = arrL;
    }
    if ([_rightSide containsObject:c]) {
        C.leftObjs = arrL;
    }
    if ([_rightSide containsObject:d]) {
        D.leftObjs = arrL;
    }
    
    KCSCollection* collection = [KCSCollection collectionFromString:@"LeftCollection" ofClass:[LeftObj class]];
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:collection options:nil];
    [store saveObject:@[One,Two,Three,Four] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        //TODO
        if (errorOrNil) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:errorOrNil.localizedDescription message:errorOrNil.localizedFailureReason delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            [alert release];
        }
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        //TODO
    }];
}

- (void) refresh
{
    NSMutableString* left = [NSMutableString string];
    NSMutableString* right = [NSMutableString string];
    if ([_leftSide containsObject:one]) {
        [left appendString:@"1."];
    }
    if ([_leftSide containsObject:two]) {
        [left appendString:@"2."];
    }
    if ([_leftSide containsObject:three]) {
        [left appendString:@"3."];
    }
    if ([_leftSide containsObject:four]) {
        [left appendString:@"4."];
    }
    if ([_rightSide containsObject:a]) {
        [right appendString:@"A."];
    }
    if ([_rightSide containsObject:b]) {
        [right appendString:@"B."];
    }
    if ([_rightSide containsObject:c]) {
        [right appendString:@"C."];
    }
    if ([_rightSide containsObject:d]) {
        [right appendString:@"D."];
    }

    
    [one setTitle:@"" forState:UIControlStateNormal];
    [two setTitle:@"" forState:UIControlStateNormal];
    [three setTitle:@"" forState:UIControlStateNormal];
    [four setTitle:@"" forState:UIControlStateNormal];
    [a setTitle:@"" forState:UIControlStateNormal];
    [b setTitle:@"" forState:UIControlStateNormal];
    [c setTitle:@"" forState:UIControlStateNormal];
    [d setTitle:@"" forState:UIControlStateNormal];
    

    
    for (UIButton* bu in _rightSide) {
        [bu setTitle:@"" forState:UIControlStateNormal];
    }

    for (UIButton* bu in _leftSide) {
        [bu setTitle:right forState:UIControlStateNormal];
    }
    for (UIButton* bu in _rightSide) {
        [bu setTitle:left forState:UIControlStateNormal];
    }
}

- (void)swapLeft:(id)sender
{
    BOOL s = [_leftSide containsObject:sender];
    if (s) {
        [_leftSide removeObject:sender];
    } else {
        [_leftSide addObject:sender];
    }
    [self refresh];
}
- (void)swapRight:(id)sender
{
    BOOL s = [_rightSide containsObject:sender];
    if (s) {
        [_rightSide removeObject:sender];
    } else {
        [_rightSide addObject:sender];
    }
    [self refresh];
}


- (IBAction)doOne:(id)sender {
    [self swapLeft:sender];
}

- (IBAction)load:(id)sender {
    [_rightSide removeAllObjects];
    [_leftSide removeAllObjects];
    [self refresh];
    KCSCollection* collection = [KCSCollection collectionFromString:@"RightCollection" ofClass:[RightObj class]];
    KCSLinkedAppdataStore* store = [KCSLinkedAppdataStore storeWithCollection:collection options:nil];
    [store loadObjectWithID:@[@"A",@"B",@"C",@"D"] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        for (RightObj* o in objectsOrNil) {
            UIButton* rb = a;
            if ([o.objId isEqualToString:@"B"]) {
                rb = b;
            } else if ([o.objId isEqualToString:@"C"]) {
                rb = c;
            } else if ([o.objId isEqualToString:@"D"]) {
                rb = d;
            }
            [_rightSide addObject:rb];
            for (LeftObj* l in o.leftObjs) {
                UIButton* lb = one;
                if ([l.objId isEqualToString:@"2"]) {
                    lb = two;
                } else if ([l.objId isEqualToString:@"3"]) {
                    lb = three;
                } else if ([l.objId isEqualToString:@"4"]) {
                    lb = four;
                }
                [_leftSide addObject:lb];
            }
        }
        [self refresh];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        //TODO
    }];
}

- (IBAction)doTwo:(id)sender {
    [self swapLeft:sender];
}

- (IBAction)doThree:(id)sender {
    [self swapLeft:sender];
}

- (IBAction)doFour:(id)sender {
    [self swapLeft:sender];
}

- (IBAction)doA:(id)sender {
    [self swapRight:sender];
}

- (IBAction)doB:(id)sender {
    [self swapRight:sender];
}

- (IBAction)doD:(id)sender {
    [self swapRight:sender];
}

- (IBAction)doC:(id)sender {
    [self swapRight:sender];
}

- (IBAction)clear:(id)sender {
    [_rightSide removeAllObjects];
    [_leftSide removeAllObjects];
    [self refresh];
}
@end
