//
//  Kinvey.h
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

@import UIKit;

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

// KinveyKit
#import <Kinvey/KCSRealmEntityPersistence.h>
#import <Kinvey/KCSReachability.h>
#import <Kinvey/KCSPush.h>
#import <Kinvey/KCSKeychain.h>
#import <Kinvey/KCSMICLoginViewController.h>
#import <Kinvey/KCSQueryAdapter.h>
#import <Kinvey/KCSAppdataStore.h>
#import <Kinvey/KCSBackgroundAppdataStore.h>
#import <Kinvey/KCSCacheUpdatePolicy.h>
#import <Kinvey/KCSCachedStore.h>
#import <Kinvey/KCSClient+KinveyDataStore.h>
#import <Kinvey/KCSClient.h>
#import <Kinvey/KCSDataStore.h>
#import <Kinvey/KCSReduceFunction.h>
#import <Kinvey/KCSMetadata.h>
#import <Kinvey/KCSGroup.h>
#import <Kinvey/KinveyPing.h>
#import <Kinvey/NSString+KinveyAdditions.h>

// NSPredicate-MongoDB-Adaptor => https://github.com/tjboneman/NSPredicate-MongoDB-Adaptor
#import <Kinvey/MongoDBPredicateAdaptor.h>
