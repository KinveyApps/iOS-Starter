//
//  KCSManagementAPI.swift
//  KinveyKit
//
//  Created by Victor Barros on 2015-09-25.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import UIKit

class KCSManageAPI: NSObject {
    
    var baseURL: String
    var kid: String
    var token: String!
    
    init(baseURL: String = "https://manage.kinvey.com", kid: String) {
        self.baseURL = baseURL
        self.kid = kid
    }
    
    func loginWithEmail(email: String, password: String, completionBlock: ((NSURLResponse?, [String : AnyObject]?, NSError?) -> Void)) {
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        let URL = NSURL(string: "\(baseURL)/session")
        let request = NSMutableURLRequest(URL: URL!)
        request.HTTPMethod = "POST"
        
        // Headers
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // JSON Body
        let bodyObject = [
            "email": email,
            "password": password
        ]
        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(bodyObject, options: [])
            
            let task = session.dataTaskWithRequest(request, completionHandler: { (data : NSData?, response : NSURLResponse?, var error : NSError?) -> Void in
                var json: [String : AnyObject]? = nil
                if let data = data {
                    do {
                        json = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String : AnyObject]
                        
                        if let json = json {
                            self.token = json["token"] as? String
                        }
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
    
    func importData(
        collectionName: String,
        fileURL: NSURL,
        timeout: NSTimeInterval = NSTimeInterval(60 * 5), //5 minutes
        completionBlock: ((NSURLResponse?, [String : AnyObject]?, NSError?) -> Void)
    ) {
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfig.timeoutIntervalForRequest = timeout
        sessionConfig.timeoutIntervalForResource = sessionConfig.timeoutIntervalForRequest
        
        let session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        let URL = NSURL(string: "\(baseURL)/environments/\(kid)/collections/\(collectionName)/import")
        let request = NSMutableURLRequest(URL: URL!)
        request.HTTPMethod = "POST"
        
        let boundary = "__X_KINVEY_BOUNDARY_\(NSUUID().UUIDString)__"
        
        // Headers
        request.addValue("Kinvey \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Body
        let body = NSMutableData(capacity: 4096)!
        
        var bodyString = "--\(boundary)\r\n"
        bodyString += "Content-Disposition: form-data; name=\"file\"; filename=\"import.csv\"\r\n"
        bodyString += "Content-Type: text/csv\r\n"
        bodyString += "\r\n"
        body.appendData(bodyString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!)
        
        let fileContent = NSData(contentsOfFile: fileURL.path!)
        body.appendData(fileContent!)
        
        bodyString = "\r\n--\(boundary)--\r\n\r\n"
        body.appendData(bodyString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!)
        
        let task = session.uploadTaskWithRequest(request, fromData: body, completionHandler: { (data : NSData?, response : NSURLResponse?, var error : NSError?) -> Void in
            var json: [String : AnyObject]? = nil
            if let data = data {
                do {
                    json = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String : AnyObject]
                } catch let jsonError as NSError {
                    NSLog("%@", NSString(data: data, encoding: NSUTF8StringEncoding)!)
                    error = jsonError
                }
            }
            completionBlock(response, json, error)
            
            session.finishTasksAndInvalidate()
        })
        task.resume()
    }
    
}
