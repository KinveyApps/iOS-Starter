//
//  KNVUser.h
//  Kinvey
//
//  Created by Victor Barros on 2016-03-04.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KNVClient.h"

@protocol KNVRequest;

NS_SWIFT_UNAVAILABLE("Please use 'User' class")
@interface KNVUser : NSObject

typedef void(^KNVUserExistsHandler)(BOOL, NSError* _Nullable);
typedef void(^KNVUserUserHandler)(KNVUser* _Nullable, NSError* _Nullable);
typedef void(^KNVUserVoidHandler)(NSError* _Nullable);

+(id<KNVRequest> _Nonnull)existsWithUsername:(NSString* _Nonnull)username
                           completionHandler:(KNVUserExistsHandler _Nullable)completionHandler;

+(id<KNVRequest> _Nonnull)existsWithUsername:(NSString* _Nonnull)username
                                      client:(KNVClient* _Nonnull)client
                           completionHandler:(KNVUserExistsHandler _Nullable)completionHandler;

+(id<KNVRequest> _Nonnull)loginWithUsername:(NSString* _Nonnull)username
                                   password:(NSString* _Nonnull)password
                          completionHandler:(KNVUserUserHandler _Nullable)completionHandler;

+(id<KNVRequest> _Nonnull)loginWithUsername:(NSString* _Nonnull)username
                                   password:(NSString* _Nonnull)password
                                     client:(KNVClient* _Nonnull)client
                          completionHandler:(KNVUserUserHandler _Nullable)completionHandler;

+(id<KNVRequest> _Nonnull)signup:(KNVUserUserHandler _Nullable)completionHandler;

+(id<KNVRequest> _Nonnull)signupWithUsername:(NSString * _Nullable)username
                                    password:(NSString * _Nullable)password
                           completionHandler:(KNVUserUserHandler _Nullable)completionHandler;

+(id<KNVRequest> _Nonnull)signupWithClient:(KNVClient* _Nonnull)client
                         completionHandler:(KNVUserUserHandler _Nullable)completionHandler;

+(id<KNVRequest> _Nonnull)signupWithUsername:(NSString * _Nullable)username
                                    password:(NSString * _Nullable)password
                                      client:(KNVClient* _Nonnull)client
                           completionHandler:(KNVUserUserHandler _Nullable)completionHandler;

+(id<KNVRequest> _Nonnull)destroyWithUserId:(NSString * _Nonnull)userId
                          completionHandler:(KNVUserVoidHandler _Nullable)completionHandler;

+(id<KNVRequest> _Nonnull)destroyWithUserId:(NSString * _Nonnull)userId
                                     client:(KNVClient * _Nonnull)client
                          completionHandler:(KNVUserVoidHandler _Nullable)completionHandler;

+(id<KNVRequest> _Nonnull)destroyWithUserId:(NSString * _Nonnull)userId
                                       hard:(BOOL)hard
                          completionHandler:(KNVUserVoidHandler _Nullable)completionHandler;

+(id<KNVRequest> _Nonnull)destroyWithUserId:(NSString * _Nonnull)userId
                                       hard:(BOOL)hard
                                     client:(KNVClient * _Nonnull)client
                          completionHandler:(KNVUserVoidHandler _Nullable)completionHandler;

-(id<KNVRequest> _Nonnull)destroy:(KNVUserVoidHandler _Nullable)completionHandler;

-(id<KNVRequest> _Nonnull)destroyWithHard:(BOOL)hard
                        completionHandler:(KNVUserVoidHandler _Nullable)completionHandler;

-(id<KNVRequest> _Nonnull)destroyWithHard:(BOOL)hard
                                   client:(KNVClient* _Nonnull)client
                        completionHandler:(KNVUserVoidHandler _Nullable)completionHandler;

+(id<KNVRequest> _Nonnull)getWithUserId:(NSString* _Nonnull)userId
                      completionHandler:(KNVUserUserHandler _Nullable)completionHandler;

+(id<KNVRequest> _Nonnull)getWithUserId:(NSString* _Nonnull)userId
                                 client:(KNVClient* _Nonnull)client
                      completionHandler:(KNVUserUserHandler _Nullable)completionHandler;

-(void)logout;

-(id<KNVRequest> _Nonnull)save:(KNVUserUserHandler _Nullable)completionHandler;

-(id<KNVRequest> _Nonnull)saveWithClient:(KNVClient* _Nonnull)client
                       completionHandler:(KNVUserUserHandler _Nullable)completionHandler;

+(void)presentMICViewControllerWithRedirectURI:(NSURL* _Nonnull)redirectURI
                             completionHandler:(KNVUserUserHandler _Nullable)completionHandler;

+(void)presentMICViewControllerWithRedirectURI:(NSURL* _Nonnull)redirectURI
                                       timeout:(NSTimeInterval)timeout
                             completionHandler:(KNVUserUserHandler _Nullable)completionHandler;

+(void)presentMICViewControllerWithRedirectURI:(NSURL* _Nonnull)redirectURI
                                        client:(KNVClient* _Nonnull)client
                             completionHandler:(KNVUserUserHandler _Nullable)completionHandler;

+(void)presentMICViewControllerWithRedirectURI:(NSURL* _Nonnull)redirectURI
                                       timeout:(NSTimeInterval)timeout
                                        client:(KNVClient* _Nonnull)client
                             completionHandler:(KNVUserUserHandler _Nullable)completionHandler;

@end
