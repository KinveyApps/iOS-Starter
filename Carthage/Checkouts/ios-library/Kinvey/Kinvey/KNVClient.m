//
//  KNVClient.m
//  Kinvey
//
//  Created by Victor Barros on 2016-03-03.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import "KNVClient+Internal.h"
#import "KNVUser+Internal.h"

@implementation KNVClient

+(instancetype)sharedClient
{
    static KNVClient* client;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        client = [[KNVClient alloc] initWithClient:[__KNVClient sharedClient]];
    });
    return client;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        self.client = [[__KNVClient alloc] init];
    }
    return self;
}

-(instancetype)initWithAppKey:(NSString *)appKey
                    appSecret:(NSString *)appSecret
{
    return [self initWithAppKey:appKey
                      appSecret:appSecret
                    apiHostName:[__KNVClient defaultApiHostName]
                   authHostName:[__KNVClient defaultAuthHostName]];
}

-(instancetype)initWithAppKey:(NSString *)appKey
                    appSecret:(NSString *)appSecret
                  apiHostName:(NSURL *)apiHostName
                 authHostName:(NSURL *)authHostName
{
    __KNVClient* client = [[__KNVClient alloc] initWithAppKey:appKey
                                                    appSecret:appSecret
                                                  apiHostName:apiHostName
                                                 authHostName:authHostName];
    return [self initWithClient:client];
}

-(instancetype)initWithClient:(__KNVClient *)client
{
    self = [super init];
    if (self) {
        self.client = client;
    }
    return self;
}

-(instancetype)initializeWithAppKey:(NSString *)appKey
                          appSecret:(NSString *)appSecret
{
    return [self initializeWithAppKey:appKey
                            appSecret:appSecret
                          apiHostName:[__KNVClient defaultApiHostName]
                         authHostName:[__KNVClient defaultAuthHostName]];
}

-(instancetype)initializeWithAppKey:(NSString *)appKey
                          appSecret:(NSString *)appSecret
                        apiHostName:(NSURL *)apiHostName
                       authHostName:(NSURL *)authHostName
{
    return [self initializeWithAppKey:appKey
                            appSecret:appSecret
                          apiHostName:apiHostName
                         authHostName:authHostName
                        schemaVersion:0
                     migrationHandler:nil];
}

-(instancetype)initializeWithAppKey:(NSString *)appKey
                          appSecret:(NSString *)appSecret
                        apiHostName:(NSURL *)apiHostName
                       authHostName:(NSURL *)authHostName
                      schemaVersion:(unsigned long long)schemaVersion
                   migrationHandler:(KNVMigrationBlock)migrationHandler
{
    [self.client initializeWithAppKey:appKey
                            appSecret:appSecret
                          apiHostName:apiHostName
                         authHostName:authHostName
                        encryptionKey:nil
                        schemaVersion:schemaVersion
                     migrationHandler:migrationHandler];
    return self;
}

-(NSString *)appKey
{
    return self.client.appKey;
}

-(NSString *)appSecret
{
    return self.client.appSecret;
}

-(NSURL *)apiHostName
{
    return self.client.apiHostName;
}

-(NSURL *)authHostName
{
    return self.client.authHostName;
}

-(NSString *)authorizationHeader
{
    return self.client.authorizationHeader;
}

-(KNVUser *)activeUser
{
    __KNVUser* activeUser = self.client.activeUser;
    if (activeUser) {
        return [[KNVUser alloc] initWithUser:activeUser];
    }
    return nil;
}

-(NSURLRequestCachePolicy)cachePolicy
{
    return self.client.cachePolicy;
}

-(void)setCachePolicy:(NSURLRequestCachePolicy)cachePolicy
{
    self.client.cachePolicy = cachePolicy;
}

-(NSTimeInterval)timeoutInterval
{
    return self.client.timeoutInterval;
}

-(void)setTimeoutInterval:(NSTimeInterval)timeoutInterval
{
    self.client.timeoutInterval = timeoutInterval;
}

-(NSString *)clientAppVersion
{
    return self.client.clientAppVersion;
}

-(void)setClientAppVersion:(NSString *)clientAppVersion
{
    self.client.clientAppVersion = clientAppVersion;
}

-(NSDictionary<NSString *,NSString *> *)customRequestProperties
{
    return self.client.customRequestProperties;
}

-(void)setCustomRequestProperties:(NSDictionary<NSString *,NSString *> *)customRequestProperties
{
    self.client.customRequestProperties = customRequestProperties;
}

@end
