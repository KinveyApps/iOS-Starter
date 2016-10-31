//
//  Push.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-01.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectiveC

#if os(OSX)
    import Cocoa
#endif

/// Class used to register and unregister a device to receive push notifications.
@objc(KNVPush)
open class Push: NSObject {
    
    public typealias BoolCompletionHandler = (Bool, Swift.Error?) -> Void
    
    fileprivate let client: Client
    
    fileprivate var keychain: Keychain {
        get {
            return Keychain(appKey: client.appKey!)
        }
    }
    
    fileprivate var deviceToken: Data? {
        get {
            return keychain.deviceToken
        }
        set {
            keychain.deviceToken = newValue
        }
    }
    
    init(client: Client) {
        self.client = client
    }

#if os(iOS)
    /// Sets and returns the number for the icon badge for the current running app.
    open var badgeNumber: Int {
        get {
            return UIApplication.shared.applicationIconBadgeNumber
        }
        set {
            let app = UIApplication.shared
            guard app.applicationIconBadgeNumber == newValue else {
                return
            }
            app.applicationIconBadgeNumber = newValue
        }
    }
    
    fileprivate typealias ApplicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation = @convention(c) (NSObject, Selector, UIApplication, Data) -> Void
    fileprivate typealias ApplicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation = @convention(c) (NSObject, Selector, UIApplication, NSError) -> Void
#endif
    
    fileprivate var originalApplicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation: IMP?
    fileprivate var originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation: IMP?

#if os(iOS)
    fileprivate func replaceAppDelegateMethods(_ completionHandler: BoolCompletionHandler?) {
        let app = UIApplication.shared
        guard let appDelegate = app.delegate else { return }
        let appDelegateType = type(of: appDelegate)
        
        let applicationDidRegisterForRemoteNotificationsWithDeviceTokenSelector = #selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
        let applicationDidFailToRegisterForRemoteNotificationsWithErrorSelector = #selector(UIApplicationDelegate.application(_:didFailToRegisterForRemoteNotificationsWithError:))
        
        let originalApplicationDidRegisterForRemoteNotificationsWithDeviceTokenMethod = class_getInstanceMethod(appDelegateType, applicationDidRegisterForRemoteNotificationsWithDeviceTokenSelector)
        let originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorMethod = class_getInstanceMethod(appDelegateType, applicationDidFailToRegisterForRemoteNotificationsWithErrorSelector)
        
        let applicationDidRegisterForRemoteNotificationsWithDeviceTokenBlock: @convention(block) (NSObject, UIApplication, Data) -> Void = { obj, application, deviceToken in
            self.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken, completionHandler: completionHandler)
            
            if let originalApplicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation = self.originalApplicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation {
                let implementation = unsafeBitCast(originalApplicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation, to: ApplicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation.self)
                implementation(obj, applicationDidRegisterForRemoteNotificationsWithDeviceTokenSelector, application, deviceToken)
            }
        }
        
        let originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorBlock: @convention(block) (NSObject, UIApplication, NSError) -> Void = { obj, application, error in
            if let originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation = self.originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation {
                let implementation = unsafeBitCast(originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation, to: ApplicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation.self)
                implementation(obj, applicationDidFailToRegisterForRemoteNotificationsWithErrorSelector, application, error)
            }
        }
        
        let applicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation = imp_implementationWithBlock(unsafeBitCast(applicationDidRegisterForRemoteNotificationsWithDeviceTokenBlock, to: AnyObject.self))
        let applicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation = imp_implementationWithBlock(unsafeBitCast(originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorBlock, to: AnyObject.self))
        
        if originalApplicationDidRegisterForRemoteNotificationsWithDeviceTokenMethod == nil {
            class_addMethod(appDelegateType, applicationDidRegisterForRemoteNotificationsWithDeviceTokenSelector, applicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation, method_getTypeEncoding(originalApplicationDidRegisterForRemoteNotificationsWithDeviceTokenMethod))
            
        } else {
            self.originalApplicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation = method_setImplementation(originalApplicationDidRegisterForRemoteNotificationsWithDeviceTokenMethod, applicationDidRegisterForRemoteNotificationsWithDeviceTokenImplementation)
        }
        
        if originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorMethod == nil {
            class_addMethod(appDelegateType, applicationDidFailToRegisterForRemoteNotificationsWithErrorSelector, applicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation, method_getTypeEncoding(originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorMethod))
        } else {
            self.originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation = method_setImplementation(originalApplicationDidFailToRegisterForRemoteNotificationsWithErrorMethod, applicationDidFailToRegisterForRemoteNotificationsWithErrorImplementation)
        }
    }
    
    fileprivate var initializeToken: Int = 0
    
    private static let lock = NSLock()
    private static var appDelegateMethodsNeedsToRun = true
    
    /**
     Register for remote notifications.
     Call this in your implementation for updating the registration in case the device tokens change.
     
     ```
     func applicationDidBecomeActive(application: UIApplication) {
         Kinvey.sharedClient.push.registerForPush()
     }
     ```
     */
    open func registerForPush(forTypes types: UIUserNotificationType = [.alert, .badge, .sound], categories: Set<UIUserNotificationCategory>? = nil, completionHandler: BoolCompletionHandler? = nil) {
    
        Push.lock.lock()
        if Push.appDelegateMethodsNeedsToRun {
            if Thread.isMainThread {
                self.replaceAppDelegateMethods(completionHandler)
            } else {
                DispatchQueue.main.sync {
                    self.replaceAppDelegateMethods(completionHandler)
                }
            }
            Push.appDelegateMethodsNeedsToRun = false
        }
        Push.lock.unlock()
        
        let app = UIApplication.shared
        let userNotificationSettings = UIUserNotificationSettings(
            types: types,
            categories: categories
        )
        app.registerUserNotificationSettings(userNotificationSettings)
        app.registerForRemoteNotifications()
    }
#endif
    
    /// Unregister the current device to receive push notifications.
    open func unRegisterDeviceToken(_ completionHandler: BoolCompletionHandler? = nil) {
        guard let deviceToken = deviceToken else {
            fatalError("Device token not found")
        }
        
        Promise<Bool> { fulfill, reject in
            let request = self.client.networkRequestFactory.buildPushUnRegisterDevice(deviceToken)
            request.execute({ (data, response, error) -> Void in
                if let response = response , response.isOK {
                    fulfill(true)
                } else {
                    reject(buildError(data, response, error, self.client))
                }
            })
        }.then { success in
            completionHandler?(success, nil)
        }.catch { error in
            completionHandler?(false, error)
        }
    }
    
    /// Call this method inside your App Delegate method `application(application:didRegisterForRemoteNotificationsWithDeviceToken:completionHandler:)`.
#if os(iOS)
    fileprivate func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data, completionHandler: BoolCompletionHandler? = nil) {
        self.deviceToken = deviceToken
        let block: () -> Void = {
            Promise<Bool> { fulfill, reject in
                let request = self.client.networkRequestFactory.buildPushRegisterDevice(deviceToken)
                request.execute({ (data, response, error) -> Void in
                    if let response = response , response.isOK {
                        fulfill(true)
                    } else {
                        reject(buildError(data, response, error, self.client))
                    }
                })
            }.then { success in
                completionHandler?(success, nil)
            }.catch { error in
                completionHandler?(false, error)
            }
        }
        if let _ = self.client.activeUser {
            block()
        } else {
            self.client.userChangedListener = { user in
                if let _ = user {
                    block()
                    self.client.userChangedListener = nil
                }
            }
        }
    }
    
    /// Resets the badge number to zero.
    open func resetBadgeNumber() {
        badgeNumber = 0
    }
#endif
    
    
}
