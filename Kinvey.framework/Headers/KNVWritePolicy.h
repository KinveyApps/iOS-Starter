//
//  KNVWritePolicy.h
//  Kinvey
//
//  Created by Victor Barros on 2016-03-04.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_SWIFT_UNAVAILABLE("Please use 'KNVWritePolicy' enum")
typedef NS_ENUM(NSUInteger, KNVWritePolicy) {
    
    KNVWritePolicyLocalThenNetwork = 0,
    KNVWritePolicyForceLocal,
    KNVWritePolicyForceNetwork
    
};
