//
//  FMDatabasePool.m
//  fmdb
//
//  Created by August Mueller on 6/22/11.
//  Copyright 2011 Flying Meat Inc. All rights reserved.
//

#import "KCS_FMDatabasePool.h"
#import "KCS_FMDatabase.h"
#import "KCSLogManager.h"

@interface KCS_FMDatabasePool()

- (void)pushDatabaseBackInPool:(KCS_FMDatabase*)db;
- (KCS_FMDatabase*)db;

@end


@implementation KCS_FMDatabasePool
@synthesize path=_path;
@synthesize delegate=_delegate;
@synthesize maximumNumberOfDatabasesToCreate=_maximumNumberOfDatabasesToCreate;
@synthesize openFlags=_openFlags;


+ (instancetype)databasePoolWithPath:(NSString*)aPath {
    return FMDBReturnAutoreleased([[self alloc] initWithPath:aPath]);
}

+ (instancetype)databasePoolWithPath:(NSString*)aPath flags:(int)openFlags {
    return FMDBReturnAutoreleased([[self alloc] initWithPath:aPath flags:openFlags]);
}

- (instancetype)initWithPath:(NSString*)aPath flags:(int)openFlags {
    
    self = [super init];
    
    if (self != nil) {
        _path               = [aPath copy];
        _lockQueue          = dispatch_queue_create([[NSString stringWithFormat:@"fmdb.%@", self] UTF8String], NULL);
        _databaseInPool     = FMDBReturnRetained([NSMutableArray array]);
        _databaseOutPool    = FMDBReturnRetained([NSMutableArray array]);
        _openFlags          = openFlags;
    }
    
    return self;
}

- (instancetype)initWithPath:(NSString*)aPath
{
    // default flags for sqlite3_open
    return [self initWithPath:aPath flags:SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE];
}

- (instancetype)init {
    return [self initWithPath:nil];
}


- (void)dealloc {
    
    _delegate = 0x00;
    FMDBRelease(_path);
    FMDBRelease(_databaseInPool);
    FMDBRelease(_databaseOutPool);
    
    if (_lockQueue) {
        FMDBDispatchQueueRelease(_lockQueue);
        _lockQueue = 0x00;
    }
#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
}


- (void)executeLocked:(void (^)(void))aBlock {
    dispatch_sync(_lockQueue, aBlock);
}

- (void)pushDatabaseBackInPool:(KCS_FMDatabase*)db {
    
    if (!db) { // db can be null if we set an upper bound on the # of databases to create.
        return;
    }
    
    [self executeLocked:^() {
        
        if ([_databaseInPool containsObject:db]) {
            [[NSException exceptionWithName:@"Database already in pool" reason:@"The FMDatabase being put back into the pool is already present in the pool" userInfo:nil] raise];
        }
        
        [_databaseInPool addObject:db];
        [_databaseOutPool removeObject:db];
        
    }];
}

- (KCS_FMDatabase*)db {
    
    __block KCS_FMDatabase *db;
    
    
    [self executeLocked:^() {
        db = [_databaseInPool lastObject];
        
        BOOL shouldNotifyDelegate = NO;
        
        if (db) {
            [_databaseOutPool addObject:db];
            [_databaseInPool removeLastObject];
        }
        else {
            
            if (_maximumNumberOfDatabasesToCreate) {
                NSUInteger currentCount = [_databaseOutPool count] + [_databaseInPool count];
                
                if (currentCount >= _maximumNumberOfDatabasesToCreate) {
                    KCSLogDebug(@"Maximum number of databases (%ld) has already been reached!", (long)currentCount);
                    return;
                }
            }
            
            db = [KCS_FMDatabase databaseWithPath:_path];
            shouldNotifyDelegate = YES;
        }
        
        //This ensures that the db is opened before returning
#if SQLITE_VERSION_NUMBER >= 3005000
        BOOL success = [db openWithFlags:_openFlags];
#else
        BOOL success = [db open];
#endif
        if (success) {
            if ([_delegate respondsToSelector:@selector(databasePool:shouldAddDatabaseToPool:)] && ![_delegate databasePool:self shouldAddDatabaseToPool:db]) {
                [db close];
                db = 0x00;
            }
            else {
                //It should not get added in the pool twice if lastObject was found
                if (![_databaseOutPool containsObject:db]) {
                    [_databaseOutPool addObject:db];
                    
                    if (shouldNotifyDelegate && [_delegate respondsToSelector:@selector(databasePool:didAddDatabase:)]) {
                        [_delegate databasePool:self didAddDatabase:db];
                    }
                }
            }
        }
        else {
            KCSLogError(@"Could not open up the database at path %@", _path);
            db = 0x00;
        }
    }];
    
    return db;
}

- (NSUInteger)countOfCheckedInDatabases {
    
    __block NSUInteger count;
    
    [self executeLocked:^() {
        count = [_databaseInPool count];
    }];
    
    return count;
}

- (NSUInteger)countOfCheckedOutDatabases {
    
    __block NSUInteger count;
    
    [self executeLocked:^() {
        count = [_databaseOutPool count];
    }];
    
    return count;
}

- (NSUInteger)countOfOpenDatabases {
    __block NSUInteger count;
    
    [self executeLocked:^() {
        count = [_databaseOutPool count] + [_databaseInPool count];
    }];
    
    return count;
}

- (void)releaseAllDatabases {
    [self executeLocked:^() {
        [_databaseOutPool removeAllObjects];
        [_databaseInPool removeAllObjects];
    }];
}

- (void)inDatabase:(void (^)(KCS_FMDatabase *db))block {
    
    KCS_FMDatabase *db = [self db];
    
    block(db);
    
    [self pushDatabaseBackInPool:db];
}

- (void)beginTransaction:(BOOL)useDeferred withBlock:(void (^)(KCS_FMDatabase *db, BOOL *rollback))block {
    
    BOOL shouldRollback = NO;
    
    KCS_FMDatabase *db = [self db];
    
    if (useDeferred) {
        [db beginDeferredTransaction];
    }
    else {
        [db beginTransaction];
    }
    
    
    block(db, &shouldRollback);
    
    if (shouldRollback) {
        [db rollback];
    }
    else {
        [db commit];
    }
    
    [self pushDatabaseBackInPool:db];
}

- (void)inDeferredTransaction:(void (^)(KCS_FMDatabase *db, BOOL *rollback))block {
    [self beginTransaction:YES withBlock:block];
}

- (void)inTransaction:(void (^)(KCS_FMDatabase *db, BOOL *rollback))block {
    [self beginTransaction:NO withBlock:block];
}
#if SQLITE_VERSION_NUMBER >= 3007000
- (NSError*)inSavePoint:(void (^)(KCS_FMDatabase *db, BOOL *rollback))block {
    
    static unsigned long savePointIdx = 0;
    
    NSString *name = [NSString stringWithFormat:@"savePoint%ld", savePointIdx++];
    
    BOOL shouldRollback = NO;
    
    KCS_FMDatabase *db = [self db];
    
    NSError *err = 0x00;
    
    if (![db startSavePointWithName:name error:&err]) {
        [self pushDatabaseBackInPool:db];
        return err;
    }
    
    block(db, &shouldRollback);
    
    if (shouldRollback) {
        // We need to rollback and release this savepoint to remove it
        [db rollbackToSavePointWithName:name error:&err];
    }
    [db releaseSavePointWithName:name error:&err];
    
    [self pushDatabaseBackInPool:db];
    
    return err;
}
#endif

@end
