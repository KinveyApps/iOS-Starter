//
//  MLIBZ_260_Tests.swift
//  KinveyKit
//
//  Created by Victor Barros on 2015-04-29.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

import UIKit
import XCTest

class MLIBZ_260_Tests: KCSTestCase {
    
    static let appId = "kid_bk8DBVAao"
    
    class MockURLProtocol: NSURLProtocol {
        
        override class func canInitWithRequest(request: NSURLRequest) -> Bool {
            return request.URL!.absoluteString != "https://baas.kinvey.com/user/\(appId)/login"
        }
        
        override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
            return request
        }
        
        override func startLoading() {
            client!.URLProtocol(
                self,
                didFailWithError: NSError(
                    domain: NSURLErrorDomain,
                    code: Int(CFNetworkErrors.CFURLErrorTimedOut.rawValue),
                    userInfo: [
                        NSLocalizedDescriptionKey : NSURLErrorDomain,
                        NSLocalizedFailureReasonErrorKey : NSURLErrorDomain
                    ]
                )
            )
            client!.URLProtocolDidFinishLoading(self)
        }
        
    }

    override func setUp() {
        super.setUp()
        
        KCSURLProtocol.registerClass(MockURLProtocol.self)
        
        KCSClient.sharedClient().initializeKinveyServiceForAppKey(
            MLIBZ_260_Tests.appId,
            withAppSecret: "db250c3456d148579d79b2852c773f19",
            usingOptions: nil
        )
    }
    
    override func tearDown() {
        KCSURLProtocol.unregisterClass(MockURLProtocol.self)
        
        super.tearDown()
    }

    func test() {
        KCSUser.activeUser()?.logout()
        KCSUser.clearSavedCredentials()
        
        class OfflineSaveDelegate: NSObject, KCSOfflineUpdateDelegate {
            
            @objc private func shouldDeleteObject(objectId: String!, inCollection collectionName: String!, lastAttemptedDeleteTime time: NSDate!) -> Bool {
                return true
            }
            
            @objc private func shouldEnqueueObject(objectId: String!, inCollection collectionName: String!, onError error: NSError!) -> Bool {
                return true
            }
            
            @objc private func shouldSaveObject(objectId: String!, inCollection collectionName: String!, lastAttemptedSaveTime saveTime: NSDate!) -> Bool {
                return true
            }
            
        }
        
        let delegate = OfflineSaveDelegate()
        KCSClient.sharedClient().setOfflineDelegate(delegate)
        
        weak var expectationLogin = expectationWithDescription("login")
        weak var expectationSave = expectationWithDescription("save")
        
        KCSUser.loginWithUsername(
            "jeppe",
            password: "1234",
            withCompletionBlock: { (user: KCSUser!, errorOrNil: NSError!, actionResult: KCSUserActionResult) -> Void in
                XCTAssertNotNil(user)
                XCTAssertNil(errorOrNil)
                
                if (errorOrNil != nil) {
                    NSLog("%d %@", errorOrNil.code, errorOrNil)
                } else {
                    // NOTE: SET A BREAKPOINT HERE AND DISCONNECT NETWORK (WIFI) TO MAKE SURE THE FOLLOWING NEEDS OFFLINE SAVE
                    
                    class Object : NSObject {
                        
                        dynamic var objectId: String?
                        dynamic var hey: String?
                        
                        private override func hostToKinveyPropertyMapping() -> [NSObject : AnyObject]! {
                            return [
                                "objectId" : KCSEntityKeyId,
                                "hey" : "hey"
                            ]
                        }
                        
                    }
                    
                    let collection = KCSCollection(fromString: "MyCollection", ofClass: NSMutableDictionary.self)
                    let store = KCSCachedStore(
                        collection: collection,
                        options: [
                            KCSStoreKeyOfflineUpdateEnabled : true
                        ]
                    )
                    
                    let obj = Object()
                    obj.hey = "there"
                    
                    store.saveObject(
                        obj,
                        withCompletionBlock: { (objectsOrNil: [AnyObject]!, errorOrNil: NSError!) -> Void in
                            XCTAssertNil(objectsOrNil)
                            XCTAssertNotNil(errorOrNil)
                            
                            expectationSave?.fulfill()
                        },
                        withProgressBlock: nil
                    )
                }
                
                expectationLogin?.fulfill()
            }
        )
        
        waitForExpectationsWithTimeout(60, handler: nil)
    }

}
