//
//  KCSCache.h
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

@import Foundation;
#import "KCSQuery.h"

@protocol KCSCache <NSObject>

@property (nonatomic, strong) NSString* persistenceId;
@property (nonatomic, strong) NSString* collectionName;

-(instancetype)initWithPersistenceId:(NSString *)persistenceId
                      collectionName:(NSString *)collectionName;

-(void)saveEntity:(NSDictionary<NSString*, id>*)entity;

-(void)saveEntities:(NSArray<NSDictionary<NSString*, id>*>*)entities;

-(NSDictionary<NSString*, id>*)findEntity:(NSString*)objectId;

-(NSArray<NSDictionary<NSString*, id>*>*)findEntityByQuery:(id<KCSQuery>)query;

-(NSArray<NSDictionary<NSString*, id>*>*)findAll;

-(void)removeEntity:(NSDictionary<NSString*, id>*)entity;

-(NSUInteger)removeEntitiesByQuery:(id<KCSQuery>)query;

-(void)removeAllEntities;

@end
