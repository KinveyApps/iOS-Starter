//
//  KCSDataStoreOperationRequest.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-08-31.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import "DataStoreOperation.h"
#import "KCSRequest.h"

@interface KCSDataStoreOperationRequest : KCSRequest

+(instancetype)requestWithDataStoreOperation:(DataStoreOperation*)dataStoreOperation;

-(instancetype)initWithDataStoreOperation:(DataStoreOperation*)dataStoreOperation;

@property (strong, atomic) DataStoreOperation* dataStoreOperation;
@property (strong, atomic) KCSRequest* request;

@end
