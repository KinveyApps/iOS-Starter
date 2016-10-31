////
////  KCSCodeSnippetTestsSwift.swift
////  KinveyKit
////
////  Created by Victor Barros on 2015-03-26.
////  Copyright (c) 2015 Kinvey. All rights reserved.
////
//
//import Foundation
//
//class KCSCodeSnippetTests: KCSTestCase {
//    
//    var store: KCSStore!
//    var obj = [:]
//    
//    func testDevCenter_ios_downloads_changelog_1_29_0() {
//        //global
//        let requestConfiguration = KCSRequestConfiguration(
//            clientAppVersion: "2.0",
//            andCustomRequestProperties: [
//                "lang" : "fr",
//                "globalProperty" : "abc"
//            ]
//        )
//        let clientConfiguration = KCSClientConfiguration(
//            appKey: "", //***************"<#Your App Key#>",
//            secret: "", //***************"<#Your App Secret#>",
//            options: [:], //***************<#Your Options#>,
//            requestConfiguration: requestConfiguration
//        )
//        KCSClient.sharedClient().initializeWithConfiguration(clientConfiguration)
//        
//        //per request
//        let requestConfig = KCSRequestConfiguration(
//            clientAppVersion: "1.0",
//            andCustomRequestProperties: [
//                "lang" : "pt",
//                "requestProperty" : "123"
//            ]
//        )
//        store.saveObject(
//            obj,
//            requestConfiguration: requestConfig,
//            withCompletionBlock: { (results: [AnyObject]!, error: NSError!) -> Void in
//                //do something awesome here!
//            },
//            withProgressBlock: nil
//        )
//    }
//    
//}
