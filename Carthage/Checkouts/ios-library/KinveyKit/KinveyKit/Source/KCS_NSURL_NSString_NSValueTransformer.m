//
//  KCS_NSURL_NSString_NSValueTransformer.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-12-02.
//  Copyright © 2015 Kinvey. All rights reserved.
//

#import "KCS_NSURL_NSString_NSValueTransformer.h"

@implementation KCS_NSURL_NSString_NSValueTransformer

+(instancetype)sharedInstance
{
    static KCS_NSURL_NSString_NSValueTransformer* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

+(Class)transformedValueClass
{
    return [NSString class];
}

-(id)transformedValue:(id)value
{
    if ([value isKindOfClass:[NSURL class]]) {
        return ((NSURL*) value).absoluteString;
    }
    return nil;
}

-(id)reverseTransformedValue:(id)value
{
    if ([value isKindOfClass:[NSString class]]) {
        return [NSURL URLWithString:value];
    }
    return nil;
}

@end
