//
//  KCSSync.h
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

@import Foundation;
#import "KCSPendingOperation.h"

@protocol KCSSync <NSObject>

@property (nonatomic, strong) NSString* persistenceId;
@property (nonatomic, strong) NSString* collectionName;

-(instancetype)initWithPersistenceId:(NSString *)persistenceId
                      collectionName:(NSString *)collectionName;

-(id<KCSPendingOperation>)createPendingOperation:(NSURLRequest*)request
                                        objectId:(NSString*)objectId;

-(void)savePendingOperation:(id<KCSPendingOperation>)pendingOperation;

-(NSArray<id<KCSPendingOperation>>*)pendingOperations;

-(void)removePendingOperation:(id<KCSPendingOperation>)pendingOperation;

-(void)removeAllPendingOperations;

@end
