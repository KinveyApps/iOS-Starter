//
//  KCSSyncManager.m
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import "KCSSyncManager.h"
#import "KCSRealmEntityPersistence.h"

@implementation KCSSyncManager

+(instancetype)getInstance:(NSString *)persistenceId
{
    return [[KCSSyncManager alloc] initWithPersistenceId:persistenceId];
}

-(instancetype)initWithPersistenceId:(NSString *)persistenceId
{
    self = [super init];
    if (self) {
        self.persistenceId = persistenceId;
    }
    return self;
}

-(id<KCSSync>)sync:(NSString *)collectionName
{
    return [[KCSRealmEntityPersistence alloc] initWithPersistenceId:self.persistenceId
                                                     collectionName:collectionName];
}

@end
