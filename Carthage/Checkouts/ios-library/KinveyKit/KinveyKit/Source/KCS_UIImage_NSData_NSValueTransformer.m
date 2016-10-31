//
//  KCS_UIImage_NSDate_Realm.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-11-30.
//  Copyright © 2015 Kinvey. All rights reserved.
//

#if TARGET_OS_IOS

#import "KCS_UIImage_NSData_NSValueTransformer.h"
@import UIKit;

@implementation KCS_UIImage_NSData_NSValueTransformer

+(instancetype)sharedInstance
{
    static KCS_UIImage_NSData_NSValueTransformer* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

+(Class)transformedValueClass
{
    return [NSData class];
}

-(id)transformedValue:(id)value
{
    if ([value isKindOfClass:[UIImage class]]) {
        return UIImagePNGRepresentation(value);
    }
    return nil;
}

-(id)reverseTransformedValue:(id)value
{
    if ([value isKindOfClass:[NSData class]]) {
        return [UIImage imageWithData:value];
    }
    return nil;
}

@end

#endif
