//
//  KCSEntityPersistence.m
//  KinveyKit
//
//  Created by Michael Katz on 5/14/13.
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


#import "KCSEntityPersistence.h"

#import "KinveyCoreInternal.h"
#import "KCSClient.h"
#import "KCS_FMDatabase.h"
#import "KCS_FMDatabaseAdditions.h"
#import "KCS_FMDatabaseQueue.h"
#import "KCSMutableOrderedDictionary.h"
#import "KinveyPersistable.h"
#import "KCSHttpRequest.h"

//IMPORTANT NOTE: please, always increase this number, never decrease to avoid clear your cache!
//IMPORTANT NOTE: if you changed the version, make sure that you have implemented a method that looks like -(void)upgradeDatabaseSchemaFromVersion5toVersion6:(KCS_FMDatabase*)db
#define KCS_CACHE_VERSION 5

#define KCSLogLastDatabaseError(db) KCSLogError(KCS_LOG_CONTEXT_FILESYSTEM, @"Err %d: %@", [db lastErrorCode], [db lastErrorMessage])

@interface KCSEntityPersistence ()
@property (nonatomic, strong) KCS_FMDatabaseQueue* db;
@end

@interface KCSCacheValueDB : NSObject
@property (nonatomic) NSUInteger count;
@property (retain, nonatomic) NSDictionary* object;
@property (nonatomic) BOOL unsaved;
@property (nonatomic, strong) NSDate* lastReadTime;
@property (nonatomic, strong) NSString* objId;
@property (nonatomic, strong) NSString* classname;
@end
@implementation KCSCacheValueDB

- (instancetype) init
{
    self = [super init];
    if (self) {
        _count = 1;
        _lastReadTime = [NSDate date];
    }
    return self;
}

@end

@implementation KCSEntityPersistence


- (NSString*) dbPath
{
    return [KCSFileUtils localPathForDB:[NSString stringWithFormat:@"com.kinvey.%@_cache.sqlite3", _persistenceId]];
}

- (instancetype) initWithPersistenceId:(NSString*)key
{
    self = [super init];
    if (self) {
        _persistenceId = key;
        
        [self initDB];
    }
    return self;
}

- (instancetype) init
{
    DBAssert(YES, @"should always init cache v2 with a name");
    return [self initWithPersistenceId:@"null"];
}

- (void) createMetadata
{
    [_db inDatabase:^(KCS_FMDatabase *db) {
        BOOL e = [db executeUpdate:@"CREATE TABLE metadata (id VARCHAR(255) PRIMARY KEY, version INTEGER not null, time TEXT)"];
        if (!e || [db hadError]) { KCSLogError(KCS_LOG_CONTEXT_FILESYSTEM, @"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);}
        e = [db executeUpdate:@"INSERT INTO metadata VALUES (:id, :version, :time)" withArgumentsInArray:@[@"1", @(KCS_CACHE_VERSION), @"2"]];
        if (!e || [db hadError]) { KCSLogError(KCS_LOG_CONTEXT_FILESYSTEM, @"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);}
    }];
}

- (void) initDB
{
    NSString* path = [self dbPath];
    _db = [KCS_FMDatabaseQueue databaseQueueWithPath:path flags:[KCSFileUtils dbFlags]];
    //    _db = [KCS_FMDatabase databaseWithPath:path];
//    if (![_db openWithFlags:[KCSFileUtils dbFlags]]) {
//        if ([_db hadError]) { KCSLogError(KCS_LOG_CONTEXT_FILESYSTEM, @"Err %d: %@", [_db lastErrorCode], [_db lastErrorMessage]);}
//        return;
//    }
    __block BOOL metaDataExists;
    [_db inDatabase:^(KCS_FMDatabase *db) {
        metaDataExists = [db tableExists:@"metadata"];
    }];
    if (!metaDataExists) {
        KCSLogDebug(KCS_LOG_CONTEXT_FILESYSTEM, @"Creating New Cache %@", path);
        [self createMetadata];
    } else {
        __block id version = nil;
        [_db inDatabase:^(KCS_FMDatabase *db) {
            KCS_FMResultSet *rs = [db executeQuery:@"SELECT version FROM metadata"];
            if ([db hadError]) { KCSLogError(KCS_LOG_CONTEXT_FILESYSTEM, @"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);}
            if ([rs next]) {
                NSDictionary* d = [rs resultDictionary];
                version = d[@"version"];
            }
            [rs close];
            
        }];
        if ([version isKindOfClass:[NSString class]]) {
            if ([version isEqualToString:@"0.004"]) { //last version value before the 'version' column becomes an integer
                [_db inDatabase:^(KCS_FMDatabase *db) {
                    [db beginTransaction];
                    [self upgradeDatabaseSchema:db
                                      toVersion:5]; //first version value after the 'version' column becomes an integer
                    BOOL result = [db commit];
                    if (!result) {
                        KCSLogLastDatabaseError(db);
                    }
                }];
            } else {
                [self clearCaches];
            }
        } else if ([version isKindOfClass:[NSNumber class]]) {
            NSNumber* versionNumber = version;
            __block long versionNumberLong = versionNumber.longValue;
            if (versionNumberLong < KCS_CACHE_VERSION) {
                [_db inDatabase:^(KCS_FMDatabase *db) {
                    SEL selector = nil;
                    while (versionNumberLong < KCS_CACHE_VERSION) {
                        [db beginTransaction];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                        long toVersionNumber = KCS_CACHE_VERSION;
                        while (toVersionNumber > versionNumberLong) {
                            selector = NSSelectorFromString([NSString stringWithFormat:@"upgradeDatabaseSchemaFromVersion%@toVersion%@:", @(versionNumberLong), @(toVersionNumber)]);
                            if ([self respondsToSelector:selector]) {
                                break;
                            } else {
                                if (toVersionNumber > versionNumberLong) {
                                    toVersionNumber--;
                                }
                            }
                        }
                        [self performSelector:selector
                                   withObject:db];
#pragma clang diagnostic pop
                        [self upgradeDatabaseSchema:db
                                          toVersion:toVersionNumber];
                        BOOL result = [db commit];
                        if (!result) {
                            KCSLogLastDatabaseError(db);
                        } else {
                            versionNumberLong++;
                        }
                    }
                }];
            } else if (versionNumberLong > KCS_CACHE_VERSION) {
                //clear the cache if the stored version is greater than the runtime version since we don't know how to handle this case nicely
                [self clearCaches];
            }
        }
    }
    
    [_db inDatabase:^(KCS_FMDatabase *db) {
        if (![db tableExists:@"queries"]) {
            BOOL e = [db executeUpdate:@"CREATE TABLE queries (id VARCHAR(255) PRIMARY KEY, ids TEXT, routeKey TEXT)"];
            if (!e) {
                KCSLogError(KCS_LOG_CONTEXT_FILESYSTEM, @"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
            }
        }
        if (![db tableExists:@"savequeue"]) {
            BOOL e = [db executeUpdate:@"CREATE TABLE savequeue (key TEXT PRIMARY KEY, id VARCHAR(255), routeKey TEXT, method TEXT, headers TEXT, time VARCHAR(255), obj TEXT)"];
            if (!e) {
                KCSLogError(KCS_LOG_CONTEXT_FILESYSTEM, @"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
            }
        }
        if (![db tableExists:@"groups"]) {
            BOOL e = [db executeUpdate:@"CREATE TABLE groups (key TEXT PRIMARY KEY, results TEXT)"];
            if (!e) {
                KCSLogError(KCS_LOG_CONTEXT_FILESYSTEM, @"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
            }
        }
        if (![db tableExists:@"clientmetadata"]) {
            BOOL e = [db executeUpdate:@"CREATE TABLE clientmetadata (key VARCHAR(255) PRIMARY KEY, metadata TEXT)"];
            if (!e) {
                KCSLogError(KCS_LOG_CONTEXT_FILESYSTEM, @"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
            }
        }
    }];
    
}

- (void)dealloc
{
    [_db close];
}

-(NSString*)keyValueForKey:(NSString*)key
                   headers:(NSDictionary*)headers
{
    KCSMutableOrderedDictionary* _headers = [KCSMutableOrderedDictionary dictionary];
    if (headers[kHeaderClientAppVersion]) {
        _headers[kHeaderClientAppVersion] = headers[kHeaderClientAppVersion];
    }
    if (headers[kHeaderCustomRequestProperties]) {
        _headers[kHeaderCustomRequestProperties] = headers[kHeaderCustomRequestProperties];
    }
    
    NSDictionary* keyDictionary = @{
        @"key" : key,
        @"headers" : _headers
    };
    
    NSError* error = nil;
    NSData* data = [NSJSONSerialization dataWithJSONObject:[KCSMutableOrderedDictionary dictionaryWithDictionary:keyDictionary]
                                                   options:0
                                                     error:&error];
    
    if (error) {
        [[NSException exceptionWithName:error.domain
                                 reason:error.localizedDescription ? error.localizedDescription : error.description
                               userInfo:error.userInfo] raise];
    }
    
    if (data) {
        return [[NSString alloc] initWithData:data
                                     encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

#pragma mark - Metadata
- (BOOL) setClientMetadata:(NSDictionary*)metadata
{
    NSError* error = nil;
    NSData* data = [NSJSONSerialization dataWithJSONObject:metadata
                                                   options:0
                                                     error:&error];
    if (error != nil) {
        KCSLogError(KCS_LOG_CONTEXT_DATA, @"could not serialize: %@", metadata);
        return NO;
    }
    NSString* metaStr = [[NSString alloc] initWithData:data
                                              encoding:NSUTF8StringEncoding];
    __block BOOL e;
    [_db inDatabase:^(KCS_FMDatabase *db) {
        e = [db executeUpdate:@"REPLACE INTO clientmetadata VALUES (:key, :metadata)" withArgumentsInArray:@[@"client", metaStr]];
        if (!e || [db hadError]) { KCSLogError(KCS_LOG_CONTEXT_FILESYSTEM, @"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        }
    }];
    return e;
}

- (NSDictionary*) clientMetadata
{
    NSString* q = [NSString stringWithFormat:@"SELECT metadata FROM clientmetadata WHERE key='client'"];
    
    __block NSDictionary* obj = nil;
    [_db inDatabase:^(KCS_FMDatabase *db) {
        KCS_FMResultSet* rs = [db executeQuery:q];
        if ([db hadError]) {
            KCSLogError(KCS_LOG_CONTEXT_FILESYSTEM, @"DB error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        }
        
        if ([rs next]) {
            NSDictionary* d = [rs resultDictionary];
            if (d) {
                obj = [self dictObjForJson:d[@"metadata"]];
            }
        }
        [rs close];
    }];

    return obj;
}

#pragma mark - Save Queue

- (NSString*) addUnsavedEntity:(NSDictionary*)entity route:(NSString*)route collection:(NSString*)collection method:(NSString*)method headers:(NSDictionary*)headers
{
    NSString* _id = [entity isKindOfClass:[NSString class]] ? entity : entity[KCSEntityKeyId];
    if (_id == nil) {
        KCSLogInfo(KCS_LOG_CONTEXT_DATA, @"nil `_id` in %@. Adding local id.", entity);
        _id = [KCSDBTools KCSMongoObjectId];
        entity = [entity dictionaryByAddingDictionary:@{KCSEntityKeyId : _id}];
    }
    
    NSError* error = nil;
    NSData* data = [NSJSONSerialization dataWithJSONObject:entity
                                                   options:0
                                                     error:&error];
    if (error) {
        KCSLogError(KCS_LOG_CONTEXT_DATA, @"could not serialize: %@", entity);
        DBAssert(NO, @"No object");
    }
    NSString* entityStr = [[NSString alloc] initWithData:data
                                                encoding:NSUTF8StringEncoding];

    data = [NSJSONSerialization dataWithJSONObject:headers
                                           options:0
                                             error:&error];
    if (error) {
        KCSLogError(KCS_LOG_CONTEXT_DATA, @"could not serialize: %@", headers);
        DBAssert(NO, @"No object");
    }
    NSString* headerStr = [[NSString alloc] initWithData:data
                                                encoding:NSUTF8StringEncoding];
    
    NSString* routeKey = [self tableForRoute:route collection:collection];
    
    NSString *key = [self keyValueForKey:[routeKey stringByAppendingString:_id]
                                 headers:headers];

    NSString* update = @"REPLACE INTO savequeue VALUES (:key, :id, :routeKey, :method, :headers, :time, :obj)";
    NSDictionary* valDictionary = @{@"key": key,
                                    @"id":_id,
                                    @"obj":entityStr,
                                    @"time":[NSDate date],
                                    @"routeKey": routeKey,
                                    @"headers": headerStr,
                                    @"method":method};
    
    __block BOOL updated;
    [_db inDatabase:^(KCS_FMDatabase *db) {
        updated = [db executeUpdate:update withParameterDictionary:valDictionary];
        if (!updated) {
            KCSLogError(KCS_LOG_CONTEXT_DATA, @"Error insert/updating %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        }
    }];
    return updated ? _id : nil;
}

- (BOOL) addUnsavedDelete:(NSString*)key route:(NSString*)route collection:(NSString*)collection method:(NSString*)method headers:(NSDictionary*)headers
{
    DBAssert(key, @"should save with a key");
    
    NSError* error = nil;
    NSData* data = [NSJSONSerialization dataWithJSONObject:headers
                                                   options:0
                                                     error:&error];
    if (error != nil) {
        KCSLogError(KCS_LOG_CONTEXT_DATA, @"could not serialize: %@", headers);
        DBAssert(NO, @"No object");
    }
    NSString* headerStr = [[NSString alloc] initWithData:data
                                                encoding:NSUTF8StringEncoding];
    
    NSString* routeKey = [self tableForRoute:route collection:collection];
    
    key = [self keyValueForKey:[routeKey stringByAppendingString:key]
                       headers:headers];
    
    NSString* update = @"REPLACE INTO savequeue VALUES (:key, :id, :routeKey, :method, :headers, :time, :obj)";
    NSDictionary* valDictionary = @{@"key":key,
                                    @"id":key,
                                    @"obj":key,
                                    @"time":[NSDate date],
                                    @"routeKey": routeKey,
                                    @"headers": headerStr,
                                    @"method":method};
    __block BOOL updated;
    [_db inDatabase:^(KCS_FMDatabase *db) {
        updated = [db executeUpdate:update withParameterDictionary:valDictionary];
        if (!updated) {
            KCSLogError(KCS_LOG_CONTEXT_DATA, @"Error insert/updating %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        }
    }];
    return updated;
}


- (NSDictionary*) dictObjForJson:(NSString*)s
{
    NSError* error = nil;
    NSMutableDictionary* obj = [NSJSONSerialization JSONObjectWithData:[s dataUsingEncoding:NSUTF8StringEncoding]
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&error];
    if (error) {
        KCSLogError(KCS_LOG_CONTEXT_DATA, @"DB deserialization error %@", error);
    }
    return obj;
}

- (NSArray*) unsavedEntities
{
    NSString* query = @"SELECT * from savequeue ORDER BY time";
    __block NSMutableArray* entities = [NSMutableArray array];
    [_db inDatabase:^(KCS_FMDatabase *db) {
        KCS_FMResultSet* results = [db executeQuery:query];
        if ([db hadError]) {
            KCSLogError(KCS_LOG_CONTEXT_FILESYSTEM, @"DB error (looking up unsaved entities) %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        }
        
        while ([results next]) {
            NSDictionary* d = [results resultDictionary];
            if (d) {
                NSDictionary* obj = [self dictObjForJson:d[@"obj"]];
                if (!obj) obj = d[@"obj"];
                NSDictionary* headers = [self dictObjForJson:d[@"headers"]];
                NSString* routeKey = d[@"routeKey"];
                NSArray* routes = [routeKey componentsSeparatedByString:@"_"];
                NSString* route = routes[0];
                NSString* collection = routes[1];
                NSDictionary* entity = @{@"obj":obj,
                                         @"headers":headers,
                                         @"time":[NSDate dateWithTimeIntervalSince1970:[d[@"time"] doubleValue]],
                                         @"method":d[@"method"],
                                         @"_id":d[@"id"],
                                         @"route":route,
                                         @"collection":collection};
                if (entity) {
                    [entities addObject:entity];
                }
            }
        }
        [results close];
    }];
    
    return entities;
}

- (int) unsavedCount
{
    __block int result;
    [_db inDatabase:^(KCS_FMDatabase *db) {
        result = [db intForQuery:@"SELECT COUNT(*) FROM savequeue"];
        if ([db hadError]) {
            KCSLogError(KCS_LOG_CONTEXT_FILESYSTEM, @"DB error in unsaved count %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        }
    }];
    return result;
}

- (BOOL) removeUnsavedEntity:(NSString*)unsavedId
                       route:(NSString*)route
                  collection:(NSString*)collection
                     headers:(NSDictionary*)headers
{
    KCSLogDebug(KCS_LOG_CONTEXT_FILESYSTEM, @"Deleting obj %@ from unsaved queue", unsavedId);
    
    NSString* routeKey = [self tableForRoute:route collection:collection];
    NSString* entityKey = [self keyValueForKey:[routeKey stringByAppendingString:unsavedId]
                                       headers:headers];
    
    NSString* update = [NSString stringWithFormat:@"DELETE FROM savequeue WHERE key='%@'", entityKey];

    __block BOOL updated;
    [_db inDatabase:^(KCS_FMDatabase *db) {
        updated = [db executeUpdate:update];
        if (updated == NO) {
            KCSLogError(KCS_LOG_CONTEXT_FILESYSTEM, @"Cache error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        }
    }];
    return updated;

}

#pragma mark - Updates
- (NSString*) tableForRoute:(NSString*)route collection:(NSString*)collection
{
//    collection = [collection stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
    return [NSString stringWithFormat:@"%@_%@",route,collection];
}

- (BOOL) tableExists:(NSString*)tableString
{
//    static NSCharacterSet* charset;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        charset = [NSCharacterSet characterSetWithCharactersInString:@"[]"];
//    });
    __block BOOL exsits;
    [_db inDatabase:^(KCS_FMDatabase *db) {
//        exsits = [db tableExists:[tableString stringByTrimmingCharactersInSet:charset]];
        exsits = [db tableExists:tableString];
    }];
    return exsits;
}

- (BOOL) updateWithEntity:(NSDictionary*)entity route:(NSString*)route collection:(NSString*)collection
{
    NSString* _id = entity[KCSEntityKeyId];
    if (_id == nil) {
        KCSLogError(KCS_LOG_CONTEXT_DATA, @"nil `_id` in %@", entity);
        DBAssert(YES, @"No id!");
    }
    NSError* error = nil;
    NSData* data = [entity kcsJSONDataRepresentation:&error];
    if (error != nil) {
        KCSLogError(KCS_LOG_CONTEXT_DATA, @"could not serialize: %@", entity);
        DBAssert(YES, @"No object");
        return NO;
    }
    NSString* objStr = [[NSString alloc] initWithData:data
                                             encoding:NSUTF8StringEncoding];
    
    KCSLogDebug(KCS_LOG_CONTEXT_DATA, @"Insert/update %@/%@", _persistenceId, _id);
    NSDictionary* valDictionary = @{@"id":_id,
                                    @"obj":objStr,
                                    @"time":[NSDate date],
                                    @"dirty":@NO, //TODO
                                    @"count":@1, //TODO
                                    @"classname":@"" //TODO
                                    };
    
    NSString* table = [self tableForRoute:route collection:collection];

    if (![self tableExists:table]) {
        NSString* update = [NSString stringWithFormat:@"CREATE TABLE [%@] (id VARCHAR(255) PRIMARY KEY, obj TEXT, time VARCHAR(255), saved BOOL, count INT, classname TEXT)", table];
        
        [_db inDatabase:^(KCS_FMDatabase *db) {
            BOOL created = [db executeUpdate:update];
            if (created == NO) {
                KCSLogError(KCS_LOG_CONTEXT_FILESYSTEM, @"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
            }
        }];
    }

    
    NSString* update = [NSString stringWithFormat:@"REPLACE INTO [%@] VALUES (:id, :obj, :time, :dirty, :count, :classname)", table];
    __block BOOL updated = NO;
    [_db inDatabase:^(KCS_FMDatabase *db) {
        updated = [db executeUpdate:update withParameterDictionary:valDictionary];
        if (updated == NO) {
            KCSLogError(KCS_LOG_CONTEXT_DATA, @"Error insert/updating %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        }
    }];
    return updated;
}

- (NSDictionary*) entityForId:(NSString*)_id route:(NSString*)route collection:(NSString*)collection
{
    NSString* table = [self tableForRoute:route collection:collection];
    NSString* q = [NSString stringWithFormat:@"SELECT * FROM [%@] WHERE id='%@'", table, _id];
    
    KCSLogDebug(KCS_LOG_CONTEXT_DATA, @"DB fetching '%@' from %@/%@", _id, route, collection);
    
    __block NSDictionary* obj = nil;
    [_db inDatabase:^(KCS_FMDatabase *db) {
        KCS_FMResultSet* rs = [db executeQuery:q];
        if ([db hadError]) {
            KCSLogError(KCS_LOG_CONTEXT_FILESYSTEM, @"DB error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        }
        
        if ([rs next]) {
            NSDictionary* d = [rs resultDictionary];
            if (d) {
                obj = [self dictObjForJson:d[@"obj"]];
            }
        }
        [rs close];
    }];
    
    return obj;
}

- (BOOL) removeEntity:(NSString*)_id route:(NSString*)route collection:(NSString*)collection
{
//    KCSCacheValueDB* val = [self dbObjectForId:objId];
//    val.count--;
//    if (val.count == 0) {
    KCSLogDebug(KCS_LOG_CONTEXT_FILESYSTEM, @"Deleting obj %@ from cache", _id);
    NSString* table = [self tableForRoute:route collection:collection];
    NSString* update = [NSString stringWithFormat:@"DELETE FROM [%@] WHERE id='%@'", table, _id];
    
    __block BOOL updated;
    [_db inDatabase:^(KCS_FMDatabase *db) {
        updated = [db executeUpdate:update];
        if (updated == NO) {
            KCSLogError(KCS_LOG_CONTEXT_FILESYSTEM, @"Cache error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        }
    }];
    return updated;
    //    }

}

#pragma mark - queries
- (NSString*)queryKey:(NSString*)query routeKey:(NSString*)routeKey
{
    return [NSString stringWithFormat:@"[%@]_%@", routeKey, query].sha1;
}

- (BOOL) setIds:(NSArray*)theseIds forQuery:(NSString*)query route:(NSString*)route collection:(NSString*)collection
{
    KCSLogDebug(KCS_LOG_CONTEXT_DATA, @"update query: '%@'", query);
    
    NSArray* oldIds = [self idsForQuery:query route:route collection:collection];
    if (oldIds && oldIds.count > 0) {
        NSMutableArray* removedIds = [oldIds mutableCopy];
        [removedIds removeObjectsInArray:theseIds];
        [self removeIds:removedIds route:route collection:collection];
    }
    
    NSError* error = nil;
    NSData* data = [NSJSONSerialization dataWithJSONObject:theseIds
                                                   options:0
                                                     error:&error];
    NSString* jsonStr = [[NSString alloc] initWithData:data
                                              encoding:NSUTF8StringEncoding];
    if (error) {
        KCSLogError(KCS_LOG_CONTEXT_DATA, @"could not serialize: %@", theseIds);
    }
    
    NSString* routeKey = [self tableForRoute:route collection:collection];
    NSString* queryKey = [self queryKey:query routeKey:routeKey];

    __block BOOL updated;
    [_db inDatabase:^(KCS_FMDatabase *db) {
        updated = [db executeUpdate:@"REPLACE INTO queries VALUES (:id, :ids, :routeKey)" withArgumentsInArray:@[queryKey, jsonStr, routeKey]];
        if (updated == NO) {
            KCSLogError(KCS_LOG_CONTEXT_FILESYSTEM, @"Cache error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        }
    }];
    return updated;
}

- (NSArray*)idsForQuery:(NSString*)query route:(NSString*)route collection:(NSString*)collection
{
    NSString* routeKey = [self tableForRoute:route collection:collection];
    NSString* queryKey = [self queryKey:query routeKey:routeKey];

    NSString* q = [NSString stringWithFormat:@"SELECT ids FROM queries WHERE id='%@'", queryKey];
    __block NSString* result = nil;
    [_db inDatabase:^(KCS_FMDatabase *db) {
        result = [db stringForQuery:q];
        if ([db hadError]) {
            KCSLogError(KCS_LOG_CONTEXT_FILESYSTEM, @"Cache error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        }
    }];
    NSMutableArray* ids = nil;

    if (result) {
        NSError* error = nil;
        ids = [NSJSONSerialization JSONObjectWithData:[result dataUsingEncoding:NSUTF8StringEncoding]
                                              options:NSJSONReadingMutableContainers
                                                error:&error];
        if (result != nil && error != nil) {
            KCSLogError(KCS_LOG_CONTEXT_DATA, @"Error converting id array string into array: %@", error);
        }
    }
    return ids;
}

- (NSArray*)allIds:(NSString*)route collection:(NSString*)collection
{
    NSString* table = [self tableForRoute:route collection:collection];

    NSString* q = [NSString stringWithFormat:@"SELECT id FROM [%@]", table];
    NSMutableArray* results = [NSMutableArray array];
    [_db inDatabase:^(KCS_FMDatabase *db) {
        KCS_FMResultSet* rs = [db executeQuery:q];
        if ([db hadError]) {
            KCSLogError(KCS_LOG_CONTEXT_FILESYSTEM, @"DB error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        }
        
        while ([rs next]) {
            NSDictionary* d = [rs resultDictionary];
            if (d) {
                NSString* anid = d[@"id"];
                if (anid) {
                    [results addObject:anid];
                }
            }
        }
        [rs close];
    }];

    return results;
}



- (NSUInteger) removeIds:(NSArray*)ids route:(NSString*)route collection:(NSString*)collection
{
    NSUInteger count = 0;
    for (NSString* _id in ids) {
        BOOL u = [self removeEntity:_id route:route collection:collection];
        if (u) count++;
    }
    return count;
}

- (BOOL) removeQuery:(NSString*)query route:(NSString*)route collection:(NSString*)collection
{
    KCSLogDebug(KCS_LOG_CONTEXT_DATA, @"remove query: '%@'", query);
    //TODO: deal with cleaning up unneeded entities - this just removes the query - not the associated objects
    
    NSString* routeKey = [self tableForRoute:route collection:collection];
    NSString* queryKey = [self queryKey:query routeKey:routeKey];

    __block BOOL updated;
    [_db inDatabase:^(KCS_FMDatabase *db) {
        updated = [db executeUpdateWithFormat:@"DELETE FROM queries WHERE id=%@", queryKey];
        if (updated == NO) {
            KCSLogError(KCS_LOG_CONTEXT_FILESYSTEM, @"Cache error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        }
    }];
    return updated;
}

#pragma mark - Import
- (BOOL) import:(NSArray *)entities route:(NSString *)route collection:(NSString *)collection
{
    if (entities == nil) return NO;
    //TODO set the all?
    for (NSDictionary* entity in entities) {
        BOOL updated = [self updateWithEntity:entity route:route collection:collection];
        if (updated == NO) {
            return NO;
        }
    }
    return YES;
}

- (NSArray*) export:(NSString*)route collection:(NSString*)collection
{
    NSString* table = [self tableForRoute:route collection:collection];
    
    if (![self tableExists:table]) {
        KCSLogWarn(KCS_LOG_CONTEXT_DATA, @"No persisted table for '%@'", collection);
        return @[];
    }

    NSString* query = [NSString stringWithFormat:@"SELECT * FROM [%@]", table];
    __block NSMutableArray* results = [NSMutableArray array];
    [_db inDatabase:^(KCS_FMDatabase *db) {
        KCS_FMResultSet* rs = [db executeQuery:query];
        if ([db hadError]) {
            KCSLogError(KCS_LOG_CONTEXT_FILESYSTEM, @"DB error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        }
        
        while ([rs next]) {
            NSDictionary* d = [rs resultDictionary];
            if (d) {
                id obj = [self dictObjForJson:d[@"obj"]];
                if (obj) {
                    [results addObject:obj];
                }
            }
        }
        [rs close];
    }];

    return results;
}

#pragma mark - Management
- (void) clearCaches
{
    @synchronized (self) {
        KCSLogDebug(KCS_LOG_CONTEXT_FILESYSTEM, @"Clearing Caches");
        [_db close];
        
        NSError* error = nil;
        
        NSURL* url = [NSURL fileURLWithPath:[self dbPath]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
            [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
        }
        DBAssert(!error, @"error clearing cache: %@", error);
        
        [self initDB];
    }
}

#pragma mark - Upgrade Schema Version methods. IMPORTANT NOTE: any method in this section MUST NOT be changed or removed after released for the public. Please, always add methods, never change or remove.

-(void)upgradeDatabaseSchema:(KCS_FMDatabase*)db
                   toVersion:(long)toVersion
{
    [db executeUpdate:@"REPLACE INTO metadata VALUES (:version)" withArgumentsInArray:@[@(toVersion)]];
}

//IMPORTANT NOTE: here's a sample example how to implement an upgrade database schema method
//-(void)upgradeDatabaseSchemaFromVersion5toVersion6:(KCS_FMDatabase*)db
//{
//}
//
//-(void)upgradeDatabaseSchemaFromVersion5toVersion7:(KCS_FMDatabase*)db
//{
//}

@end
