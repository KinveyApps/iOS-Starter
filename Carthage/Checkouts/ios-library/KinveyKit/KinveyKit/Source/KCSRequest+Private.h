//
//  KCSRequest.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-08-26.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

@import Foundation;
#import "KCSRequest.h"
#import "KCSNetworkOperation.h"

@interface KCSRequest ()

+(instancetype)requestWithNetworkOperation:(id<KCSNetworkOperation>)networkOperation;

-(instancetype)initWithNetworkOperation:(NSOperation<KCSNetworkOperation>*)networkOperation;

@property (weak, atomic) NSOperation<KCSNetworkOperation>* networkOperation;
@property BOOL _cancelled;

@end
