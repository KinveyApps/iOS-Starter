//
//  KCSMetadata.m
//  KinveyKit
//
//  Created by Michael Katz on 6/25/12.
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


#import "KCSMetadata.h"
#import "NSDate+ISO8601.h"
#import "KCSClient.h"
#import "KinveyUser.h"
#import "KCSLogManager.h"

#define KCS_CONST_IMPL NSString* const

#define kKMDLMTKey @"lmt"
#define kKMDECTKey @"ect"
#define kACLCreatorKey @"creator"
#define kACLReadersKey @"r"
#define kACLWritersKey @"w"
#define kACLGlobalReadKey @"gr"
#define kACLGlobalWriteKey @"gw"

KCS_CONST_IMPL KCSMetadataFieldCreator = @"_acl.creator";
KCS_CONST_IMPL KCSMetadataFieldLastModifiedTime = @"_kmd.lmt";
KCS_CONST_IMPL KCSMetadataFieldCreationTime = @"_kmd.ect";

@interface KCSUser ()
- (NSString*) userId;
@end

@interface KCSMetadata ()
@property (nonatomic, strong, readonly) NSString* lmt;
@property (nonatomic, strong, readonly) NSDate* lmtAsDate;
@property (nonatomic, strong, readonly) NSString* ect;
@property (nonatomic, strong, readonly) NSDate* ectAsDate;
@property (nonatomic, strong, readonly) NSMutableDictionary* acl;
@end

@implementation KCSMetadata

- (instancetype) init
{
    self = [super init];
    if (self) {
        _acl = [NSMutableDictionary dictionary];
    }
    return self;
}

- (instancetype) initWithKMD:(NSDictionary*)kmd acl:(NSDictionary*)pACL
{
    self = [self init];
    if (self) {
        _lmt = [kmd objectForKey:kKMDLMTKey];
        _ect = [kmd objectForKey:kKMDECTKey];
        _acl = [NSMutableDictionary dictionaryWithDictionary:pACL];

        NSMutableArray* readers = [_acl objectForKey:kACLReadersKey];
        if (readers != nil) {
            [_acl setObject:[readers mutableCopy] forKey:kACLReadersKey];
        }
        NSMutableArray* writers = [_acl objectForKey:kACLWritersKey];
        if (writers != nil) {
            [_acl setObject:[writers mutableCopy] forKey:kACLWritersKey];
        }
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    KCSMetadata* metadata = [[KCSMetadata allocWithZone:zone] init];
    if (metadata) {
        [metadata.acl addEntriesFromDictionary:_acl];
        metadata->_ect = [_ect copyWithZone:zone];
        metadata->_ectAsDate = [_ectAsDate copyWithZone:zone];
        metadata->_lmt = [_lmt copyWithZone:zone];
        metadata->_lmtAsDate = [_lmtAsDate copyWithZone:zone];
        [metadata.writers addObjectsFromArray:self.writers];
        [metadata.readers addObjectsFromArray:self.readers];
    }
    return metadata;
}

- (NSDictionary*) kmdDict
{
    NSDictionary* kmd;
    if (_ect) {
        kmd = @{kKMDECTKey : _ect, kKMDLMTKey : _lmt};
    } else if (_lmt) {
        kmd =  @{kKMDLMTKey : _lmt};
    } else {
        kmd = nil;
    }
    return kmd;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    if ([aCoder isKindOfClass:[NSKeyedArchiver class]]) {
        [aCoder encodeObject:_acl forKey:@"acl"];
        NSDictionary* kmd = [self kmdDict];
        [aCoder encodeObject:kmd forKey:@"kmd"];
    } else {
        KCSLogError(@"Tried to encode %@, but encoder %@ is not a NSKeyedArchiver", self, aCoder);
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ([aDecoder isKindOfClass:[NSKeyedUnarchiver class]]) {
        NSDictionary* kmd = [aDecoder decodeObjectForKey:@"kmd"];
        NSDictionary* acl = [aDecoder decodeObjectForKey:@"acl"];
        self = [self initWithKMD:kmd acl:acl];
    } else {
        KCSLogError(@"Tried to decode %@, but decoder %@ is not a NSKeyedUnArchiver", self, aDecoder);
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[KCSMetadata class]] &&
    [_acl isEqualToDictionary:[(KCSMetadata*)object acl]] &&
    [[self kmdDict] isEqualToDictionary:[(KCSMetadata*)object kmdDict]];
}

- (NSUInteger)hash
{
    return [_acl hash] +  [[self kmdDict] hash];
}

#pragma mark -

- (NSString*) creatorId 
{
    return [_acl objectForKey:kACLCreatorKey];
}

- (BOOL) hasWritePermission
{
    KCSUser* user = [KCSUser activeUser];
    NSString* userId = [user userId];
    return [[self creatorId] isEqualToString:userId] || [self.writers containsObject:userId] || [self isGloballyWritable];
}

#pragma mark - readers/writers

- (NSMutableArray *)readers
{
    NSMutableArray* readers = [_acl objectForKey:kACLReadersKey];
    if (readers == nil) {
        readers = [NSMutableArray array];
        [_acl setObject:readers forKey:kACLReadersKey];
    }
    DBAssert(readers != nil && [readers isKindOfClass:[NSMutableArray class]], @"should be mutable");
    return readers;
}

- (NSMutableArray *) writers
{
    NSMutableArray* writers = [_acl objectForKey:kACLWritersKey];
    if (writers == nil) {
        writers = [NSMutableArray array];
        [_acl setObject:writers forKey:kACLWritersKey];
    }
    DBAssert(writers != nil && [writers isKindOfClass:[NSMutableArray class]], @"should be mutable");
    return writers;
}

#pragma mark - Globals

- (BOOL) isGloballyReadable
{
    return [[_acl objectForKey:kACLGlobalReadKey] boolValue];
}

- (void) setGloballyReadable:(BOOL)readable
{
    [_acl setObject:@(readable) forKey:kACLGlobalReadKey];
}

- (BOOL) isGloballyWritable
{
    return [[_acl objectForKey:kACLGlobalWriteKey] boolValue];
}

- (void) setGloballyWritable:(BOOL)writable
{
    [_acl setObject:@(writable) forKey:kACLGlobalWriteKey];
}

- (NSDictionary*) aclValue
{
    return _acl;
}

- (NSDate*) lastModifiedTime {
    if (!self.lmtAsDate && self.lmt) {
        _lmtAsDate = [NSDate dateFromISO8601EncodedString:self.lmt];
    }
    return self.lmtAsDate;
}

- (NSDate*) creationTime {
    if (!self.ectAsDate && self.ect) {
        _ectAsDate = [NSDate dateFromISO8601EncodedString:self.ect];
    }
    return self.ectAsDate;
}

@end
