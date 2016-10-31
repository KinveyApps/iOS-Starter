//
//  KCS_NSArray_KCS_CLLocation_Realm_NSValueTransformer.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-12-02.
//  Copyright © 2015 Kinvey. All rights reserved.
//

#import "KCS_NSArray_KCS_CLLocation_Realm_NSValueTransformer.h"
#import "KCS_CLLocation_Realm.h"

@implementation KCS_NSArray_KCS_CLLocation_Realm_NSValueTransformer

+(instancetype)sharedInstance
{
    static KCS_NSArray_KCS_CLLocation_Realm_NSValueTransformer* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[KCS_NSArray_KCS_CLLocation_Realm_NSValueTransformer alloc] init];
    });
    return instance;
}

+(Class)transformedValueClass
{
    return [KCS_CLLocation_Realm class];
}

-(id)transformedValue:(id)value
{
    if ([value isKindOfClass:[NSArray class]]) {
        NSArray* location = value;
        return [KCS_CLLocation_Realm locationWithLatitude:[location[1] doubleValue]
                                                longitude:[location[0] doubleValue]];
    }
    return nil;
}

-(id)reverseTransformedValue:(id)value
{
    if ([value isKindOfClass:[KCS_CLLocation_Realm class]]) {
        KCS_CLLocation_Realm* location = value;
        return @[@(location.longitude), @(location.latitude)];
    }
    return nil;
}

@end
