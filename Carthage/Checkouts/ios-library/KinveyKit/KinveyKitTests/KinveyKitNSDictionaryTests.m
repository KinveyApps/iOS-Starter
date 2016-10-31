//
//  KinveyKitNSDictionaryTests.m
//  KinveyKit
//
//  Created by Michael Katz on 10/11/12.
//  Copyright (c) 2012-2015 Kinvey. All rights reserved.
//

#import "KinveyKitNSDictionaryTests.h"
#import "NSDictionary+KinveyAdditions.h"
#import "NSMutableDictionary+KinveyAdditions.h"

@implementation KinveyKitNSDictionaryTests

- (void) doTest:(NSDictionary*)d keyset:(NSArray*)k expected:(NSDictionary*)ed
{
    NSMutableDictionary* md = [d mutableCopy];
    [md append:@"X" ontoKeySet:k recursive:YES];
    
    XCTAssertEqualObjects(md, ed, @"should be equal");
}

- (void) testEmpty
{
    [self doTest:@{} keyset:@[] expected:@{}];
}

- (void) testEmptyAppend
{
    [self doTest:@{@"s":@"sv", @"n":@1} keyset:@[] expected:@{@"s":@"sv", @"n":@1}];
}

- (void) testAppend1
{
    [self doTest:@{@"s":@"sv", @"n":@1, @"a":@[@"a", @"b"]}
          keyset:@[@"s"]
        expected:@{@"sX":@"sv", @"n":@1, @"a":@[@"a", @"b"]}];
}

- (void) testAppend2
{
    [self doTest:@{@"s":@"sv", @"n":@1, @"a":@[@"a", @"b"]}
          keyset:@[@"s",@"n"]
        expected:@{@"sX":@"sv", @"nX":@1, @"a":@[@"a", @"b"]}];
}

- (void) testAppendR
{
    [self doTest:@{@"s":@"sv", @"n":@1, @"a":@[@"a", @"b"],
     @"d" : @{@"ds" : @"m", @"n" : @20},
     @"d2" : @{ @"dd" : @{ @"a" : @[@"n",@"s"] }, @"ds" : @"n"},
     @"de" : @{}}
          keyset:@[@"s",@"n",@"ds"]
        expected:@{@"sX":@"sv", @"nX":@1, @"a":@[@"a", @"b"],
     @"d" : @{@"dsX" : @"m", @"nX" : @20},
     @"d2" : @{ @"dd" : @{ @"a" : @[@"n",@"s"] }, @"dsX" : @"n"},
     @"de" : @{}}];
}

- (void) testArray
{
    [self doTest:@{@"A" : @[@{@"Z" : @1, @"X" : @2}, @{@"Y": @10}, @"B"]}
          keyset:@[@"X"]
         expected:@{@"A" : @[@{@"Z" : @1, @"XX" : @2}, @{@"Y": @10}, @"B"]}];
}

- (void) testInvert
{
    NSDictionary* source = @{@"Ak":@"Av",@"Bk":@"Bv",@"Nk":@1,@"Nuk":[NSNull null],@"Ck":@"Cv"};
    NSDictionary* inverted = [source invert];
    NSDictionary* expected = @{@"Av":@"Ak",@"Bv":@"Bk",@"Cv":@"Ck"};
    XCTAssertEqualObjects(inverted, expected, @"should be inverted, no non-strings");
    
}

@end
