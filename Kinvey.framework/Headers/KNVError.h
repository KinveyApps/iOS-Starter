//
//  KNVError.h
//  Kinvey
//
//  Created by Victor Barros on 2016-03-29.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KNVError : NSObject

+ (NSError * _Nonnull)ObjectIdMissing;
+ (NSError * _Nonnull)InvalidResponse;
+ (NSError * _Nonnull)NoActiveUser;
+ (NSError * _Nonnull)RequestCancelled;
+ (NSError * _Nonnull)InvalidStoreType;

@end
