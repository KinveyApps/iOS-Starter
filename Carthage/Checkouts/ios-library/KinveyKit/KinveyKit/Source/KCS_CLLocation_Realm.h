//
//  KCS_CLLocation_Realm.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-12-01.
//  Copyright © 2015 Kinvey. All rights reserved.
//

@import Realm;
@import MapKit;

@interface KCS_CLLocation_Realm : RLMObject

@property CLLocationDegrees latitude;
@property CLLocationDegrees longitude;

+(instancetype)locationWithLatitude:(CLLocationDegrees)latitude
                          longitude:(CLLocationDegrees)longitude;

-(instancetype)initWithLatitude:(CLLocationDegrees)latitude
                      longitude:(CLLocationDegrees)longitude;

@end
