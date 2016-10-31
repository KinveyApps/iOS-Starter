//
//  RealmSync.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-06-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import RealmSwift

class RealmSync<T: Persistable>: Sync<T> where T: NSObject {
    
    let realm: Realm
    let objectSchema: ObjectSchema
    let propertyNames: [String]
    let executor: Executor
    
    lazy var entityType = T.self as! Entity.Type
    
    required init(persistenceId: String, filePath: String? = nil, encryptionKey: Data? = nil) {
        if !(T.self is Entity.Type) {
            preconditionFailure("\(T.self) needs to be a Entity")
        }
        var configuration = Realm.Configuration()
        if let filePath = filePath {
            configuration.fileURL = URL(fileURLWithPath: filePath)
        }
        configuration.encryptionKey = encryptionKey
        realm = try! Realm(configuration: configuration)
        let className = NSStringFromClass(T.self).components(separatedBy: ".").last!
        objectSchema = realm.schema[className]!
        propertyNames = objectSchema.properties.map { return $0.name }
        executor = Executor()
//        print("\(realm.configuration.fileURL!.path!)")
        super.init(persistenceId: persistenceId)
    }

    required init(persistenceId: String) {
        fatalError("init(persistenceId:) has not been implemented")
    }
    
    override func createPendingOperation(_ request: URLRequest, objectId: String?) -> RealmPendingOperation {
        return RealmPendingOperation(request: request, collectionName: T.collectionName(), objectId: objectId)
    }
    
    override func savePendingOperation(_ pendingOperation: RealmPendingOperation) {
        executor.executeAndWait {
            try! self.realm.write {
                self.realm.create(RealmPendingOperation.self, value: pendingOperation, update: true)
            }
        }
    }
    
    override func pendingOperations() -> Results<RealmPendingOperation> {
        return pendingOperations(nil)
    }
    
    override func pendingOperations(_ objectId: String?) -> Results<RealmPendingOperation> {
        var results: Results<RealmPendingOperation>?
        executor.executeAndWait {
            var realmResults = self.realm.objects(RealmPendingOperation.self)
            if let objectId = objectId {
                realmResults = realmResults.filter("objectId == %@", objectId)
            }
            results = Results(realmResults)
        }
        return results!
    }
    
    override func removePendingOperation(_ pendingOperation: RealmPendingOperation) {
        executor.executeAndWait {
            try! self.realm.write {
                self.realm.delete(pendingOperation)
            }
        }
    }
    
    override func removeAllPendingOperations() {
        removeAllPendingOperations(nil)
    }
    
    override func removeAllPendingOperations(_ objectId: String?) {
        executor.executeAndWait {
            try! self.realm.write {
                var realmResults = self.realm.objects(RealmPendingOperation.self)
                if let objectId = objectId {
                    realmResults = realmResults.filter("objectId == %@", objectId)
                }
                self.realm.delete(realmResults)
            }
        }
    }
    
}
