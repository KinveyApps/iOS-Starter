//
//  DocTests.m
//  KinveyKit
//
//  Created by Michael Katz on 12/9/13.
//  Copyright (c) 2015 Kinvey. All rights reserved.
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


#import <SenTestingKit/SenTestingKit.h>
#import "KinveyKit.h"

@interface DataClass :NSObject <KCSPersistable>

@end
@implementation DataClass

@end

@interface DocTests : SenTestCase

@end

@implementation DocTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testExample
{
    STFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}


- (void) exportData
{
    KCSCollection* collection = [KCSCollection collectionFromString:@"ACollection" ofClass:[DataClass class]];
    KCSCachedStore* store = [KCSCachedStore storeWithCollection:collection
                                                        options:@{KCSStoreKeyCachePolicy : @(KCSCachePolicyNetworkFirst)}];
    //... load data from network
    
    NSArray* entities = [store exportCache];
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:entities options:0 error:NULL];
    NSString* path =  [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"ACollection.json"];
    [jsonData writeToFile:path atomically:NO];
}

- (void) importData
{
    KCSCollection* collection = [KCSCollection collectionFromString:@"ACollection" ofClass:[DataClass class]];
    KCSCachedStore* store = [KCSCachedStore storeWithCollection:collection
                                                        options:@{KCSStoreKeyCachePolicy : @(KCSCachePolicyNetworkFirst)}];
    
    NSString* jsonPath = [[NSBundle mainBundle] pathForResource:@"ACollection" ofType:@"json"]; //include ACollection.json in bundle
    NSData* jsonData = [NSData dataWithContentsOfFile:jsonPath];
    NSMutableArray* entities = [NSJSONSerialization JSONObjectWithData:jsonData
                                                               options:NSJSONReadingMutableContainers
                                                                 error:NULL];
    
    [store import:entities];
    
    //get all the items back as "DataClass" objects
    [store queryWithQuery:[KCSQuery query] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        //objectsOrNil will be the imported data
    } withProgressBlock:nil cachePolicy:KCSCachePolicyLocalOnly];
}



@end
