//
//  KCSBaasAPI.swift
//  KinveyKit
//
//  Created by Victor Barros on 2015-09-25.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import UIKit

class KCSBaasAPI: NSObject {
    
    private var baseURL: String
    private var kid: String
    private var appSecret: String
    private var masterSecret: String
    
    private let apiVersion = "3"
    
    init(baseURL: String = "https://baas.kinvey.com", kid: String, appSecret: String, masterSecret: String) {
        self.baseURL = baseURL
        self.kid = kid
        self.appSecret = appSecret
        self.masterSecret = masterSecret
    }
    
    private func masterAuthorization() -> String! {
        let authorization = "\(kid):\(masterSecret)".dataUsingEncoding(NSUTF8StringEncoding)?.base64EncodedStringWithOptions([])
        return "Basic \(authorization!)"
    }
    
    func clearCollection(collectionName: String, completionBlock: ((NSURLResponse?, [String : AnyObject]?, NSError?) -> Void)) {
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        let URL = NSURL(string: "\(baseURL)/rpc/\(kid)/remove-collection")
        let request = NSMutableURLRequest(URL: URL!)
        request.HTTPMethod = "POST"
        
        // Headers
        request.addValue(masterAuthorization(), forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiVersion, forHTTPHeaderField: "X-Kinvey-API-Version")
        request.addValue("true", forHTTPHeaderField: "X-Kinvey-Delete-Entire-Collection")
        request.addValue("true", forHTTPHeaderField: "X-Kinvey-Retain-collection-Metadata")
        
        // JSON Body
        let bodyObject = [
            "collectionName": collectionName
        ]
        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(bodyObject, options: [])
            
            let task = session.dataTaskWithRequest(request, completionHandler: { (data : NSData?, response : NSURLResponse?, var error : NSError?) -> Void in
                var json: [String : AnyObject]? = nil
                if let data = data {
                    do {
                        json = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String : AnyObject]
                    } catch let jsonError as NSError {
                        error = jsonError
                    }
                }
                completionBlock(response, json, error)
                
                session.finishTasksAndInvalidate()
            })
            task.resume()
        } catch let error as NSError {
            completionBlock(nil, nil, error)
        }
    }
    
    func count(collectionName: String, completionBlock: ((NSURLResponse?, [String : AnyObject]?, NSError?) -> Void)) {
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        let URL = NSURL(string: "\(baseURL)/appdata/\(kid)/\(collectionName)/_count")
        let request = NSMutableURLRequest(URL: URL!)
        request.HTTPMethod = "GET"
        
        // Headers
        request.addValue(masterAuthorization(), forHTTPHeaderField: "Authorization")
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data : NSData?, response : NSURLResponse?, var error : NSError?) -> Void in
            var json: [String : AnyObject]? = nil
            if let data = data {
                do {
                    json = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String : AnyObject]
                } catch let jsonError as NSError {
                    error = jsonError
                }
            }
            completionBlock(response, json, error)
            
            session.finishTasksAndInvalidate()
        })
        task.resume()
    }
    
    func query(collectionName: String, completionBlock: ((NSURLResponse?, [[String : AnyObject]]?, NSError?) -> Void)) {
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        let URL = NSURL(string: "\(baseURL)/appdata/\(kid)/\(collectionName)")
        let request = NSMutableURLRequest(URL: URL!)
        request.HTTPMethod = "GET"
        
        // Headers
        request.addValue(masterAuthorization(), forHTTPHeaderField: "Authorization")
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data : NSData?, response : NSURLResponse?, var error : NSError?) -> Void in
            var json: [[String : AnyObject]]? = nil
            if let data = data {
                do {
                    json = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [[String : AnyObject]]
                } catch let jsonError as NSError {
                    error = jsonError
                }
            }
            completionBlock(response, json, error)
            
            session.finishTasksAndInvalidate()
        })
        task.resume()
    }

}
