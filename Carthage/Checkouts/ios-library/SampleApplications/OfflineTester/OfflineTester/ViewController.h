//
//  ViewController.h
//  OfflineTester
//
//  Created by Michael Katz on 8/16/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <KinveyKit/KinveyKit.h>

@interface ViewController : UIViewController  <KCSOfflineSaveDelegate>
@property (retain, nonatomic) IBOutlet UILabel *nSavesLabel;
- (IBAction)addSave:(id)sender;

@end
