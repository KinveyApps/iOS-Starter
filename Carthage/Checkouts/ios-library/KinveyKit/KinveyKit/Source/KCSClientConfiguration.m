//
//  KCSClientConfiguration.m
//  KinveyKit
//
//  Created by Michael Katz on 8/16/13.
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


#import "KCSClientConfiguration.h"
#import "KCSClientConfiguration+KCSInternal.h"

KK2(remove import)
#import "KCSClient.h"
#import "KinveyUser.h"
#import "KinveyErrorCodes.h"
#import "KinveyCoreInternal.h"

#pragma mark - Constants

KCS_CONST_IMPL KCS_APP_KEY                = @"KCS_APP_KEY";
KCS_CONST_IMPL KCS_APP_SECRET             = @"KCS_APP_SECRET";
KCS_CONST_IMPL KCS_CONNECTION_TIMEOUT     = @"KCS_CONNECTION_TIMEOUT";
KCS_CONST_IMPL KCS_SERVICE_HOST           = @"KCS_SERVICE_HOST";
KCS_CONST_IMPL KCS_URL_CACHE_POLICY       = @"KCS_URL_CACHE_POLICY";
KCS_CONST_IMPL KCS_DATE_FORMAT            = @"KCS_DATE_FORMAT";
KCS_CONST_IMPL KCS_LOG_SINK               = @"KCS_LOG_SINK";
KCS_CONST_IMPL KCS_LOG_LEVEL              = @"KCS_LOG_LEVEL";
KCS_CONST_IMPL KCS_LOG_ADDITIONAL_LOGGERS = @"KCS_LOG_ADDITIONAL_LOGGERS";
KCS_CONST_IMPL KCS_CONFIG_RETRY_DISABLED  = @"KCS_CONFIG_RETRY_DISABLED";
KCS_CONST_IMPL KCS_DATA_PROTECTION_LEVEL  = @"KCS_DATA_PROTECTION_LEVEL";
KCS_CONST_IMPL KCS_USER_CLASS             = @"KCS_USER_CLASS";
KCS_CONST_IMPL KCS_KEEP_USER_LOGGED_IN_ON_BAD_CREDENTIALS = @"KCS_KEEP_USER_LOGGED_IN_ON_BAD_CREDENTIALS";
KCS_CONST_IMPL KCS_ALWAYS_USE_NSURLREQUEST = @"KCS_ALWAYS_USE_NSURLREQUEST";

#define KCS_HOST_PORT     @"KCS_HOST_PORT"
#define KCS_HOST_PROTOCOL @"KCS_HOST_PROTOCOL"
#define KCS_HOST_DOMAIN   @"KCS_HOST_DOMAIN"
#define KCS_HOSTNAME      @"KCS_HOSTNAME"
#define KCS_AUTH_HOSTNAME @"KCS_AUTH_HOSTNAME"

#define KCS_DEFAULT_AUTH_HOSTNAME     @"auth"
#define KCS_DEFAULT_HOSTNAME          @"baas"
#define KCS_DEFAULT_HOST_PORT         @""
#define KCS_DEFAULT_HOST_PROTOCOL     @"https"
#define KCS_DEFAULT_HOST_DOMAIN       @"kinvey.com"

// Default timeout to 10 seconds
#define KCS_DEFAULT_CONNETION_TIMEOUT_RAW 10
#define KCS_DEFAULT_CONNETION_TIMEOUT @KCS_DEFAULT_CONNETION_TIMEOUT_RAW

#define KCS_DEFAULT_URL_CACHE_POLICY  @(NSURLRequestReloadIgnoringLocalAndRemoteCacheData)
#define KCS_DEFAULT_DATE_FORMAT       @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"

@implementation KCSClientConfiguration

- (instancetype) init
{
    self = [super init];
    if (self) {
        _appKey = nil;
        _appSecret = nil;
        _options = @{KCS_CONNECTION_TIMEOUT    : KCS_DEFAULT_CONNETION_TIMEOUT,
                     KCS_URL_CACHE_POLICY      : KCS_DEFAULT_URL_CACHE_POLICY,
                     KCS_HOST_PORT             : KCS_DEFAULT_HOST_PORT,
                     KCS_HOST_PROTOCOL         : KCS_DEFAULT_HOST_PROTOCOL,
                     KCS_HOSTNAME              : KCS_DEFAULT_HOSTNAME,
                     KCS_AUTH_HOSTNAME         : KCS_DEFAULT_AUTH_HOSTNAME,
                     KCS_HOST_DOMAIN           : KCS_DEFAULT_HOST_DOMAIN,
                     KCS_DATE_FORMAT           : KCS_DEFAULT_DATE_FORMAT,
                     KCS_LOG_LEVEL             : @(0),
                     KCS_DATA_PROTECTION_LEVEL : @(KCSDataCompleteUntilFirstLogin),
                     KCS_USER_CLASS            : [KCSUser class]
                     };
        
        
        KCSLogFormatter* formatter = [[KCSLogFormatter alloc] init];
        
        id<KCS_DDLogger> logger = [KCS_DDASLLogger sharedInstance];
        [logger setLogFormatter:formatter];
        [KCS_DDLog addLogger:logger];
        
        logger = [KCS_DDTTYLogger sharedInstance];
        [logger setLogFormatter:formatter];
        [KCS_DDLog addLogger:logger];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    KCSClientConfiguration* c = [[KCSClientConfiguration allocWithZone:zone] init];
    c.appKey = self.appKey;
    c.appSecret = self.appSecret;
    c.options = self.options;
    c.serviceHostname = self.serviceHostname;
    c.authHostname = self.authHostname;
    c.requestConfiguration = self.requestConfiguration.copy;
    
    return c;
}

+ (instancetype)configurationWithAppKey:(NSString *)appKey secret:(NSString *)appSecret
{
    return [self configurationWithAppKey:appKey
                                  secret:appSecret
                                 options:@{}];
}

+ (instancetype)configurationWithAppKey:(NSString *)appKey
                                 secret:(NSString *)appSecret
                                options:(NSDictionary *)optionsDictionary
{
    return [self configurationWithAppKey:appKey
                                  secret:appSecret
                                 options:optionsDictionary
                    requestConfiguration:nil];
}

+ (instancetype)configurationWithAppKey:(NSString *)appKey
                                 secret:(NSString *)appSecret
                                options:(NSDictionary *)optionsDictionary
                   requestConfiguration:(KCSRequestConfiguration *)requestConfiguration
{
    KCSClientConfiguration* config = nil;
    
    if ([appKey hasPrefix:@"<"] || [appSecret hasPrefix:@"<"]) {
        config = [KCSClientConfiguration configurationFromEnvironment];
    }

    if (!config) {
        config = [[KCSClientConfiguration alloc] init];
        config.appKey = appKey;
        config.appSecret = appSecret;
    }
    
    NSMutableDictionary* newOptions = [config.options mutableCopy];
    [newOptions addEntriesFromDictionary:optionsDictionary];
    config.options = newOptions;
    
    config.requestConfiguration = requestConfiguration;
    
    NSArray* loggers = config.options[KCS_LOG_ADDITIONAL_LOGGERS];
    for (id logger in loggers) {
        [KCS_DDLog addLogger:logger];
    }
    
    return config;
}

+ (instancetype)configurationFromPlist:(NSString*)plist
{
#if BUILD_FOR_UNIT_TEST
    NSString* path = [[[NSBundle bundleForClass:[self class]] URLForResource:plist withExtension:@"plist"] path];
#else
    NSString* path = [[NSBundle mainBundle] pathForResource:plist ofType:@"plist"];
#endif
    NSDictionary *opt = [NSDictionary dictionaryWithContentsOfFile:path];
    
    if (plist == nil){
        opt = [[NSBundle mainBundle] infoDictionary];
    }
    
    if (opt == nil) {
        [[NSException exceptionWithName:@"KinveyInitializationError" reason:[NSString stringWithFormat:@"Unable to read configuration plist: '%@'.", plist] userInfo:nil] raise];
    }
    
    NSString* appKey = [opt valueForKey:KCS_APP_KEY];
    NSString* appSecret = [opt valueForKey:KCS_APP_SECRET];
    
    return [self configurationWithAppKey:appKey
                                  secret:appSecret
                                 options:opt];
}


+ (instancetype) configurationFromEnvironment
{
    KCSClientConfiguration* configuration = nil;
    NSString* appKey = [[[NSProcessInfo processInfo] environment] objectForKey:KCS_APP_KEY];
    if (appKey) {
        NSString* appSecret = [[[NSProcessInfo processInfo] environment] objectForKey:KCS_APP_SECRET];
        if (appSecret) {
            configuration = [[KCSClientConfiguration alloc] init];
            configuration.appKey = appKey;
            configuration.appSecret = appSecret;
            
            NSString* serviceHostname = [[[NSProcessInfo processInfo] environment] objectForKey:KCS_SERVICE_HOST];
            configuration.serviceHostname = serviceHostname;
            return configuration;
        }
    }
    
    return configuration;
}

-(id)valueForOption:(id)key
       defaultValue:(id)defaultValue
{
    id value = self.options[key];
    if (value == nil) {
        value = defaultValue;
    }
    return value;
}

-(void)setValue:(id)value
      forOption:(id)key
{
    NSMutableDictionary* options = [NSMutableDictionary dictionaryWithDictionary:self.options];
    if (value) {
        options[key] = value;
    } else {
        [options removeObjectForKey:key];
    }
    self.options = options;
}

-(void)setValue:(id)value
      forOption:(id)key
   defaultValue:(id)defaultValue
{
    if (value == nil) {
        value = defaultValue;
    }
    [self setValue:[value copy]
         forOption:key];
    if ([KCSClient sharedClient].configuration == self) {
        [[KCSClient sharedClient] setConfiguration:self];
    }
}

-(NSString *)hostProtocol
{
    return [self valueForOption:KCS_HOST_PROTOCOL
                   defaultValue:KCS_DEFAULT_HOST_PROTOCOL];
}

-(void)setHostProtocol:(NSString *)hostProtocol
{
    if (hostProtocol == nil || ([hostProtocol compare:@"https" options:NSCaseInsensitiveSearch] != NSOrderedSame && [hostProtocol compare:@"http" options:NSCaseInsensitiveSearch] != NSOrderedSame)) {
        @throw [NSException exceptionWithName:KCSErrorDomain
                                       reason:[NSString stringWithFormat:@"'%@' is not a valid protocol. Please use https (highly recommended) or http.", hostProtocol]
                                     userInfo:nil];
    }
    [self setValue:hostProtocol
         forOption:KCS_HOST_PROTOCOL
      defaultValue:KCS_DEFAULT_HOST_PROTOCOL];
}

-(NSString *)serviceHostname
{
    return [self valueForOption:KCS_HOSTNAME
                   defaultValue:KCS_DEFAULT_HOSTNAME];
}

- (void)setServiceHostname:(NSString *)serviceHostname
{
    [self setValue:serviceHostname
         forOption:KCS_HOSTNAME
      defaultValue:KCS_DEFAULT_HOSTNAME];
}

-(NSString *)authHostname
{
    return [self valueForOption:KCS_AUTH_HOSTNAME
                   defaultValue:KCS_DEFAULT_AUTH_HOSTNAME];
}

-(void)setAuthHostname:(NSString *)authHostname
{
    [self setValue:authHostname
         forOption:KCS_AUTH_HOSTNAME
      defaultValue:KCS_DEFAULT_AUTH_HOSTNAME];
}

-(NSString *)hostDomain
{
    return [self valueForOption:KCS_HOST_DOMAIN
                   defaultValue:KCS_DEFAULT_HOST_DOMAIN];
}

-(void)setHostDomain:(NSString *)hostDomain
{
    [self setValue:hostDomain
         forOption:KCS_HOST_DOMAIN
      defaultValue:KCS_DEFAULT_HOST_DOMAIN];
}

-(NSString *)hostPort
{
    return [self valueForOption:KCS_HOST_PORT
                   defaultValue:KCS_DEFAULT_HOST_PORT];
}

-(void)setHostPort:(NSString *)hostPort
{
    [self setValue:hostPort
         forOption:KCS_HOST_PORT
      defaultValue:KCS_DEFAULT_HOST_PORT];
}

-(NSString *)baseAuthURL
{
    return [self baseURLWithHostname:self.authHostname];
}

-(NSString*)baseURL
{
    return [self baseURLWithHostname:self.serviceHostname];
}

-(NSString*)baseURLWithHostname:(NSString*)hostname
{
    NSString* protocol = self.hostProtocol;
    
    if (hostname.length > 0 && ![hostname hasSuffix:@"."]) {
        hostname = [NSString stringWithFormat:@"%@.", hostname];
    }
    
    NSString* hostdomain = self.hostDomain;
    
    NSString* port = self.hostPort;
    if (port.length > 0 && ![port hasPrefix:@":"]) {
        port = [NSString stringWithFormat:@":%@", port];
    }
    
    return [NSString stringWithFormat:@"%@://%@%@%@/", protocol, hostname, hostdomain, port];
}

-(void)setBaseURL:(NSString *)baseURL
{
    NSURL* url = [NSURL URLWithString:baseURL.copy];
    if (url == nil) {
        @throw [NSException exceptionWithName:KCSErrorDomain
                                       reason:[NSString stringWithFormat:@"'%@' is not a valid URL.", baseURL]
                                     userInfo:nil];
    }
    self.hostProtocol = url.scheme;
    self.serviceHostname = @"";
    self.hostDomain = url.host;
    self.hostPort = url.port ? url.port.stringValue : @"";
}

-(NSTimeInterval)connectionTimeout
{
    id value = self.options[KCS_CONNECTION_TIMEOUT];
    if (value && [value isKindOfClass:[NSNumber class]]) {
        return ((NSNumber*) value).doubleValue;
    }
    return KCS_DEFAULT_CONNETION_TIMEOUT_RAW;
}

-(void)setConnectionTimeout:(NSTimeInterval)connectionTimeout
{
    [self setValue:connectionTimeout > 0 ? @(connectionTimeout) : nil
         forOption:KCS_CONNECTION_TIMEOUT];
}

- (BOOL) valid
{
    return _appKey != nil && _appSecret != nil;
}

@end
