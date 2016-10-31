//
//  FileRequestTests.m
//  KinveyKit
//
//  Created by Michael Katz on 9/24/13.
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

#import "KinveyCoreInternal.h"
#import "KinveyFileStoreInteral.h"

#import "TestUtils2.h"

#define publicFileURL @"http://storage.googleapis.com/kinvey_staging_4b4b2dd210ba4b7d8b7ae5342176b137/67a183fc-b08d-4af6-a6ed-69fd688ce920/mavericks.jpg"
#define kImageSize 3510397

/* Test File loading irrespective of KCS blob service */
@interface FileRequestTests : KCSTestCase

@end

@implementation FileRequestTests

- (void)setUp
{
    [super setUp];
    [self setupKCS:YES];
}

- (void)testDownloadStream
{
    KCSFileRequestManager* f = [[KCSFileRequestManager alloc] init];
    KCSFile* file = [[KCSFile alloc] init];
    NSString* fileStr = @"/tmp/123.jpg";
    file.localURL = [KCSFileUtils fileURLForName:fileStr];
    [[NSFileManager defaultManager] removeItemAtURL:file.localURL error:NULL];
    
    __weak __block XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    
    [f downloadStream:file
              fromURL:[NSURL URLWithString:publicFileURL]
  alreadyWrittenBytes:@0
 requestConfiguration:nil
      completionBlock:^(BOOL done, NSDictionary *returnInfo, NSError *error)
    {
        KTAssertNoError
        long bytes = [returnInfo[@"bytesWritten"] longValue];
        NSDictionary* d = [[NSFileManager defaultManager] attributesOfItemAtPath:[file.localURL path] error:NULL];
        NSNumber* fileOnDiskSize = d[NSFileSize];
        XCTAssertEqual(bytes, (long)kImageSize, @"bytes downloaded should match");
        XCTAssertEqual(bytes, [fileOnDiskSize longValue], @"bytes should also match");
        XCTAssertFalse([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete, NSDictionary *additionalContext)
    {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDownload = nil;
    }];
}

- (void)testDownloadStreamCancel
{
    KCSFileRequestManager* f = [[KCSFileRequestManager alloc] init];
    KCSFile* file = [[KCSFile alloc] init];
    NSString* fileStr = @"/tmp/123.jpg";
    file.localURL = [KCSFileUtils fileURLForName:fileStr];
    [[NSFileManager defaultManager] removeItemAtURL:file.localURL error:NULL];
    
    __weak __block XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    
    [f downloadStream:file
              fromURL:[NSURL URLWithString:publicFileURL]
  alreadyWrittenBytes:@0
 requestConfiguration:nil
      completionBlock:^(BOOL done, NSDictionary *returnInfo, NSError *error)
    {
        KTAssertNoError
        long bytes = [returnInfo[@"bytesWritten"] longValue];
        NSDictionary* d = [[NSFileManager defaultManager] attributesOfItemAtPath:[file.localURL path] error:NULL];
        NSNumber* fileOnDiskSize = d[NSFileSize];
        XCTAssertEqual(bytes, (long)kImageSize, @"bytes downloaded should match");
        XCTAssertEqual(bytes, [fileOnDiskSize longValue], @"bytes should also match");
        XCTAssertFalse([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete, NSDictionary *additionalContext)
    {
         XCTAssertTrue([NSThread isMainThread]);
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDownload = nil;
    }];
}

@end
