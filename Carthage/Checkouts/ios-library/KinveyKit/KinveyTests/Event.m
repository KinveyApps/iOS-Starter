//
//  Event.m
//  Kinvey
//
//  Created by Santosh on 01/10/15.
//  Copyright (c) 2015 GQuotient. All rights reserved.
//

#import "Event.h"

@implementation Event

@synthesize entityId,name,date,location,metadata,response,age;

- (NSDictionary *)hostToKinveyPropertyMapping
{
    return @{
             @"entityId" : KCSEntityKeyId, //the required _id field
             @"name" : @"name",
             @"date" : @"date",
             @"location" : @"location",
             @"age" : @"Age",
             @"response" : @"response",
             @"metadata" : KCSEntityKeyMetadata, //optional _metadata field
             @"descriptionEvent" : @"descriptionEvent"
             };
}

@end
