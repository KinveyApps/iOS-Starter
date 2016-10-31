//
//  KCSClient+KinveyDataStore.m
//  KinveyKit
//
//  Created by Michael Katz on 11/14/13.
//  Copyright (c) 2015 Kinvey. All rights reserved.
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


#import "KCSClient+KinveyDataStore.h"

KK2(removes)
#import "KCSHiddenMethods.h"
#import "KinveyCoreInternal.h"

KCS_CONST_IMPL KCS_ERROR_UNSAVED_OBJECT_IDS_KEY = @"KCSStore.OfflineSave.UnsavedObjectIds";

@implementation KCSClient (KinveyDataStore)

- (void)setOfflineDelegate:(id<KCSOfflineUpdateDelegate>)delegate
{
    [[KCSAppdataStore caches] setOfflineUpdateDelegate:delegate];
}

@end
