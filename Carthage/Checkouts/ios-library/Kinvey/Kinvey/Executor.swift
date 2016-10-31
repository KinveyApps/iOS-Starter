//
//  Executor.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-06-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class Executor {
    
    fileprivate let operationQueue: OperationQueue
    fileprivate let thread: Thread
    
    init() {
        operationQueue = OperationQueue.current!
        operationQueue.maxConcurrentOperationCount = 1
        thread = Thread.current
    }
    
    func execute(_ block: @escaping () -> Void) {
        operationQueue.addOperation(block)
    }
    
    func executeAndWait(_ block: @escaping () -> Void) {
        if thread == Thread.current {
            block()
        } else {
            operationQueue.addOperation(block)
            operationQueue.waitUntilAllOperationsAreFinished()
        }
    }
    
}
