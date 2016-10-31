//
//  KCSSocialRequest.m
//  KinveyKit
//
//  Created by Michael Katz on 1/28/14.
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

#import "KCSSocialRequest.h"
#import "KCSClient.h"
#import "KinveyCoreInternal.h"
#import "KinveySocialInternal.h"

#import "KCSNSURLSessionOperation.h"
#import "KCSNSURLRequestOperation.h"

#define kMaxTries 5
#define kErrorKeyMethod @"KinveyKit.HTTPMethod"

@interface KCSSocialRequest ()
@property (nonatomic, copy) NSString* apiKey;
@property (nonatomic, copy) NSString* secretKey;
@property (nonatomic, copy) NSString* url;
@property (nonatomic, copy) NSString* method;
@property (nonatomic, copy) NSString* token;
@property (nonatomic, copy) NSString* tokenSecret;
@property (nonatomic, copy) NSDictionary* additionalKeys;
@property (nonatomic, retain) NSData* bodyData;
@end

@implementation KCSSocialRequest

- (instancetype) initWithApiKey:(NSString*)apiKey secret:(NSString*)secretKey url:(NSString*)url httpMethod:(NSString*)method
{
    self = [super init];
    if (self) {
        _apiKey = apiKey;
        _secretKey = secretKey;
        _url = url;
        _method = method;
        _token = nil;
        _tokenSecret = nil;
        _additionalKeys = nil;
        _bodyData = nil;
    }
    return self;
}

- (instancetype) initWithApiKey:(NSString*)apiKey secret:(NSString*)secretKey token:(NSString*)token tokenSecret:(NSString*)tokenSecret additionalKeys:(NSDictionary*)additionalKeys url:(NSString*)url httpMethod:(NSString*)method
{
    self = [self initWithApiKey:apiKey secret:secretKey url:url httpMethod:method];
    if (self) {
        _token = token;
        _tokenSecret = tokenSecret;
        _additionalKeys = additionalKeys;
    }
    return self;
}

- (instancetype) initWithApiKey:(NSString*)apiKey secret:(NSString*)secretKey token:(NSString*)token tokenSecret:(NSString*)tokenSecret additionalKeys:(NSDictionary*)additionalKeys body:(NSData*)bodyData url:(NSString*)url httpMethod:(NSString*)method
{
    self = [self initWithApiKey:apiKey secret:secretKey token:token tokenSecret:tokenSecret additionalKeys:additionalKeys url:url httpMethod:method];
    if (self) {
        _bodyData = bodyData;
    }
    return self;
}

- (NSMutableURLRequest*) urlRequest
{
    KCSClientConfiguration* config = [KCSClient2 sharedClient].configuration;
    NSURL* url = [NSURL URLWithString:self.url];
    DBAssert(url, @"Should have a valid url");
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:[config.options[KCS_URL_CACHE_POLICY] unsignedIntegerValue]
                                                       timeoutInterval:[config.options[KCS_CONNECTION_TIMEOUT] doubleValue]];
    request.HTTPMethod = self.method;
    
    NSMutableDictionary* headers = [NSMutableDictionary dictionary];
    headers[@"Authorization"] = KCS_OAuthorizationHeader([NSURL URLWithString:self.url], self.method, self.bodyData, self.apiKey, self.secretKey, self.token, self.tokenSecret, self.additionalKeys);
    [request setAllHTTPHeaderFields:headers];
    
    if (self.bodyData) {
        request.HTTPBody = self.bodyData;
    }

    return request;
}

- (id<KCSNetworkOperation>) start
{
    
    NSMutableURLRequest* request = [self urlRequest];
    
    NSOperation<KCSNetworkOperation>* op = nil;
    if ([KCSPlatformUtils supportsNSURLSession]) {
        op = [[KCSNSURLSessionOperation alloc] initWithRequest:request];
    } else {
        op = [[KCSNSURLRequestOperation alloc] initWithRequest:request];
    }
    
    op.clientRequestId = [NSString UUID];
    KCSLogInfo(KCS_LOG_CONTEXT_NETWORK, @"%@ %@ [KinveyKit id: '%@']", request.HTTPMethod, request.URL, op.clientRequestId);
    
    
    @weakify(op);
    op.completionBlock = ^() {
        @strongify(op);
        [self requestCallback:op request:request];
    };
    
    [[KCSNetworkObserver sharedObserver] connectionStart];
    [[KCSHttpRequest requestQueue] addOperation:op];
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
        } else {
            //status OK or is a non-retryable error
            [self callCallback:op request:request];
        }
    }
}

- (void) retryOp:(NSOperation<KCSNetworkOperation>*)oldOp request:(NSURLRequest*)request
{
    NSUInteger newcount = oldOp.retryCount + 1;
    if (newcount == kMaxTries) {
        [self callCallback:oldOp request:request];
    } else {
        NSOperation<KCSNetworkOperation>* op = [[[oldOp class] alloc] initWithRequest:request];
        op.clientRequestId = oldOp.clientRequestId;
        op.retryCount = newcount;
        @weakify(op);
        op.completionBlock = ^() {
            @strongify(op);
            [self requestCallback:op request:request];
        };
        
        double delayInSeconds = 0.1 * pow(2, newcount - 1); //exponential backoff
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [[KCSHttpRequest requestQueue] addOperation:op];
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
        KCSLogInfo(KCS_LOG_CONTEXT_NETWORK, @"Service Error (%ld) %@ [KinveyKit id: '%@' %@]", (long)op.response.code, [op.response jsonObjectError:nil], op.clientRequestId, op.response.headers);
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
    return [NSString stringWithFormat:@"%@ [%@]", [super debugDescription], [self url]];
}

@end
