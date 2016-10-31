//
//  LocalRequest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc(__KNVLocalRequest)
internal class LocalRequest: NSObject, Request {
    
    let executing = false
    let cancelled = false
    
    typealias LocalHandler = () -> Void
    
    var progress: ((ProgressStatus) -> Void)?
    
    let localHandler: LocalHandler?
    
    init(_ localHandler: LocalHandler? = nil) {
        self.localHandler = localHandler
    }
    
    func execute(_ completionHandler: LocalHandler) {
        localHandler?()
        completionHandler()
    }
    
    func cancel() {
        //do nothing
    }

}
