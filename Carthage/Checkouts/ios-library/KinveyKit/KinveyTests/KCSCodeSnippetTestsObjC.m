////
////  KCSCodeSnippetTests.m
////  KinveyKit
////
////  Created by Victor Barros on 2015-03-26.
////  Copyright (c) 2015 Kinvey. All rights reserved.
////
//
//#import <UIKit/UIKit.h>
//#import <XCTest/XCTest.h>
//#import "KinveyKit.h"
//
//@interface KCSCodeSnippetTestsObjC : KCSTestCase
//
//@property (nonatomic, strong) id<KCSStore> store;
//@property (nonatomic, strong) NSDictionary* obj;
//
//@end
//
//@implementation KCSCodeSnippetTestsObjC
//
//@synthesize store = store;
//@synthesize obj = obj;
//
//- (void)setUp {
//    [super setUp];
//    // Put setup code here. This method is called before the invocation of each test method in the class.
//}
//
//- (void)tearDown {
//    // Put teardown code here. This method is called after the invocation of each test method in the class.
//    [super tearDown];
//}
//
//- (void)testDevCenter_ios_downloads_changelog_1_29_0 {
//    //global
//    KCSRequestConfiguration* requestConfiguration = [KCSRequestConfiguration requestConfigurationWithClientAppVersion:@"2.0"
//                                                                                           andCustomRequestProperties:@{@"lang" : @"fr",
//                                                                                                                        @"globalProperty" : @"abc"}];
//    KCSClientConfiguration* clientConfiguration = [KCSClientConfiguration configurationWithAppKey:@"<#Your App Key#>"
//                                                                                           secret:@"<#Your App Secret#>"
//                                                                                          options:nil //***************<#Your Options#>
//                                                                             requestConfiguration:requestConfiguration];
//    
//    [[KCSClient sharedClient] initializeWithConfiguration:clientConfiguration];
//    
//    //per request
//    KCSRequestConfiguration* requestConfig = [KCSRequestConfiguration requestConfigurationWithClientAppVersion:@"1.0"
//                                                                                    andCustomRequestProperties:@{@"lang" : @"pt",
//                                                                                                                 @"requestProperty" : @"123"}];
//    [store saveObject:obj
// requestConfiguration:requestConfig
//  withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
//      //do something awesome here!
//  } withProgressBlock:nil];
//}
//
//@end
