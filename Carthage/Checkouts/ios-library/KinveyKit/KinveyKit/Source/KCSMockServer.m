//
//  KCSMockServer.m
//  KinveyKit
//
//  Created by Michael Katz on 8/15/13.
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


#import "KCSMockServer.h"
#import "KinveyCoreInternal.h"


KCSNetworkResponse* createMockErrorResponse(NSString* error, NSString* debug, NSString* message, NSInteger code)
{
    NSDictionary* data = @{@"error" : error ? error : @"",
                           @"debug" : debug ? debug : @"",
                           @"message" : message ? message : @""};
    KCSNetworkResponse* response = [KCSNetworkResponse MockResponseWith:code data:data];
    return response;
}


@interface KCSMockServer ()
@property (nonatomic, strong) NSMutableDictionary* routes;
@end

@implementation KCSMockServer
- (instancetype) init
{
    self = [super init];
    if (self) {
        _routes = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (instancetype)sharedServer
{
    static KCSMockServer* server;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        server = [[KCSMockServer alloc] init];
    });
    return server;
}

#pragma mark - Reachability

- (void) setReachable:(BOOL)reachable
{
    self.offline = reachable;
}


#pragma mark - Responses

+ (KCSNetworkResponse*) make404
{
    KCSNetworkResponse* response = [[KCSNetworkResponse alloc] init];
    response.code = 404;
    response.jsonData = [NSJSONSerialization dataWithJSONObject:@{
                          @"error": @"EntityNotFound",
                          @"description": @"This entity not found in the collection",
                          @"debug": @""
                          } options:0 error:NULL];

    return response;
}

+ (KCSNetworkResponse*) make401
{
    KCSNetworkResponse* response = [[KCSNetworkResponse alloc] init];
    response.code = 401;
    response.jsonData = [NSJSONSerialization dataWithJSONObject:@{
                          @"error": @"InvalidCredentials",
                          @"description": @"Invalid credentials. Please retry your request with correct credentials",
                          @"debug": @""
                          } options:0 error:NULL];
    
    return response;
}

+ (KCSNetworkResponse*) makePingResponse
{
    KCSNetworkResponse* response = [[KCSNetworkResponse alloc] init];
    response.code = 200;
    response.jsonData = [NSJSONSerialization dataWithJSONObject:@{
                          @"version": @"3.1.6-snapshot", //TODO: match from header
                          @"kinvey": @"Hello mock server", //TODO: pull from somewhere else
                          } options:0 error:NULL];
    return response;
}

+ (KCSNetworkResponse*) makeReflectionResponse:(NSURLRequest*)request
{
    KCSNetworkResponse* response = [[KCSNetworkResponse alloc] init];
    response.code = 200;
    if (request.HTTPBody) {
        response.jsonData = request.HTTPBody;
    }
    response.headers = request.allHTTPHeaderFields;
    return response;
}

+ (KCSNetworkResponse*) makeDeleteResponse:(NSInteger)count
{
    KCSNetworkResponse* response = [[KCSNetworkResponse alloc] init];
    response.code = 200;
    response.jsonData = [NSJSONSerialization dataWithJSONObject:@{@"count":@(count)} options:0 error:NULL];
    return response;
}

- (KCSNetworkResponse*) responseForRequest:(NSURLRequest*)request
{
    NSString* url = [request.URL absoluteString];
    KCSNetworkResponse* response = [KCSMockServer make404];
    
    url = [url stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
    NSArray* components = [url pathComponents];
    if (components != nil && components.count >= 4) {
//        NSString* protocol = components[0];
//        NSString* host = components[1];
        NSString* route = components[2];
        NSString* kid = components[3];
        if (self.appKey != nil && [kid isEqualToString:self.appKey] == NO) {
            return [KCSMockServer make401];
        }
        
        if ([route isEqualToString:KCSRestRouteTestReflection]) {
            return [KCSMockServer makeReflectionResponse:request];
        }
  
        if (components.count > 4) {
            NSMutableDictionary* d = _routes[route];
            if (d) {
                NSMutableDictionary* lastd = d;
                for (int i = 4; i < components.count - 1; i++) {
                    lastd = d;
                    d = d[components[i]];
                }
                KCSNetworkResponse* aresponse = d[components[components.count-1]];
                if (aresponse) {
                    response = aresponse;
                } else {
                    NSString* method = request.HTTPMethod;
                    if ([method isEqualToString:KCSRESTMethodPOST] || [method isEqualToString:KCSRESTMethodPUT]) {
                        //TODO: add _id on POSTS to a collection
                        if (!d) {
                            NSMutableDictionary* d = [NSMutableDictionary dictionary];
                            lastd[components[components.count - 2]] = d;
                        }
                        KCSNetworkResponse* getresponse =  [[KCSNetworkResponse alloc] init];
                        getresponse.code = 200;
                        if (request.HTTPBody) {
                            //TODO: add _id if none
                            getresponse.jsonData = request.HTTPBody;
                        }
                        //TODO this will add to the collection, but should be added to the _id under the collection
                        d[components[components.count-1]] = getresponse;
                        
                        response = [KCSMockServer makeReflectionResponse:request];
                        response.code = [method isEqualToString:KCSRESTMethodPOST] ? 201 : 200;
                    }
                }
            } else {
                NSString* method = request.HTTPMethod;
                if ([method isEqualToString:KCSRESTMethodPOST] || [method isEqualToString:KCSRESTMethodPUT]) {
                    NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
                    _routes[route] = dictionary;
                    DBAssert(components.count == 5, @"just handle the 5 case for now");
                    
                    KCSNetworkResponse* getresponse =  [[KCSNetworkResponse alloc] init];
                    getresponse.code = 200;
                    if (request.HTTPBody) {
                        //TODO: add _id if none
                        getresponse.jsonData = [NSJSONSerialization JSONObjectWithData:request.HTTPBody
                                                                               options:NSJSONReadingMutableContainers
                                                                                 error:nil];
                    }
                    dictionary[components[components.count-1]] = getresponse;

                    response = [KCSMockServer makeReflectionResponse:request];
                    response.code = [method isEqualToString:KCSRESTMethodPOST] ? 201 : 200;
                }
            }
        } else {
            if ([route isEqualToString:KCSRESTRouteAppdata]) {
                return [KCSMockServer makePingResponse];
            }
        }
        
    }
    
    return response;
}

- (NSMutableDictionary*)containerForRoute:(NSString*)route
{
    route = [route stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
    NSMutableDictionary* container = nil;
    NSArray* components = [route pathComponents];
    if (components != nil && components.count >= 3) {
        NSString* route = components[0];
        //TODO: do we care about kid? NSString* kid = components[1];
        
        NSMutableDictionary* routeResponses = _routes[route];
        if (routeResponses == nil) {
            routeResponses = [NSMutableDictionary dictionary];
            _routes[route] = routeResponses;
        }
        
        NSMutableDictionary* ld = routeResponses;
        for (int i = 2; i < components.count - 1; i++) {
            NSMutableDictionary* d = ld[components[i]];
            if (d == nil) {
                d = [NSMutableDictionary dictionary];
                ld[components[i]] = d;
            }
            ld = d;
        }
//        ld[components[components.count - 1]] = response;
        container = ld;
    }
    return container;
}

- (void) setResponse:(KCSNetworkResponse*)response forRoute:(NSString*)route
{
    NSMutableDictionary* container = [self containerForRoute:route];
    container[[route lastPathComponent]] = response;
}

- (NSError *)errorForRequest:(NSURLRequest *)request
{
    if (self.offline) {
#if !TARGET_OS_WATCH
        NSError* error = [NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil];
        return error;
#endif
    }
    
    NSString* url = [request.URL path];
    
    url = [url stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
    NSDictionary* d = [self containerForRoute:url];
    id response = d[[url lastPathComponent]];
    return [response isKindOfClass:[NSError class]] ? response : nil;
}

- (void) setError:(NSError *)error forRoute:(NSString *)route
{
    NSMutableDictionary* container = [self containerForRoute:route];
    container[[route lastPathComponent]] = error;
}

#pragma mark - debug

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"%@ (%@)", [super debugDescription], self.appKey];
}

@end
