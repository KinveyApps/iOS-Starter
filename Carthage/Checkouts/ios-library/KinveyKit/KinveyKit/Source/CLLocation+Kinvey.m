//
//  CLLocation+Kinvey.m
//  KinveyKit
//
//  Created by Michael Katz on 8/20/12.
//  Copyright (c) 2012-2015 Kinvey. All rights reserved.
//
// This software is licensed to you under the Kinvey terms of service located at
// http://www.kinvey.com/terms-of-use. By downloading, accessing and/or using this
// software, you hereby accept such terms of service  (and any agreement referenced
// therein) and agree that you have read, understand and agree to be bound by such
// terms of service and are of legal age to agree to such terms with Kinvey.
//
// This software contains valuable confidential and proprietary information of
// KINVEY, INC and is subject to applicable licensing agreements.
// Unauthorized reproduction, transmission or distribution of this file and its
// contents is a violation of applicable laws.
//


#import "CLLocation+Kinvey.h"

NSArray* CLLocationCoordinate2DToKCS(CLLocationCoordinate2D coordinate)
{
    return @[@(coordinate.longitude), @(coordinate.latitude)];
}

@implementation CLLocation (Kinvey)

- (id) proxyForJson
{
    return [self kinveyValue];
}

- (NSArray *)kinveyValue
{
    return CLLocationCoordinate2DToKCS(self.coordinate);
}

+ (CLLocation*) locationFromKinveyValue:(NSArray*)kinveyValue
{
    return [[CLLocation alloc] initWithLatitude:[kinveyValue[1] doubleValue] longitude:[kinveyValue[0] doubleValue]];
}
@end
