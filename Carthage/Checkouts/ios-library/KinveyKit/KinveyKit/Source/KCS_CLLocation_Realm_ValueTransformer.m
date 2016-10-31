//
//  KCS_CLLocation_Realm_ValueTransformer.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-12-01.
//  Copyright © 2015 Kinvey. All rights reserved.
//

#import "KCS_CLLocation_Realm_ValueTransformer.h"
#import "KCS_CLLocation_Realm.h"

@implementation KCS_CLLocation_Realm_ValueTransformer

+(instancetype)sharedInstance
{
    static KCS_CLLocation_Realm_ValueTransformer* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

+(Class)transformedValueClass
{
    return [KCS_CLLocation_Realm class];
}

-(id)transformedValue:(id)value
{
    if ([value isKindOfClass:[CLLocation class]]) {
        CLLocation* location = value;
        KCS_CLLocation_Realm* realm = [[KCS_CLLocation_Realm alloc] init];
        realm.latitude = location.coordinate.latitude;
        realm.longitude = location.coordinate.longitude;
        return realm;
    }
    return nil;
}

-(id)reverseTransformedValue:(id)value
{
    if ([value isKindOfClass:[KCS_CLLocation_Realm class]]) {
        KCS_CLLocation_Realm* realm = value;
        return [[CLLocation alloc] initWithLatitude:realm.latitude
                                          longitude:realm.longitude];
    }
    return nil;
}

@end
