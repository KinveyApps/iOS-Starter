//
//  KCSFileUtils.h
//  KinveyKit
//
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

@import Foundation;

@interface KCSFileUtils : NSObject

#if TARGET_OS_IPHONE
+ (NSString*) fileProtectionKey;
#endif

+ (int) dbFlags;

+ (NSString*) localPathForDB:(NSString*)dbname;
+ (NSURL*) filesFolder;
+ (NSURL*) fileURLForName:(NSString*)name;
+ (NSError*) writeData:(NSData*)data toURL:(NSURL*)url;
+ (void) touchFile:(NSURL*)url;
+ (NSError*) moveFile:(NSURL*)source to:(NSURL*)destination;

+ (void) dataDidBecomeAvailable;
+ (void) dataDidBecomeUnavailable;

+ (BOOL) clearFiles;

@end
