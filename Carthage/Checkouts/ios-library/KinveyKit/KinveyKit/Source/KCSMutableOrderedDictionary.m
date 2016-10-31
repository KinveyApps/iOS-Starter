//
//  KCSMutableSortedDictionary.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-03-22.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import "KCSMutableOrderedDictionary.h"

@interface KCSMutableOrderedDictionary ()

@property (nonatomic, strong) NSMutableDictionary* dictionary;
@property (nonatomic, strong) NSMutableOrderedSet* keys;

@end

@implementation KCSMutableOrderedDictionary

-(instancetype)initWithCapacity:(NSUInteger)numItems
{
    self = [super init];
    if (self) {
        self.dictionary = [NSMutableDictionary dictionaryWithCapacity:numItems];
        self.keys = [NSMutableOrderedSet orderedSetWithCapacity:numItems];
    }
    return self;
}

-(instancetype)initWithDictionary:(NSDictionary *)otherDictionary
{
    self = [super initWithDictionary:otherDictionary];
    return self;
}

-(void)setObject:(id)anObject forKey:(id<NSCopying>)aKey
{
    if (![(id)aKey isKindOfClass:[NSString class]]) {
        [[NSException exceptionWithName:@"Invalid Key"
                                 reason:@"Key needs to be a string"
                               userInfo:@{ NSLocalizedDescriptionKey : @"Key needs to be a string" }] raise];
    }
    if ([anObject isKindOfClass:[NSDictionary class]] && ![anObject isKindOfClass:[KCSMutableOrderedDictionary class]]) {
        anObject = [KCSMutableOrderedDictionary dictionaryWithDictionary:anObject];
    }
    [self.dictionary setObject:anObject forKey:aKey];
    [self.keys addObject:aKey];
}

-(void)removeObjectForKey:(id)aKey
{
    [self.dictionary removeObjectForKey:aKey];
    [self.keys removeObject:aKey];
}

-(NSUInteger)count
{
    return self.dictionary.count;
}

-(id)objectForKey:(id)aKey
{
    return [self.dictionary objectForKey:aKey];
}

-(NSEnumerator *)keyEnumerator
{
    [self.keys sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        if ([obj1 respondsToSelector:@selector(compare:)]) {
            return [obj1 compare:obj2];
        }
        return NSOrderedSame;
    }];
    return self.keys.objectEnumerator;
}

@end
