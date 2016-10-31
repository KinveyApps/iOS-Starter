//
//  KCSRequest2.m
//  KinveyKit
//
//  Created by Michael Katz on 8/12/13.
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

#import "KCSHttpRequest.h"
#import "KinveyCoreInternal.h"
#import "KinveyErrorCodes.h"
#import "KCSNSURLRequestOperation.h"
#import "KCSMockRequestOperation.h"
#import "KCSNSURLSessionOperation.h"
#import "KCSMutableOrderedDictionary.h"
#import "KinveyUser+Private.h"
#import "KCSUser2+KinveyUserService+Private.h"
#import "KCSLogManager.h"
#import "KCSClient+Private.h"

#define kHeaderAuthorization           @"Authorization"
#define kHeaderDate                    @"Date"
#define kHeaderUserAgent               @"User-Agent"
#define kHeaderApiVersion              @"X-Kinvey-Api-Version"
#define kHeaderClientMethod            @"X-Kinvey-Client-Method"
#define kHeaderDeviceInfo              @"X-Kinvey-Device-Information"
#define kHeaderResponseWrapper         @"X-Kinvey-ResponseWrapper"
#define kHeaderBypassBL                @"x-kinvey-skip-business-logic"

#define kHeaderValueJson @"application/json"

#define kErrorKeyMethod @"KinveyKit.HTTPMethod"

#define kMaxTries 5

KCS_CONST_IMPL KCSRequestOptionClientMethod = kHeaderClientMethod;
KCS_CONST_IMPL KCSRequestOptionUseMock      = @"UseMock";
KCS_CONST_IMPL KCSRESTRouteAppdata          = @"appdata";
KCS_CONST_IMPL KCSRESTRouteUser             = @"user";
KCS_CONST_IMPL KCSRESTRouteBlob             = @"blob";
KCS_CONST_IMPL KCSRESTRouteRPC              = @"rpc";
KCS_CONST_IMPL KCSRESTRoutePush             = @"push";
KCS_CONST_IMPL KCSRestRouteTestReflection   = @"!reflection";

KCS_CONST_IMPL KCSRESTMethodDELETE = @"DELETE";
KCS_CONST_IMPL KCSRESTMethodGET    = @"GET";
KCS_CONST_IMPL KCSRESTMethodPATCH  = @"PATCH";
KCS_CONST_IMPL KCSRESTMethodPOST   = @"POST";
KCS_CONST_IMPL KCSRESTMethodPUT    = @"PUT";

#define KCS_VERSION @"3"

#import <Kinvey/Kinvey-Swift.h>

#define MAX_DATE_STRING_LENGTH_K 40
KK2(make just 1)
NSString * getLogDate3()
{
    time_t now = time(NULL);
    struct tm *t = gmtime(&now);
    
    char timestring[MAX_DATE_STRING_LENGTH_K];
    
    NSInteger len = strftime(timestring, MAX_DATE_STRING_LENGTH_K - 1, "%a, %d %b %Y %T %Z", t);
    assert(len < MAX_DATE_STRING_LENGTH_K);
    
    return [NSString stringWithCString:timestring encoding:NSASCIIStringEncoding];
}

#import "KCSHttpRequest+Private.h"

@implementation KCSHttpRequest
static NSOperationQueue* kcsRequestQueue;

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kcsRequestQueue = [[NSOperationQueue alloc] init];
        kcsRequestQueue.maxConcurrentOperationCount = 4;
        [kcsRequestQueue setName:@"com.kinvey.KinveyKit.RequestQueue"];
    });
}

+ (NSOperationQueue*) requestQueue
{
    return kcsRequestQueue;
}

+ (instancetype) requestWithCompletion:(KCSRequestCompletionBlock)completion
                                 route:(NSString*)route
                               options:(NSDictionary*)options
                           credentials:(id)credentials
{
    return [self requestWithCompletion:completion
                                 route:route
                               options:options
                           credentials:credentials
                                client:[KCSClient sharedClient].client];
}

+ (instancetype) requestWithCompletion:(KCSRequestCompletionBlock)completion
                                 route:(NSString*)route
                               options:(NSDictionary*)options
                           credentials:(id)credentials
                                client:(KNVClient*)client
{
    return [self requestWithCompletion:completion
                                 route:route
                               options:options
                           credentials:credentials
                  requestConfiguration:nil
                                client:client];
}

+ (instancetype) requestWithCompletion:(KCSRequestCompletionBlock)completion
                                 route:(NSString*)route
                               options:(NSDictionary*)options
                           credentials:(id)credentials
                  requestConfiguration:(KCSRequestConfiguration*)requestConfiguration
{
    return [self requestWithCompletion:completion
                                 route:route
                               options:options
                           credentials:credentials
                  requestConfiguration:requestConfiguration
                                client:[KCSClient sharedClient].client];
}

+ (instancetype) requestWithCompletion:(KCSRequestCompletionBlock)completion
                                 route:(NSString*)route
                               options:(NSDictionary*)options
                           credentials:(id)credentials
                  requestConfiguration:(KCSRequestConfiguration*)requestConfiguration
                                client:(KNVClient*)client
{
    KCSHttpRequest* request = [[KCSHttpRequest alloc] initWithClient:client];
    request.useMock = [options[KCSRequestOptionUseMock] boolValue];
    request.completionBlock = completion;
    request.credentials = credentials;
    request.route = route;
    request.options = options;
    request.requestConfiguration = requestConfiguration;
    return request;
}

- (instancetype) init
{
    return [self initWithClient:[KCSClient sharedClient].client];
}

- (instancetype) initWithClient:(KNVClient*)client
{
    self = [super init];
    if (self) {
        _contentType = kHeaderValueJson;
        _method = KCSRESTMethodGET;
        _client = client;
    }
    return self;
}

# pragma mark -
- (NSString*)finalURL
{
    NSMutableString* endpoint = self.client.apiHostName.absoluteString.mutableCopy;
    if ([endpoint characterAtIndex:endpoint.length - 1] != '/') {
        [endpoint appendString:@"/"];
    }
    NSString* kid = self.client.appKey;

    if (_useMock && kid == nil) {
        kid = @"mock";
        if (!endpoint) {
            endpoint = @"https://localhost:2110/".mutableCopy;
        }
    }
    
    NSArray* path = [@[self.route, kid] arrayByAddingObjectsFromArray:[_path arrayByPercentEncoding]];
    NSString* urlStr = [path componentsJoinedByString:@"/"];
    if (self.queryString) {
        if ([urlStr hasPrefix:@"/"]) {
            urlStr = [urlStr stringByAppendingString:self.queryString];
        } else {
            urlStr = [urlStr stringByAppendingFormat:@"/%@",self.queryString];
        }
    }
    [endpoint appendString:urlStr];

    return endpoint;
}

+(NSString*)clientAppVersion
{
    NSString* clientAppVersion;
    
    if ([KCSClient2 sharedClient].configuration &&
        [KCSClient2 sharedClient].configuration.requestConfiguration &&
        [KCSClient2 sharedClient].configuration.requestConfiguration.clientAppVersion)
    {
        clientAppVersion = [KCSClient2 sharedClient].configuration.requestConfiguration.clientAppVersion;
    } else {
        clientAppVersion = nil;
    }
    
    return clientAppVersion;
}

-(NSString*)clientAppVersion
{
    NSString* clientAppVersion;
    
    if (self.requestConfiguration &&
        self.requestConfiguration.clientAppVersion)
    {
        clientAppVersion = self.requestConfiguration.clientAppVersion;
    } else {
        clientAppVersion = [self.class clientAppVersion];
    }
    
    return clientAppVersion;
}

+(NSMutableDictionary*)customRequestProperties
{
    NSMutableDictionary* customRequestProperties = [NSMutableDictionary dictionary];
    
    [customRequestProperties addEntriesFromDictionary:[KCSClient sharedClient].configuration.requestConfiguration.customRequestProperties];
    
    [customRequestProperties addEntriesFromDictionary:[KCSClient2 sharedClient].configuration.requestConfiguration.customRequestProperties];
    
    return customRequestProperties;
}

-(NSDictionary*)customRequestProperties
{
    NSMutableDictionary* customRequestProperties = [self.class customRequestProperties];
    
    [customRequestProperties addEntriesFromDictionary:self.requestConfiguration.customRequestProperties];
    
    return customRequestProperties;
}

+(NSMutableURLRequest *)requestForURL:(NSURL *)url
{
    return [self requestForURL:url
                        client:[KCSClient sharedClient].client];
}

+(NSMutableURLRequest *)requestForURL:(NSURL *)url
                               client:(KNVClient*)client
{
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:client.cachePolicy
                                                       timeoutInterval:client.timeoutInterval];
    if (url.host) {
        [request setValue:url.host
       forHTTPHeaderField:@"Host"];
    }
    
    [request setValue:KCS_VERSION
   forHTTPHeaderField:kHeaderApiVersion];
    
    [request setValue:[NSString stringWithFormat:@"ios-kinvey-http/%@ kcs/%@", __KINVEYKIT_VERSION__, MINIMUM_KCS_VERSION_SUPPORTED]
   forHTTPHeaderField:kHeaderUserAgent];
    
    [request setValue:[KCSPlatformUtils platformString]
   forHTTPHeaderField:kHeaderDeviceInfo];
    
    NSString* clientAppVersion = client.clientAppVersion;
    if (clientAppVersion) {
        [request setValue:clientAppVersion
       forHTTPHeaderField:kHeaderClientAppVersion];
    }
    
    NSString* customRequestPropertiesJsonString = client.customRequestProperties && client.customRequestProperties.count > 0 ? client.customRequestProperties.jsonString : nil;
    if (customRequestPropertiesJsonString) {
        [request setValue:customRequestPropertiesJsonString
       forHTTPHeaderField:kHeaderCustomRequestProperties];
    }
    
    [request setValue:getLogDate3() //always update date
   forHTTPHeaderField:kHeaderDate];
    
    return request;
}

-(NSMutableURLRequest *)requestForURL:(NSURL *)url
{
    NSMutableURLRequest* request = [self.class requestForURL:url
                                                      client:self.client];
    
    NSString* clientAppVersion = self.clientAppVersion;
    if (clientAppVersion) {
        [request setValue:clientAppVersion forHTTPHeaderField:kHeaderClientAppVersion];
    }
    
    NSString* customRequestPropertiesJsonString = self.customRequestProperties && self.customRequestProperties.count > 0 ? self.customRequestProperties.jsonString : nil;
    if (customRequestPropertiesJsonString) {
        [request setValue:customRequestPropertiesJsonString forHTTPHeaderField:kHeaderCustomRequestProperties];
    }
    
    if (self.requestConfiguration && self.requestConfiguration.timeout > 0){
        request.timeoutInterval = self.requestConfiguration.timeout;
    }
    
    return request;
}

- (NSMutableURLRequest*)urlRequest
{
    NSString* endpoint = [self finalURL];
    
    NSURL* url = [NSURL URLWithString:endpoint];
    DBAssert(url, @"Should have a valid url");
    
    if (![url.scheme isEqualToString:@"https"]) {
        NSRange range = [url.host rangeOfString:@"(.{1,}\\.)*kinvey\\.com" options:NSRegularExpressionSearch];
        if (range.location == 0 && range.length == url.host.length) {
            NSString* reason = [NSString stringWithFormat:@"Kinvey requires `https` as the protocol when setting a base URL, instead found: %@ in baseURL: %@://%@%@", url.scheme, url.scheme, url.host, url.port ? [NSString stringWithFormat:@":%@", url.port] : @""];
            NSDictionary* userInfo = @{
                                       NSLocalizedDescriptionKey : reason,
                                       NSLocalizedFailureReasonErrorKey : reason
                                       };
            @throw [NSException exceptionWithName:@"KinveyException"
                                           reason:reason
                                         userInfo:userInfo];
        }
    }

    NSMutableURLRequest* request = [self requestForURL:url];
    request.HTTPMethod = self.method;
    
    NSMutableDictionary* headers = [NSMutableDictionary dictionaryWithDictionary:request.allHTTPHeaderFields];
    @try {
        NSString* authorizationHeader;
        if ([KCSClient sharedClient].appKey && [KCSClient sharedClient].appSecret) {
            authorizationHeader = [self.credentials authString];
        } else {
            authorizationHeader = self.client.authorizationHeader;
        }
        headers[kHeaderAuthorization] = authorizationHeader;
    }
    @catch (NSException *exception) {
        KCSLogError(@"Error setting the authorization header: %@", exception);
        [headers removeObjectForKey:kHeaderAuthorization];
    }
    
    headers[kHeaderResponseWrapper] = @"true";
    setIfValNotNil(headers[kHeaderClientMethod], self.options[KCSRequestOptionClientMethod]);

    [headers addEntriesFromDictionary:self.headers];
    
    [request setAllHTTPHeaderFields:headers];
    
    [request setHTTPShouldUsePipelining:YES];

    if ([self.method isEqualToString:KCSRESTMethodPOST] || [self.method isEqualToString:KCSRESTMethodPUT]) {
        [request setHTTPShouldUsePipelining:NO];
        //set the body
        if (!_body) {
            _body = @{};
        }
        NSData* bodyData = [_body kcsJSONDataRepresentation:nil];
        DBAssert(bodyData != nil, @"should be able to parse body");
        [request setHTTPBody:bodyData];
        [request setValue:_contentType forHTTPHeaderField:kHeaderContentType];
    } else if ([self.method isEqualToString:KCSRESTMethodDELETE]) {
        // [request setHTTPBody:bodyData]; no need for body b/c of no content type
    }

    return request;
}

- (NSOperation<KCSNetworkOperation>*) start
{
    NSAssert(_route, @"should have route");
    if (!self.credentials) {
        NSError* error = [NSError errorWithDomain:KCSNetworkErrorDomain code:KCSDeniedError userInfo:@{NSLocalizedDescriptionKey : @"No Authorization Found", NSLocalizedFailureReasonErrorKey : @"There is no active user/client and this request requires credentials.", NSURLErrorFailingURLStringErrorKey : [self finalURL]}];
        self.completionBlock(nil, error);
        return nil;
    }
    NSAssert(self.credentials, @"should have credentials");
    DBAssert(self.options[KCSRequestOptionClientMethod], @"DB should set client method");
    
    NSMutableURLRequest* request = [self urlRequest];
    
    NSOperation<KCSNetworkOperation>* op = nil;
    if (_useMock) {
        op = [[KCSMockRequestOperation alloc] initWithRequest:request];
    } else {
        
        if ([KCSPlatformUtils supportsNSURLSession] && !KCSConfigValueBOOL(KCS_ALWAYS_USE_NSURLREQUEST)) {
            op = [[KCSNSURLSessionOperation alloc] initWithRequest:request];
        } else {
            op = [[KCSNSURLRequestOperation alloc] initWithRequest:request];
        }
    }

    op.clientRequestId = [NSString UUID];
    KCSLogInfo(KCS_LOG_CONTEXT_NETWORK, @"%@ %@ [KinveyKit id: '%@']", request.HTTPMethod, request.URL, op.clientRequestId);

    
    @weakify(op);
    op.completionBlock = ^() {
        @strongify(op);
        if (!op.isCancelled) {
            [self requestCallback:op request:request];
        }
    };
    op.progressBlock = self.progress;
    
    [[KCSNetworkObserver sharedObserver] connectionStart];
    [kcsRequestQueue addOperation:op];
    
#if BUILD_FOR_UNIT_TEST
    [_sRequestArray addObject:request];
#endif
    return op;
}

- (void) requestCallback:(NSOperation<KCSNetworkOperation>*)op request:(NSURLRequest*)request
{
    if ([[KCSClient sharedClient].options[KCS_CONFIG_RETRY_DISABLED] boolValue] == YES) {
        [self callCallback:op request:request];
    } else {
        if (opIsRetryableNetworkError(op)) {
            KCSLogNotice(KCS_LOG_CONTEXT_NETWORK, @"Retrying request (%@). Network error: %ld.", op.clientRequestId, (long)op.error.code);
            [self retryOp:op request:request];
        } else if (opIsRetryableKCSError(op)) {
            KCSLogNotice(KCS_LOG_CONTEXT_NETWORK, @"Retrying request (%@). Kinvey server error: %@", op.clientRequestId, [op.response jsonObjectError:nil]);
            [self retryOp:op request:request];
        } else {
            //status OK or is a non-retryable error
            [self callCallback:op request:request];
        }
    }
}

BOOL opIsRetryableNetworkError(NSOperation<KCSNetworkOperation>* op)
{
    BOOL isError = NO;
    if (op.error) {
        if ([[op.error domain] isEqualToString:NSURLErrorDomain]) {
            switch (op.error.code) {
#if !TARGET_OS_WATCH
                case kCFURLErrorUnknown:
                case kCFURLErrorTimedOut:
                case kCFURLErrorCannotFindHost:
                case kCFURLErrorCannotConnectToHost:
                case kCFURLErrorNetworkConnectionLost:
                case kCFURLErrorDNSLookupFailed:
                case kCFURLErrorResourceUnavailable:
                case kCFURLErrorRequestBodyStreamExhausted:
                    isError = YES;
                    break;
#endif
            }
        }
    }
    
    return isError;
}

BOOL opIsRetryableKCSError(NSOperation<KCSNetworkOperation>* op)
{
    //kcs error KinveyInternalErrorRetry:
    //        statusCode: 500
    //        description: "The Kinvey server encountered an unexpected error. Please retry your request"
    
    return [op.response isKCSError] &&
    ((op.response.code == 500 &&
      [[op.response jsonObjectError:nil][@"error"] isEqualToString:@"KinveyInternalErrorRetry"]) ||
     op.response.code == 429);
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"cancelled"] &&
        [object isKindOfClass:[NSOperation<KCSNetworkOperation> class]] &&
        [(__bridge NSObject*)context isKindOfClass:[NSOperation<KCSNetworkOperation> class]] &&
        [change[NSKeyValueChangeNewKey] isKindOfClass:[NSNumber class]] &&
        ((NSNumber*) change[NSKeyValueChangeNewKey]).boolValue)
    {
        [((__bridge NSOperation<KCSNetworkOperation>*) context) cancel];
    } else {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

- (void) retryOp:(NSOperation<KCSNetworkOperation>*)oldOp request:(NSURLRequest*)request
{
    NSUInteger newcount = oldOp.retryCount + 1;
    if (newcount == kMaxTries) {
        [self callCallback:oldOp request:request];
    } else {
        NSOperation<KCSNetworkOperation>* op = [[[oldOp class] alloc] initWithRequest:request];
        [oldOp addObserver:self
                forKeyPath:@"cancelled"
                   options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                   context:(__bridge void * _Nullable)(op)];
        op.clientRequestId = oldOp.clientRequestId;
        op.retryCount = newcount;
        @weakify(op);
        op.completionBlock = ^() {
            @strongify(op);
            [oldOp removeObserver:self
                       forKeyPath:@"cancelled"];
            if (!(op.isCancelled)) {
                [self requestCallback:op request:request];
            }
        };
        
        double delayInSeconds = 0.1 * pow(2, newcount - 1); //exponential backoff
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            if (!(op.isCancelled)) {
                [kcsRequestQueue addOperation:op];
            }
        });
    }
}

- (void) callCallback:(NSOperation<KCSNetworkOperation>*)op request:(NSURLRequest*)request
{
    [[KCSNetworkObserver sharedObserver] connectionEnd];
    op.response.originalURL = request.URL;
    NSError* error = nil;
    if (op.error) {
        error = [op.error errorByAddingCommonInfo];
        KCSLogInfo(KCS_LOG_CONTEXT_NETWORK, @"Network Client Error %@ [KinveyKit id: '%@']", error, op.clientRequestId);
    } else if ([op.response isKCSError]) {
        KCSUser* user = [KCSUser activeUser];
        NSDictionary* kinveyAuth = user.userAttributes[@"_socialIdentity"][@"kinveyAuth"];
        if (op.response.code == KCSDeniedError && kinveyAuth[kKCSMICRefreshTokenKey] && kinveyAuth[kKCSMICRedirectURIKey]) {
            KCSLogInfo(KCS_LOG_CONTEXT_NETWORK, @"Kinvey Refresh Token (%@)", kinveyAuth[kKCSMICRefreshTokenKey]);
            __block id<KCSUser2> user = nil;
            __block NSError *error = nil;
            [KCSUser2 oAuthTokenWithRefreshToken:kinveyAuth[kKCSMICRefreshTokenKey]
                                     redirectURI:kinveyAuth[kKCSMICRedirectURIKey]
                                            sync:YES
                                      completion:^(id<KCSUser2> _user, NSError* _error)
            {
                user = _user;
                error = _error;
            }];
            if (!error && user) {
                [self retryOp:op
                      request:request];
                return;
            }
        }
        
        KCSLogInfo(KCS_LOG_CONTEXT_NETWORK, @"Kinvey Server Error (%ld) %@ [KinveyKit id: '%@' %@]", (long)op.response.code, [op.response jsonObjectError:nil], op.clientRequestId, op.response.headers);
        [self.credentials handleErrorResponse:op.response];
        error = [op.response errorObject];
    } else {
        KCSLogInfo(KCS_LOG_CONTEXT_NETWORK, @"Kinvey Success (%ld) [KinveyKit id: '%@'] %@", (long)op.response.code, op.clientRequestId, op.response.headers);
    }
    error = [error updateWithInfo:@{kErrorKeyMethod : request.HTTPMethod}];
    self.completionBlock(op.response, error);
}


#pragma mark - Debug

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"%@ [%@]", [super debugDescription], [self finalURL]];
}

#if BUILD_FOR_UNIT_TEST
static NSMutableArray* _sRequestArray;
+ (void) setRequestArray:(NSMutableArray*)requestArray
{
    _sRequestArray = requestArray;
}
#else
+ (void) setRequestArray:(NSMutableArray*)requestArray
{
    NSAssert(NO, @"Should not call this function");
}
#endif

+(void)cancelAndWaitUntilAllOperationsAreFinished
{
    [kcsRequestQueue cancelAllOperations];
    [kcsRequestQueue waitUntilAllOperationsAreFinished];
}

@end

#pragma clang diagnostic pop
