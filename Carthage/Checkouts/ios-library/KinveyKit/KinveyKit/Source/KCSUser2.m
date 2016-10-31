//
//  KCSUser2.m
//  KinveyKit
//
//  Created by Michael Katz on 12/10/13.
//  Copyright (c) 2013-2015 Kinvey. All rights reserved.
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

#import "KCSUser2.h"

#import "KCSHiddenMethods.h"
#import "KinveyCollection.h"
#import "KinveyUser.h"
#import "KinveyErrorCodes.h"
#import "KinveyCoreInternal.h"
#import "KinveyDataStoreInternal.h"
#import "KinveyUserService.h"

#define kDeviceTokensKey @"_devicetokens"

@interface KCSUser2()
@property (nonatomic, strong) NSMutableDictionary* userAttributes;
@property (nonatomic, strong) NSMutableDictionary* push;
@end

@implementation KCSUser2

- (instancetype) init
{
    self = [super init];
    if (self){
        _username = @"";
        _userId = @"";
        _userAttributes = [NSMutableDictionary dictionary];
    }
    return self;
}


+ (NSDictionary *)kinveyObjectBuilderOptions
{
    static NSDictionary *options = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = @{KCS_USE_DICTIONARY_KEY : @(YES),
                    KCS_DICTIONARY_NAME_KEY : @"userAttributes"};
    });
    
    return options;
}

- (NSDictionary *)hostToKinveyPropertyMapping
{
    static NSDictionary *mappedDict = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mappedDict = @{@"userId" : KCSEntityKeyId,
                       @"username" : KCSUserAttributeUsername,
                       @"email" : KCSUserAttributeEmail,
                       @"givenName" : KCSUserAttributeGivenname,
                       @"surname" : KCSUserAttributeSurname,
                       @"metadata" : KCSEntityKeyMetadata,
                       };
    });
    
    return mappedDict;
}

- (NSString *)authString
{
    if (!self.userId) {
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:@"Active user does not have an `id` set." userInfo:@{@"user":self}] raise];
    }
    NSString* token = [KCSKeychain2 kinveyTokenForUserId:self.userId];
    NSString *authString = @"";
    if (token) {
        authString = [@"Kinvey " stringByAppendingString: token];
        KCSLogInfo(KCS_LOG_CONTEXT_USER, @"Current user found, using sessionauth (%@) => XXXXXXXXX", self.username);
    } else {
        KCSLogError(KCS_LOG_CONTEXT_USER, @"No session auth for current user found (%@)", self.username);
    }
    return authString;
}

- (void)handleErrorResponse:(KCSNetworkResponse *)response
{
    NSError* error = nil;
    NSDictionary* jsonObj = [response jsonObjectError:&error];
    if (!error && jsonObj != nil && [jsonObj isKindOfClass:[NSDictionary class]]) {
        NSString* errorCode = jsonObj[@"error"];
        if (response.code == KCSDeniedError) {
            BOOL shouldLogout = NO;
            if ([errorCode isEqualToString:@"UserLockedDown"]) {
                shouldLogout = YES;
            } else if ([errorCode isEqualToString:@"InvalidCredentials"] && [[KCSClient sharedClient].configuration.options[KCS_KEEP_USER_LOGGED_IN_ON_BAD_CREDENTIALS] boolValue] == NO) {
                shouldLogout = YES;
            }
            if (shouldLogout) {
                [self logout];
            }
        }
    }
}

#pragma mark - KinveyKit1 compatability

- (NSMutableSet*) deviceTokens
{
    if (_push == nil) {
        self.push = [NSMutableDictionary dictionary];
    }
    if (_push[kDeviceTokensKey] == nil) {
        _push[kDeviceTokensKey] = [NSMutableSet set];
    } else if ([_push[kDeviceTokensKey] isKindOfClass:[NSArray class]]) {
        _push[kDeviceTokensKey] = [NSMutableSet setWithArray:_push[kDeviceTokensKey]];
    } else if ([_push[kDeviceTokensKey] isKindOfClass:[NSDictionary class]] &&
               ![_push[kDeviceTokensKey] isKindOfClass:[NSMutableDictionary class]])
    {
        _push[kDeviceTokensKey] = ((NSDictionary*) _push[kDeviceTokensKey]).mutableCopy;
    }
    return _push[kDeviceTokensKey];
}


- (void) refreshFromServer:(KCSCompletionBlock)completionBlock
{
    [KCSUser2 refreshUser:(id)self options:nil completion:^(id<KCSUser2> user, NSError *error) {
        completionBlock(user?@[user]:nil, error);
    }];
}

- (void) saveWithCompletionBlock:(KCSCompletionBlock)completionBlock
{
    [KCSUser2 saveUser:(id)self options:nil completion:^(id<KCSUser2> user, NSError *error) {
        completionBlock(user?@[user]:nil, error);
    }];
}

- (void) removeWithCompletionBlock:(KCSCompletionBlock)completionBlock
{
    [KCSUser2 deleteUser:(id)self options:nil completion:^(unsigned long count, NSError *errorOrNil) {
        completionBlock(@[],errorOrNil);
    }];
}


- (void) logout
{
    [KCSUser2 logoutUser:self];
}

@end

#pragma clang diagnostic pop
