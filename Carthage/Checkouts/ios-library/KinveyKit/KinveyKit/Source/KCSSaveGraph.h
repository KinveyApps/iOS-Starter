//
//  KCSSaveGraph.h
//  KinveyKit
//
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

@import Foundation;

@class KCSSerializedObject;
@class KCSFile;
@protocol KCSPersistable;

typedef void(^KCSCompletionWrapperBlock_t)();

@interface KCSCompletionWrapper : NSObject
{
    NSMutableArray* _references;
    NSMutableArray* _waitingBlocks;
    NSMutableArray* _resaveBlocks;
    NSMutableArray* _resaveWaiters;
    KCSCompletionWrapperBlock_t _doAfterWaitingResave;
}
@property (nonatomic) double size;
@property (nonatomic) double pc;
@property (nonatomic) uint type;
@property (strong, nonatomic, readonly) NSArray* references;
@property (nonatomic, strong) id handle;
@property (atomic) BOOL loading;
@property (atomic) BOOL done;
@property (atomic) uint resaveCount;
@property (atomic, readonly, strong) NSMutableSet* waitingObjects;
@property (atomic, readonly, strong) NSMutableArray* waitingBlocks;

- (void) finished:(NSArray*)objectsOrNil error:(NSError*)errorOrNil;
- (void) resaveComplete;
- (void) ifNotLoaded:(KCSCompletionWrapperBlock_t)noloadedBlock otherwiseWhenLoaded:(KCSCompletionWrapperBlock_t)loadedBlock andResaveAfterReferencesSaved:(KCSCompletionWrapperBlock_t)resaveBlock;
- (void) doAfterWaitingResaves:(KCSCompletionWrapperBlock_t)doAfterBlock;
@end

@interface KCSSaveGraph : NSObject
{
    NSMutableArray* _resourceSeen;
    double _totalBytes;
    NSMutableSet* _entitySeen;
}

@property (nonatomic, readonly, getter = percentDone) double percentDone;

- (instancetype) initWithEntityCount:(NSUInteger)entityCount;

- (id) markEntity:(KCSSerializedObject*)serializedObj;
- (id) addReference:(id<KCSPersistable>)reference entity:(KCSCompletionWrapper*)wp;
- (id) addResource:(KCSFile*)resource entity:(KCSCompletionWrapper*)wp;
- (void) tell:(id)reference toWaitForResave:(id)referer;
@end
