//
//  Kinvey.h
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

@import Foundation;

//! Project version number for Kinvey.
FOUNDATION_EXPORT double KinveyVersionNumber;

//! Project version string for Kinvey.
FOUNDATION_EXPORT const unsigned char KinveyVersionString[];

#import <Kinvey/KNVKinvey.h>
#import <Kinvey/KNVClient.h>
#import <Kinvey/KNVUser.h>
#import <Kinvey/KNVDataStore.h>
#import <Kinvey/KNVReadPolicy.h>
#import <Kinvey/KNVWritePolicy.h>
#import <Kinvey/KNVError.h>

// KinveyKit
#import <Kinvey/KCSURLProtocol.h>
#import <Kinvey/KCSReachability.h>
#import <Kinvey/KCSKeychain.h>
#import <Kinvey/KCSMICLoginViewController.h>
#import <Kinvey/KCSClient.h>
#import <Kinvey/KinveyUser.h>

// NSPredicate-MongoDB-Adaptor => https://github.com/tjboneman/NSPredicate-MongoDB-Adaptor
#import <Kinvey/MongoDBPredicateAdaptor.h>
