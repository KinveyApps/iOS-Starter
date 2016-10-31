//
//  KCSRequestConfiguration.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-03-20.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import "KCSRequestConfiguration.h"

@implementation KCSRequestConfiguration

+(instancetype)requestConfigurationWithClientAppVersion:(NSString *)clientAppVersion
                             andCustomRequestProperties:(NSDictionary *)customRequestProperties
{
    return [[self alloc] initWithClientAppVersion:clientAppVersion
                       andCustomRequestProperties:customRequestProperties];
}

-(id)initWithClientAppVersion:(NSString *)clientAppVersion
   andCustomRequestProperties:(NSDictionary *)customRequestProperties
{
    self = [super init];
    if (self) {
        self.clientAppVersion = clientAppVersion;
        self.customRequestProperties = customRequestProperties;
    }
    return self;
}

@end
