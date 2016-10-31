//
//  KinveyCollection.m
//  KinveyKit
//
//  Created by Brian Wilson on 10/13/11.
//  Copyright (c) 2011-2015 Kinvey. All rights reserved.
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


#import "KinveyCollection.h"

#import "KCSClient.h"
#import "KinveyUser.h"
#import "KCSClientConfiguration.h"
#import "KCSHttpRequest.h"
#import "KCSAppdataStore.h"

NSString* const KCSUserCollectionName = @"user";

typedef enum KCSCollectionCategory : NSInteger {
    KCSCollectionAppdata,
    KCSCollectionUser,
    KCSCollectionBlob
} KCSCollectionCategory;

@interface KCSCollection ()
@property (nonatomic) KCSCollectionCategory category;

@end


@implementation KCSCollection

// Usage concept
// In controller
// self.objectCollection = [[KCSCollection alloc] init];
// self.objectCollection.collectionName = @"lists";
// self.objectColleciton.objectTemplate = [[MyObject alloc] init];
// self.objectCollection.kinveyConnection = [globalConnection];
//
// And later...
// [self.objectCollection collectionDelegateFetchAll: ()

- (id)initWithName: (NSString *)name forTemplateClass: (Class) theClass
{
    self = [super init];
    
    if (self){
        if ([name isEqualToString:KCSUserCollectionName]) {
            //remove this in the wake fo KCSUser2 & KCSUser2 subclasses
//            if ([theClass isSubclassOfClass:[KCSUser class]] == NO) {
//                [[NSException exceptionWithName:@"Invalid Template" reason:@"User collection must have a template that is of type 'KCSUser'" userInfo:nil] raise];
//            }
            _category = KCSCollectionUser;
        } else if ([name isEqualToString:@"_blob"]) {
            _category = KCSCollectionBlob;
        } else {
            _category = KCSCollectionAppdata;
        }
        _collectionName = name;
        _objectTemplate = theClass;
        _lastFetchResults = nil;
        _query = nil;
    }
    
    return self;
}


- (id)init
{
    return [self initWithName:nil forTemplateClass:[NSMutableDictionary class]];
}



// Override isEqual method to allow comparing of Collections
// A collection is equal if the name, object template and filter are the same
- (BOOL) isEqual:(id)object
{
    KCSCollection *c = (KCSCollection *)object;
    
    if (![object isKindOfClass:[self class]]){
        return NO;
    }
    
    if (![self.collectionName isEqualToString:c.collectionName]){
        return NO;
    }
    
    if (![c.objectTemplate isEqual:c.objectTemplate]){
        return NO;
    }
    
    return YES;
}



+ (KCSCollection *)collectionFromString: (NSString *)string ofClass: (Class)templateClass
{
    KCSCollection *collection = [[self alloc] initWithName:string forTemplateClass:templateClass];
    return collection;
}


#pragma mark Basic Methods
- (NSString*) baseURL
{
    NSString* baseURL = nil;
    switch (_category) {
        case KCSCollectionUser:
            baseURL = [[KCSClient sharedClient] userBaseURL]; /*use user url for user collection*/
            break;
        case KCSCollectionBlob:
            baseURL = [[KCSClient sharedClient] resourceBaseURL]; /*use blob url*/
            break;
        case KCSCollectionAppdata:
        default:
            baseURL = [[KCSClient sharedClient] appdataBaseURL]; /* Initialize this to the default appdata URL*/
            break;
    }
    DBAssert(baseURL != nil, @"Should have a base url for the collection %@", _collectionName);
    return baseURL;
}

- (NSString*) urlForEndpoint:(NSString*)endpoint
{
    if (endpoint == nil) {
        endpoint = @"";
    }
    
    NSString *resource = nil;
    // create a link: baas.kinvey.com/:appid/:collection/:id
    if ([self.collectionName isEqualToString:@""]){
        resource = [self.baseURL stringByAppendingFormat:@"%@", endpoint];
    } else {
        resource = [self.baseURL stringByAppendingFormat:@"%@/%@", self.collectionName, endpoint];
    }
    return resource;
}

- (void)fetchAllWithDelegate:(id<KCSCollectionDelegate>)delegate
{
    [[KCSAppdataStore storeWithCollection:self options:nil] queryWithQuery:[KCSQuery query] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        if (errorOrNil) {
            [delegate collection:self didFailWithError:errorOrNil];
        } else {
            [delegate collection:self didCompleteWithResult:objectsOrNil];;
        }
    } withProgressBlock:nil];
}

- (void)fetchWithQuery:(KCSQuery *)query withCompletionBlock:(KCSCompletionBlock)onCompletion withProgressBlock:(KCSProgressBlock)onProgress
{
    SWITCH_TO_MAIN_THREAD_COMPLETION_BLOCK(onCompletion);
    SWITCH_TO_MAIN_THREAD_PROGRESS_BLOCK(onProgress);
    [[KCSAppdataStore storeWithCollection:self options:nil] queryWithQuery:query withCompletionBlock:onCompletion withProgressBlock:onProgress];
}


- (void)fetchWithDelegate:(id<KCSCollectionDelegate>)delegate
{
    [[KCSAppdataStore storeWithCollection:self options:nil] queryWithQuery:self.query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        if (errorOrNil) {
            [delegate collection:self didFailWithError:errorOrNil];
        } else {
            [delegate collection:self didCompleteWithResult:objectsOrNil];;
        }
    } withProgressBlock:nil];
}

#pragma mark Utility Methods

- (void)entityCountWithDelegate:(id<KCSInformationDelegate>)delegate
{
    [[KCSAppdataStore storeWithCollection:self options:nil] countWithBlock:^(unsigned long count, NSError *errorOrNil) {
        if (errorOrNil) {
            [delegate collection:self informationOperationFailedWithError:errorOrNil];
        } else {
            [delegate collection:self informationOperationDidCompleteWithResult:(int)count];
        }
    }];
}

-(void)entityCountWithBlock:(KCSCountBlock)countBlock
{
    SWITCH_TO_MAIN_THREAD_COUNT_BLOCK(countBlock);
    [[KCSAppdataStore storeWithCollection:self options:nil] countWithBlock:countBlock];
}

// AVG is not in the REST docs anymore

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"KCSCollection: %@", _collectionName];
}

#pragma mark - User collection
+ (instancetype) userCollection
{
    Class userClass = [KCSClient sharedClient].configuration.options[KCS_USER_CLASS];
    if (!userClass) {
        userClass = [KCSUser class];
    }
    return [self collectionFromString:KCSUserCollectionName ofClass:userClass];
}


#pragma mark - KinveyKit2
- (NSString*) route
{
    NSString* route = KCSRESTRouteAppdata;
    if ([_collectionName isEqualToString:KCSUserCollectionName]) {
        route = KCSRESTRouteUser;
    } else if ([_collectionName isEqualToString:@"_blob"]) {
        route = KCSRESTRouteBlob;
    }
    return route;
}
@end
