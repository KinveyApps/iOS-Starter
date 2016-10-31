//
//  KNVClient.h
//  Kinvey
//
//  Created by Victor Barros on 2016-03-03.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import "KNVClient.h"
#import <Kinvey/Kinvey-Swift.h>

@interface KNVClient ()

@property (nonatomic, strong) __KNVClient* _Nonnull client;

-(instancetype _Nonnull)initWithClient:(__KNVClient* _Nonnull)client;

@end
