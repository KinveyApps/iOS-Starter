//
//  MLIBZ_326_Tests.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-06-12.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KCSTestCase.h"
#import <KinveyKit/KinveyKit.h>

@interface MLIBZ_326_Tests : KCSTestCase

@end

@implementation MLIBZ_326_Tests

- (void)test
{
    KCSCollection *collection = [KCSCollection collectionFromString:@"Vet" ofClass:[NSMutableDictionary class]];
    KCSCachedStore *store = [KCSCachedStore storeWithCollection:collection options:@
                             {KCSStoreKeyOfflineUpdateEnabled : @(YES)}
                             ];
    
    KCSQuery *queryName = [KCSQuery queryOnField:@"name" withExactMatchForValue:@"name1"];
    KCSQuery *queryAddress = [KCSQuery queryOnField:@"address" withExactMatchForValue:@"address1"];
    KCSQuery *queryANDThatDoesNotWork = [queryName queryByJoiningQuery:queryAddress usingOperator:kKCSAnd];
    
    KCSQuery *queryANDThatWorks = [KCSQuery queryWithQuery:queryName];
    [queryANDThatWorks addQuery:queryAddress];
    
    XCTAssertEqualObjects(queryANDThatDoesNotWork.query, queryANDThatWorks.query);
    XCTAssertEqualObjects(queryANDThatDoesNotWork.query, (@{@"address":@"address1",@"name":@"name1"}));
}

@end
