//
//  KCSJsonTest.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-10-28.
//  Copyright © 2015 Kinvey. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface KCSJsonTest : XCTestCase

@end

@implementation KCSJsonTest

-(void)testJsonArray
{
    NSString* cdata = @"[{\"date\":\"ISODate(\\\"2013-06-21T12:51:38.969Z\\\")\",\"objCount\":10,\"objDescription\":\"one\",\"_acl\":{\"creator\":\"51c44c5982cd0ade36000012\"},\"_kmd\":{\"lmt\":\"2013-06-21T12:51:37.817Z\",\"ect\":\"2013-06-21T12:51:37.817Z\"},\"_id\":\"51c44c5982cd0ade36000013\"},{\"date\":\"ISODate(\\\"2013-06-21T12:51:38.969Z\\\")\",\"objCount\":10,\"objDescription\":\"two\",\"_acl\":{\"creator\":\"51c44c5982cd0ade36000012\"},\"_kmd\":{\"lmt\":\"2013-06-21T12:51:37.818Z\",\"ect\":\"2013-06-21T12:51:37.818Z\"},\"_id\":\"51c44c5982cd0ade36000014\"},{\"date\":\"ISODate(\\\"2013-06-21T12:51:38.969Z\\\")\",\"objCount\":10,\"objDescription\":\"two\",\"_acl\":{\"creator\":\"51c44c5982cd0ade36000012\"},\"_kmd\":{\"lmt\":\"2013-06-21T12:51:37.819Z\",\"ect\":\"2013-06-21T12:51:37.819Z\"},\"_id\":\"51c44c5982cd0ade36000015\"},{\"_acl\":{\"creator\":\"kid10005\"},\"_kmd\":{\"lmt\":\"2013-08-07T02:22:50.154Z\",\"ect\":\"2013-08-07T02:22:50.154Z\"},\"_id\":\"5201af7a3bb9501365000025\"},{\"_acl\":{\"creator\":\"506f3c35aa9734091d0000ee\"},\"_kmd\":{\"lmt\":\"2013-08-07T02:23:02.122Z\",\"ect\":\"2013-08-07T02:23:02.122Z\"},\"_id\":\"5201af863bb9501365000026\"},{\"_acl\":{\"creator\":\"kid10005\"},\"_kmd\":{\"lmt\":\"2013-09-24T19:14:55.984Z\",\"ect\":\"2013-09-24T19:14:55.984Z\"},\"_id\":\"5241e4af8daed3725400009c\"},{\"abc\":\"1\",\"_acl\":{\"creator\":\"kid10005\"},\"_kmd\":{\"lmt\":\"2013-09-24T19:15:02.536Z\",\"ect\":\"2013-09-24T19:15:02.536Z\"},\"_id\":\"5241e4b68daed3725400009d\"},{\"abc\":\"true\",\"_acl\":{\"creator\":\"kid10005\"},\"_kmd\":{\"lmt\":\"2013-09-24T19:15:11.263Z\",\"ect\":\"2013-09-24T19:15:11.263Z\"},\"_id\":\"5241e4bf8daed3725400009e\"}]";
    
    //SBJson                0.150 sec (14% STDEV)
    //NSJSONSerialization   0.014 sec (57% STDEV)
    [self measureBlock:^{
        for (int i = 0; i < 100; i++) {
            NSError* error = nil;
            NSMutableArray* entities = [NSJSONSerialization JSONObjectWithData:[cdata dataUsingEncoding:NSUTF8StringEncoding]
                                                                       options:NSJSONReadingMutableContainers
                                                                         error:&error];
            XCTAssertNotNil(entities, @"Should have data to import: %@", error);
        }
    }];
}

@end
