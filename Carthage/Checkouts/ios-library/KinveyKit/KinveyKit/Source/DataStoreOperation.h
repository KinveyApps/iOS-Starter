//
//  DataStoreOperation.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-08-31.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

@import Foundation;

@interface DataStoreOperation : NSOperation

@property (nonatomic, copy) dispatch_block_t block;
@property (atomic, getter=isExecuting) BOOL executing;
@property (atomic, getter=isFinished) BOOL finished;

@end
