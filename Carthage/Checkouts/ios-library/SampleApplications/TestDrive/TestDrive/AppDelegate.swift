//
//  AppDelegate.swift
//  TestDrive
//
//  Created by Victor Barros on 2016-01-27.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import UIKit
import Kinvey
import PromiseKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var client: Client!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
//        client = Kinvey.sharedClient.initialize(appKey: "kid_WJg0WNTX5e", appSecret: "b321ba722b1c4dc4a084ad03a361a45a")
        client = Kinvey.sharedClient.initialize(appKey: "kid_Wy35WH6X9e", appSecret: "2498a81d1e9f4920b977b66ad62815e9", apiHostName: NSURL(string: "https://v3yk1n-kcs.kinvey.com/")!)
//        client = Kinvey.sharedClient.initialize(appKey: "kid_bycUAdCPTg", appSecret: "a6126fec6fa340c28a3f0eaeecfd234a")
        
        let store = DataStore<Recipe>.getInstance(.Sync)
        let chocolateCake = Recipe(name: "Chocolate Cake")
        
        let reachability = Reachability.reachabilityForInternetConnection()
        print("Reachable: \(reachability.isReachable())")
        print("ReachableViaWiFi: \(reachability.isReachableViaWiFi())")
        print("ReachableViaWWAN: \(reachability.isReachableViaWWAN())")
        
        Promise<User> { fulfill, reject in
            if let user = client.activeUser {
                fulfill(user)
            } else {
                User.exists(username: "test") { exists, error in
                    if exists {
                        User.login(username: "test", password: "test") { user, error in
                            if let user = user {
                                fulfill(user)
                            } else if let error = error {
                                reject(error)
                            }
                        }
                    } else {
                        User.signup(username: "test", password: "test") { user, error in
                            if let user = user {
                                fulfill(user)
                            } else if let error = error {
                                reject(error)
                            }
                        }
                    }
                }
            }
        }.then { _ in
            self.client.push.registerForPush()
        }.then { _ in
            return Promise<File> { fulfill, reject in
                let image = UIImage(named: "Kinvey")!
                let file = File()
                FileStore.getInstance().upload(file, image: image) { file, error in
                    if let file = file {
                        fulfill(file)
                    } else if let error = error {
                        reject(error)
                    } else {
                        abort()
                    }
                }
            }
        }.then { file in
            return Promise<File> { fulfill, reject in
                FileStore.getInstance().download(file) { file, data, error in
                    if let file = file, let _ = data {
                        fulfill(file)
                    } else if let error = error {
                        reject(error)
                    } else {
                        abort()
                    }
                }
            }
//        }.then { file in
//            return Promise<UInt> { fulfill, reject in
//                FileStore.getInstance().remove(file) { count, error in
//                    if let count = count {
//                        fulfill(count)
//                    } else if let error = error {
//                        reject(error)
//                    } else {
//                        abort()
//                    }
//                }
//            }
        }.then { file in
            return Promise<[File]> { fulfill, reject in
                FileStore.getInstance().find() { files, error in
                    if let files = files {
                        fulfill(files)
                    } else if let error = error {
                        reject(error)
                    } else {
                        abort()
                    }
                }
            }
        }.then { _ in
            return Promise<Recipe> { fulfill, reject in
                store.save(chocolateCake) { recipe, error in
                    if let recipe = recipe {
                        print("Recipe: \(recipe.name!) (\(recipe.id!))")
                        fulfill(recipe)
                    } else if let error = error {
                        reject(error)
                    } else {
                        abort()
                    }
                }
            }
//        }.then { recipe in
//            return Promise<Recipe> { fulfill, reject in
//                guard let recipeId = recipe.id else {
//                    reject(Kinvey.Error.ObjectIdMissing)
//                    return
//                }
//                store.findById(recipeId) { recipe, error in
//                    if let recipe = recipe {
//                        print("Recipe found by ID: \(recipe.toJson())")
//                        fulfill(recipe)
//                    } else if let error = error {
//                        reject(error)
//                    } else {
//                        abort()
//                    }
//                }
//            }
        }.then { recipe in
            return Promise<Recipe> { fulfill, reject in
                recipe.name = "Dark \(recipe.name!)"
                store.save(recipe) { recipe, error in
                    if let recipe = recipe {
                        print("Recipe: \(recipe.name!) (\(recipe.id!))")
                        fulfill(recipe)
                    } else if let error = error {
                        reject(error)
                    } else {
                        abort()
                    }
                }
            }
//        }.then { _ in
//            return Promise<[Recipe]> { fulfill, reject in
//                store.find() { recipes, error in
//                    if let recipes = recipes {
//                        print("Recipes found: \(recipes.count)")
//                        for recipe in recipes {
//                            print("Recipe found by ID: \(recipe.toJson())")
//                        }
//                        fulfill(recipes)
//                    } else if let error = error {
//                        reject(error)
//                    } else {
//                        abort()
//                    }
//                }
//            }
        }.then { _ in
            return Promise<(UInt, [Recipe]?)> { fulfill, reject in
                try store.sync { count, results, error in
                    if let count = count {
                        print("Sync Count: \(count)")
                        if let results = results {
                            for result in results {
                                print("Recipe: \(result.toJson())")
                            }
                        }
                        fulfill(count, results)
                    } else if let error = error {
                        reject(error)
                    } else {
                        abort()
                    }
                }
            }
//        }.then { _ in
//            return Promise<UInt> { fulfill, reject in
//                try store.push { count, error in
//                    if let error = error {
//                        reject(error)
//                    } else if let count = count {
//                        fulfill(count)
//                    } else {
//                        abort()
//                    }
//                }
//            }
//        }.then { recipe in
//            return Promise<UInt> { fulfill, reject in
//                store.removeAll() { count, error in
//                    if let count = count {
//                        print("Recipes deleted: \(count)")
//                        fulfill(count)
//                    } else if let error = error {
//                        reject(error)
//                    } else {
//                        abort()
//                    }
//                }
//            }
        }.error { error in
            print("Error: \(error)")
        }
        
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        client.push.application(application, didReceiveRemoteNotification: userInfo)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        client.push.application(application, didReceiveRemoteNotification: userInfo)
        if UIApplication.sharedApplication().applicationState != .Active, let _ = userInfo["id"] {
            let notification = UILocalNotification()
            notification.alertBody = "New recipe available!"
            UIApplication.sharedApplication().scheduleLocalNotification(notification)
        }
        completionHandler(.NewData)
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        client.push.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken) { success, error in
            print("\(success)")
            if let error = error {
                print("\(error)")
            }
            
        }
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        client.push.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }

}
