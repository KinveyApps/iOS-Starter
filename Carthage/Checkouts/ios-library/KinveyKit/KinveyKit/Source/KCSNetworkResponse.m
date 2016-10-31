//
//  KCSNetworkResponse.m
//  KinveyKit
//
//  Created by Michael Katz on 8/23/13.
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

#import "KCSNetworkResponse.h"
#import "KinveyCoreInternal.h"
#import "KinveyErrorCodes.h"
#import "KCSClient.h"
#import "KinveyPersistable.h"

#define kHeaderRequestId @"X-Kinvey-Request-Id"
#define kHeaderExecutedHooks @"x-kinvey-executed-collection-hooks"

#define KCS_ERROR_DEBUG_KEY @"debug"
#define KCS_ERROR_DESCRIPTION_KEY @"description"
#define KCS_ERROR_KINVEY_ERROR_CODE_KEY @"error"

#define kKCSErrorCode KCSErrorCodeKey
#define kKCSRequestId @"Kinvey.RequestId"
#define kKCSUnknownBody @"Kinvey.UnknownErrorBody"
#define kKCSExecutedBL @"Kinvey.ExecutedHooks"

#define kResultsKey @"result"

@interface KCSNetworkResponse ()
@end

@implementation KCSNetworkResponse

+ (instancetype) MockResponseWith:(NSInteger)code data:(id)data
{
    KCSNetworkResponse* response = [[KCSNetworkResponse alloc] init];
    response.code = code;
    if ([data isKindOfClass:[NSData class]] == NO) {
        data = [NSJSONSerialization dataWithJSONObject:data
                                               options:0
                                                 error:nil];
    }
    response.jsonData = data;
    return response;
}

- (BOOL)isKCSError
{
    return self.code >= 400;
}

- (NSString*) requestId
{
    return self.headers[kHeaderRequestId];
}

- (NSError*) errorObject
{
    NSError* error = nil;
    NSDictionary* kcsErrorDict = [self jsonObjectError:&error];
    if (error) {
        return error;
    }

    NSMutableDictionary* userInfo = [NSMutableDictionary dictionaryWithCapacity:5];
    if (kcsErrorDict) {
        if ([kcsErrorDict isKindOfClass:[NSDictionary class]]) {
            setIfValNotNil(userInfo[NSLocalizedDescriptionKey], kcsErrorDict[KCS_ERROR_DESCRIPTION_KEY]);
            setIfValNotNil(userInfo[NSLocalizedFailureReasonErrorKey], kcsErrorDict[KCS_ERROR_DEBUG_KEY]);
            setIfValNotNil(userInfo[kKCSErrorCode], kcsErrorDict[KCS_ERROR_KINVEY_ERROR_CODE_KEY]);
        } else {
            setIfValNotNil(userInfo[kKCSUnknownBody], kcsErrorDict);
        }
    }
    
    setIfValNotNil(userInfo[NSURLErrorFailingURLErrorKey], self.originalURL);
    setIfValNotNil(userInfo[kKCSRequestId], [self requestId]);
    
    setIfValNotNil(userInfo[kKCSExecutedBL], self.headers[kHeaderExecutedHooks]);

    error = [NSError createKCSError:KCSServerErrorDomain code:self.code userInfo:userInfo];
    return error;
}

- (NSString*) stringValue
{
    return [[NSString alloc] initWithData:self.jsonData encoding:NSUTF8StringEncoding];
}

- (id) jsonResponseValue:(NSError**) anError format:(NSStringEncoding)format
{
    NSString* string = [[NSString alloc] initWithData:self.jsonData encoding:format];
    NSData* data = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error = nil;
    NSMutableDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data
                                                                        options:NSJSONReadingMutableContainers
                                                                          error:&error];
    if (error) {
        KCSLogError(KCS_LOG_CONTEXT_NETWORK, @"JSON Serialization retry failed: %@", error);
        if (anError != NULL) {
            *anError = error;
        }
    }
    return jsonResponse[kResultsKey];
}

- (id) jsonResponseValue:(NSError**) anError
{
    if (self.jsonData == nil) {
        return nil;
    }
    if (self.jsonData.length == 0) {
        return nil;
    }
    //results are now wrapped by request in KCSRESTRequest, and need to unpack them here.
    NSError* error = nil;
    NSMutableDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:self.jsonData
                                                                        options:NSJSONReadingMutableContainers
                                                                          error:&error];
    NSObject* jsonObj = nil;
    if (![jsonResponse isKindOfClass:[NSDictionary class]]) {
        if (anError) {
            *anError = [NSError createKCSErrorWithReason:@"Kinvey requires a JSON Object as response body"];
        }
    } else if (error) {
        KCSLogError(KCS_LOG_CONTEXT_NETWORK, @"JSON Serialization failed: %@", error);
        if (anError != NULL) {
            *anError = error;
        }
    } else {
        jsonObj = jsonResponse[kResultsKey];
        jsonObj = jsonObj ? jsonObj : jsonResponse;
    }
    
    if (jsonObj) {
        jsonObj = [NSDictionary transformValue:jsonObj];
    }
    
    return jsonObj;
}

- (id)jsonObject
{
    NSString* cytpe = self.headers[kHeaderContentType];
    
    if (cytpe == nil || [cytpe containsStringCaseInsensitive:@"json"]) {
        return [self jsonResponseValue:nil];
    } else {
        if (self.jsonData.length == 0) {
            return @{};
        } else {
            KCSLogWarn(KCS_LOG_CONTEXT_NETWORK, @"not a json repsonse");
            return @{@"debug" : [self stringValue]};
        }
    }
}

- (id)jsonObjectError:(NSError**)error
{
    NSString* cytpe = self.headers[kHeaderContentType];
    cytpe = cytpe.lowercaseString;
    
    id jsonObj;
    if ([cytpe isEqualToString:@"application/json"] || [cytpe hasPrefix:@"application/json;"]) {
        jsonObj = [self jsonResponseValue:error];
        if ([jsonObj isKindOfClass:[NSDictionary class]] && !self.skipValidation && !jsonObj[@"error"]) {
            if (!jsonObj[KCSEntityKeyId]) {
                if (error) {
                    *error = [NSError createKCSErrorWithReason:[NSString stringWithFormat:@"KCSPersistable objects requires the `%@` property", KCSEntityKeyId]];
                }
            } else if (![jsonObj[KCSEntityKeyId] isKindOfClass:[NSString class]]) {
                if (error) {
                    *error = [NSError createKCSErrorWithReason:[NSString stringWithFormat:@"`%@` property needs to be string", KCSEntityKeyId]];
                }
            }
        }
    } else {
        jsonObj = nil;
        if (error) {
            *error = [NSError createKCSErrorWithReason:@"Kinvey requires `application/json` as the Content-Type of the response"];
        }
    }
    
    return jsonObj;
}

@end
