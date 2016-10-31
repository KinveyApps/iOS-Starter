//
//  KCSRequest2Tests.m
//  KinveyKit
//
//  Created by Michael Katz on 8/23/13.
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

#import "KinveyCoreInternal.h"
#import "TestUtils2.h"

@interface KCSRequest2Tests : KCSTestCase

@end

@implementation KCSRequest2Tests

- (void)setUp
{
    [super setUp];
    [self setupKCS:YES];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testQueuesAreSame
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    dispatch_queue_t startQ = dispatch_get_current_queue();
    __weak XCTestExpectation* expectationRequest = [self expectationWithDescription:@"request"];
    KCSHttpRequest* request = [KCSHttpRequest requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {
        
        dispatch_queue_t endQ = dispatch_get_current_queue();
#pragma clang diagnostic pop
        XCTAssertEqual(startQ, endQ, @"queues should match");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationRequest fulfill];
    } route:KCSRESTRouteAppdata options:@{KCSRequestOptionUseMock: @(YES), KCSRequestLogMethod} credentials:mockCredentails()];
    [request start];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

//- (void) testMethodAnayltics
//{
//    XCTestExpectation* expectationRequest = [self expectationWithDescription:@"request"];
//    KCSRequest2* request = [KCSRequest2 requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {
//        XCTAssertNotNil(response, @"need response");
//        NSDictionary* headers = response.headers;
//        NSString* method = headers[@"X-Kinvey-Client-Method"];
//        XCTAssertNotNil(method, @"should have the method");
//        XCTAssertEqualObjects(method, @"KCSRequest2Tests testMethodAnayltics", @"should be this method");
//        
//        XCTAssertTrue([NSThread isMainThread]);
//        
//        [expectationRequest fulfill];
//    } route:KCSRestRouteTestReflection options:@{KCSRequestOptionUseMock: @(YES), KCSRequestLogMethod} credentials:mockCredentails()];
//    [request start];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//}
//
//- (void) testPath
//{
//    NSArray* path =  @[@"1",@"2"];
//    XCTestExpectation* expectationRequest = [self expectationWithDescription:@"request"];
//    KCSRequest2* request = [KCSRequest2 requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {
//        XCTAssertNotNil(response, @"need response");
//        NSURL* url = response.originalURL;
//        XCTAssertNotNil(url, @"needed url");
//
//        NSArray* components = [url pathComponents];
//        NSArray* lastComponents = [components subarrayWithRange:NSMakeRange(components.count - 2, 2)];
//        KTAssertCount(2, lastComponents);
//        XCTAssertEqualObjects(lastComponents, path, @"should match");
//        
//        XCTAssertTrue([NSThread isMainThread]);
//        
//        [expectationRequest fulfill];
//    } route:KCSRestRouteTestReflection options:@{KCSRequestOptionUseMock: @(YES), KCSRequestLogMethod} credentials:mockCredentails()];
//    request.path = path;
//    [request start];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//}
//
//- (void) testRetryKCS
//{
//    KCSNetworkResponse* retryResponse = createMockErrorResponse(@"KinveyInternalErrorRetry", nil, nil, 500);
//    [[KCSMockServer sharedServer] setResponse:retryResponse forRoute:@"appdata/:kid/foo"];
//
//    LogTester* tester = [LogTester sharedInstance];
//    [tester clearLogs];
//    
//    NSArray* path =  @[@"foo"];
//    XCTestExpectation* expectationRequest = [self expectationWithDescription:@"request"];
//    KCSRequest2* request = [KCSRequest2 requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {
//        NSArray* logs = tester.logs;
//        NSArray* retries = [logs filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
//            return [evaluatedObject hasPrefix:@"Retrying"];
//        }]];
//        KTAssertCount(5, retries);
//        
//        XCTAssertTrue([NSThread isMainThread]);
//        
//        [expectationRequest fulfill];
//    } route:KCSRESTRouteAppdata options:@{KCSRequestOptionUseMock: @(YES), KCSRequestLogMethod} credentials:mockCredentails()];
//    request.path = path;
//    [request start];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//}
//
//- (void) testRetryCFNetwork
//{
//    KTNIY
//}
//
//- (void) testCreateCustomURLRquest
//{
//    KCSRequest2* request = [KCSRequest2 requestWithCompletion:^(KCSNetworkResponse *response, NSError *error)
//    {
//        XCTAssertTrue([NSThread isMainThread]);
//    }
//                                                        route:KCSRESTRouteRPC
//                                                      options:@{}
//                                                  credentials:mockCredentails()];
//    request.method = KCSRESTMethodPOST;
//    request.path = @[@"custom",@"endpoint"];
//    request.body = @{@"foo":@"bar",@"baz":@[@1,@2,@3]};
//    
//    NSURLRequest* urlRequest = [request urlRequest];
//    NSURL* url = urlRequest.URL;
//    
//    KCSClient* client = [KCSClient sharedClient];
//    NSString* expectedURL = [NSString stringWithFormat:@"https://%@.kinvey.com/rpc/%@/custom/endpoint", client.configuration.serviceHostname, client.appKey];
//    
//    XCTAssertEqualObjects(expectedURL, url.absoluteString, @"should have a url match");
//    
//    NSData* bodyData = urlRequest.HTTPBody;
//    NSDictionary* undidBody = [NSJSONSerialization JSONObjectWithData:bodyData options:0 error:NULL];
//    NSDictionary* expBody = @{@"foo":@"bar",@"baz":@[@1,@2,@3]};
//    XCTAssertEqualObjects(expBody, undidBody, @"bodies should match");
//}
//
//- (void) testDate
//{
//    KCSRequest2* request = [KCSRequest2 requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {}
//                                                        route:KCSRESTRouteRPC
//                                                      options:@{}
//                                                  credentials:mockCredentails()];
//    NSURLRequest* urlRequest = [request urlRequest];
//    NSDictionary* headers = [urlRequest allHTTPHeaderFields];
//    NSString* d = headers[@"Date"];
//    XCTAssertNotNil(d, @"should have a header");
//
//}

@end
