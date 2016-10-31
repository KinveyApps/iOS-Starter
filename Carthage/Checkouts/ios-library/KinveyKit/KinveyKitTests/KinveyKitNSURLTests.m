//
//  KinveyKitNSURLTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/5/12.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import "KinveyKitNSURLTests.h"
#import "NSURL+KinveyAdditions.h"

@implementation KinveyKitNSURLTests

- (void)testURLByAppendingQueryString
{
    // Test empty String + empty string
    NSURL *emptyURL = [NSURL URLWithString:@""];
    XCTAssertEqualObjects([emptyURL URLByAppendingQueryString:@""], emptyURL, @"");
    
    
    // Test empty string + value
    NSURL *testURL = [NSURL URLWithString:@"?value"];
    XCTAssertEqualObjects([emptyURL URLByAppendingQueryString:@"value"], testURL, @"");
    
    // Test Value + empty string
    testURL = [NSURL URLWithString:@"http://www.kinvey.com/"];
    XCTAssertEqualObjects([testURL URLByAppendingQueryString:@""], testURL, @"");

    // Test nil
    XCTAssertEqualObjects([testURL URLByAppendingQueryString:nil], testURL, @"");

    // Test simple query
    NSURL *rootURL = [NSURL URLWithString:@"http://www.kinvey.com/"];
    testURL = [NSURL URLWithString:@"http://www.kinvey.com/?test"];
    XCTAssertEqualObjects([rootURL URLByAppendingQueryString:@"test"], testURL, @"");
    
    // Test double append
    testURL = [NSURL URLWithString:@"http://www.kinvey.com/?one=1&two=2"];    
    XCTAssertEqualObjects([[rootURL URLByAppendingQueryString:@"one=1"] URLByAppendingQueryString:@"two=2"], testURL, @"");
}

- (void)testURLWithUnencodedString
{
    NSString *unEncoded = @"!#$&'()*+,/:;=?@[]{} %";
    NSString *encoded = @"%21%23%24%26%27%28%29%2A%2B%2C%2F%3A%3B%3D%3F%40%5B%5D%7B%7D%20%25";

    NSURL *one = [NSURL URLWithString:encoded];
    NSURL *two = [NSURL URLWithUnencodedString:unEncoded];
    
    XCTAssertEqualObjects(two, one, @"");
}
@end
