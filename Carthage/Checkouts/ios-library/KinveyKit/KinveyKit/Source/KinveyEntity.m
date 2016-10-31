//
//  KinveyEntity.m
//  KinveyKit
//
//  Created by Brian Wilson on 10/13/11.
//  Copyright (c) 2011-2015 Kinvey. All rights reserved.
//
// This software is licensed to you under the Kinvey terms of service located at
// http://www.kinvey.com/terms-of-use. By downloading, accessing and/or using this
// software, you hereby accept such terms of service  (and any agreement referenced
// therein) and agree that you have read, understand and agree to be bound by such
// terms of service and are of legal age to agree to such terms with Kinvey.
//
// This software contains valuable confidential and proprietary information of
// KINVEY, INC and is subject to applicable licensing agreements.
// Unauthorized reproduction, transmission or distribution of this file and its
// contents is a violation of applicable laws.
//


#import "KinveyEntity.h"

#import "KCSLogManager.h"
#import "KinveyPersistable.h"


// NOTE: We're supressing the remainder of protocol warnings here
//       (maintainers please periodically disable this workaround
//       to ensure program correctness).  We're disabling this
//       because we don't implement the NSObject protocol...
//       since NSObject implements it.  I'm not 100% positive
//       how we should really be removing these warnings, but
//       we should fix this for real in the future!

#pragma clang diagnostic ignored "-Wprotocol"
@implementation NSObject (KCSEntity)
- (NSString *)kinveyObjectIdHostProperty
{
    NSDictionary *kinveyMapping = [self hostToKinveyPropertyMapping];
    for (NSString *key in kinveyMapping){
        NSString *jsonName = [kinveyMapping valueForKey:key];
        if ([jsonName isEqualToString:KCSEntityKeyId]){
            return key;
        }
    }
    return nil;
}

- (NSString *)kinveyObjectId
{
    NSString* objKey = [self kinveyObjectIdHostProperty];
    return ifNotNil(objKey, [self valueForKey:objKey]);
}

- (void) setKinveyObjectId:(NSString*) objId
{
    NSString* objKey = [self kinveyObjectIdHostProperty];
    if (objKey == nil) {
        NSString* exp = [NSString stringWithFormat:@"Cannot set the 'id', the entity of class '%@' does not map KCSEntityKeyId in -hostToKinveyPropertyMapping.", [self class]];
        @throw [NSException exceptionWithName:@"KCSEntityNoId" reason:exp userInfo:@{@"object" : self}];
    } else {
        [self setValue:objId forKey:objKey];
    }
}

- (NSDictionary *)hostToKinveyPropertyMapping
{
    // Eventually this will be used to allow a default scanning of "self" to build and cache a
    // 1-1 mapping of the client properties
    KCSLogForced(@"EXCEPTION Encountered: Name => %@, Reason => %@", @"UnsupportedFeatureException", @"This version of the Kinvey iOS library requires clients to override this method");
    
    NSString* errorMessage = [NSString stringWithFormat:@"Object \"%@\" of type \"%@\" does not implement 'hostToKinveyPropertyMapping', a required 'KCSPersistable' method for saving the object to the backend", self, [self class]];
    
    NSException* myException = [NSException
                                exceptionWithName:@"UnsupportedFeatureException"
                                reason:errorMessage
                                userInfo:nil];
    
    @throw myException;

    return nil;
}

+ (id)kinveyDesignatedInitializer:(NSDictionary*)jsonDocument
{
    // Eventually this will be used to allow a default scanning of "self" to build and cache a
    // 1-1 mapping of the client properties
    KCSLogForced(@"EXCEPTION Encountered: Name => %@, Reason => %@", @"UnsupportedFeatureException", @"This version of the Kinvey iOS library requires clients to override this method");

    NSString* errorMessage = [NSString stringWithFormat:@"Object \"%@\" of type \"%@\" does not implement 'kinveyDesignatedInitializer', an optional 'KCSPersistable' method for saving the object to the backend. This method is called beacuse of options set in the class' 'kinveyObjectBuilderOptions' method.", self, [self class]];
    
    NSException* myException = [NSException
                                exceptionWithName:@"UnsupportedFeatureException"
                                reason:errorMessage
                                userInfo:nil];

    
    @throw myException;
    
    return nil;

}

+ (NSDictionary *)kinveyObjectBuilderOptions
{
    return nil;
}


@end
