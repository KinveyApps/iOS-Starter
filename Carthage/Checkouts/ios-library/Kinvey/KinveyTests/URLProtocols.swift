//
//  TimeoutErrorURLProtocol.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-14.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class TimeoutErrorURLProtocol: URLProtocol {
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        client!.urlProtocol(self, didFailWithError: NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil))
    }
    
    override func stopLoading() {
    }
    
}
