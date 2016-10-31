//
//  KinveyKitBase64Tests.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/17/12.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import "KinveyKitBase64Tests.h"
#import "KCSBase64.h"

@implementation KinveyKitBase64Tests

- (void)testBase64Enc
{
    NSString *expectedString = @"QWxhZGRpbjpvcGVuIHNlc2FtZQ==";
    NSString *string = @"Aladdin:open sesame";
    NSString *b64 = [[string dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
    
    XCTAssertEqualObjects(b64, expectedString, @"");
}

- (void)testBase64Dec
{
    NSString *string = @"QWxhZGRpbjpvcGVuIHNlc2FtZQ==";
    NSString *expectedString = @"Aladdin:open sesame";
    NSData *b64 = [[NSData alloc] initWithBase64EncodedString:string options:0];
    NSString *actual = [NSString stringWithUTF8String:[b64 bytes]];
    
    XCTAssertEqualObjects(actual, expectedString, @"");
}

- (void)testStringsHaveNoBreaks
{
    NSString *expectedString = @"N0M5MUU2RTMtNDlFMy01RUNELUI2NjAtNUU5NDA0REVEMTUwOmIzOTI3MjM4LTViNTctNDQ5ZS1hMjdmLWZiNjM3ZDhhNWU4Yg==";
    NSString *string = @"7C91E6E3-49E3-5ECD-B660-5E9404DED150:b3927238-5b57-449e-a27f-fb637d8a5e8b";
    NSString *b64 = [[string dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
    XCTAssertEqualObjects(b64, expectedString, @"");
    
    // Round trip
    NSData *bd64 = [[NSData alloc] initWithBase64EncodedString:expectedString options:0];
    NSString *actual = [[NSString alloc] initWithData:bd64 encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(actual, string, @"");
}

-(void)testBasicAuthString
{
    NSString *expectedString = @"Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==";
    NSString *b64 = KCSbasicAuthString(@"Aladdin", @"open sesame");
    XCTAssertEqualObjects(b64, expectedString);
}

@end
