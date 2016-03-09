//
//  KNVClient.h
//  Kinvey
//
//  Created by Victor Barros on 2016-03-03.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KNVUser;

NS_SWIFT_UNAVAILABLE("Please use 'Client' class")
@interface KNVClient : NSObject

@property (nonatomic, readonly) NSString* _Nullable appKey;
@property (nonatomic, readonly) NSString* _Nullable appSecret;

@property (nonatomic, readonly) NSString* _Nullable authorizationHeader;

@property (nonatomic, readonly) NSURL* _Nonnull apiHostName;
@property (nonatomic, readonly) NSURL* _Nonnull authHostName;

@property (nonatomic, readonly) KNVUser* _Nullable activeUser;

@property (nonatomic, assign) NSURLRequestCachePolicy cachePolicy;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, strong) NSString* _Nullable clientAppVersion;
@property (nonatomic, strong) NSDictionary<NSString*, NSString*>* _Nonnull customRequestProperties;

+(instancetype _Nonnull)sharedClient;

-(instancetype _Nonnull)init;

-(instancetype _Nonnull)initWithAppKey:(NSString * _Nonnull)appKey
                             appSecret:(NSString * _Nonnull)appSecret
                           apiHostName:(NSURL * _Nonnull)apiHostName
                          authHostName:(NSURL * _Nonnull)authHostName;

-(instancetype _Nonnull)initWithAppKey:(NSString * _Nonnull)appKey
                             appSecret:(NSString * _Nonnull)appSecret;

-(instancetype _Nonnull)initializeWithAppKey:(NSString * _Nonnull)appKey
                                   appSecret:(NSString * _Nonnull)appSecret;

-(instancetype _Nonnull)initializeWithAppKey:(NSString * _Nonnull)appKey
                                   appSecret:(NSString * _Nonnull)appSecret
                                 apiHostName:(NSURL * _Nonnull)apiHostName
                                authHostName:(NSURL * _Nonnull)authHostName;

@end
