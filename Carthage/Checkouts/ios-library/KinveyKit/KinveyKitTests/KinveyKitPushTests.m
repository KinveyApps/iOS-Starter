//
//  KinveyKitPushTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/5/12.
//  Copyright (c) 2012-2015 Kinvey. All rights reserved.
//

#import "KinveyKitPushTests.h"
#import "KCSPush.h"
#import "KinveyUser.h"
#import "TestUtils.h"
#import "NSString+KinveyAdditions.h"
#import "KCSHiddenMethods.h"



@interface KinveyKitPushTests()
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSData* tokenData;

@end

@implementation KinveyKitPushTests

/////////
// NB: This is really difficult to test as none of the backend stuff gets called
//     on apple's simulator, so we need to run the tests on a device, but then
//     they'll fail in CI, unless we check to see if we're on the simulator, but
//     then we don't test the routines at all...
//     Not sure how to fix this yet...
/////////

// All code under test must be linked into the Unit Test bundle
NSData* dataForTokenString(NSString* token)
{
    NSMutableData *tokenData = [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < token.length / 2; i++) {
        byte_chars[0] = [token characterAtIndex:i*2];
        byte_chars[1] = [token characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [(NSMutableData*)tokenData appendBytes:&whole_byte length:1];
    }
    return tokenData;
}

- (void)setUp
{
    [super setUp];
    
    XCTAssertTrue([TestUtils setUpKinveyUnittestBackend:self], @"should be set up");
    
    _token = [NSString stringWithFormat:@"d4011af80d8cc2623f361d074a3c0a63162cc524bd18c4c07fbe05ebd074c62%d", arc4random() % 10];
    _tokenData = [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < _token.length / 2; i++) {
        byte_chars[0] = [_token characterAtIndex:i*2];
        byte_chars[1] = [_token characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [(NSMutableData*)_tokenData appendBytes:&whole_byte length:1];
    }

}

- (void)testSharedPushReturnsInitializedSingleton{
    KCSPush *push = [KCSPush sharedPush];
    XCTAssertNotNil(push, @"should have a push value");
}

//- (void) testAddTokenNormalFlow
//{
//    KCSUser* myUser = [KCSUser activeUser];
//    XCTAssertNotNil(myUser, @"start with valid user");
//    
//    NSSet* tokens = myUser.deviceTokens;
//    XCTAssertNotNil(tokens, @"should have no token");
//    KTAssertCount(0, tokens);
//    
//    XCTestExpectation* expectationRegister = [self expectationWithDescription:@"register"];
//    [[KCSPush sharedPush] application:nil didRegisterForRemoteNotificationsWithDeviceToken:_tokenData completionBlock:^(BOOL success, NSError *error) {
//        STAssertNoError_;
//        XCTAssertTrue(success, @"should register new token");
//        
//        XCTAssertTrue([NSThread isMainThread]);
//        
//        [expectationRegister fulfill];
//    }];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//    
//    //Test that local user was updated
//    
//    XCTAssertEqualObjects([KCSUser activeUser], myUser, @"still have same user");
//    NSSet* postTokens = myUser.deviceTokens;
//    XCTAssertNotNil(postTokens, @"should have no token");
//    KTAssertCount(1, postTokens);
//    NSString* setToken = [postTokens anyObject];
//    XCTAssertEqualObjects(setToken, _token, @"token was set");
//    
//    //Test that server object was updated
//    
//    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:[KCSCollection userCollection] options:nil];
//    XCTestExpectation* expectationLoad = [self expectationWithDescription:@"load"];
//    [store loadObjectWithID:[KCSUser activeUser].userId withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
//        STAssertNoError
//        STAssertObjects(1)
//        KCSUser* loadedUser = objectsOrNil[0];
//        
//        NSSet* loadedTokens = loadedUser.deviceTokens;
//        XCTAssertNotNil(loadedTokens, @"should have no token");
//        KTAssertCount(1, loadedTokens);
//        NSString* loadedToken = [loadedTokens anyObject];
//        XCTAssertEqualObjects(loadedToken, _token, @"token was set");
//        
//        XCTAssertTrue([NSThread isMainThread]);
//        
//        [expectationLoad fulfill];
//    } withProgressBlock:^(NSArray *objects, double percentComplete) {
//        XCTAssertTrue([NSThread isMainThread]);
//    }];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//}

//- (void) testUserGetsTokenIfPreRegistered
//{
//    [[KCSUser activeUser] logout];
//
//    XCTestExpectation* expectationRegister = [self expectationWithDescription:@"register"];
//    [[KCSPush sharedPush] application:nil didRegisterForRemoteNotificationsWithDeviceToken:_tokenData completionBlock:^(BOOL success, NSError *error) {
//        STAssertNoError_;
//        XCTAssertFalse(success, @"should not register new token");
//        
//        XCTAssertTrue([NSThread isMainThread]);
//        
//        [expectationRegister fulfill];
//    }];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//    
//    //create new user after setting the token
//    
//    XCTestExpectation* expectationCreateAutogeneratedUser = [self expectationWithDescription:@"createAutogeneratedUser"];
//    [KCSUser createAutogeneratedUser:nil completion:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
//        STAssertNoError
//        
//        XCTAssertTrue([NSThread isMainThread]);
//        
//        [expectationCreateAutogeneratedUser fulfill];
//    }];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//    
//    KCSUser* myUser = [KCSUser activeUser];
//    XCTAssertNotNil(myUser, @"have a valid user");
//    
//    NSSet* tokens = myUser.deviceTokens;
//    XCTAssertNotNil(tokens, @"should have no token");
//    KTAssertCount(1, tokens);
//    NSString* aToken = [tokens anyObject];
//    XCTAssertEqualObjects(aToken, _token, @"token was set proprely");
//
//    //Test that server object was updated
//    
//    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:[KCSCollection userCollection] options:nil];
//    XCTestExpectation* expectationLoad = [self expectationWithDescription:@"load"];
//    [store loadObjectWithID:[KCSUser activeUser].userId withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
//        STAssertNoError
//        STAssertObjects(1)
//        KCSUser* loadedUser = objectsOrNil[0];
//        
//        NSSet* loadedTokens = loadedUser.deviceTokens;
//        XCTAssertNotNil(loadedTokens, @"should have no token");
//        KTAssertCount(1, loadedTokens);
//        NSString* loadedToken = [loadedTokens anyObject];
//        XCTAssertEqualObjects(loadedToken, _token, @"token was set");
//        
//        XCTAssertTrue([NSThread isMainThread]);
//        
//        [expectationLoad fulfill];
//    } withProgressBlock:^(NSArray *objects, double percentComplete) {
//        XCTAssertTrue([NSThread isMainThread]);
//    }];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//
//}

- (void) testRemoveNormalFlow
{
    KCSUser* myUser = [KCSUser activeUser];
    XCTAssertNotNil(myUser, @"start with valid user");
    
    NSSet* tokens = myUser.deviceTokens;
    XCTAssertNotNil(tokens, @"should have no token");
    KTAssertCount(0, tokens);
    
    __weak XCTestExpectation* expectationRegister = [self expectationWithDescription:@"register"];
    [[KCSPush sharedPush] application:nil didRegisterForRemoteNotificationsWithDeviceToken:_tokenData completionBlock:^(BOOL success, NSError *error) {
        STAssertNoError_;
        XCTAssertTrue(success, @"should register new token");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationRegister fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    //Test that local user was updated
    
    XCTAssertEqualObjects([KCSUser activeUser], myUser, @"still have same user");
    NSSet* postTokens = myUser.deviceTokens;
    XCTAssertNotNil(postTokens, @"should have no token");
    KTAssertCount(1, postTokens);
    NSString* setToken = [postTokens anyObject];
    XCTAssertEqualObjects(setToken, _token, @"token was set");
    
    // remove the token
    
    __weak XCTestExpectation* expectationUnRegister = [self expectationWithDescription:@"unRegister"];
    [[KCSPush sharedPush] unRegisterDeviceToken:^(BOOL success, NSError *error) {
        STAssertNoError_
        XCTAssertTrue(success, @"should remove the token");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationUnRegister fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    XCTAssertEqualObjects([KCSUser activeUser], myUser, @"still have same user");
    NSSet* postRemoveTokens = myUser.deviceTokens;
    XCTAssertNotNil(postRemoveTokens, @"should have no token");
    KTAssertCount(0, postRemoveTokens);
    
    //Test that server object was updated
    
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:[KCSCollection userCollection] options:nil];
    __weak XCTestExpectation* expectationLoad = [self expectationWithDescription:@"load"];
    [store loadObjectWithID:[KCSUser activeUser].userId withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertObjects(1)
        KCSUser* loadedUser = objectsOrNil[0];
        
        NSSet* loadedTokens = loadedUser.deviceTokens;
        XCTAssertNotNil(loadedTokens, @"should have no token");
        KTAssertCount(0, loadedTokens);
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationLoad fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

//- (void) testAddNewDoesntKillOld
//{
//    KCSUser* myUser = [KCSUser activeUser];
//    XCTAssertNotNil(myUser, @"start with valid user");
//    
//    NSSet* tokens = myUser.deviceTokens;
//    XCTAssertNotNil(tokens, @"should have no token");
//    KTAssertCount(0, tokens);
//    
//    XCTestExpectation* expectationRegister = [self expectationWithDescription:@"register"];
//    [[KCSPush sharedPush] application:nil didRegisterForRemoteNotificationsWithDeviceToken:_tokenData completionBlock:^(BOOL success, NSError *error) {
//        STAssertNoError_;
//        XCTAssertTrue(success, @"should register new token");
//        
//        XCTAssertTrue([NSThread isMainThread]);
//        
//        [expectationRegister fulfill];
//    }];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//    
//    //Test that local user was updated
//    
//    XCTAssertEqualObjects([KCSUser activeUser], myUser, @"still have same user");
//    NSSet* postTokens = myUser.deviceTokens;
//    XCTAssertNotNil(postTokens, @"should have no token");
//    KTAssertCount(1, postTokens);
//    NSString* setToken = [postTokens anyObject];
//    XCTAssertEqualObjects(setToken, _token, @"token was set");
//    
//    //add a second token
//    NSString* secondTokenString = [NSString stringWithFormat:@"c4011af80d8cc26aaa361d074a3c0a63162cc524bd18c4c07fbe05ebd074c62%d", arc4random() % 10];
//    NSData* secondTokenData = dataForTokenString(secondTokenString);
//
//    XCTestExpectation* expectationRegister2 = [self expectationWithDescription:@"register2"];
//    [[KCSPush sharedPush] application:nil didRegisterForRemoteNotificationsWithDeviceToken:secondTokenData completionBlock:^(BOOL success, NSError *error) {
//        STAssertNoError_;
//        XCTAssertTrue(success, @"should register new token");
//        
//        XCTAssertTrue([NSThread isMainThread]);
//        
//        [expectationRegister2 fulfill];
//    }];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//    
//    //Test that local user was updated
//    
//    XCTAssertEqualObjects([KCSUser activeUser], myUser, @"still have same user");
//    NSSet* postTokens2 = myUser.deviceTokens;
//    XCTAssertNotNil(postTokens2, @"should have no token");
//    KTAssertCount(2, postTokens2);
//    XCTAssertTrue([postTokens2.allObjects containsObject:[_token copy]], @"token was set");
//    XCTAssertTrue([postTokens2.allObjects containsObject:secondTokenString], @"token was set");
//    
//    
//    //Test that server object was updated
//    
//    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:[KCSCollection userCollection] options:nil];
//    XCTestExpectation* expectationLoad = [self expectationWithDescription:@"load"];
//    [store loadObjectWithID:[KCSUser activeUser].userId withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
//        STAssertNoError
//        STAssertObjects(1)
//        KCSUser* loadedUser = objectsOrNil[0];
//        
//        NSSet* loadedTokens = loadedUser.deviceTokens;
//        XCTAssertNotNil(loadedTokens, @"should have no token");
//        KTAssertCount(2, loadedTokens);
//        XCTAssertTrue([loadedTokens.allObjects containsObject:_token], @"token was set");
//        XCTAssertTrue([loadedTokens.allObjects containsObject:secondTokenString], @"token was set");
//        
//        XCTAssertTrue([NSThread isMainThread]);
//        
//        [expectationLoad fulfill];
//    } withProgressBlock:^(NSArray *objects, double percentComplete) {
//        XCTAssertTrue([NSThread isMainThread]);
//    }];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//}
//
//- (void) testemoveDoesntKillOld
//{
//    KCSUser* myUser = [KCSUser activeUser];
//    XCTAssertNotNil(myUser, @"start with valid user");
//    
//    NSSet* tokens = myUser.deviceTokens;
//    XCTAssertNotNil(tokens, @"should have no token");
//    KTAssertCount(0, tokens);
//    
//    //add a first token
//    
//    XCTestExpectation* expectationRegister = [self expectationWithDescription:@"register"];
//    [[KCSPush sharedPush] application:nil didRegisterForRemoteNotificationsWithDeviceToken:_tokenData completionBlock:^(BOOL success, NSError *error) {
//        STAssertNoError_;
//        XCTAssertTrue(success, @"should register new token");
//        
//        XCTAssertTrue([NSThread isMainThread]);
//        
//        [expectationRegister fulfill];
//    }];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//    
//    //add a second token
//    NSString* secondTokenString = [NSString stringWithFormat:@"c4011af80d8cc26aaa361d074a3c0a63162cc524bd18c4c07fbe05ebd074c62%d", arc4random() % 10];
//    NSData* secondTokenData = dataForTokenString(secondTokenString);
//    
//    XCTestExpectation* expectationRegister2 = [self expectationWithDescription:@"register2"];
//    [[KCSPush sharedPush] application:nil didRegisterForRemoteNotificationsWithDeviceToken:secondTokenData completionBlock:^(BOOL success, NSError *error) {
//        STAssertNoError_;
//        XCTAssertTrue(success, @"should register new token");
//        
//        XCTAssertTrue([NSThread isMainThread]);
//        
//        [expectationRegister2 fulfill];
//    }];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//    
//    //Test that local user was updated
//    
//    XCTAssertEqualObjects([KCSUser activeUser], myUser, @"still have same user");
//    NSSet* postTokens2 = myUser.deviceTokens;
//    XCTAssertNotNil(postTokens2, @"should have no token");
//    KTAssertCount(2, postTokens2);
//    XCTAssertTrue([postTokens2.allObjects containsObject:[_token copy]], @"token was set");
//    XCTAssertTrue([postTokens2.allObjects containsObject:secondTokenString], @"token was set");
//    
//    // Remove 2nd token
//    XCTestExpectation* expectationUnRegister = [self expectationWithDescription:@"unRegister"];
//    [[KCSPush sharedPush] unRegisterDeviceToken:^(BOOL success, NSError *error) {
//        STAssertNoError_
//        XCTAssertTrue(success, @"should be true");
//        
//        XCTAssertTrue([NSThread isMainThread]);
//        
//        [expectationUnRegister fulfill];
//    }];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//    
//    XCTAssertNil([[KCSPush sharedPush] deviceToken], @"should clear the token");
//    
//    NSSet* tokensAfterReg = myUser.deviceTokens;
//    XCTAssertNotNil(tokensAfterReg, @"should have no token");
//    KTAssertCount(1, tokensAfterReg);
//    NSString* aToken = [tokensAfterReg anyObject];
//    XCTAssertEqualObjects(aToken, _token, @"token was set proprely");
//    
//    //Test that server object was updated
//    
//    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:[KCSCollection userCollection] options:nil];
//    XCTestExpectation* expectationLoad = [self expectationWithDescription:@"load"];
//    [store loadObjectWithID:[KCSUser activeUser].userId withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
//        STAssertNoError
//        STAssertObjects(1)
//        KCSUser* loadedUser = objectsOrNil[0];
//        
//        NSSet* loadedTokens = loadedUser.deviceTokens;
//        XCTAssertNotNil(loadedTokens, @"should have no token");
//        KTAssertCount(1, loadedTokens);
//        NSString* loadedToken = [loadedTokens anyObject];
//        XCTAssertEqualObjects(loadedToken, _token, @"token was set");
//        
//        XCTAssertTrue([NSThread isMainThread]);
//        
//        [expectationLoad fulfill];
//    } withProgressBlock:^(NSArray *objects, double percentComplete) {
//        XCTAssertTrue([NSThread isMainThread]);
//    }];
//    [self waitForExpectationsWithTimeout:30 handler:nil];
//}

- (void) testExistingOneDoesntTransferToNew
{
    NSString* myUser = [KCSUser activeUser].userId;
    XCTAssertNotNil(myUser, @"start with valid user");
    
    NSSet* tokens = [KCSUser activeUser].deviceTokens;
    XCTAssertNotNil(tokens, @"should have no token");
    KTAssertCount(0, tokens);
    
    __weak XCTestExpectation* expectationRegister = [self expectationWithDescription:@"register"];
    [[KCSPush sharedPush] application:nil didRegisterForRemoteNotificationsWithDeviceToken:_tokenData completionBlock:^(BOOL success, NSError *error) {
        STAssertNoError_;
        XCTAssertTrue(success, @"should register new token");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationRegister fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    //Test that local user was updated
    XCTAssertEqualObjects([KCSUser activeUser].userId, myUser, @"still have same user");
    NSSet* postTokens = [KCSUser activeUser].deviceTokens;
    XCTAssertNotNil(postTokens, @"should have no token");
    KTAssertCount(1, postTokens);
    
    [[KCSUser activeUser] logout];
    
    XCTAssertNil([KCSUser activeUser].userId, @"user should be cleared");
    XCTAssertNil([[KCSPush sharedPush] deviceToken], @"Should be cleared");
    
    __weak XCTestExpectation* expectationCreateAutogeneratedUser = [self expectationWithDescription:@"createAutogeneratedUser"];
    [KCSUser createAutogeneratedUser:nil completion:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
        STAssertNoError
        XCTAssertNotNil([KCSUser activeUser], @"user is real");
        KTAssertCount(0, [KCSUser activeUser].deviceTokens);
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationCreateAutogeneratedUser fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];

    //verify server user
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:[KCSCollection userCollection] options:nil];
    __weak XCTestExpectation* expectationLoad = [self expectationWithDescription:@"load"];
    [store loadObjectWithID:[KCSUser activeUser].userId withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertObjects(1)
        KCSUser* loadedUser = objectsOrNil[0];
        
        NSSet* loadedTokens = loadedUser.deviceTokens;
        XCTAssertNotNil(loadedTokens, @"should have no token");
        KTAssertCount(0, loadedTokens);
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationLoad fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

@end
