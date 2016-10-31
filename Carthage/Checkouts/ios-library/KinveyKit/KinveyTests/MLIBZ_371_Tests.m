//
//  MLIBZ_371_Tests.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-06-04.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KCSTestCase.h"
#import <KinveyKit/KinveyKit.h>

@interface MLIBZ_371_Tests : KCSTestCase

@end

@implementation MLIBZ_371_Tests

- (void)setUp {
    [super setUp];
    
    [[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid_Z1nKQD1KT"
                                                 withAppSecret:@"f01e4f4f81bf4c919e83bee54fe945bd"
                                                  usingOptions:nil];
    
    __weak XCTestExpectation* expectationLogin = [self expectationWithDescription:@"login"];
    
//    [KCSUser loginWithUsername:@"4a51dbe2-cbfe-42c2-837b-0c81f533ac19" password:@"fb882daa-9168-4e00-a49c-57e35a9e74e4" withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result)
//    {
//        XCTAssertNotNil(user);
//        XCTAssertNil(errorOrNil);
//        
//        [expectationLogin fulfill];
//    }];
    
    [KCSUser loginWithAuthorizationCodeAPI:@"http://us-staging.merial.com/kinvey/api/Authenticate"
                                   options:@{@"username" : @"MerialKinveyjeppe6", @"password" : @"12345678"}
                       withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result)
    {
        XCTAssertNotNil(user);
        XCTAssertNil(errorOrNil);

        [expectationLogin fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void)tearDown {
    [[KCSUser activeUser] logout];
    
    [super tearDown];
}

- (void)test {
    KCSCollection *collection = [KCSCollection collectionFromString:@"Pet" ofClass:[NSMutableDictionary class]];
    KCSCachedStore *store =[KCSCachedStore storeWithCollection:collection options:nil];
    
    __block NSString *petID = @"2c4f04d3-9c09-e511-9477-005056a51cd0";
    
    __weak XCTestExpectation* expectationLoad = [self expectationWithDescription:@"load"];
    __weak XCTestExpectation* expectationSave = [self expectationWithDescription:@"save"];
    
    [store loadObjectWithID:petID withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        NSLog(@"Loaded pet %@", petID);
        NSMutableDictionary *loadedPet = objectsOrNil[0];
        [store saveObject:loadedPet withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
            if (errorOrNil) {
                NSLog(@"Failed saving pet: %@", errorOrNil);
            } else {
                NSLog(@"Saving pet succeded");
            }
            
            [expectationSave fulfill];
            
        } withProgressBlock:nil];
        
        [expectationLoad fulfill];
        
    } withProgressBlock:nil];
    
    [self waitForExpectationsWithTimeout:300 handler:nil];
}

@end
