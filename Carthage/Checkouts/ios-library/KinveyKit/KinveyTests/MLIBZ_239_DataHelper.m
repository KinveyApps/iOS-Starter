//
//  DataHelper.m
//  ContentBox
//
//  Created by Igor Sapyanik on 14.01.14.
/**
 * Copyright (c) 2015 Kinvey Inc. *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at *
 * http://www.apache.org/licenses/LICENSE-2.0 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License. *
 */

#import "MLIBZ_239_DataHelper.h"

#define KINVEY_APP_KEY @"kid_-1WAs8Rh2"
#define KINVEY_APP_SECRET @"2f355bfaa8cb4f7299e914e8e85d8c98"

#define QUOTES_COLLECTIONS_NAME @"quotes"
#define ORDERS_COLLECTIONS_NAME @"orders"
#define PRODUCTS_COLLECTIONS_NAME @"products"

#define USER_INFO_KEY_CONTACT @"contact"
#define USER_INFO_KEY_COMPANY @"company"
#define USER_INFO_KEY_ACCOUNT_NUMBER @"account_number"
#define USER_INFO_KEY_PHONE @"phone"
#define USER_INFO_KEY_PUSH_NOTIFICATION_ENABLE @"push_notification_enable"
#define USER_INFO_KEY_EMAIL_CONFIRMATION_ENABLE @"email_confirmation_enable"
#define USER_INFO_KEY_EMAIL @"email"

@implementation MLIBZ_239_Quote

+(NSArray *)textFieldsName
{
    return @[ @"reference", @"activeUsers" ];
}

-(NSDictionary *)hostToKinveyPropertyMapping
{
    return @{
        @"objectId" : KCSEntityKeyId,
        @"reference" : @"reference",
        @"originator" : @"originator",
        @"activeUsers" : @"activeUsers"
    };
}

+ (NSDictionary *)kinveyPropertyToCollectionMapping{
    //    backend field name:collection name
    //----------------------:---------------------------
    return @{ @"originator" : KCSUserCollectionName};             //product link to Products
}

-(NSString *)description
{
    return @{
        @"objectId" : self.objectId != nil ? self.objectId : [NSNull null],
        @"reference" : self.reference != nil ? self.reference : [NSNull null],
        @"originator" : self.originator != nil ? self.originator : [NSNull null],
        @"activeUsers" : self.activeUsers != nil ? self.activeUsers : [NSNull null]
    }.description;
}


@end

@implementation MLIBZ_239_Order

+(NSArray *)textFieldsName
{
    return @[];
}

@end

@implementation MLIBZ_239_Product

+(NSArray *)textFieldsName
{
    return @[];
}

@end

@interface MLIBZ_239_DataHelper ()

@property (nonatomic, strong) KCSLinkedAppdataStore *quotesStore;
@property (nonatomic, strong) KCSLinkedAppdataStore *ordersStore;
@property (nonatomic, strong) KCSLinkedAppdataStore *productsStore;
@property (nonatomic, strong) NSDictionary *contentTypesByName;

@end

@implementation MLIBZ_239_DataHelper

@synthesize formatter = _formatter;

//SYNTHESIZE_SINGLETON_FOR_CLASS(DataHelper)

+(instancetype)instance
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}


#pragma mark - Initialization

- (id)init {
    
	self = [super init];
    
	if (self) {
        
        //Kinvey: Here we initialize KCSClient instance
		(void)[[KCSClient sharedClient] initializeKinveyServiceForAppKey:KINVEY_APP_KEY
														   withAppSecret:KINVEY_APP_SECRET
															usingOptions:nil];
        
        //Kinvey: Here we define our collection to use
        //Quotes collection
        KCSCollection *collectionQuote = [KCSCollection collectionFromString:QUOTES_COLLECTIONS_NAME
                                                                     ofClass:[MLIBZ_239_Quote class]];
        self.quotesStore = [KCSLinkedAppdataStore storeWithOptions:@{ KCSStoreKeyResource       : collectionQuote,                  //collection
                                                                      KCSStoreKeyCachePolicy    : @(KCSCachePolicyNetworkFirst)}];  //default cache policy
        
        //Orders collection
        KCSCollection *collectionOrder = [KCSCollection collectionFromString:ORDERS_COLLECTIONS_NAME
                                                                     ofClass:[MLIBZ_239_Order class]];
        self.ordersStore = [KCSLinkedAppdataStore storeWithOptions:@{ KCSStoreKeyResource       : collectionOrder,                  //collection
                                                                      KCSStoreKeyCachePolicy    : @(KCSCachePolicyNetworkFirst)}];  //default cache policy
        
        //Products collection
        KCSCollection *collectionProduct = [KCSCollection collectionFromString:PRODUCTS_COLLECTIONS_NAME
                                                                       ofClass:[MLIBZ_239_Product class]];
        self.productsStore = [KCSLinkedAppdataStore storeWithOptions:@{ KCSStoreKeyResource      : collectionProduct,                //collection
                                                                       KCSStoreKeyCachePolicy   : @(KCSCachePolicyNetworkFirst)}];  //default cache policy
	}
    
	return self;
}


#pragma mark - Setters and Getters

- (NSDateFormatter *)formatter{
    
    if (!_formatter) {
        _formatter = [[NSDateFormatter alloc] init];
        [_formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [_formatter setDateStyle:NSDateFormatterShortStyle];
        [_formatter setTimeStyle:NSDateFormatterNoStyle];
    }
    
    return _formatter;
}


#pragma mark - Utils

- (NSString *)regexForContaintSubstring:(NSString *)substring{
    
    //Return string of regex format for search substring
    return [[@"^(?i).{0,}" stringByAppendingString:substring] stringByAppendingString:@".{0,}"];
}

- (KCSQuery *)queryForOriginatorEqualsActiveUser{
    
    //Kinvey: Built a query for filter entity with field originator is equal avctive Kinvey user
    return [KCSQuery queryOnField:@"originator._id"
           withExactMatchForValue:[KCSUser activeUser].userId];
    
//    return [KCSQuery queryOnField:@"_acl.creator"
//           withExactMatchForValue:[KCSUser activeUser].userId];
}

- (KCSQuery *)queryForSearchSubstring:(NSString *)substring inFields:(NSArray *)textFields{
    
    //Kinvey: Built complex query for filter entity which contains string field with substing
    KCSQuery *query = [KCSQuery queryOnField:textFields.firstObject
                                   withRegex:[self regexForContaintSubstring:substring]];
    
    for (NSInteger i = 1; i < textFields.count; i ++) {
        KCSQuery *fieldQuery = [KCSQuery queryOnField:textFields[i]
                                            withRegex:[self regexForContaintSubstring:substring]];
        query = [query queryByJoiningQuery:fieldQuery
                             usingOperator:kKCSOr];
    }
    
    return query;
}

- (NSArray *)allUserInfoKey{
    
    //Return attribute user key which use in app
    return @[USER_INFO_KEY_CONTACT,
             USER_INFO_KEY_COMPANY,
             USER_INFO_KEY_ACCOUNT_NUMBER,
             USER_INFO_KEY_PHONE,
             USER_INFO_KEY_PUSH_NOTIFICATION_ENABLE,
             USER_INFO_KEY_EMAIL_CONFIRMATION_ENABLE,
             USER_INFO_KEY_EMAIL];
}


#pragma mark - QUOTE
#pragma mark - Save and Load Entity

- (void)loadQuotesUseCache:(BOOL)useCache containtSubstinrg:(NSString *)substring OnSuccess:(void (^)(NSArray *))reportSuccess onFailure:(MLIBZ_239_STErrorBlock)reportFailure
{
    
    KCSQuery *query = [KCSQuery query];
    
    if (substring.length) {
        
        //Add search query
        query = [self queryForSearchSubstring:substring
                                     inFields:[MLIBZ_239_Quote textFieldsName]];
    }
    
    //Add originator query
    [query addQueryForJoiningOperator:kKCSAnd
                            onQueries:[self queryForOriginatorEqualsActiveUser], nil];
        
    //Kinvey: Load entity from Quote collection which correspond query
	[self.quotesStore queryWithQuery:query
                 withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
                     
                     //Return to main thread for update UI
                     dispatch_async(dispatch_get_main_queue(), ^{
                         if (!errorOrNil) {
                             if (reportSuccess) reportSuccess(objectsOrNil);
                         }else{
                             if (reportFailure) reportFailure(errorOrNil);
                         }
                     });
                     
                 }
                   withProgressBlock:nil
                         cachePolicy:useCache ? KCSCachePolicyLocalFirst : KCSCachePolicyNetworkFirst];
    
}

- (void)saveQuote:(MLIBZ_239_Quote *)quote OnSuccess:(void (^)(NSArray *))reportSuccess onFailure:(MLIBZ_239_STErrorBlock)reportFailure
{
    
    //Kinvey: Save object to Quote collection
    [self.quotesStore saveObject:quote
             withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
                 
                 //Return to main thread for update UI
                 dispatch_async(dispatch_get_main_queue(), ^{
                     if (errorOrNil != nil) {
                         if (reportFailure) reportFailure(errorOrNil);
                     } else {
                         if (reportSuccess) reportSuccess(objectsOrNil);
                     }
                 });
                 
             }
               withProgressBlock:nil];
    
}

- (void)deleteQuote:(MLIBZ_239_Quote *)quote onSuccess:(void (^)(BOOL))reportSuccess onFailure:(MLIBZ_239_STErrorBlock)reportFailure{
    
    [self.quotesStore removeObject:quote
               withCompletionBlock:^(unsigned long count, NSError *errorOrNil) {
                   
                   //Return to main thread for update UI
                   dispatch_async(dispatch_get_main_queue(), ^{
                       if (count != 1) {
                           if (reportFailure) reportFailure(errorOrNil);
                       } else {
                           if (reportSuccess) reportSuccess(YES);
                       }
                   });
               } withProgressBlock:nil];
}


#pragma mark - ORDER
#pragma mark - Save and Load Entity

- (void)loadOrdersUseCache:(BOOL)useCache containtSubstinrg:(NSString *)substring OnSuccess:(void (^)(NSArray *))reportSuccess onFailure:(MLIBZ_239_STErrorBlock)reportFailure{
    
    KCSQuery *query = [KCSQuery query];
    
    if (substring.length) {
        
        //Add search query
        query = [self queryForSearchSubstring:substring
                                     inFields:[MLIBZ_239_Order textFieldsName]];
    }
    
    //Add originator query
    [query addQueryForJoiningOperator:kKCSAnd
                            onQueries:[self queryForOriginatorEqualsActiveUser], nil];
    
    //Kinvey: Load entity from Orders collection which correspond query
    [self.ordersStore queryWithQuery:query
                 withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
                     
                     //Return to main thread for update UI
                     dispatch_async(dispatch_get_main_queue(), ^{
                         if (!errorOrNil) {
                             if (reportSuccess) reportSuccess(objectsOrNil);
                         }else{
                             if (reportFailure) reportFailure(errorOrNil);
                         }
                     });
                     
                 }
                   withProgressBlock:nil
                         cachePolicy:useCache ? KCSCachePolicyLocalFirst : KCSCachePolicyNetworkFirst];
    
}

- (void)saveOrder:(MLIBZ_239_Order *)order OnSuccess:(void (^)(NSArray *))reportSuccess onFailure:(MLIBZ_239_STErrorBlock)reportFailure{
    
    
    //Kinvey: Save object to Orders collection
    [self.ordersStore saveObject:order
             withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
                 
                 //Return to main thread for update UI
                 dispatch_async(dispatch_get_main_queue(), ^{
                     if (errorOrNil != nil) {
                         if (reportFailure) reportFailure(errorOrNil);
                     } else {
                         if (reportSuccess) reportSuccess(objectsOrNil);
                     }
                 });
                 
             }
               withProgressBlock:nil];
    
}

- (void)deleteOrder:(MLIBZ_239_Order *)order onSuccess:(void (^)(BOOL))reportSuccess onFailure:(MLIBZ_239_STErrorBlock)reportFailure{
    
    [self.ordersStore removeObject:order
               withCompletionBlock:^(unsigned long count, NSError *errorOrNil) {
                   
                   //Return to main thread for update UI
                   dispatch_async(dispatch_get_main_queue(), ^{
                       if (count != 1) {
                           if (reportFailure) reportFailure(errorOrNil);
                       } else {
                           if (reportSuccess) reportSuccess(YES);
                       }
                   });
               } withProgressBlock:nil];
}


#pragma mark - USER
#pragma mark - Save and Load Attributes

- (void)saveUserWithInfo:(NSDictionary *)userInfo OnSuccess:(void (^)(NSArray *))reportSuccess onFailure:(MLIBZ_239_STErrorBlock)reportFailure{
    
    //Kinvey: Get current active user
    KCSUser *user = [KCSUser activeUser];
    
    if (user) {
        NSArray *keyArray = [self allUserInfoKey];
        
        //Kinvey: Add current user attribute from user info
        for (int i = 0; i < keyArray.count; i++) {
            if (userInfo[keyArray[i]]) {
                [user setValue:userInfo[keyArray[i]]
                  forAttribute:keyArray[i]];
            }
        }
        
        //Kinver: Save current active user data
        [user saveWithCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
            
            //Return to main thread for update UI
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!errorOrNil) {
                    if (reportSuccess) reportSuccess(objectsOrNil);
                }
                else {
                    if (reportFailure) reportFailure(errorOrNil);
                }
            });
            
        }];
    }
}

- (void)loadUserOnSuccess:(void (^)(NSArray *))reportSuccess onFailure:(MLIBZ_239_STErrorBlock)reportFailure{
    
    //Kinvey: Get current active user
    KCSUser *user = [KCSUser activeUser];
    
    //Kinvey: Update data of current active user
    [user refreshFromServer:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        
        //Return to main thread for update UI
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!errorOrNil) {
                NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                NSArray *keyArray = [self allUserInfoKey];
                
                //Kinvey: extract user data to dictionary
                for (int i = 0; i < keyArray.count; i++) {
                    if ([user getValueForAttribute:keyArray[i]]) {
                        userInfo[keyArray[i]] = [user getValueForAttribute:keyArray[i]];
                    }
                }
                
                if (reportSuccess) reportSuccess(@[[userInfo copy]]);
            }
            else {
                if (reportFailure) reportFailure(errorOrNil);
            }
        });
        
    }];
}


#pragma mark - PRODUCT
#pragma mark - Load

- (void)loadProductsUseCache:(BOOL)useCache containtSubstinrg:(NSString *)substring OnSuccess:(void (^)(NSArray *))reportSuccess onFailure:(MLIBZ_239_STErrorBlock)reportFailure{
    
    KCSQuery *query = [KCSQuery query];
    
    if (substring.length) {
        
        //Add search query
        query = [self queryForSearchSubstring:substring
                                     inFields:[MLIBZ_239_Product textFieldsName]];
    }
    
    //Kinvey: Load entity from Product collection which correspond query
    [self.productsStore queryWithQuery:query
                  withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
                      
                      //Return to main thread for update UI
                      dispatch_async(dispatch_get_main_queue(), ^{
                          if (!errorOrNil) {
                              if (reportSuccess) reportSuccess(objectsOrNil);
                          }else{
                              if (reportFailure) reportFailure(errorOrNil);
                          }
                      });
                      
                  }
                    withProgressBlock:nil
                          cachePolicy:(useCache ? KCSCachePolicyLocalFirst : KCSCachePolicyNetworkFirst)];
}

@end
