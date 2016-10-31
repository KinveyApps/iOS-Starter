//
//  KCSQuery.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/26/12.
//  Copyright (c) 2012-2015 Kinvey. All rights reserved.
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


#import "KCSQuery.h"
#import "KCSLogManager.h"
#import "NSString+KinveyAdditions.h"
#import "NSArray+KinveyAdditions.h"
#import "KinveyPersistable.h"
#import "KinveyEntity.h"
#import "KCSHiddenMethods.h"
#import "KCSBuilders.h"
#import "NSMutableDictionary+KinveyAdditions.h"
#import "KCSMetadata.h"
#import "NSDate+ISO8601.h"
#import "KCSMutableOrderedDictionary.h"
#import "NSDictionary+KinveyAdditions.h"

//http://www.mongodb.org/display/DOCS/Advanced+Queries#AdvancedQueries-%24type
typedef enum KCSQueryType : NSUInteger {
    KCSQueryTypeNull = 10
} KCSQueryType;

@protocol KCSQueryModifier <NSObject, NSCopying>
- (NSString *)parameterStringRepresentation;
@end

#pragma mark - KCSQuerySortModifier
@interface KCSQuerySortModifier () <KCSQueryModifier>
@end
@implementation KCSQuerySortModifier

- (instancetype) copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithField:_field inDirection:_direction];
}

- (instancetype)initWithField:(NSString *)field inDirection:(KCSSortDirection)direction
{
    self = [super init];
    if (self) {
        _field = field;
        _direction = direction;
    }
    return self;
}

- (NSString*) parameterStringRepresentation
{   //TODO: find out how to include these
    KCSLogError(@"tried to PSR on a Sort Modifier");
    return @"";
}

@end

#pragma mark - KCSQueryLimitModifier
@interface KCSQueryLimitModifier () <KCSQueryModifier>
@end
@implementation KCSQueryLimitModifier

- (instancetype) copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithLimit:_limit];
}

- (instancetype) initWithLimit:(NSInteger)limit
{
    self = [super init];
    if (self){
        _limit = limit;
    }
    return self;
}

- (NSString *)parameterStringRepresentation
{
    KCSLogDebug(@"Limit String: %@", [NSString stringWithFormat:@"limit=%ld", (long)self.limit]);
    return [NSString stringWithFormat:@"limit=%d", (int) self.limit];
}
@end

#pragma mark - KCSQuerySkipModifier
@interface KCSQuerySkipModifier () <KCSQueryModifier>
@end
@implementation KCSQuerySkipModifier
- (instancetype) copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithcount:_count];
}

- (instancetype)initWithcount:(NSInteger)count
{
    self = [super init];
    if (self){
        _count = count;
    }
    return self;
}

- (NSString *)parameterStringRepresentation
{
    KCSLogDebug(@"Count String: %@", [NSString stringWithFormat:@"skip=%ld", (long)self.count]);
    return [NSString stringWithFormat:@"skip=%d", (int) self.count];
}

@end

#pragma mark - TTL modifier
@interface KCSQueryTTLModifier () <KCSQueryModifier>
@end
@implementation KCSQueryTTLModifier
- (instancetype) copyWithZone:(NSZone *)zone
{
    return [[[self class] alloc] initWithTTL:_ttl];
}
- (instancetype) initWithTTL:(NSNumber*)ttl
{
    self = [super init];
    if (self) {
        self.ttl = ttl;
    }
    return self;
}
- (NSString *)parameterStringRepresentation
{
    NSString* ttlStr = [NSString stringWithFormat:@"ttl_in_seconds=%@",_ttl];
    KCSLogDebug(@"TTL String: %@", ttlStr);
    return ttlStr;
}
@end

#pragma mark - Private Interface

// Private interface
@interface KCSQuery ()
@property (nonatomic, readwrite, copy) NSMutableDictionary *query;
@property (nonatomic, strong, readwrite) NSArray *sortModifiers;
@property (nonatomic, strong) NSArray* referenceFieldsToResolve;
@property (nonatomic, strong) KCSQueryTTLModifier* ttlModifier;


NSString *KCSConditionalStringFromEnum(KCSQueryConditional conditional);

+ (NSDictionary *)queryDictionaryWithFieldname: (NSString *)fieldname operation:(KCSQueryConditional)op forQueries:(NSArray *)queries useQueriesForOps: (BOOL)useQueriesForOps;


@end

#pragma mark -
#pragma mark KCSQuery Implementation

@implementation KCSQuery

NSString * KCSConditionalStringFromEnum(KCSQueryConditional conditional)
{
    static NSDictionary *KCSOperationStringLookup = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        KCSOperationStringLookup = @{
        // Basic Queries
        @(kKCSLessThan)           : @"$lt",
        @(kKCSLessThanOrEqual)    : @"$lte",
        @(kKCSGreaterThan)        : @"$gt",
        @(kKCSGreaterThanOrEqual) : @"$gte",
        @(kKCSNotEqual)           : @"$ne",
        
        // Geo Queries
        @(kKCSNearSphere)         : @"$nearSphere",
        @(kKCSWithinBox)          : @"$box",
        @(kKCSWithinCenterSphere) : @"$centerSphere",
        @(kKCSWithinPolygon)      : @"$polygon",
        @(kKCSMaxDistance)        : @"$maxDistance",
        
        // String Operators
        @(kKCSRegex) : @"$regex",
        
        // Joining Operators
        @(kKCSIn)    : @"$in",
        @(kKCSOr)    : @"$or",
        @(kKCSAnd)   : @"$and",
        @(kKCSNotIn) : @"$nin",
        
        // Array Operators
        @(kKCSAll)  : @"$all",
        @(kKCSSize) : @"$size",
        
        // Internal Operators
        @(kKCSWithin)  : @"$within",
        @(kKCSOptions) : @"$options",
        @(kKCSExists)  : @"$exists",
        @(kKCSType)    : @"$type",
        };
    });

    return [KCSOperationStringLookup objectForKey:@(conditional)];
}

+ (NSDictionary *)queryDictionaryWithFieldname: (NSString *)fieldname operation:(KCSQueryConditional)op forQueries:(NSArray *)queries useQueriesForOps: (BOOL)useQueriesForOps
{
    NSDictionary *query = nil;
    NSString *opName = KCSConditionalStringFromEnum(op);
    
    if (useQueriesForOps == YES){
        op = kKCSMulti;
    }
    
    switch (op) {
            
        // These guys all have the extra nesting
        case kKCSNearSphere:
        case kKCSWithinBox:
        case kKCSWithinCenterSphere:
        case kKCSWithinPolygon:
        {
            if (queries.count > 1){
                // ERROR
                return nil;
            }
            NSString *within = KCSConditionalStringFromEnum(kKCSWithin);
            NSDictionary *geoQ = nil;
            if (op == kKCSNearSphere){
                geoQ = @{ opName : queries[0] };
            } else {
                geoQ = @{ within :@{ opName : queries[0]}};
            }
            
            //////////// HACK //////////////
            ///// For right now Kinvey has _geoloc as a free indexed property, if the user is using a geoquery now
            if ([fieldname isEqualToString:KCSEntityKeyGeolocation] == NO) {
                //not geoloc
                NSString* reason = [NSString stringWithFormat:@"Attempting to geo-query field '%@'. Geo-location queries can only be performed on the field 'KCSEntityKeyGeolocation'.",fieldname];
                @throw [NSException exceptionWithName:@"InvalidQuery" reason:reason userInfo:nil];
            }
            query = @{KCSEntityKeyGeolocation : geoQ};
            ////
            //////////// HACK //////////////
        }
            break;
            
            // Interior array ops
        case kKCSIn:
        case kKCSNotIn:
        {
            if (fieldname == nil || queries == nil){
                return nil;
            }
            if (queries.count >0 && [queries[0] isKindOfClass:[NSArray class]]) {
                queries = queries[0];
            }
            NSDictionary *innerQ = @{opName : queries};
            query = @{fieldname : innerQ};
        }
            break;
            // Exterior array ops
        case kKCSOr:
        case kKCSAnd:
            
            if (fieldname != nil || queries == nil){
                KCSLogWarning(@"Fieldname was not nil (was %@) for a joining op, this is unexpected", fieldname);
                return nil;
            }
            
            query = @{opName : queries};
            
            break;
            
            // This is the case where we're doing a direct match
        case kKCSNOOP:
            
            if (fieldname == nil || queries == nil || queries.count > 1){
                // ERROR!
                return nil;
            }
            query = @{ fieldname : queries[0]};
            break;
            
        case kKCSLessThan:
        case kKCSLessThanOrEqual:
        case kKCSGreaterThan:
        case kKCSGreaterThanOrEqual:
        case kKCSNotEqual:
        case kKCSRegex:
        case kKCSMulti:
        case kKCSExists:
        case kKCSType:
            
            if (fieldname == nil){
                // Error
                return nil;
            }
            
            if (!useQueriesForOps){
                if (op == kKCSNOOP || queries == nil || queries.count > 1){
                    // Error
                    return nil;
                }
                
                query = @{ fieldname : @{ opName : queries[0]} };
            } else {
                BOOL isGeoQuery = NO;
                if (op != kKCSMulti || queries == nil){
                    // Error
                    return nil;
                }
                
                NSMutableDictionary *tmp = [NSMutableDictionary dictionary];
                for (NSDictionary *pair in queries) {
                    KCSQueryConditional thisOp = [[pair objectForKey:@"op"] intValue];
                    NSObject *q = [pair objectForKey:@"query"];
                    [tmp setObject:q forKey:KCSConditionalStringFromEnum(thisOp)];
                    
                    // Make sure to account for Geo Queries in this version of KCS
                    switch(thisOp){
                        case kKCSNearSphere:
                        case kKCSWithinBox:
                        case kKCSWithinCenterSphere:
                        case kKCSWithinPolygon:
                        case kKCSMaxDistance:
                            isGeoQuery = YES;
                            break;
                        default:
                            break;
                    }
                }
                
                if (isGeoQuery){
                    //////////// HACK //////////////
                    ///// For right now Kinvey has _geoloc as a free indexed property, if the user is using a geoquery now, then we
                    ////  rewrite to the correct property, in the future use their passed in property
#if 0
                    query = @{fieldname : tmp};
#else
                    query = @{KCSEntityKeyGeolocation : tmp};
#endif
                    ////
                    //////////// HACK //////////////
                } else {
                    
                    query = [NSDictionary dictionaryWithObject:tmp forKey:fieldname];
                }
                
            }
            break;
            
            
            // These are not yet implemented...
        case kKCSAll:
        case kKCSSize:
            return nil;
            break;
            
        default:
            break;
    }
    
    return query;
}

- (id)init
{
    self = [super init];
    if (self){
        _query = [NSMutableDictionary dictionary];
        _sortModifiers = @[];
        _referenceFieldsToResolve = @[];
    }
    return self;
}


- (void)setQuery:(NSMutableDictionary *)query
{
    if (_query == query){
        return;
    }
    _query = [query mutableCopy];
}

+ (id) valueOrKCSPersistableId:(NSObject*) value field:(NSString*)field
{
    if (([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSNull class]]) == NO) {
        //there's no test to determine if an object has an id since there's a NSObject category
        @try {
            if ([field isEqualToString:KCSMetadataFieldLastModifiedTime] && [value isKindOfClass:[NSDate class]]) {
                value = [(NSDate*)value stringWithISO8601Encoding];
            } else {
                NSDictionary* builders = defaultBuilders();
                Class<KCSDataTypeBuilder> builderClass = [builders objectForKey:[value classForCoder]];
                if (builderClass) {
                    value = [builderClass JSONCompatabileValueForObject:value];
                } else {
                    value = [value kinveyObjectId];
                }
            }
        }
        @catch (NSException *exception) {
            // do nothing in this case
        }
    }
    if ([value isKindOfClass:[NSArray class]]) {
        //handle arrays of objects
        NSMutableArray* mArray = [value mutableCopy];
        for (NSObject* obj in [value copy]) {
            [mArray removeObject:obj];
            [mArray addObject:[self valueOrKCSPersistableId:obj field:field]];
        }
        value = mArray;
    }
    return value;
}

#pragma mark - Creating Queries
+ (KCSQuery *)queryOnField:(NSString*)field withRegex:(NSString*)pattern
{
    if ([pattern isKindOfClass:[NSString class]] == NO || [pattern hasPrefix:@"^"] == NO) {
        [NSException exceptionWithName:NSInvalidArgumentException reason:@"Regex pattern must be a string starting with `^`." userInfo:nil];
    }
    
    return [self queryOnField:field usingConditional:kKCSRegex forValue:pattern];
}

+ (KCSQuery *)queryOnField:(NSString *)field usingConditional:(KCSQueryConditional)conditional forValue: (NSObject *)value
{
    KCSQuery *query = [KCSQuery query];
    value = [KCSQuery valueOrKCSPersistableId:value field:field];
    
    query.query = [[self queryDictionaryWithFieldname:field operation:conditional forQueries:@[value] useQueriesForOps:NO] mutableCopy];
    
    return query;
    
}

+ (KCSQuery *)queryOnField:(NSString *)field withExactMatchForValue:(NSObject *)value
{
    if (!value) [[NSException exceptionWithName:NSInvalidArgumentException reason:@"value should not be `nil`" userInfo:nil] raise];
    
    if ([value isEqual:[NSNull null]]) {
        //for the special case using 'null' in mongo is not exist or null; but since this is an exact value test, we are hijacking and returing the matches `null` query
        return [KCSQuery queryOnField:field usingConditional:kKCSType forValue:@(KCSQueryTypeNull)];
    }
    
    KCSQuery *query = [self query];
    
    value = [self valueOrKCSPersistableId:value field:field];
    
    query.query = [[KCSQuery queryDictionaryWithFieldname:field operation:kKCSNOOP forQueries:@[value] useQueriesForOps:NO] mutableCopy];
    
    return query;
    
}

+ (KCSQuery *)queryOnField:(NSString *)field usingConditionalsForValues:(KCSQueryConditional)firstConditional, ...
{
    va_list items;
    va_start(items, firstConditional);
    KCSQuery* query = [self queryOnField:field usingConditionalsForValuesArgs:items firstArg:firstConditional];
    va_end(items);
    
    return query;
}

+(KCSQuery *)queryOnField:(NSString *)field usingConditionalsForValuesArgs:(va_list)items
{
    return [self queryOnField:field usingConditionalsForValuesArgs:items firstArg:va_arg(items, KCSQueryConditional)];
}

+(KCSQuery *)queryOnField:(NSString *)field usingConditionalsForValuesArgs:(va_list)items firstArg:(KCSQueryConditional)firstArg
{
    NSMutableArray *args = [NSMutableArray array];
    
    KCSQueryConditional currentCondition = firstArg;
    
    while (currentCondition) {
        id currentQuery = va_arg(items, id);
        NSDictionary *pair = @{ @"op" : @(currentCondition), @"query" : currentQuery};
        [args addObject:pair];
        //do it this way b/c for last condition currentCondition == 0 and the next one will be undefined
        currentCondition = va_arg(items, KCSQueryConditional);
    }
    
    KCSQuery *query = [self query];
    
    query.query = [[KCSQuery queryDictionaryWithFieldname:field operation:kKCSNOOP forQueries:args useQueriesForOps:YES] mutableCopy];
    
    return query;
}

+(BOOL)numberIsKCSQueryConditional:(NSNumber*)queryConditional
{
    switch ((KCSQueryConditional) queryConditional.integerValue) {
        case kKCSNOOP:
        case kKCSLessThan:
        case kKCSLessThanOrEqual:
        case kKCSGreaterThan:
        case kKCSGreaterThanOrEqual:
        case kKCSNotEqual:
        case kKCSNearSphere:
        case kKCSWithinBox:
        case kKCSWithinCenterSphere:
        case kKCSWithinPolygon:
        case kKCSNotIn:
        case kKCSIn:
        case kKCSMaxDistance:
        case kKCSRegex:
        case kKCSOr:
        case kKCSAnd:
        case kKCSAll:
        case kKCSSize:
        case kKCSWithin:
        case kKCSMulti:
        case kKCSOptions:
        case kKCSExists:
        case kKCSType:
            return true;
        default:
            return false;
    }
}

+(KCSQuery *)queryOnField:(NSString *)field usingConditionalPairs:(NSArray *)conditionalPairs
{
    NSMutableArray *args = [NSMutableArray array];
    
    KCSQueryConditional currentCondition;
    id currentConditionPtr = nil, currentQuery = nil;
    for (NSUInteger i = 0; i < conditionalPairs.count; i += 2) {
        currentConditionPtr = conditionalPairs[i];
        if (![currentConditionPtr isKindOfClass:[NSNumber class]] || ![self numberIsKCSQueryConditional:(NSNumber*) currentConditionPtr]) {
            @throw [NSException exceptionWithName:@"Invalid Parameter" reason:[NSString stringWithFormat:@"Index %@ is not a KCSQueryConditional.", @(i)] userInfo:nil];
        }
        currentCondition = (KCSQueryConditional) ((NSNumber*) currentConditionPtr).integerValue;
        
        if (i + 1 >= conditionalPairs.count) {
            @throw [NSException exceptionWithName:@"Invalid Parameter" reason:[NSString stringWithFormat:@"The conditionalPairs argument must be pairs of KCSQueryConditional and values. Index %@ does not have a value associated.", @(i)] userInfo:nil];
        }
        currentQuery = conditionalPairs[i + 1];
        
        NSDictionary *pair = @{ @"op" : @(currentCondition), @"query" : currentQuery};
        [args addObject:pair];
    }
    
    KCSQuery *query = [self query];
    
    query.query = [[KCSQuery queryDictionaryWithFieldname:field operation:kKCSNOOP forQueries:args useQueriesForOps:YES] mutableCopy];
    
    return query;
}

+ (KCSQuery *)queryForJoiningOperator:(KCSQueryConditional)joiningOperator onQueries: (KCSQuery *)firstQuery, ...
{
    NSMutableArray *queries = [NSMutableArray array];
    va_list args;
    va_start(args, firstQuery);
    for (KCSQuery *arg = firstQuery; arg != nil; arg = va_arg(args, KCSQuery *)){
        [queries addObject:arg.query];
    }
    va_end(args);
    
    KCSQuery *query = [self query];
    
    query.query = [[KCSQuery queryDictionaryWithFieldname:nil operation:joiningOperator forQueries:queries useQueriesForOps:NO] mutableCopy];
    
    return query;
}

BOOL kcsIsOperator(NSString* queryField)
{
    return [queryField hasPrefix:@"$"];
}

+ (NSMutableDictionary*) negateQuery:(KCSQuery*)query
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    // We need to take each key in query and replace the value with a dictionary containing the key $not and the old value
    for (NSString *field in query.query) {
        NSObject *oldQuery = [query.query objectForKey:field];
        if ([oldQuery isKindOfClass:[NSDictionary class]] == NO) {
            NSException* myException = [NSException exceptionWithName:@"InvalidArgument" reason:@"Cannot negate field/value type queries. Use conditional query with 'kKCSNotEqual' instead." userInfo:nil];
            @throw myException;
        }
        
        [dict setObject:@{@"$not" : oldQuery} forKey:field];
    }
    return dict;
}

+ (KCSQuery *)queryNegatingQuery:(KCSQuery *)query
{
    KCSQuery *q = [self query];
    q.query = [self negateQuery:query];
    
    return q;
}


+ (KCSQuery*) queryForEmptyValueInField:(NSString*)field
{
    return [self queryOnField:field usingConditional:kKCSExists forValue:@(NO)];
}

+ (KCSQuery*) queryForEmptyOrNullValueInField:(NSString*)field
{
    KCSQuery *query = [self query];
    query.query = [[self queryDictionaryWithFieldname:field operation:kKCSNOOP forQueries:@[[NSNull null]] useQueriesForOps:NO] mutableCopy];
    return query;
}

+ (instancetype)query
{
    KCSQuery *query = [[self alloc] init];
    return query;
}

+ (KCSQuery*) queryWithQuery:(KCSQuery *)query
{
    KCSQuery* newQuery = [self query];
    newQuery.query = query.query;

    //limit
    KCSQueryLimitModifier* oldLimit = query.limitModifer;
    if (oldLimit != nil) {
        newQuery.limitModifer = [oldLimit copy];
    }
    
    //skip
    KCSQuerySkipModifier* oldSKip = query.skipModifier;
    if (oldSKip != nil) {
        newQuery.skipModifier = [oldLimit copy];
    }
    
    //sort
    NSArray* sorts = query.sortModifiers;
    if (sorts != nil && sorts.count > 0) {
        NSMutableArray* newSorts = [NSMutableArray arrayWithCapacity:sorts.count];
        for (KCSQuerySortModifier* s in sorts) {
            [newSorts addObject:[[KCSQuerySortModifier alloc] initWithField:s.field inDirection:s.direction]];
        }
        newQuery.sortModifiers = newSorts;
    }
    
    //ttl
    if (query.ttlModifier != nil) {
        newQuery.ttlModifier = [query.ttlModifier copy];
    }
    
    return newQuery;
}


#pragma mark - Modifying Queries
- (void)addQuery: (KCSQuery *)query
{
    for (NSString *key in query.query) {
        [self.query setObject:[query.query objectForKey:key] forKey:key];
    }
}

- (void)addQueryOnField:(NSString *)field usingConditional:(KCSQueryConditional)conditional forValue: (NSObject *)value
{
    if (!value) [[NSException exceptionWithName:NSInvalidArgumentException reason:@"value should not be `nil`" userInfo:nil] raise];
    
    value = [KCSQuery valueOrKCSPersistableId:value field:field];
    
    NSDictionary *tmp = [KCSQuery queryDictionaryWithFieldname:field operation:conditional forQueries:@[value] useQueriesForOps:NO];
    
    for (NSString *key in tmp) {
        [self.query setObject:[tmp objectForKey:key] forKey:key];
    }
}

- (void)addQueryOnField:(NSString *)field withExactMatchForValue:(NSObject *)value
{
    if (!value) [[NSException exceptionWithName:NSInvalidArgumentException reason:@"value should not be `nil`" userInfo:nil] raise];
    
    value = [KCSQuery valueOrKCSPersistableId:value field:field];
    
    NSDictionary *tmp = [KCSQuery queryDictionaryWithFieldname:field operation:kKCSNOOP forQueries:@[value] useQueriesForOps:NO];
    for (NSString *key in tmp) {
        [self.query setObject:[tmp objectForKey:key] forKey:key];
    }
}

- (void)addQueryOnField:(NSString *)field usingConditionalsForValues:(KCSQueryConditional)firstConditional, ...
{
    NSMutableArray *args = [NSMutableArray array];
    va_list items;
    va_start(items, firstConditional);
    
    KCSQueryConditional currentCondition = firstConditional;
    NSObject *currentQuery = va_arg(items, NSObject *);
    
    while (currentCondition && currentQuery){
        NSDictionary *pair = @{@"op" : @(currentCondition), @"query" : currentQuery};
        [args addObject:pair];
        currentCondition = va_arg(items, KCSQueryConditional);
        currentQuery = va_arg(items, NSObject *);
        
    }
    va_end(items);
    
    NSDictionary *tmp = [KCSQuery queryDictionaryWithFieldname:field operation:kKCSNOOP forQueries:args useQueriesForOps:YES];
    for (NSString *key in tmp) {
        [self.query setObject:[tmp objectForKey:key] forKey:key];
    }
}

- (void)addQueryForJoiningOperator:(KCSQueryConditional)joiningOperator onQueries: (KCSQuery *)firstQuery, ...
{
    NSMutableArray *queries = [NSMutableArray array];
    va_list args;
    va_start(args, firstQuery);
    for (KCSQuery *arg = firstQuery; arg != nil; arg = va_arg(args, KCSQuery *)){
        [queries addObject:arg.query];
    }
    va_end(args);
    
    NSDictionary *tmp = [KCSQuery queryDictionaryWithFieldname:nil operation:joiningOperator forQueries:queries useQueriesForOps:NO];
    for (NSString *key in tmp) {
        [self.query setObject:[tmp objectForKey:key] forKey:key];
    }
}

- (void)addQueryNegatingQuery:(KCSQuery *)query
{
    NSMutableDictionary* d = [KCSQuery negateQuery:query];
    [self.query addEntriesFromDictionary:d];
}

- (void)clear
{
    [self.query removeAllObjects];
}


- (void)negateQuery
{
    self.query = [KCSQuery negateQuery:self];
}


// TODO: This should use common code for the AND case.
- (KCSQuery *)queryByJoiningQuery: (KCSQuery *)query usingOperator: (KCSQueryConditional)joiningOperator
{
    NSMutableDictionary *left = self.query;
    NSMutableDictionary *right = query.query;
    KCSQuery *q = [KCSQuery query];
    
    if (joiningOperator == kKCSOr){
        NSArray *queries = [NSArray arrayWithObjects:left, right, nil];
        q.query = [NSMutableDictionary dictionaryWithObject:queries forKey:KCSConditionalStringFromEnum(kKCSOr)];
    } else {
        
        NSMutableDictionary *tmp = [NSMutableDictionary dictionary];
        for (NSString *key in query.query) {
            [tmp setObject:[query.query objectForKey:key] forKey:key];
        }
        
        for (NSString *key in self.query) {
            [tmp setObject:[self.query objectForKey:key] forKey:key];
        }
        q.query = [tmp mutableCopy];
    }
    return q;
}

- (void)addSortModifier:(KCSQuerySortModifier *)modifier
{
    self.sortModifiers = [self.sortModifiers arrayByAddingObject:modifier];
}

- (void)clearSortModifiers
{
    // Assign an empty array to clear the modifiers (ie count == 0)
    self.sortModifiers = [NSArray array];
}

#pragma mark -
#pragma mark Validating Queries

+ (BOOL)validateQuery:(KCSQuery *)query
{
    return NO;
}

- (BOOL)isValidQuery
{
    return NO;
}


#pragma mark - Query Representations
- (BOOL) hasReferences
{
    return self.referenceFieldsToResolve != nil && self.referenceFieldsToResolve.count > 0;
}

- (NSString *)JSONStringRepresentation
{
    NSMutableDictionary* d = [_query mutableCopy];
    if ([self hasReferences]) {
        [_query append:@"._id" ontoKeySet:self.referenceFieldsToResolve recursive:YES];
    }
    return [d kcsJSONStringRepresentation:nil];
}

- (NSData *)UTF8JSONStringRepresentation
{
    return [NSJSONSerialization dataWithJSONObject:self.query
                                           options:0
                                             error:nil];
}

- (NSString *)parameterStringRepresentation
{
    NSString* stringRepresentation = @"";
    // Add the Query portion of the request
    if (self.query != nil && self.query.count > 0){
        NSString* stringRep = [self JSONStringRepresentation];
        NSString* queryString = [NSString stringWithFormat:@"query=%@", [NSString stringByPercentEncodingString:stringRep]];
        stringRepresentation = [stringRepresentation stringByAppendingQueryString:queryString];
    }
    
    // Add any sort modifiers
    if (self.sortModifiers.count > 0){
        stringRepresentation = [stringRepresentation stringByAppendingQueryString:[self parameterStringForSortKeys]];
    }
    
    // Add any limit modifiers
    if (self.limitModifer != nil){
        stringRepresentation = [stringRepresentation stringByAppendingQueryString:[self.limitModifer parameterStringRepresentation]];
    }
    
    // Add any skip modifiers
    if (self.skipModifier != nil){
        stringRepresentation = [stringRepresentation stringByAppendingQueryString:[self.skipModifier parameterStringRepresentation]];
    }
    
    //Add any references
    if ([self hasReferences]) {
        stringRepresentation = [stringRepresentation stringByAppendingQueryString:[@"resolve=" stringByAppendingString:[self.referenceFieldsToResolve join:@","]]];
    }
    
    //add ttls
    if (self.ttlModifier != nil) {
        stringRepresentation = [stringRepresentation stringByAppendingQueryString:[self.ttlModifier parameterStringRepresentation]];
    }
    
    KCSLogDebug(@"query: %@",stringRepresentation);
    return stringRepresentation;
}

- (NSString*)debugDescription
{
    return [self JSONStringRepresentation];
}

#pragma mark - Getting our sort keys
- (NSString *)parameterStringForSortKeys
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:self.sortModifiers.count];
    for (KCSQuerySortModifier *sortKey in self.sortModifiers) {
        NSNumber *direction = @(sortKey.direction);
        [dict setValue:direction forKey:sortKey.field];
    }
    
    NSString* jsonString = [dict kcsJSONStringRepresentation:nil];
    KCSLogDebug(@"Sort Keys: %@", [NSString stringWithFormat:@"sort=%@", jsonString]);
    
    return [NSString stringWithFormat:@"sort=%@", [NSString stringByPercentEncodingString:jsonString]];
    
}

#pragma mark - Equality / hashing for comparison
- (BOOL) isEqual:(id)object
{
    return [object isKindOfClass:[KCSQuery class]] && [[self JSONStringRepresentation] isEqualToString:[object JSONStringRepresentation]];
}

- (NSUInteger)hash
{
    return [[self JSONStringRepresentation] hash];
}

@end
