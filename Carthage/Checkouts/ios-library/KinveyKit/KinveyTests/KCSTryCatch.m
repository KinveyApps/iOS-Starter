//
//  KCSTryCatch.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-04-27.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import "KCSTryCatch.h"

@implementation KCSTryCatch

+(void)try:(void (^)())try
     catch:(void (^)(NSException *))catch
   finally:(void (^)())finally
{
    @try {
        if (try) {
            try();
        }
    }
    @catch (NSException *exception) {
        if (catch) {
            catch(exception);
        }
    }
    @finally {
        if (finally) {
            finally();
        }
    }
}

@end
