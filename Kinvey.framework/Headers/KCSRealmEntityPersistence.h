//
//  KCSRealmManager.h
//  Kinvey
//
//  Created by Victor Barros on 2015-12-16.
//  Copyright © 2015 Kinvey. All rights reserved.
//

@import Foundation;
@import Realm;

#import "KCSCache.h"
#import "KCSSync.h"

@interface KCSRealmEntityPersistence : NSObject <KCSCache, KCSSync>

+(nonnull RLMRealmConfiguration*)configurationForPersistenceId:(nonnull NSString *)persistenceId;

+(nonnull RLMRealmConfiguration*)configurationForPersistenceId:(nonnull NSString *)persistenceId
                                                      filePath:(nullable NSString *)filePath
                                                 encryptionKey:(nullable NSData*)encryptionKey;

-(nonnull instancetype)initWithPersistenceId:(nonnull NSString *)persistenceId
                              collectionName:(nullable NSString *)collectionName;

-(nonnull instancetype)initWithPersistenceId:(nonnull NSString *)persistenceId
                              collectionName:(nullable NSString *)collectionName
                                    filePath:(nullable NSString *)filePath
                               encryptionKey:(nullable NSData*)encryptionKey;

@end
