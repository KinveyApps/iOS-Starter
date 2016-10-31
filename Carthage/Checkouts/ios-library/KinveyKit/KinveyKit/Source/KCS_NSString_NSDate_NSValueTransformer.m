//
//  KCS_NSString_NSDate_NSValueTransformer.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-12-02.
//  Copyright © 2015 Kinvey. All rights reserved.
//

#import "KCS_NSString_NSDate_NSValueTransformer.h"

#import "NSDate+ISO8601.h"

@implementation KCS_NSString_NSDate_NSValueTransformer

+(instancetype)sharedInstance
{
    static KCS_NSString_NSDate_NSValueTransformer* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

+(Class)transformedValueClass
{
    return [NSDate class];
}

-(id)transformedValue:(id)value
{
    static NSRegularExpression* regex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:@"ISODate\\(\"(.+)\"\\)"
                                                          options:0
                                                            error:nil];
    });
    if ([value isKindOfClass:[NSString class]]) {
        NSString* date = value;
        NSArray<NSTextCheckingResult*>* matches = [regex matchesInString:date
                                                                  options:0
                                                                    range:NSMakeRange(0, date.length)];
        if (matches.count > 0) {
            NSTextCheckingResult* textCheckingResult = matches.firstObject;
            if (textCheckingResult.numberOfRanges > 1) {
                NSRange range = [textCheckingResult rangeAtIndex:1];
                if (range.location != NSNotFound) {
                    date = [date substringWithRange:range];
                    return [NSDate dateFromISO8601EncodedString:date];
                }
            }
        }
    }
    return nil;
}

-(id)reverseTransformedValue:(id)value
{
    if ([value isKindOfClass:[NSDate class]]) {
        return [(NSDate*) value stringWithISO8601Encoding];
    }
    return nil;
}

@end
