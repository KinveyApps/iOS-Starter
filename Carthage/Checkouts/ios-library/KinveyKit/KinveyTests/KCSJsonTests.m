//
//  KCSJsonTests.m
//  KinveyKit
//
//  Created by Victor Barros on 2016-04-07.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSDictionary+KinveyAdditions.h"
#import "KCSObjectMapper.h"
#import "Event.h"

@interface KCSJsonTests : XCTestCase

@end

@implementation KCSJsonTests

- (void)testJsonParser
{
    NSDictionary* jsonObject = @{
        @"_socialIdentity" : @{
            @"facebook" : @{
                @"access_token" : [NSUUID UUID].UUIDString,
                @"appid" : [NSUUID UUID].UUIDString,
                @"id" : [NSUUID UUID].UUIDString,
                @"name" : @"Victor Barros",
                @"email" : @"victor@kinvey.com",
                @"gender" : @"male",
            }
        },
        @"username" : [NSUUID UUID].UUIDString,
        @"password" : [NSUUID UUID].UUIDString,
        @"_kmd" : @{
            @"lmt" : @"2016-04-07T20:22:46.373Z",
            @"ect" : @"2016-04-07T20:22:46.373Z",
            @"authtoken" : [NSUUID UUID].UUIDString
        },
        @"_id" : [NSUUID UUID].UUIDString,
        @"_acl" : @{
            @"creator" : [NSUUID UUID].UUIDString
        }
    };
    NSData* data = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                   options:0
                                                     error:nil];
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data
                                                         options:0
                                                           error:nil];
    XCTAssertEqualObjects(NSStringFromClass([json class]), @"__NSCFDictionary");
    NSString* jsonString = [json kcsJSONStringRepresentation:nil];
    XCTAssertNotNil(jsonString);
}

- (void)testDateToJson
{
    NSDictionary* jsonObject = @{
        @"date" : [NSDate dateWithTimeIntervalSince1970:1451703845.006]
    };
    NSError* error = nil;
    NSString* json = [jsonObject kcsJSONStringRepresentation:&error];
    
    XCTAssertNil(error);
    XCTAssertNotNil(json);
    XCTAssertEqualObjects(json, @"{\"date\":\"ISODate(\\\"2016-01-02T03:04:05.006Z\\\")\"}");
}

- (void)testDateMillisecondsFromJson
{
    NSString* json = @"{\"date\":\"ISODate(\\\"2016-01-02T03:04:05.006Z\\\")\"}";
    NSData* data = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error = nil;
    NSDictionary* jsonObject = [NSDictionary transformValue:[NSJSONSerialization JSONObjectWithData:data
                                                                                            options:0
                                                                                              error:&error]];
    XCTAssertNil(error);
    XCTAssertNotNil(jsonObject);
    NSDictionary* expected = @{ @"date" : [NSDate dateWithTimeIntervalSince1970:1451703845.006] };
    Event* event = [KCSObjectMapper makeObjectOfType:[Event class]
                                            withData:jsonObject
                              withResourceDictionary:[NSMutableDictionary dictionary]
                                              object:nil];
    XCTAssertEqualObjects(event.date, expected[@"date"]);
}

- (void)testDateFromJson
{
    NSString* json = @"{\"date\":\"ISODate(\\\"2016-01-02T03:04:05Z\\\")\"}";
    NSData* data = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error = nil;
    NSDictionary* jsonObject = [NSDictionary transformValue:[NSJSONSerialization JSONObjectWithData:data
                                                                                            options:0
                                                                                              error:&error]];
    XCTAssertNil(error);
    XCTAssertNotNil(jsonObject);
    NSDictionary* expected = @{ @"date" : [NSDate dateWithTimeIntervalSince1970:1451703845] };
    Event* event = [KCSObjectMapper makeObjectOfType:[Event class]
                                            withData:jsonObject
                              withResourceDictionary:[NSMutableDictionary dictionary]
                                              object:nil];
    XCTAssertEqualObjects(event.date, expected[@"date"]);
}

@end
