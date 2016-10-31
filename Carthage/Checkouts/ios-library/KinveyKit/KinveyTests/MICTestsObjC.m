//
//  MICTestsObjC.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-04-07.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KinveyKit.h"
#import "TestUtils2.h"
#import "KCSMutableOrderedDictionary.h"
#import "KCSUser2+KinveyUserService.h"
#import "KinveyUser+Private.h"
#import "NSString+KinveyAdditions.h"

@interface MICTestsObjC : KCSTestCase

@end

@interface MockURLProtocol : NSURLProtocol

@end

@implementation MockURLProtocol

static BOOL canHandleRequest = YES;

+(BOOL)canInitWithRequest:(NSURLRequest *)request
{
    return canHandleRequest;
}

+(NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

-(void)startLoading
{
    NSData* data = [NSJSONSerialization dataWithJSONObject:@{ @"error" : @"ExpiredToken" }
                                                   options:0
                                                     error:nil];
    NSDictionary* headers = @{
        @"Content-Type" : @"application/json; charset=utf-8",
        @"Content-Length" : @(data.length).description,
        @"X-Powered-By" : @"Express"
    };
    
    NSHTTPURLResponse* response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                              statusCode:401
                                                             HTTPVersion:@"1.1"
                                                            headerFields:headers];
    
    [self.client URLProtocol:self
          didReceiveResponse:response
          cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    
    [self.client URLProtocol:self
                 didLoadData:data];
    
    [self.client URLProtocolDidFinishLoading:self];
    
    canHandleRequest = NO;
}

@end

@implementation MICTestsObjC

- (void)setUp {
    [super setUp];
    
    [[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid_WyYCSd34p"
                                                 withAppSecret:@"22a381bca79c407cb0efc6585aaed53e"
                                                  usingOptions:nil];
}

-(void)testEncodeRedirectURI {
    XCTAssertEqualObjects([NSString stringByPercentEncodingString:@"blah://"], @"blah%3A%2F%2F");
}

//- (void)testRefreshToken {
//    XCTestExpectation* expectationLogin = [self expectationWithDescription:@"login"];
//    
//    [KCSUser loginWithAuthorizationCodeAPI:@"kinveyAuthDemo://"
//                                   options:@{ KCSUsername : @"mjs",
//                                        KCSPassword : @"demo" }
//                       withCompletionBlock:^(KCSUser *user, NSError *error, KCSUserActionResult result)
//    {
//        XCTAssertNil(error);
//        XCTAssertNotNil(user);
//        
//        [expectationLogin fulfill];
//    }];
//    
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//    
//    [KCSURLProtocol registerClass:[MockURLProtocol class]];
//    
//    KCSCollection* collection = [KCSCollection collectionFromString:@"person"
//                                                            ofClass:[NSMutableDictionary class]];
//    KCSCachedStore* store = [KCSCachedStore storeWithCollection:collection
//                                                        options:@{ KCSStoreKeyCachePolicy : @(KCSCachePolicyLocalFirst),
//                                                                   KCSStoreKeyOfflineUpdateEnabled : @(YES) }];
//    
//    XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
//    
//    [store saveObject:@{ @"name" : @"Victor" }
//  withCompletionBlock:^(NSArray *results, NSError *error)
//    {
//        XCTAssertNil(error);
//        XCTAssertNotNil(results);
//        
//        [expectationSave fulfill];
//    }
//    withProgressBlock:nil];
//    
//    [self waitForExpectationsWithTimeout:60
//                                 handler:^(NSError *error)
//    {
//        [KCSURLProtocol unregisterClass:[MockURLProtocol class]];
//    }];
//}

@end
