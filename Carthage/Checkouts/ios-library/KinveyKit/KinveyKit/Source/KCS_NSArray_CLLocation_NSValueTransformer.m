//
//  KCS_NSArray_CLLocation_NSValueTransformer.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-12-02.
//  Copyright © 2015 Kinvey. All rights reserved.
//

#import "KCS_NSArray_CLLocation_NSValueTransformer.h"
#import "CLLocation+Kinvey.h"

@implementation KCS_NSArray_CLLocation_NSValueTransformer

+(instancetype)sharedInstance
{
    static KCS_NSArray_CLLocation_NSValueTransformer* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

+(Class)transformedValueClass
{
    return [CLLocation class];
}

-(id)transformedValue:(id)value
{
    if ([value isKindOfClass:[NSArray class]]) {
        return [CLLocation locationFromKinveyValue:value];
    }
    return nil;
}

-(id)reverseTransformedValue:(id)value
{
    if ([value isKindOfClass:[CLLocation class]]) {
        CLLocation* location = value;
        return CLLocationCoordinate2DToKCS(location.coordinate);
    }
    return nil;
}

@end
