//
//  ClientAppVersionTests.swift
//  KinveyKit
//
//  Created by Victor Barros on 2015-03-19.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

import Foundation

class RequestConfigurationTests: KCSTestCase {
    
    var collection: KCSCollection!
    var store: KCSStore!
    var offlineUpdateDelegate: KCSOfflineUpdateDelegate!
    let timeout = NSTimeInterval(30)
    
    override func setUp() {
        super.setUp()
        
        let requestConfiguration = KCSRequestConfiguration(clientAppVersion: "2.0",
            andCustomRequestProperties: [
                "lang" : "fr",
                "globalProperty" : "abc"
            ]
        )
        setupKCS(true, options: nil, requestConfiguration: requestConfiguration)
        
        class MockOfflineUpdateDelegate:NSObject, KCSOfflineUpdateDelegate {
            
            @objc private func shouldEnqueueObject(objectId: String!, inCollection collectionName: String!, onError error: NSError!) -> Bool {
                return true
            }
            
            @objc private func didEnqueueObject(objectId: String!, inCollection collectionName: String!) {             
            }
            
            @objc private func shouldSaveObject(objectId: String!, inCollection collectionName: String!, lastAttemptedSaveTime saveTime: NSDate!) -> Bool {
                return true
            }
            
            @objc private func willSaveObject(objectId: String!, inCollection collectionName: String!) {
            }
            
            @objc private func didSaveObject(objectId: String!, inCollection collectionName: String!) {
            }
            
            @objc private func shouldDeleteObject(objectId: String!, inCollection collectionName: String!, lastAttemptedDeleteTime time: NSDate!) -> Bool {
                return true
            }
            
            @objc private func willDeleteObject(objectId: String!, inCollection collectionName: String!) {
            }
            
            @objc private func didDeleteObject(objectId: String!, inCollection collectionName: String!) {
            }
            
        }
        offlineUpdateDelegate = MockOfflineUpdateDelegate()
        KCSClient.sharedClient().setOfflineDelegate(offlineUpdateDelegate)
        
        collection = KCSCollection(fromString: "city", ofClass: NSMutableDictionary.self)
        store = KCSCachedStore(collection: collection, options: [
            KCSStoreKeyCachePolicy : KCSCachePolicy.LocalFirst.rawValue,
            KCSStoreKeyOfflineUpdateEnabled : true
        ])
    }
    
}
