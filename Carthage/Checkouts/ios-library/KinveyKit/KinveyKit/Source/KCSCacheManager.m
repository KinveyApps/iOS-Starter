//
//  KCSCacheManager.m
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import "KCSCacheManager.h"
#import "KCSRealmEntityPersistence.h"

@implementation KCSCacheManager

+(instancetype)getInstance:(NSString *)persistenceId
{
    return [[KCSCacheManager alloc] initWithPersistenceId:persistenceId];
}

-(instancetype)initWithPersistenceId:(NSString *)persistenceId
{
    self = [super init];
    if (self) {
        self.persistenceId = persistenceId;
    }
    return self;
}

-(id<KCSCache>)cache:(NSString *)collectionName
{
    return [[KCSRealmEntityPersistence alloc] initWithPersistenceId:self.persistenceId
                                                     collectionName:collectionName];
}

@end
