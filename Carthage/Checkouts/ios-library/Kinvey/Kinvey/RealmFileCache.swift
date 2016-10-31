//
//  RealmFileCache.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-07-26.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import RealmSwift

class RealmFileCache: FileCache {
    
    let persistenceId: String
    let realm: Realm
    let executor: Executor
    
    init(persistenceId: String, filePath: String? = nil, encryptionKey: Data? = nil, schemaVersion: UInt64) {
        self.persistenceId = persistenceId
        var configuration = Realm.Configuration()
        if let filePath = filePath {
            configuration.fileURL = URL(fileURLWithPath: filePath)
        }
        configuration.encryptionKey = encryptionKey
        configuration.schemaVersion = schemaVersion
        
        do {
            realm = try Realm(configuration: configuration)
        } catch {
            configuration.deleteRealmIfMigrationNeeded = true
            realm = try! Realm(configuration: configuration)
        }
        
        executor = Executor()
    }
    
    func save(_ file: File, beforeSave: (() -> Void)?) {
        executor.executeAndWait {
            try! self.realm.write {
                beforeSave?()
                self.realm.create(File.self, value: file, update: true)
            }
        }
    }
    
    func remove(_ file: File) {
        executor.executeAndWait {
            try! self.realm.write {
                if let fileId = file.fileId, let file = self.realm.object(ofType: File.self, forPrimaryKey: fileId) {
                    self.realm.delete(file)
                }
                
                if let path = file.path {
                    let fileManager = FileManager.default
                    if fileManager.fileExists(atPath: path) {
                        do {
                            try FileManager.default.removeItem(atPath: (path as NSString).expandingTildeInPath)
                        } catch {
                            //ignore possible errors if for any reason is not possible to delete the file
                        }
                    }
                }
            }
        }
    }
    
    func get(_ fileId: String) -> File? {
        var file: File? = nil
        
        executor.executeAndWait {
            file = self.realm.object(ofType: File.self, forPrimaryKey: fileId)
        }
        
        return file
    }
    
}
