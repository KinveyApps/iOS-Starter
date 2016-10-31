//
//  KitTestObject.h
//  KitTest
//
//  Created by Brian Wilson on 11/14/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <KinveyKit/KinveyKit.h>

@interface KitTestObject : NSObject <KCSPersistable>

@property (retain) NSString *objectId;
@property (retain) NSString *name;
@property (readwrite) int count;

@end
