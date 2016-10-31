//
//  FileUtilsTest.m
//  KinveyKit
//
//  Created by Michael Katz on 12/5/13.
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

#import "KCSTestCase.h"

#import "KCSFileUtils.h"

@interface FileUtilsTest : KCSTestCase

@end

@implementation FileUtilsTest

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testClearFiles
{
    NSURL* filesDir = [KCSFileUtils filesFolder];
    
    BOOL isDir;
    BOOL filesDirExists = [[NSFileManager defaultManager] fileExistsAtPath:[filesDir path] isDirectory:&isDir];
    XCTAssertTrue(filesDirExists, @"Files dir should be there");
    XCTAssertTrue(isDir, @"should be a dir");
    
    NSData* d = [@"afasdfasfasdfasdfasfad" dataUsingEncoding:NSUTF16StringEncoding];
    NSString* dataFile = [[filesDir URLByAppendingPathComponent:@"abc.txt"] path];
    [d writeToFile:dataFile atomically:YES];
    
    BOOL dataExists = [[NSFileManager defaultManager] fileExistsAtPath:dataFile isDirectory:NO];
    XCTAssertTrue(dataExists, @"file should be there");
    
    BOOL deleted = [KCSFileUtils clearFiles];
    XCTAssertTrue(deleted, @"should be cleared");
    
    BOOL dataExists2 = [[NSFileManager defaultManager] fileExistsAtPath:dataFile isDirectory:NO];
    XCTAssertFalse(dataExists2, @"file should be there");

    BOOL filesDirExists2 = [[NSFileManager defaultManager] fileExistsAtPath:[filesDir path] isDirectory:NO];
    XCTAssertTrue(filesDirExists2, @"Files dir should be there");
}


@end
