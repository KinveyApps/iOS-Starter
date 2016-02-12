//
//  KCSCacheManager.h
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

@import Foundation;
#import "KCSCache.h"

@interface KCSCacheManager : NSObject

@property (nonatomic, strong) NSString* persistenceId;

+(instancetype)getInstance:(NSString*)persistenceId;

-(id<KCSCache>)cache:(NSString*)collectionName;

@end
