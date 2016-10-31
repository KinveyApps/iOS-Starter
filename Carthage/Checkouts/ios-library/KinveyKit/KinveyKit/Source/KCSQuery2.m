//
//  KCSQuery2.m
//  KinveyKit
//
//  Created by Michael Katz on 5/23/13.
//  Copyright (c) 2013-2015 Kinvey. All rights reserved.
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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-W#warnings"

#import "KCSQuery2.h"
#import "KinveyCoreInternal.h"
#import "KinveyDataStoreInternal.h"
#import "NSDate+ISO8601.h"
#import "KinveyErrorCodes.h"
#import "KCSQuery.h"

#define BadPredicate()  if (error != NULL) { \
                             *error = [NSError errorWithDomain:KCSAppDataErrorDomain code:KCSqueryPredicateNotSupportedError userInfo:nil]; \
                        }

typedef enum KCSQueryOperation : NSInteger {
    KCSQueryLessThan = 16,
    KCSQueryLessThanOrEqual = 17,
    KCSQueryGreaterThan = 18,
    KCSQueryGreaterThanOrEqual = 19,
} KCSQueryOperation;

NSString* kcsQueryOperatorString(KCSQueryOperation op)
{
    NSString* operator = nil;
    switch (op) {
        case KCSQueryLessThan:
            operator = @"$lt";
            break;
        case KCSQueryLessThanOrEqual:
            operator = @"$lte";
            break;
        case KCSQueryGreaterThan:
            operator = @"$gt";
            break;
        case KCSQueryGreaterThanOrEqual:
            operator = @"$gte";
            break;
        default:
            break;
    }
    return operator;
}

BOOL kcsQueryIsComparison(KCSQueryOperation op)
{
    BOOL comparison;
    switch (op) {
        case KCSQueryGreaterThan:
        case KCSQueryGreaterThanOrEqual:
        case KCSQueryLessThan:
        case KCSQueryLessThanOrEqual:
            //ne
            comparison = YES;
            break;
            
        default:
            comparison = NO;
            break;
    }
    return comparison;
}

BOOL kcsQueryIsComparisonS(NSString* opStr)
{
    NSDictionary* d = @{@"$lt"    : @YES,
                        @"$lte"   : @YES,
                        @"$gt"    : @YES,
                        @"$gte"   : @YES,
                        @"ne"     : @YES};
    return [d[opStr] boolValue];
}

@interface KCSQuery2 ()
@property (nonatomic, retain) NSMutableDictionary* internalRepresentation;
@property (nonatomic, retain) NSMutableArray* mySortDescriptors;
@end

@implementation KCSQuery2

- (instancetype) init
{
    self = [super init];
    if (self) {
        _internalRepresentation = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSString *)description
{
    return [self queryString:NO];
}

#pragma mark - directQuery
+ (instancetype) allQuery
{
    KCSQuery2* query = [[KCSQuery2 alloc] init];
    return query;
}

+ (instancetype) queryMatchField:(NSString*)field toValue:(id)value
{
    KCSQuery2* query = [[KCSQuery2 alloc] init];
    query.internalRepresentation = [@{field:value} mutableCopy];
    return query;
}

+ (instancetype) queryOnField:(NSString*)field operator:(KCSQueryOperation)operation toValue:(id)value
{
    KCSQuery2* query = [[KCSQuery2 alloc] init];
    NSString* operator = kcsQueryOperatorString(operation);
    query.internalRepresentation = [@{field:@{operator : value}} mutableCopy];
    return query;
}

#pragma mark - predicates
NSString* kcsPredToQueryStrForKeyPath(NSExpression* expr)
{
    return [expr keyPath];
}

id kcsPredToQueryExprVal(NSExpression* expr)
{
    if (expr.expressionType == NSKeyPathExpressionType) {
        return kcsPredToQueryStrForKeyPath(expr);
    }
    return nil;
}

+ (instancetype) queryWithPredicate:(NSPredicate*)predicate error:(NSError**)error
{
    KCSQuery2* query = nil;
    if ([predicate isKindOfClass:[NSComparisonPredicate class]]) {
        NSComparisonPredicate* cpredicate = (NSComparisonPredicate*) predicate;
        NSComparisonPredicateModifier modifier = [cpredicate comparisonPredicateModifier];
        //TODO: options
        if (modifier == NSDirectPredicateModifier) {
            NSExpression* lhs = [cpredicate leftExpression];
            NSExpression* rhs = [cpredicate rightExpression];
            NSPredicateOperatorType type = [cpredicate predicateOperatorType];
            
            id field = kcsPredToQueryExprVal(lhs);
            id val = kcsPredToQueryExprVal(rhs);
            if (field != nil && val != nil) {
                switch (type) {
                    case NSLessThanPredicateOperatorType:
                        query = [self queryOnField:field operator:KCSQueryLessThan toValue:val];
                        break;
                    case NSLessThanOrEqualToPredicateOperatorType:
                        query = [self queryOnField:field operator:KCSQueryLessThanOrEqual toValue:val];
                        break;
                    case NSGreaterThanPredicateOperatorType:
                        query = [self queryOnField:field operator:KCSQueryGreaterThan toValue:val];
                        break;
                    case NSGreaterThanOrEqualToPredicateOperatorType:
                        query = [self queryOnField:field operator:KCSQueryGreaterThanOrEqual toValue:val];
                        break;
                    case NSEqualToPredicateOperatorType:
                        query = [self queryMatchField:field toValue:val];
                        break;
                    default:
                        break;
                }
            }
        } else {
            //other kinds of preditcate modifiers
            BadPredicate()
        }
    } else {
        //other kinds of predicate classes
        BadPredicate()
    }
    if (query == nil) BadPredicate()
    return query;
}

NSString* kcsConvertMongoOpToPredicate(NSString* op)
{
    static NSDictionary* opMapper;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        opMapper = @{@"$lt"    : @"<",
                     @"$lte"   : @"<=",
                     @"$gt"    : @">",
                     @"$gte"   : @">=",
                     @"ne"     : @"!=",
                     @"$in"    : @"IN",
                     @"$regex" : @"MATCHES"};
    });
    return opMapper[op];
}

#warning add test for _filename IN {'Evan.O'Donnell.png'}

NSString* kcsEscapeForPred(NSString* string)
{
    string = [string stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    string = [string stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
    string = [string stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    return string;
}

id kcsConvertMongoValToPredicate(id val)
{
    id retVal = val;
    if ([val isKindOfClass:[NSString class]]) {
        retVal = [NSString stringWithFormat:@"'%@'", kcsEscapeForPred(val)];
    } else if ([val isKindOfClass:[NSArray class]]) {
        if ([val count] > 0) {
            retVal = [NSString stringWithFormat:@"{'%@'}", kcsEscapeForPred([val componentsJoinedByString:@"','"])];
        } else {
            retVal = @"{}";
        }
    } else if ([val isKindOfClass:[NSDictionary class]]) {
        retVal = nil;
    }
    return retVal;
}


- (NSPredicate*) predicate
{
    __block NSPredicate* predicate = nil;
    if (self.internalRepresentation.count == 0) {
        predicate = [NSPredicate predicateWithValue:YES];
    }
    [self.internalRepresentation enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([key hasPrefix:@"$"]) {
            //is an operator
        } else {
            //is a field
            if ([obj isKindOfClass:[NSDictionary class]]) {
                NSDictionary* query = obj;
                if (query.count == 1) {
                    NSString* op = [query allKeys][0];
                    id val = query[op];
                    //todo handle val err if dict
                    NSString* fOp = kcsConvertMongoOpToPredicate(op);
                    id fVal = kcsConvertMongoValToPredicate(val);
                    
                    if (kcsQueryIsComparisonS(op) && ![val isKindOfClass:[NSNumber class]]) {
                        if ([val isKindOfClass:[NSString class]]) {
                            NSRange range = [((NSString*)val) rangeOfString:@"^ISODate\\(\"\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d{3}Z\"\\)$" options:NSRegularExpressionSearch];
                            if (range.location != NSNotFound) {
                                range = [val rangeOfString:@"\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d{3}Z" options:NSRegularExpressionSearch];
                                NSString* dateStr = [val substringWithRange:range];
                                NSDate* date = [NSDate dateFromISO8601EncodedString:dateStr];
                                NSString* format = [NSString stringWithFormat:@"%@ %@ %%@", key, fOp];
                                predicate = [NSPredicate predicateWithFormat:format, date];
                            }
                        }
//                        predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
//                            NSComparisonResult* c = [evaluatedObject compare:<#(NSNumber *)#>]
//                        }];
                    } else {
                    
                        NSString* format = [NSString stringWithFormat:@"%@ %@ %@", key, fOp, fVal];
                        @try {
                            predicate = [NSPredicate predicateWithFormat:format];
                        }
                        @catch (NSException *exception) {
                            KCSLogError(KCS_LOG_CONTEXT_DATA, @"Error making predicate: %@", exception);
                        }
                    }
                } else {
                    //undef error
                }
            } else {
                NSString* format = [NSString stringWithFormat:@"%@ like \"%@\"", key, obj];
                @try {
                    predicate = [NSPredicate predicateWithFormat:format];
                }
                @catch (NSException *exception) {
                    KCSLogError(KCS_LOG_CONTEXT_DATA, @"Error making predicate: %@", exception);
                }
                @finally {
                }
            }
        }
    }];
    if (!predicate) {
//        KCSLogError(KCS_LOG_CONTEXT_DATA, @"Support for query \"%@\" not supported yet. Contact support@kinvey.com to get this supported.", self.internalRepresentation);
        DBAssert(NO, @"Support query: %@", self.internalRepresentation);
        predicate = [NSPredicate predicateWithValue:YES];
    }
    return predicate;
}

#pragma mark - sorting
- (NSArray *)sortDescriptors
{
    return [_mySortDescriptors copy];
}

- (void)setSortDescriptors:(NSArray *)sortDescriptors
{
    _mySortDescriptors = [NSMutableArray arrayWithCapacity:sortDescriptors.count];
    for (NSSortDescriptor* sort in sortDescriptors) {
        if (sort.comparator != nil) {
            [[NSException exceptionWithName:NSInvalidArgumentException reason:@"Cannot use a comparator with Kinvey backend" userInfo:@{@"invalidSort":sort}] raise];
        }
        if (sort.selector != @selector(compare:)) {
            [[NSException exceptionWithName:NSInvalidArgumentException reason:@"Cannot use a selector with Kinvey backend" userInfo:@{@"invalidSort":sort}] raise];
        }
        [_mySortDescriptors addObject:sort];
    }
}

//TODO handle backend vs client property name
- (NSString*) sortString:(BOOL)escape
{
    NSString* sortString = @"";
    if ([_mySortDescriptors count] > 0) {
        NSMutableDictionary* sortDictionary = [NSMutableDictionary dictionary];
        for (NSSortDescriptor* sort in _mySortDescriptors) {
            NSNumber* direction = sort.ascending ? @(1) : @(-1);
            NSString* key = sort.key;
            sortDictionary[key] = direction;
        }
        sortString = [NSString stringWithFormat:@"&sort=%@", escape ? [sortDictionary escapedJSON] : [sortDictionary kcsJSONStringRepresentation:nil]];
    }
    
    return sortString;
}

#pragma mark - stringification

- (NSString*) queryString:(BOOL)escape
{
    NSString* query =  [NSString stringWithFormat:@"?query=%@", escape ? [_internalRepresentation escapedJSON] : [_internalRepresentation kcsJSONStringRepresentation:nil]];
    query = [query stringByAppendingString:[self sortString:escape]];
    if (self.limit > 0 ) {
        query = [query stringByAppendingFormat:@"&limit=%lu", (unsigned long)self.limit];
    }
    if (self.offset > 0) {
        query = [query stringByAppendingFormat:@"&skip=%lu", (unsigned long)self.offset];
    }
    return query;
}

- (NSString *)escapedQueryString
{
    return [self queryString:YES];
}

#pragma mark - Compatability

+ (instancetype) queryWithQuery1:(KCSQuery *)query
{
    KCSQuery2* q = [[self alloc] init];
    q.internalRepresentation = [query.query mutableCopy];
    
    if ([[query sortModifiers] count] > 0) {
        NSMutableArray* sorts = [NSMutableArray arrayWithCapacity:query.sortModifiers.count];
        for (KCSQuerySortModifier* mod in query.sortModifiers) {
            NSSortDescriptor* sort = [NSSortDescriptor sortDescriptorWithKey:mod.field ascending:mod.direction == kKCSAscending];
            [sorts addObject:sort];
        }
        q.sortDescriptors = sorts;
    }
    
    if (query.limitModifer) {
        q.limit = query.limitModifer.limit;
    }
    
    if (query.skipModifier) {
        q.offset = query.skipModifier.count;
    }
    
    return q;
}

@end

#pragma clang diagnostic pop
