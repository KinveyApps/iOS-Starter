//
//  KCSURLProtocol.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-03-20.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import "KCSURLProtocol.h"

@implementation KCSURLProtocol

static NSMutableArray* protocolClasses;

+(void)initialize
{
    [super initialize];
    
    protocolClasses = [NSMutableArray array];
}

+(BOOL)registerClass:(Class)protocolClass
{
    BOOL result = [super registerClass:protocolClass];
    
    if (result) {
        [protocolClasses addObject:protocolClass];
    }
    
    return result;
}

+(void)unregisterClass:(Class)protocolClass
{
    [protocolClasses removeObject:protocolClass];
    
    [super unregisterClass:protocolClass];
}

+(NSArray *)protocolClasses
{
    return protocolClasses.copy;
}

@end
