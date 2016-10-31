//
//  KCSFileRequest.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-08-31.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import "KCSFileOperation.h"
#import "KCSRequest.h"

@interface KCSFileRequest : KCSRequest

@property (weak) NSOperation<KCSFileOperation>* fileOperation;

+(instancetype)requestWithFileOperation:(NSOperation<KCSFileOperation>*)fileOperation;

-(instancetype)initWithFileOperation:(NSOperation<KCSFileOperation>*)fileOperation;

@end
