//
//  MultiRequest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc(__KNVMultiRequest)
internal class MultiRequest: NSObject, Request {
    
    fileprivate var addProgresses = [Bool]()
    fileprivate var requests = [Request]()
    
    var progress: ((ProgressStatus) -> Void)? {
        didSet {
            for (index, request) in requests.enumerated() {
                if addProgresses[index] {
                    request.progress = progress
                }
            }
        }
    }
    
    internal func addRequest(_ request: Request, addProgress: Bool = false) {
        if _cancelled {
            request.cancel()
        }
        if addProgress {
            request.progress = progress
        }
        addProgresses.append(addProgress)
        requests.append(request)
    }
    
    internal var executing: Bool {
        get {
            for request in requests {
                if request.executing {
                    return true
                }
            }
            return false
        }
    }
    
    var _cancelled = false
    internal var cancelled: Bool {
        get {
            for request in requests {
                if request.cancelled {
                    return true
                }
            }
            return _cancelled
        }
    }
    
    internal func cancel() {
        _cancelled = true
        for request in requests {
            request.cancel()
        }
    }
    
}

func +=(lhs: MultiRequest, rhs: Request) {
    lhs.addRequest(rhs)
}

func +=(lhs: MultiRequest, rhs: (Request, addProgress: Bool)) {
    lhs.addRequest(rhs.0, addProgress: rhs.addProgress)
}
