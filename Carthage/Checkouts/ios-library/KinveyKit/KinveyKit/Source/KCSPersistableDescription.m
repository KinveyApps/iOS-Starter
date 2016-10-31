//
//  KCSPersistableDescription.m
//  KinveyKit
//
//  Copyright (c) 2015 Kinvey. All rights reserved.
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

#import "KCSPersistableDescription.h"
#import "KinveyPersistable.h"
#import "KinveyCoreInternal.h"
#import "KinveyDataStoreInternal.h"

@interface KCSReferenceDescription ()
//@property (nonatomic, copy) NSString* sourceEntity;
@property (nonatomic, copy) NSString* classname; //TODO: needed?
@property (nonatomic) BOOL isContainer;
//@property (nonatomic) BOOL isKCSObject;
@property (nonatomic, retain) KCSPersistableDescription* destinationDescription;
@end

@implementation KCSReferenceDescription


- (id<KCSPersistable>) destinationObjFromObj:(NSObject<KCSPersistable>*)sourceObj
{
    return [sourceObj valueForKeyPath:self.sourceProperty];
}

@end


@interface KCSPersistableDescription ()
@property (nonatomic, copy) NSString* objectClass;
@property (nonatomic, copy) NSString* collection;
@property (nonatomic, retain) NSDictionary* fieldToPropertyMapping;
@property (nonatomic, retain) NSDictionary* propertyToFieldMapping;
- (NSString*) objectIdFromObject:(NSObject<KCSPersistable>*)obj;
@end

@implementation KCSPersistableDescription

BOOL kcsIsContainerClass(Class aClass)
{
    return [aClass isSubclassOfClass:[NSArray class]] || [aClass isSubclassOfClass:[NSDictionary class]] || [aClass isSubclassOfClass:[NSSet class]] || [aClass isSubclassOfClass:[NSOrderedSet class]];
    // || [aClass isKindOfClass:[NSMutableArray class]] || [aClass isKindOfClass:[NSMutableDictionary class]] || [aClass isKindOfClass:[NSMutableSet class]] || [aClass isKindOfClass:[NSMutableOrderedSet class]];
}

- (NSArray*) discoverReferences:(id<KCSPersistable>)object
{
    NSArray* refs = nil;
    if (object) {
        Class objClass = [object class];
        if ([objClass respondsToSelector:@selector(kinveyPropertyToCollectionMapping)]) {
            NSDictionary* mapping = [[object class] kinveyPropertyToCollectionMapping];
            NSMutableArray* mRefs = [NSMutableArray arrayWithCapacity:mapping.count];
            
            NSDictionary* classProps = [KCSPropertyUtil classPropsFor:objClass];
            
            [mapping enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                KCSReferenceDescription* rd = [[KCSReferenceDescription alloc] init];
                rd.sourceField = key;
                rd.destinationCollection = obj;
                
                NSUInteger dotLocation = [(NSString*)key rangeOfString:@"."].location;
                NSString* refField = dotLocation == NSNotFound ? key : [key substringToIndex:dotLocation];
                NSString* sourceProp = self.fieldToPropertyMapping[refField];
                NSAssert(sourceProp, @"No property mapping for field '%@'", key);
                rd.sourceProperty = sourceProp;
                
                rd.classname = classProps[rd.sourceProperty];
                Class sourcePropClass = NSClassFromString(rd.classname);
                rd.isContainer = kcsIsContainerClass(sourcePropClass);
                
                
#warning TOTEST: id
                //The destination class?
                if (!rd.isContainer) {
                    rd.destinationDescription = [self.objectClass isEqualToString:rd.classname] ? self : [[KCSPersistableDescription alloc] initWithKinveyKit1Object:[[sourcePropClass alloc] init] collection:rd.destinationCollection];
                }
                [mRefs addObject:rd];
            }];
            refs = mRefs;
        }
    }
    return refs;
}

- (instancetype) initWithKinveyKit1Object:(id<KCSPersistable>)object collection:(NSString*)collection
{
    self = [super init];
    if (self) {
        //WARNING: ordering matters, below! Each property builds on the previous
        _collection = collection;
        _objectClass = NSStringFromClass([object class]);
        _propertyToFieldMapping = [[object hostToKinveyPropertyMapping] copy];
        _fieldToPropertyMapping = [_propertyToFieldMapping invert];
        _references = [self discoverReferences:object];
    }
    return self;
}

#pragma mark - Object Helpers

- (NSString *)objectIdFromObject:(NSObject<KCSPersistable>*)obj
{
    return [obj valueForKey:self.fieldToPropertyMapping[KCSEntityKeyId]];
}

#pragma mark - Graph Helpers
- (void) addRefsFromContainer:(id)objContainer desc:(KCSReferenceDescription*)rDesc graph:(NSMutableDictionary*)graph
{
    //    NSMutableSet* thisSet = graph[rDesc.destinationCollection];
    
    NSString* entityPath = rDesc.sourceField;
    
    NSUInteger dotLocation = [(NSString*)entityPath rangeOfString:@"."].location;
    if (dotLocation != NSNotFound) {
        NSString* keyPath = [entityPath substringFromIndex:dotLocation+1];
        objContainer = [objContainer valueForKeyPath:keyPath];
    }
    
    if (!objContainer) {
        return;
    }

    
    if ([objContainer isKindOfClass:[NSArray class]]) {
//        NSUInteger dotLocation = [(NSString*)entityPath rangeOfString:@"." options:NSBackwardsSearch].location;
//        BOOL hasKeyPath = dotLocation != NSNotFound;
//        NSString* keyPath = hasKeyPath ? [entityPath substringFromIndex:dotLocation+1] : entityPath;
//
//        if (hasKeyPath) {
//            [thisSet addObjectsFromArray:[objContainer valueForKeyPath:keyPath]];
//        } else {
//            [thisSet addObjectsFromArray:objContainer];
//        for (id<KCSPersistable> obj in objContainer) {
//            BOOL needToWalk = [self addObjToTree:graph obj:obj collection:rDesc.destinationCollection];
//            if (needToWalk) {
                [self addRefs:graph collection:rDesc.destinationCollection objects:objContainer description:rDesc.destinationDescription];
//            }
//        }
//        }
    } else if ([objContainer isKindOfClass:[NSSet class]]) {
        [self addRefs:graph collection:rDesc.destinationCollection objects:[objContainer allObjects] description:rDesc.destinationDescription];
        //        [thisSet unionSet:objContainer];
    } else if ([objContainer isKindOfClass:[NSOrderedSet class]]) {
        [self addRefs:graph collection:rDesc.destinationCollection objects:[objContainer allObjects] description:rDesc.destinationDescription];
        //        [thisSet addObjectsFromArray:[objContainer array]];
    } else if ([objContainer isKindOfClass:[NSDictionary class]]) {
        //TODO? remove this?
        NSUInteger dotLocation = [(NSString*)entityPath rangeOfString:@"."].location;
        NSString* keyPath = dotLocation == NSNotFound ? entityPath : [entityPath substringFromIndex:dotLocation+1];

        id obj = [objContainer valueForKeyPath:keyPath];
        if (obj) {
            if (kcsIsContainerClass([obj class])) {
                [self addRefsFromContainer:obj desc:rDesc graph:graph];
            } else {
//                [thisSet addObject:obj];
                [self addRefs:graph collection:rDesc.destinationCollection objects:[NSArray wrapIfNotArray:objContainer] description:rDesc.destinationDescription];
            }
        }
    } else {
        //        if (objContainer) {
            [self addRefs:graph collection:rDesc.destinationCollection objects:[NSArray wrapIfNotArray:objContainer] description:rDesc.destinationDescription];
            //            [thisSet addObject:objContainer];
            //        DBAssert(NO, @"Container should be one the tested classes.");
            //        }
    }
}

- (BOOL) addObjToTree:(NSMutableDictionary*)tree obj:(id<KCSPersistable>)obj collection:(NSString*)collection
{
    NSParameterAssert(collection);
    if (!tree[collection]) {
        tree[collection] = [NSMutableSet set];
    }
    BOOL toAdd = ![tree[collection] containsObject:obj];
    if (toAdd) {
        [tree[collection] addObject:obj];
    }
    return toAdd;
}

//TODO: pull back refdescription as private class?
- (void) addRefs:(NSMutableDictionary*)d collection:(NSString*)collection objects:(NSArray*)objects description:(KCSPersistableDescription*)desc
{
//    if (!d[collection]) {
//        d[collection] = [NSMutableSet setWithCapacity:objects.count];
//    }
    for (id<KCSPersistable> obj in objects) {
//        if ([d[collection] containsObject:obj]) {
//            continue;
//        }
//        [d[collection] addObject:obj];
        BOOL needToWalk = [self addObjToTree:d obj:obj collection:collection];
        if (needToWalk) {
            //            NSArray* refs = self.references;
            for (KCSReferenceDescription* rdesc in desc.references) {
                id<KCSPersistable> refObj = [rdesc destinationObjFromObj:obj];
                if (refObj) {
//                    if (!d[rdesc.destinationCollection]) {
//                        d[rdesc.destinationCollection] = [NSMutableSet set];
//                    }
//                    BOOL walkSub = NO;
                    if (rdesc.isContainer) {
                        [self addRefsFromContainer:refObj desc:rdesc graph:d];
                    } else {
                        [self addRefs:d collection:rdesc.destinationCollection objects:[NSArray wrapIfNotArray:refObj] description:rdesc.destinationDescription];
//                        [d[rdesc.destinationCollection] addObject:refObj];
                    }
//                    if (rdesc.isKCSObject) {
//                        [self addRefs:d collection:rdesc.destinationCollection objects:[NSArray wrapIfNotArray:refObj]];
//                    }
                }
            }
        }
    }
}

/* Algorithm
 For every object, add it to the "graph"
 For each object, add its reference.
 For each reference, add its references.
 */

- (void) doAdds:(NSArray*)objects graph:(NSMutableDictionary*)graph description:(KCSPersistableDescription*)desc
{
    NSString* const collection = desc.collection;
    for (id<KCSPersistable> obj in objects) {
        BOOL shouldWalk = [self addObjToTree:graph obj:obj collection:collection];
        if (shouldWalk) {
            for (KCSReferenceDescription* rdesc in desc.references) {
                id refObj = [rdesc destinationObjFromObj:obj];
                if (refObj) {
                    if (shouldWalk) {
                        [self doAdds:@[refObj] graph:graph description:rdesc.destinationDescription];
                    }
                }
            }
        }
    }
}

- (NSDictionary*) objectListFromObjects:(NSArray*)objects
{
    if (objects.count == 0) {
        return @{};
    }
    
    NSMutableDictionary* graph = [NSMutableDictionary dictionary];
    [self doAdds:objects graph:graph description:self];
    //    [self addRefs:d collection:collection objects:objects description:self];
    return graph;
}

@end

#pragma clang diagnostic pop
