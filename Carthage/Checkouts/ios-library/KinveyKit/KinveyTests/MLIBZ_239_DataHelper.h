//
//  DataHelper2.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-04-15.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <KinveyKit/KinveyKit.h>

typedef void(^MLIBZ_239_STErrorBlock)(NSError *errorOrNil);

@interface MLIBZ_239_Quote : NSObject<KCSPersistable>

@property (nonatomic, strong) NSString* objectId;
@property (nonatomic, strong) NSString* reference;
@property (nonatomic, strong) KCSUser* originator;
@property (nonatomic, retain) NSString *activeUsers;

+(NSArray*)textFieldsName;

@end

@interface MLIBZ_239_Order : NSObject<KCSPersistable>

+(NSArray*)textFieldsName;

@end

@interface MLIBZ_239_Product : NSObject<KCSPersistable>

+(NSArray*)textFieldsName;

@end

@interface MLIBZ_239_DataHelper : NSObject

+(instancetype)instance;

@property (nonatomic, strong) id formatter;

- (void)saveQuote:(MLIBZ_239_Quote *)quote OnSuccess:(void (^)(NSArray *))reportSuccess onFailure:(MLIBZ_239_STErrorBlock)reportFailure;

- (void)loadQuotesUseCache:(BOOL)useCache containtSubstinrg:(NSString *)substring OnSuccess:(void (^)(NSArray *))reportSuccess onFailure:(MLIBZ_239_STErrorBlock)reportFailure;

@end
