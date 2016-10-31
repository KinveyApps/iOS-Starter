//
//  KCSPush.m
//  KinveyKit
//
//  Created by Brian Wilson on 11/28/11.
//  Copyright (c) 2011-2015 Kinvey. All rights reserved.
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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"

#import "KCSPush.h"
#import "KCSClient.h"
#import "KinveyUser.h"

#import "KCSLogManager.h"
#import "KinveyErrorCodes.h"
#import "NSError+KinveyKit.h"
#import "NSMutableDictionary+KinveyAdditions.h"

#import "KCSHttpRequest.h"

#define UAPushBadgeSettingsKey @"UAPushBadge"
#define KCSPushDeviceToken @"KCSPushDeviceToken"

#define KCSValueOrNSNull(value) value ? value : [NSNull null]

@interface KCSPush()
@property (nonatomic, retain, readwrite) NSData  *deviceToken;
@property (nonatomic) BOOL hasToken;
@property (nonatomic) BOOL pushEnabled;
@end

@implementation KCSPush

#pragma mark - Init
+ (KCSPush *)sharedPush
{
    static KCSPush *sKCSPush;
    // This can be called on any thread, so we synchronise.  We only do this in 
    // the sKCSClient case because, once sKCSClient goes non-nil, it can 
    // never go nil again.
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sKCSPush = [[KCSPush alloc] init];
        assert(sKCSPush != nil);
    });
    
    return sKCSPush;
}

- (BOOL) onLoadHelper:(NSDictionary *)options error:(NSError**)error
{
    [self doRegister];
    return YES;
}

+ (void) registerForPush
{
    [[KCSPush sharedPush] doRegister];
}

- (void) doRegister
{
    self.pushEnabled = YES;
#if TARGET_OS_IOS
    [self registerForRemoteNotifications];
#endif
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:UAPushBadgeSettingsKey];
    [self resetPushBadge];//zero badge
}

#pragma mark - Properties

- (BOOL) autobadgeEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:UAPushBadgeSettingsKey];
}

#pragma mark - unloading
- (void)onUnloadHelper
{
    //do nothing for now
}

#pragma mark - Events

#if TARGET_OS_IOS

- (void) registerForRemoteNotifications
{
    // Register for notifications
    KCSLogDebug(@"Testing for version: %@: %@", [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion]);

    if (self.pushEnabled) {
        KCSLogDebug(@"Checking for iOS 8 support");


        if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
            KCSLogDebug(@"In iOS 8");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wselector"
            UIUserNotificationSettings* notificationSettings = [UIUserNotificationSettings settingsForTypes: UIUserNotificationTypeAlert |
                                                                                                             UIUserNotificationTypeBadge |
                                                                                                             UIUserNotificationTypeSound categories:nil];
            [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
            [[UIApplication sharedApplication] registerForRemoteNotifications];
#pragma clang diagnostic pop
        } else {
            KCSLogDebug(@"Less than 8");
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes: (UIRemoteNotificationTypeBadge |
                                                                                    UIRemoteNotificationTypeSound |
                                                                                    UIRemoteNotificationTypeAlert)];
        }
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)notification
{
    KCSLogDebug(@"Received remote notification: %@", notification);
    
    UIApplicationState state = application.applicationState;
    
    if (state != UIApplicationStateActive) {
        KCSLogTrace(@"Received a push notification for an inactive application state.");
        return;
    }
    
    // Please refer to the following Apple documentation for full details on handling the userInfo payloads
	// http://developer.apple.com/library/ios/#documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/ApplePushService/ApplePushService.html#//apple_ref/doc/uid/TP40008194-CH100-SW1
	
	if ([[notification allKeys] containsObject:@"aps"]) {
        NSDictionary *apsDict = [notification objectForKey:@"aps"];
        
		if ([[apsDict allKeys] containsObject:@"alert"]) {
			//handle alert message?
		}
        
        //badge
        NSString *badgeNumber = [apsDict valueForKey:@"badge"];
        if (badgeNumber) {
			if([self autobadgeEnabled]) {
				[[UIApplication sharedApplication] setApplicationIconBadgeNumber:[badgeNumber intValue]];
			}
        }
		
        //sound
		NSString *soundName = [apsDict valueForKey:@"sound"];
		if (soundName) {
			//handle sound?
		}
        
	}//aps
    
	// Now remove all the UA and Apple payload items
	NSMutableDictionary *customPayload = [notification mutableCopy];
    [customPayload removeObjectForKey:@"aps"];
    [customPayload removeObjectForKey:@"_uamid"];
    [customPayload removeObjectForKey:@"_"];
	
	// If any top level items remain, those are custom payload, pass it to the handler
	// Note: There is some convenience built into this check, if for some reason there's a key collision
	//	and we're stripping yours above, it's safe to remove this conditional
	if([[customPayload allKeys] count] > 0) {
        //handle custom payload
    }
    
    [self resetPushBadge]; // zero badge after push received
}

#pragma mark - Device Tokens
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [self application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken completionBlock:nil];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken completionBlock:(void (^)(BOOL success, NSError* error))completionBlock
{
    self.hasToken = YES;
    
    // Capture the token for us to use later
    self.deviceToken = deviceToken;
    [self registerDeviceToken:completionBlock];
}

- (void) application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    self.hasToken = NO;
    
    KCSLogNSError(@"Failed to register for remote notifications", error);
    //TODO: simulator error: Error Domain=NSCocoaErrorDomain Code=3010 "remote notifications are not supported in the simulator" UserInfo=0xa6992d0 {NSLocalizedDescription=remote notifications are not supported in the simulator}
}

#endif

- (void) removeDeviceToken:(void (^)(BOOL success, NSError* error))completionBlock

{
    self.pushEnabled = NO;
    [self unRegisterDeviceToken:completionBlock];
    self.deviceToken = nil;
}

- (NSString *)deviceTokenString
{
    NSString *deviceToken = [[self.deviceToken description] stringByReplacingOccurrencesOfString: @"<" withString: @""];
    deviceToken = [deviceToken stringByReplacingOccurrencesOfString: @">" withString: @""] ;
    deviceToken = [deviceToken stringByReplacingOccurrencesOfString: @" " withString: @""];
    return deviceToken;
}

- (void) registerDeviceToken:(KCSSuccessBlock)completionBlock
{
    SWITCH_TO_MAIN_THREAD_SUCCESS_BLOCK(completionBlock);
    BOOL deviceTokenExists;
    NSString *deviceTokenString = nil;
    @synchronized (self) {
        deviceTokenExists = self.deviceToken != nil;
        if (deviceTokenExists) {
            deviceTokenString = [self deviceTokenString];
        }
    }
    if (deviceTokenExists && deviceTokenString && [KCSUser activeUser].userId) {
        KCSHttpRequest* request = [KCSHttpRequest requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {
            if (error || deviceTokenString == nil) {
                KCSLogError(@"Device token did not register");
                
                if (completionBlock) {
                    completionBlock(NO, error);
                }
            } else {
                KCSLogDebug(@"Device token registered");
                @synchronized (self) {
                    [[KCSUser activeUser].deviceTokens addObject:deviceTokenString];
                }
                
                if (completionBlock) {
                    completionBlock(YES, nil);
                }
            }
        }
                                                            route:KCSRESTRoutePush
                                                          options:@{KCSRequestLogMethod}
                                                      credentials:[KCSUser activeUser]];
        request.method = KCSRESTMethodPOST;
        request.path = @[@"register-device"];
        request.body = @{@"userId"   : KCSValueOrNSNull([KCSUser activeUser].userId),
                         @"deviceId" : KCSValueOrNSNull(deviceTokenString),
                         @"platform" : @"ios"};
        [request start];
    } else {
        if (completionBlock) {
            NSError* error = nil;
            if ([KCSUser activeUser].userId == nil) {
                error = [NSError createKCSErrorWithReason:@"No active user at this moment. Please create an user or login with an existing one."];
#if !(TARGET_IPHONE_SIMULATOR)
            } else if (self.pushEnabled && deviceTokenString == nil) {
                error = [NSError createKCSErrorWithReason:@"Device token is empty."];
#endif
            }
            completionBlock(NO, error);
        }
    }
}

- (void) unRegisterDeviceToken:(KCSSuccessBlock)completionBlock
{
    SWITCH_TO_MAIN_THREAD_SUCCESS_BLOCK(completionBlock);
    if (self.deviceToken != nil && [KCSUser activeUser] != nil && [KCSUser activeUser].deviceTokens != nil && [[KCSUser activeUser].deviceTokens containsObject:[self deviceTokenString]] == YES) {
        
        KCSHttpRequest* request = [KCSHttpRequest requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {
            if (error) {
                KCSLogError(@"Device token did not un-register");
            } else {
                KCSLogDebug(@"Device token un-registered");
                @synchronized (self) {
                    NSString* deviceTokenString = [self deviceTokenString];
                    if (deviceTokenString) {
                        [[KCSUser activeUser].deviceTokens removeObject:deviceTokenString];
                    }
                    self.deviceToken = nil;
                }
            }
            if (completionBlock) {
                completionBlock(error == nil, error);
            }
        }
                                                            route:KCSRESTRoutePush
                                                          options:@{KCSRequestLogMethod}
                                                      credentials:[KCSUser activeUser]];
        request.method = KCSRESTMethodPOST;
        request.path = @[@"unregister-device"];
        request.body = @{@"userId"   : [KCSUser activeUser].userId,
                         @"deviceId" : [self deviceTokenString],
                         @"platform" : @"ios"};
        //TODO:        request.errorDomain = KCSUserErrorDomain;
        [request start];
    } else {
        @synchronized (self) {
            self.deviceToken = nil;
        }
        if (completionBlock) completionBlock(NO, nil);
    }
}

#pragma mark - Badges

- (void)setPushBadgeNumber: (int)number
{
#if TARGET_OS_IOS
    if ([[UIApplication sharedApplication] applicationIconBadgeNumber] == number) {
        return;
    }
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:number];
#endif
}

- (void)resetPushBadge
{
    [self setPushBadgeNumber:0];
}

-(NSData*)deviceToken
{
    return [[NSUserDefaults standardUserDefaults] dataForKey:KCSPushDeviceToken];
}

-(void)setDeviceToken:(NSData*)deviceToken
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    if (deviceToken) {
        [userDefaults setObject:deviceToken
                         forKey:KCSPushDeviceToken];
    } else {
        [userDefaults removeObjectForKey:KCSPushDeviceToken];
    }
    [userDefaults synchronize];
}

/* TODO
 - (void)applicationDidBecomeActive {
 UALOG(@"Checking registration status after foreground notification");
 if (hasEnteredBackground) {
 registrationRetryDelay = 0;
 [self updateRegistration];
 }
 else {
 UALOG(@"Checking registration on app foreground disabled on app initialization");
 }
 }
 
 - (void)applicationDidEnterBackground {
 hasEnteredBackground = YES;
 [[NSNotificationCenter defaultCenter] removeObserver:self
 name:UIApplicationDidEnterBackgroundNotification
 object:[UIApplication sharedApplication]];
 }
 */

@end

#pragma clang diagnostic pop
