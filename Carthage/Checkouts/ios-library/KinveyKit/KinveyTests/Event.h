//
//  Event.h
//  Kinvey
//
//  Created by Santosh on 01/10/15.
//  Copyright (c) 2015 GQuotient. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KinveyKit.h"

@interface Event : NSObject <KCSPersistable>

@property (nonatomic, copy) NSString* entityId; //Kinvey entity _id
@property (nonatomic, copy) NSString* name;
@property (nonatomic, copy) NSString* response;
@property (nonatomic, copy) NSString* age;
@property (nonatomic, copy) NSDate* date;
@property (nonatomic, copy) NSString* location;
@property (nonatomic, strong) NSMutableString* descriptionEvent;
@property (nonatomic, retain) KCSMetadata* metadata; //Kinvey metadata, optional

@end
