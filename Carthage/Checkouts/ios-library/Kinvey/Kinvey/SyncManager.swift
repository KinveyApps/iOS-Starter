//
//  SyncManager.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc(__KNVSyncManager)
internal class SyncManager: NSObject {
    
    fileprivate let persistenceId: String
    fileprivate let encryptionKey: Data?
    
    init(persistenceId: String, encryptionKey: Data? = nil) {
        self.persistenceId = persistenceId
        self.encryptionKey = encryptionKey
    }
    
    func sync<T: Persistable>(filePath: String? = nil, type: T.Type) -> Sync<T> where T: NSObject {
        return RealmSync<T>(persistenceId: persistenceId, filePath: filePath, encryptionKey: encryptionKey)
    }
    
}
