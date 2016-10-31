//
//  MLIBZ_322_ObjC_Tests.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-06-10.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KCSTestCase.h"
#import <KinveyKit/KinveyKit.h>

@interface MLIBZ_322_ObjC_Tests : KCSTestCase

@end

@implementation MLIBZ_322_ObjC_Tests

-(void)testDouble
{
    XCTAssertNoThrow(([KCSQuery queryOnField:KCSEntityKeyGeolocation
                       usingConditionalPairs:@[@(kKCSNearSphere), @[@-71.05, @42.35],
                                               @(kKCSMaxDistance), @0.5]]));
}

-(void)testInt
{
    XCTAssertNoThrow(([KCSQuery queryOnField:KCSEntityKeyGeolocation
                       usingConditionalPairs:@[@(kKCSNearSphere), @[@-71.05, @42.35],
                                               @(kKCSMaxDistance), @5]]));
}

-(void)testInvalidOperator
{
    NSNumber* low = @1;
    NSNumber* high = @5;
    XCTAssertThrows(([KCSQuery queryOnField:@"age" usingConditionalPairs:@[@(-1234), low, @(kKCSLessThan), high]]));
}

-(void)testInvalidOperatorString
{
    NSNumber* low = @1;
    NSNumber* high = @5;
    XCTAssertThrows(([KCSQuery queryOnField:@"age" usingConditionalPairs:@[@"1234", low, @(kKCSLessThan), high]]));
}

-(void)testInvalidArray
{
    NSNumber* low = @1;
    NSNumber* high = @5;
    XCTAssertThrows(([KCSQuery queryOnField:@"age" usingConditionalPairs:@[@(kKCSGreaterThan), low, @(kKCSLessThan), high, @(kKCSSize)]]));
}

@end
