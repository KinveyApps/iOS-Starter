//
//  KCSSync.h
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

@import Foundation;

@protocol KNVPendingOperation;

@protocol KCSSync <NSObject>

@property (nonatomic, strong) NSString* persistenceId;
@property (nonatomic, strong) NSString* collectionName;

-(instancetype)initWithPersistenceId:(NSString *)persistenceId
                      collectionName:(NSString *)collectionName;

-(id<KNVPendingOperation>)createPendingOperation:(NSURLRequest*)request
                                        objectId:(NSString*)objectId;

-(void)savePendingOperation:(id<KNVPendingOperation>)pendingOperation;

-(NSArray<id<KNVPendingOperation>>*)pendingOperations;

-(void)removePendingOperation:(id<KNVPendingOperation>)pendingOperation;

-(void)removeAllPendingOperations;

@end
