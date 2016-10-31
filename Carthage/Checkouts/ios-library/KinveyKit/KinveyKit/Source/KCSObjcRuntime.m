//
//  KCSObjcRuntime.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-12-02.
//  Copyright © 2015 Kinvey. All rights reserved.
//

#import "KCSObjcRuntime.h"

@import ObjectiveC;

@implementation KCSObjcRuntime

+(NSString*)typeForProperty:(NSString*)propertyName
                   inObject:(id)obj
{
    return [self typeForProperty:propertyName
                         inClass:[obj class]];
}

+(NSString *)typeForProperty:(NSString *)propertyName
                 inClassName:(NSString *)className
{
    return [self typeForProperty:propertyName
                         inClass:NSClassFromString(className)];
}

+(NSString*)typeForProperty:(NSString*)propertyName
                    inClass:(Class)class
{
    static NSRegularExpression* regex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:@"@\"(\\w+)(?:<(\\w+)>)?\""
                                                          options:0
                                                            error:nil];
    });
    objc_property_t property = class_getProperty(class, propertyName.UTF8String);
    if (!property) return nil;
    char* typeC = property_copyAttributeValue(property, "T");
    NSString* type = [NSString stringWithUTF8String:typeC];
    free(typeC);
    NSArray<NSTextCheckingResult *>* matches = [regex matchesInString:type
                                                              options:0
                                                                range:NSMakeRange(0, type.length)];
    NSString* result = nil;
    if (matches.count > 0) {
        NSTextCheckingResult* textCheckingResult = matches.firstObject;
        if (textCheckingResult.numberOfRanges > 0) {
            NSRange range = [textCheckingResult rangeAtIndex:1];
            if (range.location != NSNotFound) {
                result = [type substringWithRange:range];
            }
        }
    }
    return result;
}

+(NSSet<NSString *> *)propertyNamesForObject:(id)obj
{
    return [self propertyNamesForClass:[obj class]];
}

+(NSSet<NSString *> *)propertyNamesForClassName:(NSString*)className
{
    return [self propertyNamesForClass:NSClassFromString(className)];
}

+(NSSet<NSString *> *)propertyNamesForClass:(Class)class
{
    unsigned int propertyCount;
    objc_property_t *properties = class_copyPropertyList(class, &propertyCount);
    NSMutableSet<NSString*>* propertyNames = [NSMutableSet setWithCapacity:propertyCount];
    objc_property_t property;
    for (int i = 0; i < propertyCount; i++) {
        property = properties[i];
        [propertyNames addObject:[NSString stringWithUTF8String:property_getName(property)]];
    }
    free(properties);
    return propertyNames;
}

+(NSSet<NSString *> *)ivarNamesForObject:(id)obj
{
    return [self ivarNamesForClass:[obj class]];
}

+(NSSet<NSString *> *)ivarNamesForClass:(Class)class
{
    unsigned int ivarCount;
    Ivar *ivars = class_copyIvarList(class, &ivarCount);
    NSMutableSet<NSString*>* ivarNames = [NSMutableSet setWithCapacity:ivarCount];
    Ivar ivar;
    for (int i = 0; i < ivarCount; i++) {
        ivar = ivars[i];
        [ivarNames addObject:[NSString stringWithUTF8String:ivar_getName(ivar)]];
    }
    free(ivars);
    return ivarNames;
}

+(NSSet<NSString *> *)methodsForObject:(id)obj
{
    return [self methodsForClass:[obj class]];
}

+(NSSet<NSString *> *)methodsForClass:(Class)class
{
    unsigned int methodCount;
    Method *methods = class_copyMethodList(class, &methodCount);
    NSMutableSet<NSString*>* methodNames = [NSMutableSet setWithCapacity:methodCount];
    Method method;
    for (int i = 0; i < methodCount; i++) {
        method = methods[i];
        [methodNames addObject:NSStringFromSelector(method_getName(method))];
    }
    free(methods);
    return methodNames;
}

@end
