//
//  NSValueTransformer+Kinvey.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-12-02.
//  Copyright © 2015 Kinvey. All rights reserved.
//

#import "NSValueTransformer+Kinvey.h"

@import ObjectiveC;

@implementation NSValueTransformer (Kinvey)

+(NSString*)fromClass:(Class)fromClass
              toClass:(Class)toClass
{
    return [NSString stringWithFormat:@"%@->%@", NSStringFromClass(fromClass), NSStringFromClass(toClass)];
}

+(void)setValueTransformer:(NSValueTransformer *)transformer
                 fromClass:(Class)fromClass
                   toClass:(Class)toClass
{
    [self setValueTransformer:transformer
                      forName:[self fromClass:fromClass toClass:toClass]];
}

+(NSValueTransformer *)valueTransformerFromClassName:(NSString *)fromClass
                                         toClassName:(NSString *)toClass
{
    return [self valueTransformerFromClass:NSClassFromString(fromClass)
                                   toClass:NSClassFromString(toClass)];
}

+(NSValueTransformer *)valueTransformerFromClass:(Class)fromClass
                                         toClass:(Class)toClass
{
    NSValueTransformer* transformer = nil;
    do {
        transformer = [self valueTransformerForName:[self fromClass:fromClass toClass:toClass]];
        fromClass = transformer ? nil : class_getSuperclass(fromClass);
    } while (!transformer && fromClass);
    return transformer;
}

@end
