//
//  Sync.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal protocol SyncType {
    
    associatedtype PendingOperation: PendingOperationType
    
    var persistenceId: String { get }
    var collectionName: String { get }
    
    init(persistenceId: String)
    
    func createPendingOperation(_ request: URLRequest, objectId: String?) -> PendingOperation
    func savePendingOperation(_ pendingOperation: PendingOperation
    )
    
    func pendingOperations() -> Results<PendingOperationIMP>
    func pendingOperations(_ objectId: String?) -> Results<PendingOperationIMP>
    
    func removePendingOperation(_ pendingOperation: PendingOperation)
    
    func removeAllPendingOperations()
    func removeAllPendingOperations(_ objectId: String?)
    
}

internal class Sync<T: Persistable>: SyncType where T: NSObject {
    
    let collectionName: String
    let persistenceId: String
    
    required init(persistenceId: String) {
        self.collectionName = T.collectionName()
        self.persistenceId = persistenceId
    }
    
    func createPendingOperation(_ request: URLRequest, objectId: String?) -> PendingOperationIMP {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    func savePendingOperation(_ pendingOperation: PendingOperationIMP) {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    func pendingOperations() -> Results<PendingOperationIMP> {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    func pendingOperations(_ objectId: String?) -> Results<PendingOperationIMP> {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    func removePendingOperation(_ pendingOperation: PendingOperationIMP) {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    func removeAllPendingOperations() {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    func removeAllPendingOperations(_ objectId: String?) {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
}
