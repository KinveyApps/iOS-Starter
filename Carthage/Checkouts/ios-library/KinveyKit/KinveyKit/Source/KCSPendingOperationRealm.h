//
//  KCSURLRequestRealm.h
//  Kinvey
//
//  Created by Victor Barros on 2016-01-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

@import Foundation;
@import Realm;

@interface KCSPendingOperationRealm : RLMObject <KNVPendingOperation>

@property NSString* requestId;
@property NSDate* date;

@property NSString* collectionName;
@property (nonatomic, copy) NSString* objectId;

@property NSString* method;
@property NSString* url;
@property NSData* headers;
@property NSData* body;

-(instancetype)initWithURLRequest:(NSURLRequest*)urlRequest
                   collectionName:(NSString*)collectionName
                         objectId:(NSString*)objectId;

-(NSDictionary<NSString*, id>*)toJson;

@end
