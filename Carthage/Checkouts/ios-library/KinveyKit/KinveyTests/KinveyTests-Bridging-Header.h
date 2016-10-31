//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import <XCTest/XCTest.h>
#import "KinveyKit-Prefix.pch"
#import "KinveyKit.h"
#import "TestUtils2.h"
#import "KCSMutableOrderedDictionary.h"
#import "KCSUser2+KinveyUserService.h"
#import "KinveyUser+Private.h"
#import "MLIBZ_239_DataHelper.h"
#import "KCSTryCatch.h"
#import "KCSMemory.h"
#import "KCSNSURLSessionFileOperation.h"
#import "KCSTestCase.h"
#import "KCSNetworkResponse.h"
#import "KinveyErrorCodes.h"
#import "KCSClientConfiguration.h"
#import "KCSClientConfiguration+KCSInternal.h"
#import "KCSObjectCache.h"
#import "NSDictionary+KinveyAdditions.h"

@interface KCSUser2 ()

+(BOOL)isValidMICRedirectURI:(NSString *)redirectURI
                      forURL:(NSURL *)url
                      params:(NSDictionary**)params;

@end

@interface NSString (KinveyAdditions)

@property (readonly) NSString* sha1;

@end

@interface KCSFile (KCSObject)

+(NSInteger)referenceCount;

@end

@interface KCSNSURLSessionFileOperation (KCSObject)

+(NSInteger)referenceCount;

@end
