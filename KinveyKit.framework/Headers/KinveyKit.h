//
//  KinveyKit.h
//  KinveyKit
//
//  Copyright (c) 2008-2015, Kinvey, Inc. All rights reserved.
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

#import <UIKit/UIKit.h>

//! Project version number for KinveyKit.
FOUNDATION_EXPORT double KinveyKitVersionNumber;

//! Project version string for KinveyKit.
FOUNDATION_EXPORT const unsigned char KinveyKitVersionString[];

#import <KinveyKit/KCSClient.h>
#import <KinveyKit/KCSClientConfiguration.h>
#import <KinveyKit/KinveyPing.h>
#import <KinveyKit/KinveyPersistable.h>
#import <KinveyKit/KCSEntityDict.h>
#import <KinveyKit/KCSPush.h>
#import <KinveyKit/KinveyUser.h>
#import <KinveyKit/KCSUser2+KinveyUserService.h>
#import <KinveyKit/KCSUserDiscovery.h>
#import <KinveyKit/KCSQuery.h>
#import <KinveyKit/KCSQuery2.h>
#import <KinveyKit/KCSRequest.h>
#import <KinveyKit/KCSStore.h>
#import <KinveyKit/KCSBackgroundAppdataStore.h>
#import <KinveyKit/KCSAppdataStore.h>
#import <KinveyKit/KCSLinkedAppdataStore.h>
#import <KinveyKit/KCSDataStore.h>
#import <KinveyKit/KCSCachedStore.h>
#import <KinveyKit/KCSFile.h>
#import <KinveyKit/KCSFileStore.h>
#import <KinveyKit/KCSBlockDefs.h>
#import <KinveyKit/KinveyBlocks.h>
#import <KinveyKit/CLLocation+Kinvey.h>
#import <KinveyKit/KCSClient+KinveyDataStore.h>
#import <KinveyKit/KCSRequestConfiguration.h>
#import <KinveyKit/KCSMetadata.h>
#import <KinveyKit/KCSGroup.h>
#import <KinveyKit/KCSReduceFunction.h>
#import <KinveyKit/KCSLogSink.h>
#import <KinveyKit/KCSOfflineUpdateDelegate.h>
#import <KinveyKit/KCSCustomEndpoints.h>
#import <KinveyKit/KCSFacebookHelper.h>
#import <KinveyKit/KCSUser+SocialExtras.h>
#import <KinveyKit/KCSReachability.h>
#import <KinveyKit/KCSURLProtocol.h>
#import <KinveyKit/KinveyErrorCodes.h>
#import <KinveyKit/NSString+KinveyAdditions.h>
#import <KinveyKit/NSURL+KinveyAdditions.h>
#import <KinveyKit/KinveyVersion.h>
#import <KinveyKit/KCSMICLoginViewController.h>
#import <KinveyKit/KCSRealmEntityPersistence.h>
#import <KinveyKit/KCSCache.h>
#import <KinveyKit/KCSSync.h>
#import <KinveyKit/KCSPendingOperation.h>
#import <KinveyKit/KCSKeychain.h>
#import <KinveyKit/KCSCacheManager.h>
