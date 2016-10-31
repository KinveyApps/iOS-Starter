//
//  KNVError.m
//  Kinvey
//
//  Created by Victor Barros on 2016-03-29.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import "KNVError.h"

@implementation KNVError

+ (NSError * _Nonnull)ObjectIdMissing
{
    return [__KNVError ObjectIdMissing];
}

+ (NSError * _Nonnull)InvalidResponse
{
    return [__KNVError InvalidResponse];
}

+ (NSError * _Nonnull)NoActiveUser
{
    return [__KNVError NoActiveUser];
}

+ (NSError * _Nonnull)RequestCancelled
{
    return [__KNVError RequestCancelled];
}

+ (NSError * _Nonnull)InvalidStoreType
{
    return [__KNVError InvalidStoreType];
}

@end
