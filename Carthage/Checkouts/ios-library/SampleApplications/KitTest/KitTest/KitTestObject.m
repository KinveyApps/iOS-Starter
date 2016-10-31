//
//  KitTestObject.m
//  KitTest
//
//  Created by Brian Wilson on 11/14/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KitTestObject.h"


@implementation KitTestObject 

@synthesize objectId=_id;
@synthesize name=_name;
@synthesize count=_count;

- (id)init
{
    self = [super init];
    if (self){
        self.name = nil;
        self.objectId = nil;
        self.count = 0;
    }
    
    return self;
}


- (NSDictionary *)hostToKinveyPropertyMapping
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            // JSON, Objective-C
            @"_id", @"objectId",
            @"name", @"name",
            @"count", @"count",
            nil];
}

@end
