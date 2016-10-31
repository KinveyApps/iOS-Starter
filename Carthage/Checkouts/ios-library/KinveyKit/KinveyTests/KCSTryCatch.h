//
//  KCSTryCatch.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-04-27.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCSTryCatch : NSObject

+(void)try:(void(^)())try
     catch:(void(^)(NSException* exception))catch
   finally:(void(^)())finally;

@end
