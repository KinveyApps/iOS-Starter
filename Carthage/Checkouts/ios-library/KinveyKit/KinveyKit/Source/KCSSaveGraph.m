//
//  KCSSaveGraph.m
//  KinveyKit
//
//  Created by Michael Katz on 9/6/12.
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


#import "KCSSaveGraph.h"

#import "KCSObjectMapper.h"
#import "KCSFile.h"
#import "KinveyEntity.h"
#import "NSDictionary+KinveyAdditions.h"
#import "KCSLogManager.h"


@implementation KCSCompletionWrapper

- (instancetype) initWithObject:(id)object
{
    self = [super init];
    if (self) {
        _references = [NSMutableArray array];
        _handle = object;
        _waitingBlocks = [NSMutableArray array];
        _waitingObjects = [NSMutableSet set];
        _resaveBlocks = [NSMutableArray array];
        _resaveWaiters = [NSMutableArray array];
    }
    return self;
}
- (void) dealloc
{
    _size = -1;
}

- (void) addReference:(id)ref
{
    [_references addObject:ref];
}

- (void)setPc:(double)aPc
{
    DBAssert(aPc >= 0.0 && aPc <= 1.0, @"progress greater out of bounds: %f", aPc);
    _pc = aPc;
}
- (NSString *)debugDescription
{
    NSMutableString* str = [NSMutableString stringWithFormat:@"\n| %d | %8f  (%8f) ----| (%@)", _type, _pc, _size, _handle];
    for (KCSCompletionWrapper* r in _references) {
        [str appendFormat:@"\n|    %d | %8f (%8f) --| (%@)", r.type, r.pc, r.size, r.handle];
    }
    return str;
}

- (void) ifNotLoaded:(KCSCompletionWrapperBlock_t)noloadedBlock otherwiseWhenLoaded:(KCSCompletionWrapperBlock_t)loadedBlock andResaveAfterReferencesSaved:(KCSCompletionWrapperBlock_t)resaveBlock
{
    BOOL shouldSave = NO;
    BOOL alreadyFinished = NO;
    @synchronized(self) {
        alreadyFinished = self.done;
        shouldSave = self.done == NO && self.loading == NO;
        self.loading = YES;
    }
    
    [_resaveBlocks addObject:[resaveBlock copy]];
    
    if (shouldSave) {
        noloadedBlock();
    } else {
        if (alreadyFinished == YES) {
            //added after done loading
            loadedBlock();
        } else {
            [_waitingBlocks addObject:[loadedBlock copy]];
        }
    }
}

- (void) ifReferenceNotLoaded:(KCSCompletionWrapperBlock_t)noloadedBlock otherwiseWhenLoaded:(KCSCompletionWrapperBlock_t)loadedBlock andResaveAfterReferencesSaved:(KCSCompletionWrapperBlock_t)resaveBlock
{
    BOOL alreadyFinished = NO;
    @synchronized(self) {
        alreadyFinished = self.done;
    }
    
    [_resaveBlocks addObject:[resaveBlock copy]];
    
    if (alreadyFinished == YES) {
        //added after done loading
        loadedBlock();
    } else {
        [_waitingBlocks addObject:[loadedBlock copy]];
    }
}

- (void) finished:(NSArray*)objectsOrNil error:(NSError*)errorOrNil
{
    @synchronized(self) {
        self.done = YES;
        self.loading = NO;
    }
    for (KCSCompletionWrapperBlock_t block in _waitingBlocks) {
        block(objectsOrNil, errorOrNil);
    }
}

- (void) resaveComplete
{
    for (KCSCompletionWrapper* waiter in _resaveWaiters) {
        [waiter stopWaitingForResave];
    }
}

- (void) addResaveWaiter:(KCSCompletionWrapper*)waiter
{
    @synchronized(self) {
        [_resaveWaiters addObject:waiter];
    }
}

- (void) stopWaitingForResave
{
    @synchronized(self) {
        self.resaveCount--;
    }
    if (self.resaveCount == 0) {
        _doAfterWaitingResave();
    }
}

- (void) doAfterWaitingResaves:(KCSCompletionWrapperBlock_t)doAfterBlock
{
    BOOL waiting = NO;
    @synchronized(self) {
        waiting = self.resaveCount > 0;
    }
    if (waiting) {
        _doAfterWaitingResave = [doAfterBlock copy];
    } else {
        doAfterBlock();
    }
    
}

- (void) waitForResave:(KCSCompletionWrapper*)other
{
    @synchronized(self) {
        self.resaveCount++;
    }
    [other addResaveWaiter:self ];
}

- (void) doResaves
{
    for (KCSCompletionWrapperBlock_t block in _resaveBlocks) {
        block();
    }
}
@end

@implementation KCSSaveGraph
- (id) initWithEntityCount:(NSUInteger)entityCount
{
    self = [super init];
    if (self) {
        _resourceSeen = [NSMutableArray arrayWithCapacity:entityCount];
        _entitySeen = [NSMutableSet setWithCapacity:entityCount];
    }
    return self;
}

- (NSString *)debugDescription
{
    NSMutableString* str = [NSMutableString stringWithString:@"+-------------------------------+"];
    [str appendFormat:@"\n| %8f  (%8f) --------|\n+--------------------------------+",self.percentDone, _totalBytes];
    for (KCSCompletionWrapper* w in _entitySeen) {
        [str appendString:[w debugDescription]];
    }
    return str;
}

double countBytesE(KCSSerializedObject* serializedObj)
{
    NSDictionary *dictionaryToMap = serializedObj.dataToSerialize;
    NSData* data = [dictionaryToMap kcsJSONDataRepresentation:nil];
    double bytecount = [data length];
    return bytecount;
}

double countBytesRf(id referenceObj)
{
    KCSSerializedObject* serializedObj = [KCSObjectMapper makeResourceEntityDictionaryFromObject:referenceObj forCollection:@"" error:NULL];
    NSDictionary *dictionaryToMap = serializedObj.dataToSerialize;
    NSData* data = [dictionaryToMap kcsJSONDataRepresentation:nil];
    double bytecount = [data length];
    return bytecount;
}

- (KCSCompletionWrapper*) alreadySeen:(id)entity
{
    KCSCompletionWrapper* w = nil;
    NSSet* passingSet = [_entitySeen objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        BOOL passes = [((KCSCompletionWrapper*)obj).handle isEqual:entity];
        *stop = passes;
        return passes;
    }];
    if (passingSet && passingSet.count > 0) {
        return [passingSet anyObject];
    }
    return w;
}

- (id) markEntity:(KCSSerializedObject*)serializedObj
{
    KCSCompletionWrapper* w = nil;
    @synchronized(self) {
        w = [self alreadySeen:serializedObj.handleToOriginalObject];
        if (w == nil) {
            w = [[KCSCompletionWrapper alloc] initWithObject:serializedObj.handleToOriginalObject];
            [_entitySeen addObject:w];
            w.size = countBytesE(serializedObj);
            _totalBytes += w.size;
        }
        serializedObj.userInfo = @{@"entityProgress" : w};
    }
    return w;
}

- (id) addReference:(id<KCSPersistable>)reference entity:(KCSCompletionWrapper*)wp
{
    //mark the reference as seen
    KCSCompletionWrapper* w = nil;
    @synchronized(self) {
        w = [self alreadySeen:reference];
        if (w == nil) {
            w = [[KCSCompletionWrapper alloc] initWithObject:reference];
            [_entitySeen addObject:w];
            w.size = countBytesRf(reference);
            _totalBytes += w.size;
            w.type = 1;
        }
        [wp addReference:w];
    }
    
    
    [w.waitingObjects addObject:wp];
    [w.waitingObjects unionSet:wp.waitingObjects];
    if ([w.waitingObjects containsObject:w]) {
        //there is a cycle:
        KCSLogDebug(@"circular reference found between: %@ and %@", w.handle, wp.handle);
        
        [w.waitingObjects removeObject:w];
        BOOL needToSave = NO;
        if ([wp.handle respondsToSelector:@selector(kinveyObjectId)] == NO || [wp.handle kinveyObjectId] == nil) {
            //need to resave to record the entity
            [w.waitingBlocks addObject:[^{
                [wp doResaves];
            } copy]];
            needToSave = YES;
        }
        return [NSNumber numberWithBool:needToSave];
    }
    return w;
}

- (id) addResource:(KCSFile*)resource entity:(KCSCompletionWrapper*)wp
{
    KCSCompletionWrapper* w = [[KCSCompletionWrapper alloc] init];
    w.type = 2;
    w.size = [[resource data] length];
    _totalBytes += w.size;
    @synchronized(self) {
        [wp addReference:w];
    }
    [_resourceSeen addObject:w];
    return w;
}

- (void) tell:(id)reference toWaitForResave:(id)referer
{
    KCSCompletionWrapper* w = [self alreadySeen:reference];
    DBAssert(w != nil, @"should not have a nil reference");
    KCSCompletionWrapper* r = [self alreadySeen:referer];
    DBAssert(r != nil, @"should not have a nil reference");
    [w waitForResave:r];
}

- (double)percentDone
{
    double done = 0.;
    for (KCSCompletionWrapper* w in _entitySeen) {
        done += w.size / _totalBytes * w.pc;
    }
    for (KCSCompletionWrapper* w in _resourceSeen) {
        done += w.size / _totalBytes * w.pc;
    }
    DBAssert(done <= 1.0 && done >= 0.0, @"progress out of bounds: %f", done);
    return done;
}
@end
