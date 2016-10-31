# KinveyKit Release History

## 1.33
### 1.33.1

**Release Date:** June 30, 2015

* Bug fix(es):
    * Fix crash that could occur when registering/unregistering a device token if the device token was `nil`.

## 1.29
### 1.29.0

**Release Date:** March 25, 2015

* Enhancement: Added support for setting client app version.
* Enhancement: Added support for setting custom request properties.

For example:

	//global
	KCSRequestConfiguration* requestConfiguration = [KCSRequestConfiguration requestConfigurationWithClientAppVersion:@"2.0"
	                                                                                       andCustomRequestProperties:@{@"lang" : @"fr",
	                                                                                                                    @"globalProperty" : @"abc"}];
	KCSClientConfiguration* clientConfiguration = [KCSClientConfiguration configurationWithAppKey:@"<#Your App Key#>"
	                                                                                       secret:@"<#Your App Secret#>"
	                                                                                      options:<#Your Options#>
	                                                                         requestConfiguration:requestConfiguration];
																			 
	[[KCSClient sharedClient] initializeWithConfiguration:clientConfiguration];
	
	//per request
	KCSRequestConfiguration* requestConfig = [KCSRequestConfiguration requestConfigurationWithClientAppVersion:@"1.0"
	                                                                                andCustomRequestProperties:@{@"lang" : @"pt",
	                                                                                                             @"requestProperty" : @"123"}];
	   [store saveObject:obj
	requestConfiguration:requestConfig
	 withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
		 //do something awesome here!
	 } withProgressBlock:nil];

## 1.28
### 1.28.0

**Release Date:** November 26, 2014

* Added support for iOS 8 push notifications
* Removed support for iOS versions < 7.1
* Bug fix(es):
    * Fix an issue with PingResults

## 1.27
### 1.27.1

**Release Date:** July 31, 2014

* Bug fix(es):
    * Fix issue where only one result returned from local cache.

### 1.27.0 

**Release Date:** June 19, 2014

* Added new identity provider `KCSSocialIDKinvey` to use new Kinvey OAuth2 tokens for log-in. See the updated REST documentation for instructions on how to obtain an access token.

For example:

    [KCSUser loginWithSocialIdentity:KCSSocialIDKinvey accessDictionary:@{@"access_token":@"<#Access Token#>"} withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
        if (!errorOrNil) {
            //Do Stuff
        } else {
            //handle error
        }
    }];



* Add configuration option `KCS_ALWAYS_USE_NSURLREQUEST`, set to `@YES` for better performance when sending many simultaneous requests. 
* Internal Improvements
* Code cleanup:
	* Removed deprecated `KCSResourceService` and associated classes.
	* Removed the remaining delegated-based `KCSUser` methods.
	* Removed the project template since it was pretty outdated. 
* Bug fix(es):
    * Fix crash when network error occurs using `checkUsername:completion:`.


## 1.26
### 1.26.9
**Release Date:** May 5, 2014

* Bug fix(es):
    * Improved algorithm for `KCSCachePolicyNetworkFirst` loading.

### 1.26.8
**Release Date:** April 28, 2014

* Bug fix(es):
    * Fix bug where active user not properly cached between sessions.

### 1.26.7
**Release Date:** April 22, 2014

* Code Cleanup:
    * Removed deprecated `public` property of `KCSFile`.
    * Removed spurious logged error with queries. 

### 1.26.6
**Release Date:** April 1, 2014

* Exposes `- [KCSPush unreigsterDeviceToken:]` to remove a device token from a user.
* Code Cleanup:
    * Remove deprecated `KCSPush` methods.
* Bug fix(es):
    * Fix issue with file store upload blocks on iOS6. 

### 1.26.5
**Release Date:** March 19, 2014

* Bug fix(es):
    * Fix issue on `KCSOfflineUpdateDelegate` where dates were returned as strings.

### 1.26.4
**Release Date:** March 5, 2014

* Bug fix(es):
    * Fix crash when using certain query formats.

### 1.26.3
**Release Date:** February 14, 2014

* Bug fix(es):
     * Fix memory leak when using progress block. 

### 1.26.2
**Release Date:** February 10, 2014

* Bug fixes:
     * Add prefix to Cocoalumberjack classes missed in the last release.
     * Fix file upload completion block not being called.
* Code cleanup:
     * Deprecated `-[KCSClient userAgent]`.

### 1.26.1
**Release Date:** February 7, 2014

* Stability and performance improvements.
* Added `+[KCSUser getAccessDictionaryFromTwitterFromTwitterAccounts:accountChooseBock:]` to allow clients to present a list of twitter account for the user to choose which one to access. 
* Prefixed Cocoalumberjack classes to avoid conflicts.
* Bug fixes:
     * `-[KCSUser sessionAuth]` is still deprecated, but now returns the auth token.
     * Fixed deadlock when downloading a list of named files.
     * Fixed bug when PUTing objects from offline save had empty bodies.
* Code cleanup:
     * Deprecated collection-style methods from `KCSPersistable` protocol, including `KCSPersistableDelegate`, `deleteFromCollection:withDelegate:`, and `saveToCollection:withDelegate:delegate`.
     * Removed deprecated `NSObject` category method `setValue:forProperty:`, deprecated in 1.2.0.

### 1.26.0
**Release Date:** January 28, 2014

* Drop support for iOS 5. 
* Added [network activity notifications](http://devcenter.kinvey.com/ios/guides/iossdk#activityindicator): `KCSNetworkConnectionDidStart` and `KCSNetworkConnectionDidEnd`.
* Added `@"Kinvey.ExecutedHooks"`key to completionBlock error object `userInfo` dictionaries. This will show which collection hooks were executed as part of the request. This will help troubleshoot when getting unexpected results from an API call.
* Internal performance improvements. In particular, data store completion block callbacks should now always be called on main thread, and progress blocks on arbitrary background thread. 
* Dependency change:
     * `KinveyKit` now links against `Social.framework` instead of `Twitter.framework`.
* Bug fix(es):
     * Fix issue where `KCSUserDiscovery` callback called twice.
     * Stability fixes for active user refresh.
     * Fix several issues with files and user queries. 
     * Multiple simultaneous custom endpoint requests is now handled properly. 
* Code cleanup:
     * Deprecated `KCSAllObjects`; use `[KCSQuery query]` instead.
     * Deprecated `KCSCollectionDelegate` and networking-methods of the `KCSCollection` class. These don't get the benefit of caching, error handling etc. 
     * Removed `KCSEntityDelegate` protocol and `-[NSObject(KinveyEntity) loadObjectWithID:]`, originally deprecated in 1.19.0.
     * Removed store and collection factory methods from `KCSClient`, originally deprecated in 1.14.0.
     * Removed reachability helpers from `KCSPing`, originally deprecated in 1.16.0 and 1.20.1.
     * Updated fmdb library.

## 1.25
### 1.25.0
**Release Date:** January 8, 2014

* Updates to User API
    * Added `+[KCSUser createAutogeneratedUser:completion:]` and `+[KCSUser userWithUsername:password:fieldsAndValues:withCompletionBlock:]`. Deprecated `+[KCSUser createAutogeneratedUser:]` and `+[KCSUser userWithUsername:password:withCompletionBlock:]`; supply `nil` for fieldsAndValues for the old behavior.
         * This allows for setting additional attributes, such as email and name at user creation time, in one network request. 
    * Simplified user credential storage in the keychain. The user password is no longer stored. 
    * User setup/creation blocks return `KCSUserNoInformation` for the user status instead of a more detailed status code. Check the `errorOrNil` object to see the operation failed.
    * If the credentials change outside of the app, such as password update from another device, or the auth token expires,  the activer user will be logged out. This is because the only way to get the new credentials is to log in, again.
         * When this happens, a `KCSActiveUserChangedNotification` is posted. Your app can listen for this and show the log-in screen again.
         * You can choose instead to keep the user active with the `KCS_KEEP_USER_LOGGED_IN_ON_BAD_CREDENTIALS` client option. Set to `YES` in the client configuration.
    * The user is no longer refreshed in the background when loaded from the keychain. The application is now responsible for updating the cached information when appropriate, such as after the application loads or returns to foreground after a long delay. 
    * Removed deprecated `-[KCSUser loadWithDelegate:]`, `-[KCSUser removeWithDelegate:]`, and `-[KCSUser saveWithDelegate:]` methods.
* Bug fix(es):
    * Fix networking error when using `KCSPing`.
* Code Cleanup:
    * Removed deprecated `KCSMetadata` methods.
              

## 1.24
### 1.24.0
**Release Date:** December 11, 2013

* Support for [Data Protection](http://devcenter.kinvey.com/ios/guides/encryption)
    * If you enable data protection entitlements for your app, you can configure `KCSClient` to respect various levels of data protection.
        * The data protection applies to the cache, the stored keychain credentials, and files donwloaded through `KCSFileStore`.
        * The data protection application delegate methods must be forwarded on to KCSClient. See the [guide](http://devcenter.kinvey.com/ios/guides/encryption) for set-up and configuration options. 
    * Stored credentials for the active user are now single-device only. They are not shared between other other iOS devices connected to the same iTunes library or backed up locally or through iCloud. 
* Added [JSON import functionality to the data cache](http://devcenter.kinvey.com/ios/guides/caching-offline#SeedingTheCacheImportExport).
    * Import JSON objects with `-[KCSCachedStore import:]`.
    * Export the cache entities of a store with `-[KCSCachedStore exportCache]`.
    * Limitations: imported objects must match the format used by the Kinvey backend, and only query all (e.g. `[KCSQuery query]`) supported for reading.
* `-[KCSAppdataStore removeObject:withCompletionBlock:withProgressBlock:]` now uses a completion block that returns a count of items deleted, rather than a meaningless array.
* Added `+[KCSCachedStore clearCaches]` to clear out the data cache.
* Added `+[KCSFileStore clearCachedFiles]` to remove all downloaded files managed by KinveyKit.
* Bug fix(es): 
    * Caching now supports skip and limit modifiers.  
    * Fix deadlock in caching queue. 

## 1.23
### 1.23.0
**Release Date:** December 3, 2013

* [Major Caching Update & Bug Fix](http://devcenter.kinvey.com/ios/guides/caching-offline):
    * Offline Save is now Offline Update - supports both saving and deleting.
    * To enable offline updates, `KCSClient` needs a global implementation of `KCSOfflineUpdateDelegate` as well as each participating `KCSCachedStore` needs to enable the `KCSStoreKeyOfflineUpdateEnabled` option. <br/> E.g.:

            id<KCSOfflineUpdateDelegate> myDelegate = [[ImplementingClass alloc] init];
            [[KCSClient sharedClient] setOfflineDelegate:myDelegate];


            KCSCachedStore* store = [KCSCachedStore storeWithOptions:@{
                                         KCSStoreKeyCollectionName : @"Events",
                                         KCSStoreKeyCollectionTemplateClass : [Event class],
                                         KCSStoreKeyCachePolicy : @(KCSCachePolicyNone),
                                         KCSStoreKeyOfflineUpdateEnabled : @YES}];    

    * Removed `KCSOfflineSaveStore` protocol from `KCSCachedStore`. Now just enable with the above option.
    * When using a cache policy that reads locally, the cache is updated if an object is saved or deleted locally, even if the app is offline. 
    * Removed caching of GROUP results. 
* Remove support for `NSRegularExpression` with queries, as well as disable regular expression options. Also any query that does _not_ start with a "`^`" will throw an exception. 
    * Removed `+ [KCSQuery  queryOnField:withRegex:options:]`.
    * Removed `KCSRegexpQueryOptions`.
* Minor Changes:
    * Saving an empty array now returns an empty array for `objectsOrNil` instead of of `nil`.
* Code Cleanup:
    * Removed deprecated methods/classes:
         * `[KCSUser userCollection]`; use `[KCSCollection userCollection]` instead.
         * `[KCSQuery queryForNilValueInField:]`; use exact match on `NSNull`, `queryForEmptyValueInField`, or `queryForEmptyOrNullValueInField` instead.
* Built with latest XCode to support arm64 architecture


## 1.22
### 1.22.0
**Release Date:** October 28, 2013

* Internal Updates
* Code cleanup:
    * Removed deprecated methods/classes:
         * `[KCSUser loginWithFacebookAccessToken:withCompletionBlock:]`
         * Class `KCSEntityDict`. Clients should be using a `NSMutableDictionary` instead.
    * Deprecated data store constructors that use `authHandler`.
* Bug fix(es):
    * File references will no longer be auto-resolved on load if not mapped in the `kinveyPropertyToCollectionMapping` method.
    * Library now treats `@""` object id's the same as if they are `nil`, that is the object _id has not yet been set and it should be set by the server. 
    * File store can now save files with spaces in the filename.

## 1.21
### 1.21.1
**Release Date:** September 24, 2013

* Update missed `fmdb` function prefix. 

### 1.21.0
**Release Date:** September 23, 2013

* Added `NSCoding` to `KCSFile`.
* With `KCSLinkedAppdataStore`, you can use have a reference property to either an `UIImage` or a `KCSFile` file metadata object. If the property is declared as a `KCSFile`, the binary data will not be loaded. You can later download the file using the `KCSFile` object's `remoteURL` with `KCSFileStore downloadDataWithResolvedURL:completionBlock:progressBlock:`.
* Removed `kKCSWhere` query option. 
* Built with XCode 5.
* Code cleanup:
    * Internal `KCSPing` changes: remove `KCS_USE_OLD_PING_STYLE_KEY` key, and deprecated `checkKinveyServiceStatusWithAction:`.
* Bug fix(es):
    * Renamed `fmdb` classes to avoid collisions with other libraries.

## 1.20
### 1.20.1
**Release Date:** September 3, 2013

* Bug fix(es): 
    * Fix issue with Facebook login falsely returning error.

### 1.20.0
** Release Date:** August 30, 2013

* Added `KCSClientConfiguration` to make managing multiple `KCSClient` configurations easier. See the [using environments tutorial](http://devcenter.kinvey.com/ios/tutorials/using-environments) for more details. 
* Deprecated `KCSFile`'s `public` property. This is replaced with the new `publicFile` property. This was done for compatability with C++ libraries. The usage semantics are the same. If you have build errors due to the `public` property, just comment out the header line. 
* Replaced SecureUDID with `identifierForVendor` on iOS 6+. 
* Made `KCSMetadata` `NSCoding`-compliant.
* Code Cleanup:
    * Removed old KCS_PUSH_XXX client setup constants since they no longer do anything.
* Bug fix(es):
    * Fix issue saving `KCSUser` object with push tokens.


## 1.19
### 1.19.3
** Release Date:** Auguest 26, 2013

* Bug fix(es):
    * Try again fixing the build errors for XCode 4.6.
    
### 1.19.2 
** Release Date:** August 22, 2013

* Bug fix(es):
    * Fixed build error when using library.

### 1.19.1
** Release Date:** August 20, 2013

* Bug fix(es):
    * Fixed crash when using file download query by `_id`.
    * Fixed sporadic crash when file download query returns 0 results.
    * Multiple simultaneous downloads of the same file are not allowed. The completion block for subsequent downloads will contain an error.

### 1.19.0
** Release Date:** August 13, 2013

* The library no longer creates implicit users. All users must be explicitly set. However auto-generated users are still possible.
	* Removed `KCSClient` key `KCS_USER_CAN_CREATE_IMPLICT`.
	* `+[KCSUser hasSavedCredentials]` will check if the keychain has stored credentials and active user can be restored.
    * `+[KCSUser activeUser]` will instantiate the user from the keychain if credentials are saved.
    * If no active user is found, the client _must_ create a new user or login an existing user.    
    * Added `-[KCSUser refreshFromServer:]` to update the `activeUser` with data from the server. This only works on the active user. 
    * Added `+[KCSUser createAutogeneratedUser:]` to explicitly create a generated user and set it as active. For example:

```objc        
    if ([KCSUser activeUser] == nil) {
        [KCSUser createAutogeneratedUser:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
            //do something
        }];
    } else {
        //otherwise user is set and do something
    }
```

* Added `+[KCSUser sendForgotUsername:]` to help 
* Updated push feature.
    * Deprecated `-[KCSPush application:didRegisterForRemoteNotificationsWithDeviceToken:]` for `application:didRegisterForRemoteNotificationsWithDeviceToken:completionBlock:`.
    * Deprecated `+[KCSPush initializePushWithPushKey:pushSecret:mode:enabled:` for `registerForPush`.
* Removed Urban Airship library dependency. (Note that Push notifications still uses Urban Airship on the backend).
    * libUAriship-1.4.0 is no longer needed, can be removed from the project
    * The frameworks now used by the library are:
         * Foundation.framework
         * Accounts.framework
         * CoreGraphics.framework 
         * CoreLocation.framework
         * libsqlite3.dylib
         * MobileCoreServices.framework
         * Security.framework 
         * SystemConfiguration.framework
         * Twitter.framework
         * UIKit.framework
* Code Cleanup:
    * Removed old and deprecated `findEntity` methods on `KCSEntity` category on `NSObject` (KinveyEntity.h)
    * Deprecated `KCSEntityDelegate` API for directly loading objects.
    * Removed deprecated `+[KCSPush onLoadHelper:]` method.
    * Deprecated old delegate-style `KCSUser` methods. 
    * Deprecated `-[KCSClient currentUser]`; use `+[KCSUser activeUser]` instead.
 

## 1.18
### 1.18.0
** Release Date:** August 06, 2013

* Improved Resource/File Handling
    * Deprecated and deleted `KCSResourceStore` and `KCSResourceService` APIs. These methods will now throw exceptions when used. They are marked as deprecated to make them easy to find, check the deprecation warning message for suggested replacement API.
        * See our migration guide for examples. 
    * Added `KCSFileStore` with class methods for working with files:
    	* __Uploading__
    	   * `+ (void) uploadFile:(NSURL*)fileURL options:(NSDictionary*)uploadOptions completionBlock:(KCSFileUploadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock;`
           * `+ (void) uploadData:(NSData*)data options:(NSDictionary*)uploadOptions completionBlock:(KCSFileUploadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock;`
    	* __Downloading__
    	    * `+ (void) downloadFile:(id)idOrIds options:(NSDictionary*)options completionBlock:(KCSFileDownloadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock;`
    	    * `+ (void) downloadFileByName:(id)nameOrNames completionBlock:(KCSFileDownloadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock;`
    	    * `+ (void) downloadFileByQuery:(KCSQuery*)query completionBlock:(KCSFileDownloadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock;`
    	    * `+ (void) downloadFileWithResolvedURL:(NSURL*)url options:(NSDictionary*)options completionBlock:(KCSFileDownloadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock;`
    	    * `+ (void) downloadData:(id)idOrIds completionBlock:(KCSFileDownloadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock;`
    	    * `+ (void) downloadDataByName:(id)nameOrNames completionBlock:(KCSFileDownloadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock;`
    	    * `+ (void) downloadDataByQuery:(KCSQuery*)query completionBlock:(KCSFileDownloadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock;`
    	    * `+ (void) downloadDataWithResolvedURL:(NSURL*)url completionBlock:(KCSFileDownloadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock;`
    	    * `+ (void) resumeDownload:(NSURL*)partialLocalFile from:(NSURL*)resolvedURL completionBlock:(KCSFileDownloadCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock;`
    	    * `+ (void) getStreamingURL:(NSString*)fileId completionBlock:(KCSFileStreamingURLCompletionBlock)completionBlock;`
    	    * `+ (void) getStreamingURLByName:(NSString*)fileName completionBlock:(KCSFileStreamingURLCompletionBlock)completionBlock;`
    	* __Deleting__
    	    * `+ (void) deleteFile:(NSString*)fileId completionBlock:(KCSCountBlock)completionBlock;`
    * Added `KCSFile` completionBlock object to represent a file object with both local and backend metadata.
    * Added support for "public" files (i.e. files that accessible without authorization).
    * Improved support for resuming incomplete uploads/downloads.
    * Improved behavior and accuracy with file upload/download progress.
* Added support for `NSURL` data types.
* Warning log will no longer complain about incomplete `KCSUser` and other KinveyKit objects on most queries.
* Bug fix(es):
    * Better handling of broken references.

## 1.17
### 1.17.3
** Release Date:** Aug 1, 2013

* Updated `KCSPersistable` protocol with method `+kinveyDesignatedInitializer:`. This builder method is supplied the unedited json document from the server. This means the `KCSEntityKeyId` can be extracted and used to load objects from a persistent store instead of having to create a new one each time. <br><br> For example, when using Core Data, the following code will try to find an existing object with a matching property `kinveyID` before inserting a new one. 
<pre>
    &plus; (id)kinveyDesignatedInitializer:(NSDictionary *)jsonDocument
    {
        NSString* existingID = jsonDocument[KCSEntityKeyId];
        id obj = nil;
    
        NSManagedObjectContext* context = [(AppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
        NSEntityDescription* entity = [NSEntityDescription entityForName:@"<#ENTITY#>" inManagedObjectContext:context];
    
	    if (existingID) {
    	    NSFetchRequest *request = [[NSFetchRequest alloc] init];
        	[request setEntity:entity];
	        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"kinveyID = %@", existingID];
    	    [request setPredicate:predicate];
        	NSArray* results = [context executeFetchRequest:request error:NULL];
	        if (results != nil && results.count > 0) {
    	        obj = results[0];
        	}
	    }
    
    	if (obj == nil) {
        	//fall back to creating a new if one if there is an error, or if it is new
	        obj = [[self alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
    	}
    
    	return obj;
	}
</pre>

### 1.17.2
** Release Date:** July 16, 2013

* Bug fix(es):
    * Fixed bug when calling custom endpoints.

### 1.17.1
** Release Date:** June 25, 2013

* Bug fix(es):
    * Fixed bug where implicit users were created on logout. 
    * Fixed zombie issue when obtaining LinkedIn credentials.
    * Fixed unrecognized selector error when using offline save. 

### 1.17.0
** Release Date:** June 07, 2013


* Added support for custom business logic endpoints `KCSCustomEndpoints`.
* Improved Push API
    * Deprecated `- [KCSPush onLoadHelper:error:]` in favor of `+ [KCSPush initializePushWithPushKey:pushSecret:mode:enabled:]`
        * Set-up is now more explicit. See [http://devcenter.kinvey.com/ios/guides/push#AppSetUp](http://devcenter.kinvey.com/ios/guides/push#AppSetUp) for instructions on use.
        * Set-up errors will now raise an `NSException`.
    * Added `- [KCSPush application:didFailToRegisterForRemoteNotificationsWithError:]` to forward app delegate registration failure error to the push management.
    * Added `- [KCSPush registerForRemoteNotifications]` to call from `applicationDidBecomeActive:` in the app delegate. This retrieves the latest device token, if it has changed. 
    * Updated [GeoTag](http://devcenter.kinvey.com/ios/samples/geotag) sample application to support push, business logic, and custom endpoints.
    * Added [a tutorial](http://devcenter.kinvey.com/ios/tutorials/tracking-user-location-for-targeted-push) to show off location-based push.
* Added `- [KCSUser removeValueForAttribute:` to remove previously set custom user attributes.
* KinveyKit distribution zip-file now includes the [TestDrive](http://devcenter.kinvey.com/ios/samples/testdrive) sample app.
* Bug fix(es):
    * Fixed bug where a `CLLocation` could be added to a `KCUser` through `setValue:forAttribute:`;


## 1.16
### 1.16.0
** Release Date:** May 24, 2013

* Added `+ [KCSUser checkUsername:withCompletionBlock:]` to check if an username is already taken, or is available for a new user.
* Added `- [KCSClient clearCache]` to clean up all the caches maintained by the library. 
* `KCSClient` property `dateStorageFormatString` is now undeprecated and writable. This can be overridden to convert other date formats. For example if not using the recommended UTC time stamp, the format string  `@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSSZ"` can translate most RFC 822 time zone ISO 6801 formats. __NOTE:__ this is very platform dependent and not recommended as it may cause unexpected behavior on the server or with other clients. 
* Deprecated `+[KCSPing kinveyServiceIsReachable]` and  `+[KCSPing networkIsReachable]`, use `- [KCSClient networkReachability]` and `-[KCSClient kinveyReachability]` instead.
* Infrastructure Updates:
    * Replace `id` with `instancetype` return value in many classes. (See http://nshipster.com/instancetype/ for a discussion)
* Bug fix(es):
    * Allow for collections created before `KCSClient init…` to work properly.

## 1.15
### 1.15.2
** Release Date:** May 16, 2013

* Bug fix(es):
    * Fix to console logging
    
### 1.15.1
** Release Date:** May 10, 2013

* Updated Urban Airship library from `libUAirshipPush-1.3.3.a` to `libUAirship-1.4.0.a`. __Update your projects accordingly.__ 
* `-[KCSUser logout]` will now attempt to remove the current device's push token from the user in the backend.
* Added `+[KCSUser getAccessDictionaryFromLinkedIn:permissions:usingWebView:]` to allow you specify access permissions beyond `r_basicprofile`, such as `r_network`. 
* Added warning if the result set is equal to 10,000 objects - this is the Kinvey limit for a query, and there may actually be more results. If this is the case use the limit & skip modifiers on `KCSQuery` to page through the results. 

### 1.15.0
** Release Date:** April 26, 2013

* `+[KCSUser sendPasswordResetForUser:withCompletionBlock:]` now accepts an input username or email address. However the user entity in the backend still has to have an valid value in the `email` field.
* Added `KCSActiveUserChangedNotification` as a `NSNotification`. Observe this to have code informed when the active user is set or logged out. 
* Added `- [KCSAppdataStore countWithQuery:completion:]` to allow for calculating the number of matching elements without transferring the data.
* If an object's `hostToKinveyPropertyMapping` specifies an invalid property, the save will now fail with an error with code `KCSInvalidKCSPersistableError` rather than crash.
* Deprecated `KCSClient` property `dateStorageFormatString`.
* Bug fix(es):
    * NSError in completion block now returns full error message info when a business logic error occurs.
    * Linked resources now once again show up as `NSDictionary` values when loaded with `KCSAppdataStore` or `KCSCachedStore`.  
    * Fixed progress block crash when there is a server error. 

## 1.14
### 1.14.2
** Release Date:** April 1, 2013

* Kinvey now supplies a creation time in addition to last modified time. Added `creationTime` to `KCSMetadata` object. And `KCSMetadataFieldCreationTime` constant for defining queries on creation time. 
* `+ [KCSUser loginWithSocialIdentity:accessDictionary:withCompletionBlock:] and + [KCSUser registerUserWithSocialIdentity:accessDictionary:withCompletionBlock:]` for __Facebook__ now requires an additional key in the accessDictionary: `KCS_FACEBOOK_APP_KEY` where the value is the Facebook App Id. This can be found on the main page of app info in the Facebook developer site.
    * This key can be supplied as part of the `accessDictionary`, as an option when initializing `KCSClient` or in the info.plist with the key: `FacebookAppID`. The Info.plist key is also used with the Facebook iOS SDK. 

### 1.14.1
** Release Date:** March 24, 2013

* Bug fix(es):
    * Fix bug where library can crash parsing certain server errors. 
   

### 1.14.0
** Release Date:** March 21, 2013

* Added `+ [KCSReduceFunction AGGREGATE]` grouping function which returns whole objects for the store type, grouped by the specified field. This is useful for building sectioned tables. 
* Added `+ [KCSQuery queryWithQuery:]` copy factory method.
* Replaced (deprecated) `KCSMetadata` `usersWithReadAccess` and `setUsersWithReadAccess:` with `readers` mutable array; and replaced `usersWithWriteAccess` and `setUsersWithWriteAccess:` with `writers` mutable array. User `_id`'s can now be added directly to these arrays instead of using accessor methods. 
* Added `KCSClient` set-up option `KCS_USER_CAN_CREATE_IMPLICT` to disable creating "implicit users" when set to `NO`. If a request is sent before a login with a username or social identity, it will complete with an authentication error.

        (void)[[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"<#APP KEY#>"
                                                           withAppSecret:@"<#APP SECRET#>"
                                                            usingOptions:@{KCS_USER_CAN_CREATE_IMPLICT : @NO}];

                                                                                                               
* Added `KCSClient` set-up option `KCS_LOG_SINK` to allow you to send KinveyKit logs to a custom logger, such as Testflight. This requires that you create an object that implements the new `KCSLogSink` protocol and configure logging. For example:


        @interface TestFlightLogger : NSObject <KCSLogSink>
        @end
        @implementation TestFlightLogger
        
        - (void)log:(NSString *)message
        {
            TFLog(@"%@", message);
        }
        @end
        
	and, in the app delegate: 
	
    	(void)[[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"<#APP KEY#>"
    	                                                   withAppSecret:@"<#APP SECRET#>"
        	                                                usingOptions:@{KCS_LOG_SINK : [[TestFlightLogger alloc] init]}];
    
        [KCSClient configureLoggingWithNetworkEnabled:NO debugEnabled:NO traceEnabled:NO warningEnabled:YES errorEnabled:YES];

* Added support for log-in with __Salesforce__
    * Added `KCSSocialIDSalesforce` value to `KCSUserSocialIdentifyProvider` enum for use with `+ [KCSUser loginWithSocialIdentity:accessDictionary:withCompletionBlock:]` and `+ [KCSUser registerUserWithSocialIdentity:accessDictionary:withCompletionBlock:]`.    
    * To use with [Salesforce's iOS SDK](https://github.com/forcedotcom/SalesforceMobileSDK-iOS)
	
         
             - (void)oauthCoordinatorDidAuthenticate:(SFOAuthCoordinator *)coordinator authInfo:(SFOAuthInfo *)info
             {
             	NSString* accessToken = coordinator.credentials.accessToken;
             	NSString* instanceURL = [coordinator.credentials.identityUrl absoluteString];
             	NSString* refreshToken = coordinator.credentials.refreshToken;
             	NSString* clientId = coordinator.credentials.clientId;
    
             	NSDictionary* acccessDictionary = @{KCSUserAccessTokenKey : accessToken, KCS_SALESFORCE_IDENTITY_URL : instanceURL, KCS_SALESFORCE_REFRESH_TOKEN : refreshToken, KCS_SALESFORCE_CLIENT_ID : clientId};
    
             	[KCSUser loginWithSocialIdentity:KCSSocialIDSalesforce accessDictionary:acccessDictionary withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
             		NSLog(@"Logged in user: %@ - error: %@", user, errorOrNil);
             	}];
             }     

* Removed `KCSUniqueNumber` class. 
* Removed deprecated (as of version 1.2) filter API from old Collections interface. 
* Deprecated undocumented `KCSStore` factory methods on `KCSClient`.
* Infrastructure update: entire library now built with ARC.
* Bug fix(es):
    * KCSUserDiscovery returns complete `KCSUser` objects now instead of `NSDictionary`.

## 1.13
### 1.13.2
** Release Date:** January 17, 2013

* Bug fix(es):
    * Fixed issue where airship lib was added twice, causing linker failures.
    
### 1.13.1
** Release Date:** January 7, 2013

* `KCSAppdataStore` and subclasses will now return objects when partial data is loaded from the server in progress blocks with `loadObjectWithID:withCompletionBlock:withProgressBlock:` and `queryWithQuery:withCompletionBlock:withProgressBlock:`
* Bug fix(es):
    * Email verification status property on `KCSUser` is now being properly set once the user has clicked the link in the email and the user is reloaded from the server. 

### 1.13.0 
** Release Date:** December 18, 2012

* Added support for log-in with __LinkedIn__
    * Added `KCSSocialIDLinkedIn` value to `KCSUserSocialIdentifyProvider` enum for use with `+ [KCSUser loginWithSocialIdentity:accessDictionary:withCompletionBlock:]` and `+ [KCSUser registerUserWithSocialIdentity:accessDictionary:withCompletionBlock:]`.
    * Added `+ [KCSUser getAccessDictionaryFromLinkedIn:usingWebView]` to obtain an accessDictionary for use with the register & log-in methods. 
* Added `- [KCSUser updatePassword:completionBlock:]` to change the active user's password. 
* `KCSQuery` geo-queries (`kKCSNearSphere`, `kKCSWithinBox`, `kKCSWithinCenterSphere`, `kKCSWithinPolygon`) on a field other than `KCSEntityKeyGeolocation` will now throw an exception instead of silently fail. 
* Bug fix(es):
    * Fix bug when using Data Integration query and an error is returned in an unexpected format causes a crash. 

## 1.12
### 1.12.1
** Release Date:** December 12, 2012

* Bug Fix(es):
    * Fix crash when using `-[KCSQuery fetchWithQuery:withCompletionBlock:withProgressBlock:]`.

### 1.12.0 [<sub>api diff</sub>](Documents/releasenotes/General/KinveyKit1120APIDiffs/KinveyKit1120APIDiffs.html)
** Release Date:** November 29, 2012 

* Added `KCSRequestId` key to most `NSError` `userInfo` dictionaries. If available, this unique key corresponds to the request to the Kinvey backend. This value is useful for tech support purposes, and should be provided when contacting support@kinvey.com for faster issue resolution. 
* Added `KCSBackendLogicError` constant for `-[NSError code]` value for cases when there is an error running Backend Logic on the Kinvey server (HTTP error code 550).
* `+[KCSQuery queryOnField:withRegex:]` and `+[KCSQuery queryOnField:withRegex:options]` now take either `NSString` or `NSRegularExpression` objects as the regular expression parameter. The `+[KCSQuery queryOnField:withRegex:]` form will use the applicable options from the NSRegularExpression object.
* `CLLocation` objects can now be used as values for a `KCSEntityKeyGeolocation` property. These objects are saved in the form [latitude, longitude]; all other CLLocation properties are discarded. 
* `+[KCSPing pingKinveyWithBlock:]` no longer requires user authentication, and thus will not create or initialize a `KCSUser`. 
* Bug Fix(es):
    * Fix bug when using sort modifiers on queries with old collection API where the sort is not applied correctly

## 1.11
### 1.11.0 [<sub>api diff</sub>](Documents/releasenotes/General/KinveyKit1110APIDiffs/KinveyKit1110APIDiffs.html)
** Release Date:** November 16, 2012

* Replaced `libUAirship-1.3.3` with the smaller `libUAirshipPush-1.3.3` library.
* `- [KCSStore loadObjectWithID:withCompletionBlock:withProgressBlock:]` now accepts `NSSet`s of id's as well as arrays and a single id. 
* Updated `KCSQuery` to throw an exception when trying to negate an exact match query. This is invalid syntax and fails server-side. Use a conditional query with `kKCSNotEqual` to test not equals.  
* Deprecated `+[KCSQuery queryForNilValueInField:]` because it is ambiguous and did not work. It has been modified to work the same as `queryForEmptyValueInField:` and is superceeded by the following behaviors:
    * To find values that have been set to `null` : `+[KCSQuery queryOnField:field withExactMatchForValue:[NSNull null]]`
    * To find values that empty or unset: `+[KCSQuery queryForEmptyValueInField:]`
    * To find either `null` or empty or unset: `+[KCSQuery queryForEmptyOrNullValueInField:]`  
* Usability Enhancements:
    * Created options keys for `KCSAppdataStore` so that a `KCSCollection` object does not have to be explicitly created and managed by the client code.
        * `KCSStoreKeyCollectionName` the collection Name
        * `KCSStoreKeyCollectionTemplateClass` the template class
        * For example, instead of:
            
                KCSCollection* collection = [KCSCollection collectionFromString:@"Events" ofClass:[Event class]];
                _store = [KCSAppdataStore storeWithCollection:collection options:nil];
          You can use the following:
          
                _store = [KCSAppdataStore storeWithOptions:@{ KCSStoreKeyCollectionName : @"Events",
                                                     KCSStoreKeyCollectionTemplateClass : [Event class]}];
                                                    
    * Renamed `KCS_PUSH_MODE` values to match the language used eslewhere
        * `KCS_PUSH_DEBUG` is now `KCS_PUSH_DEVELOPMENT`
        * `KCS_PUSH_RELEASE` is now `KCS_PUSH_PRODUCTION`
    * Exposed `userId` property of `KCSUser` to obtain the `_id` for references.

          


## 1.10
### 1.10.8
** Release Date:** November 13, 2012

* Bug fix(es):
    * Sporadic assertion when initializing user outside of normal flow. 

### 1.10.7
** Release Date:** November 12, 2012

* Bug fix(es):
    * Fixed bug where new user could not be created when using push. 

### 1.10.6
** Release Date:** November 3, 2012

* Bug fix(es):
    * Fixed bug where sign-in with Twitter sporadically crashed or did not complete.

### 1.10.5
** Release Date:** October 30, 2012

* Added `KCSUserAttributeFacebookId` to allow for discovering users through `KCSUserDiscovery` given a Facebook id (from the FB SDK).
* Bug fix(es):
    * Joined `KCSQuery`s using `kKCSAnd` now work correctly. 
    * Fixed error where streaming resource URLs were not fetched properly.

### 1.10.4
** Release Date:** October 23, 2012

* Minor update(s)
    * Additional User information, such as surname and givenname are now persisted in the keychain.

### 1.10.3
** Release Date:** October 18, 2012

* __Change in behavior when saving objects with relationships__.
    * Objects specified as relationships (through `kinveyPropertyToCollectionMapping`) will, by default, __no longer be saved__ to its collection when the owning object is saved. Like before, there will be a reference dictionary saved to the backend in place of the object.
    * If a reference object has not had its `_id` set, either programmatically or by saving that object to the backend, then saving the owning object will fail. The save will not be sent, and the `completionBlock` callback with have an error with an error code: `KCSReferenceNoIdSetError`.
    * To save the reference objects (either to simplify the save or have the backend generate the `_id`'s), have the `KCSPersistable` object implement the `- referenceKinveyPropertiesOfObjectsToSave` method. This will return an array of backend property names for the objects to save. 
        * For example, if you have an `Invitation` object with a reference property `Invitee`, in addition to mentioning the `Invitee` property in `- hostToKinveyPropertyMapping` and `- kinveyPropertyToCollectionMapping`, if you supply `@"Invitee"` in `- referenceKinveyPropertiesOfObjectsToSave`, then any objects in the `Invitee` property will be saved to the backend before saving the `Invitation` object, populating any `_id`'s as necessary.

### 1.10.2
** Release Date:** October 12, 2012

* Improved support for querying relationships through `KCSLinkedAppdataStore` and for using objects in queries
    * Added constants: `KCSMetadataFieldCreator` and `KCSMetadataFieldLastModifiedTime` to `KCSMetadata.h` to allow for querying for entities based on the user that created the object and the last time the entity was updated on the server.
    * Added the ability to use `NSDate` objects in queries, supporting exact matches, greater than (or equal) and less than (or equal) comparisons.
* Added support for establishing references to users:
    * Added constant `KCSUserCollectionName` to allow for adding relationships to user objects from any object's `+kinveyPropertyToCollectionMapping`.
    * Deprecated `- [KCSUser userCollection]` in favor of `+[KCSCollection userCollection]` to create a collection object to the user collection. 
    

### 1.10.1
** Release Date:** October 10, 2012

* Added `+ [KCSUser sendEmailConfirmationForUser:withCompletionBlock:]` in order to send an email confirmation to the user. 

### 1.10.0 [<sub>api diff</sub>](Documents/releasenotes/General/KinveyKit1100APIDiffs/KinveyKit1100APIDiffs.html)

** Release Date: ** October 8, 2012

* Added `+ [KCSUser sendPasswordResetForUser:withCompletionBlock:]` in order to send a password reset email to the user.  
* Bug fix(es):
    * Fixed false error when deleting entities using old `KCSCollection` interface.
    * Fixed error when loading dates that did not specify millisecond information. 

## 1.9
### 1.9.1
** Release Date: ** October 2, 2012

* Bug fix(es):
    * `KCSLinkedAppdataStore` now supports relationships when specifying an optional `cachePolicy` when querying. 

### 1.9.0 [<sub>api diff</sub>](Documents/releasenotes/General/KinveyKit190APIDiffs/KinveyKit190APIDiffs.html)
** Release Date: ** October 1, 2012

* Added support for log-in with twitter
    * Deprecate Facebook-specific methods and replace with generic social identity. See `KCSUser`.
    * Requires linking Twitter.framework and Accounts.framework.
* Added support for `id<KCSPersistable>` objects to be used as match values in `KCSQuery` when using relationships through `KCSLinkedAppdataStore`.
* Deprecated `KCSEntityDict`. You can now just save/load `NSMutableDictionary` objects directly with the backend. Use them like any other `KCSPersistable`.
    * Note: using a non-mutable `NSDictionary` will not have its fields updated when saving the object.
* Upgraded Urban Airship library to 1.3.3.
* Improved usability for Push Notifications
    * Deprecated `- [KCSPush onLoadHelper:]`; use `- [KCSPush onLoadHelper:error:]` instead to capture set-up errors.

## 1.8
### 1.8.3
** Release Date: ** September 25, 2012

* Bug fix(es):
    * Fix issue with production push.
    * Fix issue with analytics on libraries built with Xcode 4.5.

### 1.8.2
** Release Date: ** September 14, 2012

* Bug fix(es): Fix sporadic crash on restore from background.

### 1.8.1 
** Release Date: ** September 13, 2012

* Added `KCSUniqueNumber` entities to provide monotonically increasing numerical sequences across a collection.

### 1.8.0 [<sub>api diff</sub>](Documents/releasenotes/General/KinveyKit180APIDiffs/KinveyKit180APIDiffs.html)
** Release date: ** September 11, 2012

* `KCSLinkedAppdataStore` now supports object relations through saving/loading entities with named fields of other entities.
* Added `kKCSRegex` regular expression querying to `KCSQuery`.
* Added `KCSEntityKeyGeolocation` constant to KinveyPersistable.h as a convience from using the `_geoloc` geo-location field. 
* Added `CLLocation` category methods `- [CLLocation kinveyValue]` and `+ [CLLocation  locationFromKinveyValue:]` to aid in the use of geo data.
* Support for `NSSet`, `NSOrderedSet`, and `NSAttributedString` property types. These are saved as arrays on the backend.  See [Datatypes in KinveyKit](Documents/guides/datatype-guide/Datatypes%20In%20KinveyKit.html) for more information.
* Support for Kinvey backend API version 2. 
* Documentation Updates.
    * Added [Datatypes in KinveyKit](Documents/guides/datatype-guide/Datatypes%20In%20KinveyKit.html) Guide.
    * Added links to the api differences to this document.

## 1.7
### 1.7.0 [<sub>api diff</sub>](Documents/releasenotes/General/KinveyKit170APIDiffs/KinveyKit170APIDiffs.html)
** Release date: ** Aug 17, 2012

* `KCSCachedStore` now provides the ability to persist saves when the application is offline, and then to save them when the application regains connectivity. See also `KCSOfflineSaveStore`.
* Added login with Facebook to `KCSUser`, allowing you to use a Facebook access token to login in to Kinvey.
* Documentation Updates.
    * Added [Threading Guide](Documents/guides/gcd-guide/Using%20KinveyKit%20with%20GCD.html).
    * Added [Core Data Migration Guide](Documents/guides/using-coredata-guide/KinveyKit%20CoreData%20Guide.html)
* Bug Fix(es).
    * Updated our reachability aliases to make the KinveyKit more compatible with other frameworks. 

## 1.6
### 1.6.1 
** Release Date: ** July 31st, 2012

* Bug Fix(es).
    * Fix issue with hang on no results using `KCSAppdataStore`.

### 1.6.0 [<sub>api diff</sub>](Documents/releasenotes/General/KinveyKit160APIDiffs/KinveyKit160APIDiffs.html)
** Release Date: ** July 30th, 2012

* Added `KCSUserDiscovery` to provide a method to lookup other users based upon criteria like name and email address. 
* Upgraded Urban Airship library to 1.2.2.
* Documentation Updates.
    * Added API difference lists for KinveyKit versions 1.4.0, 1.5.0, and 1.6.0
    * Added tutorial for using 3rd Party APIs with OAuth 2.0
* Bug Fix(es).
    * Changed `KCSSortDirection` constants `kKCSAscending` and `kKCSDescending` to sort in the proscribed orders. If you were using the constants as intended, no change is needed. If you swaped them or modified their values to work around the bug, plus update to use the new constants. 

## 1.5

### 1.5.0 [<sub>api diff</sub>](Documents/releasenotes/General/KinveyKit150APIDiffs/KinveyKit150APIDiffs.html)
** Release Date: ** July 10th, 2012

* Added `KCSMetadata` for entities to map by `KCSEntityKeyMetadata` in `hostToKinveyPropertyMapping`. This provides metadata about the entity and allows for fine-grained read/write permissions. 
* Added `KCSLinkedAppdataStore` to allow for the saving/loading of `UIImage` properties automatically from our resource service. 

## 1.4

### 1.4.0 [<sub>api diff</sub>](Documents/releasenotes/General/KinveyKit140APIDiffs/KinveyKit140APIDiffs.html)
** Release Date: ** June 7th, 2012

* Added`KCSCachedStore` for caching queries to collections. 
* Added aggregation support (`groupBy:`) to `KCSStore` for app data collections. 

## 1.3

### 1.3.1
** Release Date: ** May 7th, 2012

* Fixed defect in Resource Service that prevented downloading resources on older iOS versions (< 5.0)

### 1.3.0
** Release Date: ** April 1st, 2012

* Migrate to using SecureUDID
* General memory handling improvements
* Library now checks reachability prior to making a request and calls failure delegate if Kinvey is not reachable.
* Fixed several known bugs

## 1.2

### 1.2.1
** Release Date: ** Februrary 22, 2012

* Update user-agent string to show correct revision

### 1.2.0
** Release Date: ** Februrary 14, 2012

* Updated query interface (See KCSQuery)
* Support for GeoQueries
* Added features to check-reachability
* Stability improvements
* Documentation improvements

## 1.1

### 1.1.1
** Release Date: ** January 24th, 2012

* Fix namespace collision issues.
* Added support for Core Data (using a designated initializer to build objects)

### 1.1.0
** Release Date: ** January 24th, 2012

* Added support for NSDates
* Added full support for Kinvey Users (See KCSUser)
* Stability improvements

## 1.0

### 1.0.0
** Release Date: ** January 20th, 2012

* Initial release of Kinvey Kit
* Basic support for users, appdata and resources
* Limited release
