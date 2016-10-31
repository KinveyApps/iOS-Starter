//
//  KCSQueryAdapter.m
//  Kinvey
//
//  Created by Victor Barros on 2015-12-17.
//  Copyright © 2015 Kinvey. All rights reserved.
//

#import "KCSQueryAdapter.h"
#import <Kinvey/Kinvey-Swift.h>

@interface KCSQueryAdapter ()

@property (nonatomic, strong) KNVQuery* query;

@end

@implementation KCSQueryAdapter

-(instancetype)initWithQuery:(id)query
{
    self = [super init];
    if (self) {
        self.query = query;
    }
    return self;
}

-(NSPredicate *)predicate
{
    return self.query.predicate;
}

-(NSArray<NSSortDescriptor *> *)sortDescriptors
{
    return self.query.sortDescriptors;
}

@end
