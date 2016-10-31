//
//  KCSMutipleRequest.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-08-28.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import "KCSRequest.h"

@interface KCSMultipleRequest : KCSRequest

-(void)addRequest:(KCSRequest*)request;

@end
