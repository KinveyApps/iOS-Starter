//
//  KCSMockServerTest.m
//  KinveyKit
//
//  Created by Michael Katz on 8/15/13.
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


#import <XCTest/XCTest.h>

#import "KCSMockServer.h"
#import "KinveyCoreInternal.h"
#import "TestUtils2.h"

@interface KCSMockServer (TEST)
- (KCSNetworkResponse*) responseForURL:(NSString*)urlStr;
@end
@implementation KCSMockServer (TEST)

- (KCSNetworkResponse *)responseForURL:(NSString *)urlStr
{
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    return [self responseForRequest:req];
}

- (NSError*)errorForURL:(NSString*)urlStr
{
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    return [self errorForRequest:req];
}

@end

@interface KCSMockServerTest : KCSTestCase
@property (nonatomic, strong) KCSMockServer* server;
@end

@implementation KCSMockServerTest

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
    _server = [[KCSMockServer alloc] init];
    _server.appKey = @"kid_test";
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}


- (void) testNoURL
{
    KCSNetworkResponse* x = [_server responseForURL:@"http://v3yk1n-kcs.kinvey.com/foo/kid_test/a/b/c"];
    KTAssertNotNil(x);
    KTAssertEqualsInt(x.code, 404);
}

- (void) testAppdataBasic
{
    NSDictionary* data = @{@"_id":@1, @"key":@"value"};
    KCSNetworkResponse* response = [KCSNetworkResponse MockResponseWith:200 data:data];
    [_server setResponse:response forRoute:@"/appdata/kid_test/collection/1"];
    KCSNetworkResponse* r1 = [_server responseForURL:@"http://foo.bar.com/appdata/kid_test/collection/1"];
    KTAssertNotNil(r1);
    KTAssertEqualsInt(r1.code, 200);
    XCTAssertEqualObjects([r1 jsonObject], data, @"data should match previous");
}

- (void) testPing
{
    KCSNetworkResponse* x = [_server responseForURL:@"http://v3yk1n-kcs.kinvey.com/appdata/kid_test"];
    KTAssertNotNil(x);
    KTAssertEqualsInt(x.code, 200);
}

- (void) testBadCreds
{
    
    KCSNetworkResponse* x = [_server responseForURL:@"http://v3yk1n-kcs.kinvey.com/appdata/kid_fail"];
    KTAssertNotNil(x);
    KTAssertEqualsInt(x.code, 401);
    XCTAssertEqualObjects(x.jsonObject[@"error"], @"InvalidCredentials", @"should be an invalid creds error");
}

- (void) testReflection
{
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://v3yk1n-kcs.kinvey.com/!reflection/kid_test"]];
    NSDictionary* headers = @{@"A":@"B"};
    req.allHTTPHeaderFields = headers;
    id body = @{@"results":@[@"A",@{@"K":@1}]};
    req.HTTPBody = [NSJSONSerialization dataWithJSONObject:body
                                                   options:0
                                                     error:nil];
    
    KCSNetworkResponse* x = [_server responseForRequest:req];
    KTAssertNotNil(x);
    KTAssertEqualsInt(x.code, 200);
    XCTAssertEqualObjects([x jsonObject], body, @"body must match");
    XCTAssertEqualObjects(x.headers, headers, @"headers must match");
}

- (void) testError
{
    NSError* error = [NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil];
    [_server setError:error forRoute:@"/appdata/kid_test/collection/1"];
    NSError* r1 = [_server errorForURL:@"http://foo.bar.com/appdata/kid_test/collection/1"];
    KTAssertNotNil(r1);
    XCTAssertEqualObjects(r1.domain, NSURLErrorDomain, @"domains should match");
}




@end
