//
//  KCSObjectMapper.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/19/12.
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


#import "KCSObjectMapper.h"

@import ObjectiveC;

//TODO: remove core location as dependency injection
@import CoreLocation;

#import "KCSPropertyUtil.h"

#import "KinveyPersistable.h"
#import "KCSClient.h"
#import "KinveyEntity.h"
#import "KCSLogManager.h"

#import "KCSFile.h"
#import "KCSMetadata.h"
#import "KCSFileStore.h"

#import "KCSBuilders.h"

#import "KCSErrorUtilities.h"
#import "KinveyErrorCodes.h"
#import "KCSImageUtils.h"
#import "NSString+KinveyAdditions.h"

#define kKMDKey @"_kmd"
#define kACLKey @"_acl"
#define kTypeKey @"_type"

typedef enum KCSRefType : NSInteger {
    NotARef, FileRef, AppdataRef
} KCSRefType;

@interface NSSet (JSON)
- (id) proxyForJSON;
@end
@implementation NSSet (JSON)
- (id)proxyForJSON
{
    return [self allObjects];
}
@end

@protocol KCSPersistableInternal <NSObject>
+(id)kinveyDesignatedInitializer;
@end

@implementation KCSKinveyRef
- (instancetype) initWithObj:(id<KCSPersistable>)obj andCollection:(NSString*)collection
{
    self = [super init];
    if (self) {
        obj = [obj isEqual:[NSNull null]] ? nil : obj;
        self.object = obj;
        self.collectionName = collection;
    }
    return self;
}

- (id)proxyForJson
{
    NSString* objId = [(id)self.object kinveyObjectId];
    return objId ? @{kTypeKey : @"KinveyRef", @"_collection" : self.collectionName, @"_id" : objId } : [NSNull null];
}

- (BOOL)isEqualDict:(NSDictionary*)dict
{
    return [[dict objectForKey:kTypeKey] isEqualToString:@"KinveyRef"] && [[dict objectForKey:@"_collection"] isEqualToString:self.collectionName] && [[dict objectForKey:@"_id"] isEqualToString:[(id)self.object kinveyObjectId]];
}

- (BOOL)isEqual:(id)obj
{
    if ([obj isKindOfClass:[KCSKinveyRef class]]) {
        return [self isEqualDict:[obj proxyForJson]];
    } else if ([obj isKindOfClass:[NSDictionary class]]) {
        return [self isEqualDict:obj];
    } else {
        return NO;
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<KCSKinveyRef: { objId : '%@', _collection : '%@'}>", [(id)self.object kinveyObjectId], self.collectionName];
}

- (BOOL) unableToSaveReference:(BOOL)savingReferences
{
    NSString* objId = [(id)self.object kinveyObjectId];
    return savingReferences == NO && objId == nil;
}

@end

@interface KCSMetadata ()
- (instancetype) initWithKMD:(NSDictionary*)kmd acl:(NSDictionary*)acl;
- (NSDictionary*) aclValue;
- (NSDictionary*) kmdDict;
@end

NSDictionary* builderOptions(id object);
NSDictionary* builderOptions(id object)
{
    return  [[object class] kinveyObjectBuilderOptions];
}

@implementation KCSSerializedObject

- (instancetype)initWithObject:(id<KCSPersistable>)object ofId:(NSString *)objectId dataToSerialize:(NSDictionary *)dataToSerialize resources:(NSArray*)resources references:(NSArray *)references
{
    self = [super init];
    if (self){
        _dataToSerialize = dataToSerialize;
        _objectId = [objectId copy];
        _isPostRequest = _objectId.length == 0;
        _resourcesToSave = resources;
        _referencesToSave = references;
        _handleToOriginalObject = object;
    }
    return self;
}


- (NSString *)debugDescription
{
    return [self.dataToSerialize description];
}

- (void) restoreReferences:(KCSSerializedObject*)previousObject
{
    //should be okay to overwrite except for id
    //this will put the object in an state not good execept for saving
    //anything that was updated in between will be refreshed by the subsequent save
    NSDictionary* old = previousObject.dataToSerialize;
    NSDictionary* new = [NSMutableDictionary dictionaryWithDictionary:self.dataToSerialize];
    for (NSString* key in [old allKeys]) {
        [new setValue:[old valueForKey:key] forKey:key];
    }
    _dataToSerialize = new;
    _referencesToSave = previousObject.referencesToSave;
}

@end

@implementation KCSObjectMapper
+ (id)populateObject:(id)object withData: (NSDictionary *)data
{
    return [self populateObjectWithLinkedResources:object withData:data resourceDictionary:nil];
}

KCSRefType specialTypeOfValue(id value)
{
    KCSRefType type = NotARef;
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSString* typeString = [value objectForKey:kTypeKey];
        if ([typeString isEqualToString:@"resource"] || [typeString isEqualToString:@"KinveyFile"]) {
            type = FileRef;
        } else if ([typeString isEqualToString:@"KinveyRef"]) {
            type = AppdataRef;
        }
    } else if ([value isKindOfClass:[NSArray class]] && [value count] > 0) {
        return specialTypeOfValue(value[0]);
    }
    return type;
}

id makeObjectWithResourcesOfType(Class objectClass, NSDictionary* data, NSMutableDictionary* resources)
{
    
    // Check for special options to building this class
    NSDictionary *specialOptions = [objectClass kinveyObjectBuilderOptions];
    BOOL hasDesignatedInit = NO;
    
    if (specialOptions != nil){
        if ([specialOptions objectForKey:KCS_USE_DESIGNATED_INITIALIZER_MAPPING_KEY] != nil){
            hasDesignatedInit = YES;
        }
    }
    
    // Actually generate the instance of the class
    id copiedObject = nil;
    if (hasDesignatedInit){
        // If we need to use a designated initializer we do so here
        if ([(id)objectClass respondsToSelector:@selector(kinveyDesignatedInitializer:)]) {
            copiedObject = [objectClass kinveyDesignatedInitializer:data];
        } else {
            copiedObject = [(id)objectClass performSelector:@selector(kinveyDesignatedInitializer)];
        }
    } else {
        // Normal path
        copiedObject = [[objectClass alloc] init];
    }
    
    return [KCSObjectMapper populateObjectWithLinkedResources:copiedObject withData:data resourceDictionary:resources];
}

id makeObjectFromKinveyRef(id refDict, Class valClass)
{
    if ([refDict isEqual:[NSNull null]]) {
        return [NSNull null];
    }
    id referencedObj = [refDict objectForKey:@"_obj"];
    if ([referencedObj isEqual:[NSNull null]]) {
        KCSLogWarning(@"Could not resolve reference, setting related object to `nil`: %@", refDict);
        return nil;
    }
    
    //TODO: how to handle resources!
    id newObj = refDict;
    if (referencedObj != nil) {
        BOOL isAKCSPersistable = [valClass conformsToProtocol:@protocol(KCSPersistable)];
        if (isAKCSPersistable == YES) {
            newObj = makeObjectWithResourcesOfType(valClass, referencedObj, nil);
        } else {
            newObj = referencedObj;
        }
    }
    return newObj;
    
}

bool isAUserObject(id object)
{
    BOOL isDictionary = [object isKindOfClass:[NSDictionary class]];
    BOOL isKCSObject = [NSStringFromClass([object class]) hasPrefix:@"KCS"];
    return isDictionary == NO && isKCSObject == YES;
}

void populate(id object, NSDictionary* referencesClasses, NSDictionary* data, NSMutableDictionary* resourcesToLoad, KCSSerializedObject* serializedObject)
{
    BOOL hasFlatMap = NO;
    NSString *dictName = nil;
    
    NSDictionary *hostToJsonMap = [object hostToKinveyPropertyMapping];
    NSDictionary* properties = [KCSPropertyUtil classPropsFor:[object class]];
    
    NSDictionary *specialOptions = builderOptions(object);
    
    if (specialOptions != nil){
        dictName = [specialOptions objectForKey:KCS_DICTIONARY_NAME_KEY];
        if ([specialOptions objectForKey:KCS_USE_DICTIONARY_KEY]){
            hasFlatMap = YES;
        }
        if (referencesClasses != nil && [specialOptions objectForKey:KCS_REFERENCE_MAP_KEY] != nil) {
            //only populate from newobj with linked resources, not existing
            referencesClasses = [specialOptions objectForKey:KCS_REFERENCE_MAP_KEY];
        }
        if ([specialOptions objectForKey:KCS_IS_DYNAMIC_ENTITY] != nil && [[specialOptions objectForKey:KCS_IS_DYNAMIC_ENTITY] boolValue] == YES) {
            NSMutableDictionary* d  = [NSMutableDictionary dictionaryWithDictionary:hostToJsonMap];
            [d setValuesForKeysWithDictionary:[NSDictionary dictionaryWithObjects:[data allKeys] forKeys:[data allKeys]]];
            
            if ([d objectForKey:kKMDKey] || [d objectForKey:kACLKey]) {
                [d removeObjectForKey:kKMDKey];
                [d removeObjectForKey:kACLKey];
                [d setObject:KCSEntityKeyMetadata forKey:KCSEntityKeyMetadata];
            }
            hostToJsonMap = d;
        }
    }
    NSDictionary* kinveyRefMapping = nil;
    if (resourcesToLoad != nil && [[object class] respondsToSelector:@selector(kinveyPropertyToCollectionMapping)]) {
        kinveyRefMapping = [[object class] kinveyPropertyToCollectionMapping];
    }
    
    BOOL isUserObject = isAUserObject(object);
    
    for (NSString *hostKey in hostToJsonMap) {
        NSString *jsonKey = [hostToJsonMap objectForKey:hostKey];
        id value = nil;
        
        if ([jsonKey isEqualToString:KCSEntityKeyMetadata]) {
            NSDictionary* kmd = [data objectForKey:kKMDKey];
            NSDictionary* acl = [data objectForKey:kACLKey];
            KCSMetadata* metadata = [[KCSMetadata alloc] initWithKMD:kmd acl:acl];
            value = metadata;
        } else {
            value = [data valueForKey:jsonKey];
        }
        
        if (value == nil) {
            if (isUserObject == NO)  {
                //dictionaries don't have set properties, so no need to warn, just continue
                KCSLogWarning(@"Data Mismatch, unable to find value for JSON Key: '%@' (Client Key: '%@').  Object not 100%% valid.", jsonKey, hostKey);
            }
            continue;
        } else {
            KCSRefType maybeType = specialTypeOfValue(value);
            Class valClass = referencesClasses[hostKey];
            if (!valClass) {
                NSString* valueType = properties[hostKey];
                valClass = objc_getClass([valueType UTF8String]);
            }
            
            if ((resourcesToLoad || serializedObject) && maybeType == FileRef) {
                //if there is no resourcesToLoad dict, then it's not a linked store and the object should be replaced by a dictionary
                
                //this is a linked resource; TODO: should support array?
                if (serializedObject) {
                    //this is an existing object - no need to reload resources (or at least for saving network connection)
                    NSArray* resources = serializedObject.resourcesToSave;
                    NSUInteger resIdx = [resources indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                        return [obj isEqual:value];
                    }];
                    if (resIdx != NSNotFound && resources != nil) {
                        [object setValue:[resources[resIdx] resolvedObject] forKey:hostKey];
                    } else {
                        [object setValue:value forKey:hostKey];
                    }
                } else {
                    //this is a new object & need to download resources
                    KCSFile* file = [KCSFile fileRefFromKinvey:value class:valClass];
                    if (kinveyRefMapping[hostKey] == nil ||
                        [[properties valueForKey:hostKey] isEqualToString:NSStringFromClass([KCSFile class])]) {
                        // just a KCSFile if the type is KCSFile or if the reference is not mapped
                        [object setValue:file forKey:hostKey];
                    } else {
                        //otherwise need to load the binary
                        resourcesToLoad[hostKey] = file;
                    }
                }
            } else if (maybeType == AppdataRef) {
                //this is a reference
                //TODO: update sig
                
                if ([value isKindOfClass:[NSArray class]]) {
                    NSString* valueType = [properties valueForKey:hostKey];
                    Class collectionClass = objc_getClass([valueType UTF8String]);
                    id objVals = [NSMutableArray arrayWithCapacity:[value count]];
                    if (collectionClass != nil) {
                        objVals = [[[collectionClass alloc] init] mutableCopy];
                    }
                    for (id arVal in value) {
                        if (serializedObject != nil) {
                            //populate with existing refs
                            NSArray* references = serializedObject.referencesToSave;
                            NSUInteger refIdx = [references indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                                return [obj isEqual:arVal];
                            }];
                            if (refIdx == NSNotFound || references == nil) {
                                [objVals addObject:arVal];
                            } else {
                                [objVals addObject:[references[refIdx] object]];
                            }
                        } else {
                            NSDictionary* kinveyRefDict = nil;
                            NSString *_collection = nil, *_id = nil;
                            if ([arVal isKindOfClass:[NSDictionary class]] &&
                                (kinveyRefDict = (NSDictionary*)arVal) &&
                                [kinveyRefDict[@"_type"] isEqualToString:@"KinveyRef"] &&
                                (_collection = kinveyRefDict[@"_collection"]) &&
                                [_collection isKindOfClass:[NSString class]] &&
                                (_id = kinveyRefDict[@"_id"]) &&
                                [_id isKindOfClass:[NSString class]])
                            {
                                NSMutableDictionary* kinveyRef = [NSMutableDictionary dictionaryWithDictionary:kinveyRefDict];
                                kinveyRef[@"_obj"] = kinveyRefDict;
                                [objVals addObject:makeObjectFromKinveyRef(kinveyRef, valClass)];
                            } else {
                                //create for new
                                [objVals addObject:makeObjectFromKinveyRef(arVal, valClass)];
                            }
                        }
                    }
                    [object setValue:objVals forKey:hostKey];
                } else {
                    if (serializedObject != nil) {
                        NSArray* references = serializedObject.referencesToSave;
                        NSUInteger refIdx = [references indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                            return [obj isEqual:value];
                        }];
                        if (refIdx != NSNotFound) {
                            [object setValue:[references[refIdx] object] forKey:hostKey];
                        } else {
                            id oldVal = [object valueForKey:hostKey];
                            NSString* refId = [value objectForKey:@"_id"];
                            BOOL hasAnObjectAlreadyAssigned = oldVal != nil && refId != nil && [refId isEqualToString:[oldVal kinveyObjectId]];
                            if (hasAnObjectAlreadyAssigned == NO) {
                                [object setValue:value forKey:hostKey];
                            }
                        }
                    } else {
                        [object setValue:makeObjectFromKinveyRef(value, valClass) forKey:hostKey];
                    }
                }
                
            } else {
                NSString* valueType = [properties valueForKey:hostKey];
                Class valClass = objc_getClass([valueType UTF8String]);
                Class<KCSDataTypeBuilder> builder = builderForComplexType(object, valClass);
                
                static NSSet* mutableTypes = nil;
                static dispatch_once_t onceToken;
                dispatch_once(&onceToken, ^{
                    /*
                     Based on the basic classes:
                     https://developer.apple.com/library/ios/documentation/General/Conceptual/CocoaEncyclopedia/ObjectMutability/ObjectMutability.html
                     */
                    mutableTypes = [NSSet setWithArray:@[@"NSMutableArray",
                                                         @"NSMutableDictionary",
                                                         @"NSMutableSet",
                                                         @"NSMutableIndexSet",
                                                         @"NSMutableCharacterSet",
                                                         @"NSMutableData",
                                                         @"NSMutableString",
                                                         @"NSMutableAttributedString",
                                                         @"NSMutableURLRequest"]];
                });
                id (^mutableValue)(id value) = ^(id value){
                    if ([mutableTypes containsObject:valueType] &&
                        [value isKindOfClass:[NSObject class]] &&
                        [value respondsToSelector:@selector(mutableCopy)])
                    {
                        return ((NSObject*) value).mutableCopy;
                    }
                    return value;
                };
                
                if (builder != nil) {
                    id builtValue = [builder objectForJSONObject:value];
                    builtValue = mutableValue(builtValue);
                    [object setValue:builtValue forKey:hostKey];
                } else {
                    if ([jsonKey isEqualToString:KCSEntityKeyId] && [object kinveyObjectId] != nil && [[object kinveyObjectId] isKindOfClass:[NSString class]] && [[object kinveyObjectId] isEqualToString:value] == NO) {
                        KCSLogWarning(@"%@ is having it's id overwritten.", object);
                    }
                    if ([object respondsToSelector:@selector(setValue:forKey:)]) {
                        value = mutableValue(value);
                        [object setValue:value forKey:hostKey];
                    } else {
                        KCSLogWarning(@"%@ cannot setValue for %@", hostKey);
                    }
                    
                }
            }
        }
    }
    
    // We've processed all the known keys, let's put the rest in our "dictionary" if required
    if (hasFlatMap){
        if (dictName){
            NSArray *knownJsonProps = [hostToJsonMap allValues];
            for (NSString *property in data) {
                // Check if in known set
                if ([knownJsonProps containsObject:property]){
                    continue;
                } else {
                    // otherwise build key path and insert.
                    NSString *keyPath = [dictName stringByAppendingFormat:@".%@", property];
                    [object setValue:[data objectForKey:property] forKeyPath:keyPath];
                }
            }
        }
    }
}

+ (id)populateExistingObject:(KCSSerializedObject*)serializedObject withNewData:(NSDictionary*)data
{
    id object = serializedObject.handleToOriginalObject;
    if ([object isKindOfClass:[NSDictionary class]] && ![object isKindOfClass:[NSMutableDictionary class]]) {
        object = ((NSObject*) object).mutableCopy;
    }
    populate(object, nil, data, nil, serializedObject);
    return object;
}

+ (id)populateObjectWithLinkedResources:(id)object withData: (NSDictionary *)data resourceDictionary:(NSMutableDictionary*)resourcesToLoad
{
    populate(object, @{}, data, resourcesToLoad, nil);
    return object;
}

+(id)makeObjectWithResourcesOfType:(Class)objectClass
                           withData:(NSDictionary *)data
             withResourceDictionary:(NSMutableDictionary*)resources
{
    return [self makeObjectWithResourcesOfType:objectClass
                                      withData:data
                        withResourceDictionary:resources
                                        object:nil];
}

+(id)makeObjectWithResourcesOfType:(Class)objectClass
                          withData:(NSDictionary *)data
            withResourceDictionary:(NSMutableDictionary*)resources
                            object:(id*)obj
{
    
    // Check for special options to building this class
    NSDictionary *specialOptions = [objectClass kinveyObjectBuilderOptions];
    BOOL hasDesignatedInit = NO;
    
    if (specialOptions != nil){
        if ([specialOptions objectForKey:KCS_USE_DESIGNATED_INITIALIZER_MAPPING_KEY] != nil){
            hasDesignatedInit = YES;
        }
    }
    
    // Actually generate the instance of the class
    id copiedObject = nil;
    if (obj) {
        copiedObject = *obj;
    } else {
        if (hasDesignatedInit){
            // If we need to use a designated initializer we do so here
            if ([(id)objectClass respondsToSelector:@selector(kinveyDesignatedInitializer:)]) {
                copiedObject = [objectClass kinveyDesignatedInitializer:data];
            } else {
                copiedObject = [(id)objectClass performSelector:@selector(kinveyDesignatedInitializer)];
            }
        } else {
            // Normal path
            copiedObject = [[objectClass alloc] init];
        }
    }
    
    copiedObject = [KCSObjectMapper populateObjectWithLinkedResources:copiedObject withData:data resourceDictionary:resources];
    return copiedObject;
}

+ (id)makeObjectOfType:(Class)objectClass
              withData:(NSDictionary *)data
{
    return [self makeObjectWithResourcesOfType:objectClass
                                      withData:data
                        withResourceDictionary:nil];
}

+ (id)makeObjectOfType:(Class)objectClass
              withData:(NSDictionary *)data
                object:(id*)obj
{
    return [self makeObjectWithResourcesOfType:objectClass
                                      withData:data
                        withResourceDictionary:nil
                                        object:obj];
}

+ (id)makeObjectOfType:(Class)objectClass
              withData:(NSDictionary *)data
withResourceDictionary:(NSMutableDictionary*)resources
{
    return [self makeObjectWithResourcesOfType:objectClass
                                      withData:data
                        withResourceDictionary:resources];
}

+ (id)makeObjectOfType:(Class)objectClass
              withData:(NSDictionary *)data
withResourceDictionary:(NSMutableDictionary*)resources
                object:(id*)obj
{
    return [self makeObjectWithResourcesOfType:objectClass
                                      withData:data
                        withResourceDictionary:resources
                                        object:obj];
}

static NSDictionary* _defaultBuilders;
NSDictionary* defaultBuilders();
NSDictionary* defaultBuilders()
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultBuilders = @{
                             (id)[NSDate class] : [KCSDateBuilder class],
                             (id)[NSSet class] : [KCSSetBuilder class],
                             (id)[NSMutableSet class] : [KCSMSetBuilder class],
                             (id)[NSOrderedSet class] : [KCSOrderedSetBuilder class],
                             (id)[NSMutableOrderedSet class] : [KCSMOrderedSetBuilder class],
                             (id)[NSMutableAttributedString class] : [KCSMAttributedStringBuilder class],
                             (id)[NSAttributedString class] : [KCSAttributedStringBuilder class],
                             (id)[CLLocation class] : [KCSCLLocationBuilder class],
                             (id)[NSURL class] : [KCSURLBuilder class]
                             };
    });
    
    return _defaultBuilders;
}

Class<KCSDataTypeBuilder> builderForComplexType(id object, Class valClass);
Class<KCSDataTypeBuilder> builderForComplexType(id object, Class valClass)
{
    NSDictionary* options = builderOptions(object);
    NSDictionary* builders = [options objectForKey:KCS_DICTIONARY_DATATYPE_BUILDER];
    Class<KCSDataTypeBuilder> builderClass = ifNotNil(builders, [builders objectForKey:valClass]);
    if (builderClass == nil) {
        NSDictionary* d = defaultBuilders();
        builderClass = [d objectForKey:valClass];
    }
    return ifNotNil(builderClass, builderClass);
}

BOOL isCollection(id obj)
{
    return [obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSSet class]] || [obj isKindOfClass:[NSOrderedSet class]];
}

void setError(NSError** error, NSString* objectId, NSString* jsonName)
{
    if (error != NULL) {
        NSDictionary* info = @{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Reference object does not have ID set."],
                               NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:@"Object (id=%@) is trying to create a reference in field '%@', but that object does not yet have an assigned id. Save this object to its collection first", objectId, jsonName], NSLocalizedRecoverySuggestionErrorKey : @"Save reference object first or pre-assign it an id."};
        *error = [NSError errorWithDomain:KCSAppDataErrorDomain code:KCSReferenceNoIdSetError userInfo:info];
    }
}

id valueForProperty(NSString* jsonName, id value, BOOL withRefs, id object, NSString* collectionName, NSString* key, NSString* refCollection, NSMutableArray* resourcesToSave, NSError** error, NSString** objectId, NSMutableArray* referencesToSave)
{
    if (withRefs == YES && constantsEqual(refCollection, KCSFileStoreCollectionName)) {
        if (*objectId == nil) {
            *objectId = [NSString UUID];
            [object setKinveyObjectId:*objectId];
        }
        NSString* fileId = [NSString stringWithFormat:@"%@-%@-%@", collectionName, *objectId, key];
        KCSFile* fileRef = [KCSFile fileRef:value collectionIdProperty:fileId];
        
        //pass parent ACLs to ref file
        NSDictionary* hostToJsonMap = [object hostToKinveyPropertyMapping];
        if (hostToJsonMap != nil) {
            NSArray* metaProperties = [hostToJsonMap allKeysForObject:KCSEntityKeyMetadata];
            if (metaProperties && metaProperties.count > 0) {
                NSString* metaProperty = metaProperties[0];
                KCSMetadata* meta = [object valueForKey:metaProperty];
                if (meta) {
                    fileRef.metadata = meta;
                }
            }
        }
        
        [resourcesToSave addObject:fileRef];
        return fileRef;
    } else if (withRefs == YES && refCollection != nil) {
        // have a kinvey ref
        BOOL shouldSaveRef = [object respondsToSelector:@selector(referenceKinveyPropertiesOfObjectsToSave)] && [[object referenceKinveyPropertiesOfObjectsToSave] containsObject:jsonName] == YES;
        if (isCollection(value)) {
            NSArray* arrayValue = value;
            Class<KCSDataTypeBuilder> builder = builderForComplexType(object, [value classForCoder]);
            if (builder != nil) {
                arrayValue = [builder JSONCompatabileValueForObject:value];
            }
            NSMutableArray* refArray = [NSMutableArray arrayWithCapacity:[arrayValue count]];
            for (id arrayVal in arrayValue) {
                if ([arrayVal isEqual:[NSNull null]]) {
                    continue;
                }
                KCSKinveyRef* ref = [[KCSKinveyRef alloc] initWithObj:arrayVal andCollection:refCollection];
                if ([ref unableToSaveReference:shouldSaveRef]) {
                    setError(error, *objectId, jsonName);
                    return nil;
                }
                [refArray addObject:ref];
            }
            if (shouldSaveRef) {
                [referencesToSave addObjectsFromArray:refArray];
            }
            return refArray;
        } else {
            KCSKinveyRef* ref = [[KCSKinveyRef alloc] initWithObj:value andCollection:refCollection];
            if ([ref unableToSaveReference:shouldSaveRef]) {
                setError(error, *objectId, jsonName);
                return nil;
            }
            if (shouldSaveRef) {
                [referencesToSave addObject:ref];
            }
            return ref;
        }
    } else {
        Class valClass = [value classForCoder];
        Class<KCSDataTypeBuilder> builder = builderForComplexType(object, valClass);
        if (builder != nil) {
            id jsonType = [builder JSONCompatabileValueForObject:value];
            return jsonType;
        } else {
            //TODO: handle complex types
            //don't need to look at type, just save
            return value;
        }
    }
}

+ (KCSSerializedObject*) raiseUnkownKeyException:(NSException*)exception error:(NSError**)error key:(NSString*)clientPropertyName;
{
    if ([[exception name] isEqualToString:@"NSUnknownKeyException"]) {
        KCSLogError(@"Error serialzing entity for use with Kinvey: '%@'", [exception reason]);
        if (error != NULL) {
            NSDictionary* info = @{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Entity does not have property '%@' as specified in hostToKinveyPropertyMapping", clientPropertyName],
                                   NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:@"Cannot map '%@', a non-existant property", clientPropertyName], NSLocalizedRecoverySuggestionErrorKey : @"Check the hostToKinveyPropertyMapping for typos and errors."};
            *error = [NSError errorWithDomain:KCSAppDataErrorDomain code:KCSInvalidKCSPersistableError userInfo:info];
        }
        return nil;
    } else {
        [exception raise];
    }
    return nil;
}

+ (KCSSerializedObject*) makeResourceEntityDictionaryFromObject:(id)object forCollection:(NSString*)collectionName withReferences:(BOOL)withRefs error:(NSError**)error
{
    NSMutableDictionary *dictionaryToMap = [[NSMutableDictionary alloc] init];
    NSDictionary *kinveyMapping = [object hostToKinveyPropertyMapping];
    NSString* objectId = nil;
    @try {
        objectId = [object kinveyObjectId]; //need to get the id up front for kinveyfile naming
    }
    @catch (NSException *exception) {
        return [self raiseUnkownKeyException:exception error:error key:@"_id"];
    }
    
    NSMutableArray* resourcesToSave = nil;
    NSMutableArray* referencesToSave = nil;
    NSDictionary* kinveyRefMapping = nil;
    
    if (withRefs == YES && [[object class] respondsToSelector:@selector(kinveyPropertyToCollectionMapping)]) {
        resourcesToSave = [NSMutableArray array];
        referencesToSave = [NSMutableArray array];
        kinveyRefMapping = [[object class] kinveyPropertyToCollectionMapping];
    }
    
    for (NSString* clientPropertyName in [kinveyMapping allKeys]) {
        NSString *jsonName = [kinveyMapping valueForKey:clientPropertyName];
        
        id value = nil;
        @try {
            value = [object valueForKey:clientPropertyName];
        }
        @catch (NSException *exception) {
            return [self raiseUnkownKeyException:exception error:error key:clientPropertyName];
        }
        
        if (value == nil) {
            //don't map nils
            continue;
        }
        if ([jsonName isEqualToString:KCSEntityKeyId] && (value == [NSNull null] || ([value isKindOfClass:[NSString class]] && [value isEqualToString:@""]))) {
            //treat @"" as nil for the _id case; assembla #2676
            objectId = nil;
            continue;
        }
        
        //serialize the fields to a dictionary
        if ([jsonName isEqualToString:KCSEntityKeyMetadata]) {
            //hijack metadata & only save ACLs (kmd can't be overwritten yet)
            if ([value isKindOfClass:[KCSMetadata class]]) {
                dictionaryToMap[kACLKey] = [(KCSMetadata*)value aclValue];
                dictionaryToMap[kKMDKey] = [(KCSMetadata*)value kmdDict];
            } else if ([value isKindOfClass:[NSDictionary class]]) {
                dictionaryToMap[kKMDKey] = value[kKMDKey];
                //dictionaryToMap[kACLKey] = value[kACLKey];
            }
        } else {
            value = valueForProperty(jsonName, //jsonName
                                     value, //value
                                     withRefs, //withRefs
                                     object, //object
                                     collectionName, //collectionName (the object's collection)
                                     clientPropertyName,// key
                                     kinveyRefMapping[jsonName], //ref Collection
                                     resourcesToSave, //resourcesTo Save
                                     error, //error
                                     &objectId, //objectId
                                     referencesToSave); //referencesToSave
            if (value == nil) {
                return nil;
            }
            
            dictionaryToMap[jsonName] = value;
        } // end test object name
    } // end for key in kinveyMapping
    
    // We've handled all the built-in keys, we need to just store the dict if there is one
    BOOL useDictionary = [[builderOptions(object) objectForKey:KCS_USE_DICTIONARY_KEY] boolValue];
    
    if (useDictionary == YES) {
        // Get the name of the dictionary to store
        NSString *dictionaryName = [builderOptions(object) objectForKey:KCS_DICTIONARY_NAME_KEY];
        
        NSDictionary *subDict = (NSDictionary *)[object valueForKey:dictionaryName];
        for (NSString *key in subDict) {
            id value = subDict[key];
            value = valueForProperty(key,
                                     value,
                                     withRefs,
                                     object,
                                     collectionName,
                                     key,
                                     kinveyRefMapping[key],
                                     resourcesToSave,
                                     error,
                                     &objectId,
                                     referencesToSave);
            dictionaryToMap[key] = value;
        }
    }
    
    return [[KCSSerializedObject alloc] initWithObject:object ofId:objectId dataToSerialize:dictionaryToMap resources:resourcesToSave references:referencesToSave];
}

+ (KCSSerializedObject *)makeResourceEntityDictionaryFromObject:(id)object forCollection:(NSString*)collectionName error:(NSError**)error
{
    return [self makeResourceEntityDictionaryFromObject:object forCollection:collectionName withReferences:YES error:error];
}

+ (KCSSerializedObject *)makeKinveyDictionaryFromObject: (id)object error:(NSError**)error
{
    return [self makeResourceEntityDictionaryFromObject:object forCollection:nil withReferences:NO error:error];
}

@end
