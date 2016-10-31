//
//  KCS_CLLocation_Realm.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-12-01.
//  Copyright © 2015 Kinvey. All rights reserved.
//

#import "KCS_CLLocation_Realm.h"

@implementation KCS_CLLocation_Realm

+(instancetype)locationWithLatitude:(CLLocationDegrees)latitude
                          longitude:(CLLocationDegrees)longitude
{
    return [[self alloc] initWithLatitude:latitude
                                longitude:longitude];
}

-(instancetype)initWithLatitude:(CLLocationDegrees)latitude
                      longitude:(CLLocationDegrees)longitude
{
    self = [self init];
    if (self) {
        self.latitude = latitude;
        self.longitude = longitude;
    }
    return self;
}

@end
