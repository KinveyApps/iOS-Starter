//
//  ThreadTests.m
//  KinveyKit
//
//  Created by Michael Katz on 1/13/14.
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


#import <XCTest/XCTest.h>

#import "EXTScope.h"
#import "TestUtils2.h"
#import "KinveyKit.h"

@interface TestOperation : NSOperation
@property (nonatomic, copy) dispatch_block_t block;
@property (nonatomic) BOOL executing;
@property (nonatomic) BOOL finished;
@end

@implementation TestOperation
@synthesize executing = _executing;
@synthesize finished = _finished;

- (void)start
{
    [self setExecuting:YES];
    _block();
}

- (BOOL)isConcurrent
{
    return NO;
}

- (BOOL)isReady
{
    return YES;
}

- (void)setFinished:(BOOL)finished
{
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing
{
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isExecuting
{
    return _executing;
}

- (BOOL)isFinished
{
    return _finished;
}

- (BOOL)isCancelled
{
    return NO;
}

@end


@interface ThreadTests : KCSTestCase <NSURLSessionDataDelegate>
@property (nonatomic) int count;
@property (nonatomic, retain) NSMutableDictionary* d;
@end

@implementation ThreadTests

static NSOperationQueue* queue;

+ (void)initialize
{
    queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 2;
    [queue setName:@"com.kinvey.KinveyKit.TestQueue"];
}

- (void)setUp
{
    [super setUp];
    _count = 0;
    @synchronized (self) {
        _d = [NSMutableDictionary dictionary];
    }
    // Put setup code here; it will be run once, before the first test case.
}

+ (void)tearDown
{
    [queue cancelAllOperations];
    if (queue.operationCount > 0) {
        for (NSOperation* op in queue.operations) {
            if ([op isKindOfClass:[TestOperation class]]) {
                ((TestOperation*) op).finished = YES;
            }
        }
    }
    [queue waitUntilAllOperationsAreFinished];
    
    [super tearDown];
}

- (void) runOp:(TestOperation*)op
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        double delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
            NSOperationQueue* q = [[NSOperationQueue alloc] init];
            NSURLSession* session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:q];
            //            session.delegate = self;
            NSURLSessionDataTask* task = [session dataTaskWithURL:[NSURL URLWithString:@"http://localhost:3000/locations"]];
            if (op) {
                @synchronized (self) {
                    _d[task] = op;
                }
            }
            [task resume];
             
//            [[session dataTaskWithURL:[NSURL URLWithString:@"http://localhost:3000/locations"]
//              
//                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
//                op.finished = YES;
//                NSLog(@"%@ done", op);
//                _count++;
//                self.done = (_count==3);
//            }] resume];
            
        });
        
    });

}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    TestOperation* op = nil;
    @synchronized (self) {
        op = _d[task];
    }
    op.finished = YES;
    NSLog(@"%@ done", op);
    _count++;
    self.done = (_count==3);
}

- (void) makeAndRunOp
{
    TestOperation* op = [[TestOperation alloc] init];
    __weak TestOperation* opWeak = op;
    op.block = ^{
        [self runOp:opWeak];
    };
    [queue addOperation:op];
}

- (void)testExample
{
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7" options:NSNumericSearch] == NSOrderedAscending) {
        return;
    }
    
    NSLog(@"COUNT %d", (int)queue.operationCount);
    NSLog(@"ITEMS %@", queue.operations);
    
    self.done = NO;
    
    [self makeAndRunOp];
    [self makeAndRunOp];
    [self makeAndRunOp];
    
    [self poll];

    
    XCTAssertEqual(_count, 3, @".");
}

- (void) testThreadTestDataStore
{
    KCSClientConfiguration* config = [KCSClientConfiguration configurationWithAppKey:@"kid_TTmaAVkCeO" secret:@"c194704457f5479e869c3c57d56deaae"];
    [[KCSClient sharedClient] initializeWithConfiguration:config];
    [KCSClient configureLoggingWithNetworkEnabled:YES debugEnabled:YES traceEnabled:YES warningEnabled:YES errorEnabled:YES];
    
    __weak XCTestExpectation* expectationLogin = [self expectationWithDescription:@"login"];
    [KCSUser loginWithUsername:@"roger" password:@"roger" withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
//        XCTAssertNil(errorOrNil, @"error should be nil");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationLogin fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak XCTestExpectation* expectationLoad = [self expectationWithDescription:@"load"];
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:[KCSCollection userCollection] options:nil];

    NSArray* toFetch = @[@"523a0b3fd4af557103001771",@"523a0b3fd4af557103001771",@"523c4c2371037d725e007dac",@"523c4c2371037d725e007dac",@"523c4c2371037d725e007dac",@"523c4c2371037d725e007dac",@"523c4c2371037d725e007dac",@"523c4c2371037d725e007dac",@"523c4c2371037d725e007dac"];
    for (NSString* anId in toFetch){
        [store loadObjectWithID:anId withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
//            XCTAssertNil(errorOrNil, @"no error");
            
            XCTAssertTrue([NSThread isMainThread]);
            
            if (++_count == toFetch.count) {
                [expectationLoad fulfill];
            }
        } withProgressBlock:^(NSArray *objects, double percentComplete) {
            XCTAssertTrue([NSThread isMainThread]);
        }];
    }
    
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

@end
