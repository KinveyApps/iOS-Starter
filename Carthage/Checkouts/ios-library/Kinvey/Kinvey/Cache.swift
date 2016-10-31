//
//  Cache.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal protocol CacheType {
    
    var persistenceId: String { get }
    var collectionName: String { get }
    var ttl: TimeInterval? { get set }
    
    associatedtype `Type`
    
    func saveEntity(_ entity: Type)
    
    func saveEntities(_ entities: [Type])
    
    func findEntity(_ objectId: String) -> Type?
    
    func findEntityByQuery(_ query: Query) -> [Type]
    
    func findIdsLmtsByQuery(_ query: Query) -> [String : String]
    
    func findAll() -> [Type]
    
    func count(_ query: Query?) -> Int
    
    func removeEntity(_ entity: Type) -> Bool
    
    func removeEntities(_ entity: [Type]) -> Bool
    
    func removeEntitiesByQuery(_ query: Query) -> Int
    
    func removeAllEntities()
    
}

extension CacheType {
    
    func isEmpty() -> Bool {
        return count(nil) == 0
    }
    
}

internal class Cache<T: Persistable>: CacheType where T: NSObject {
    
    internal typealias `Type` = T
    
    let persistenceId: String
    let collectionName: String
    var ttl: TimeInterval?
    
    init(persistenceId: String, ttl: TimeInterval? = nil) {
        self.persistenceId = persistenceId
        self.collectionName = T.collectionName()
        self.ttl = ttl
    }
    
    func detach(_ entity: T) -> T {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    func detach(_ entity: [T], query: Query) -> [T] {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    func saveEntity(_ entity: T) {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    func saveEntities(_ entities: [T]) {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    func findEntity(_ objectId: String) -> T? {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    func findEntityByQuery(_ query: Query) -> [T] {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    func findIdsLmtsByQuery(_ query: Query) -> [String : String] {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    func findAll() -> [T] {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    func count(_ query: Query? = nil) -> Int {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    @discardableResult
    func removeEntity(_ entity: T) -> Bool {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    @discardableResult
    func removeEntities(_ entity: [T]) -> Bool {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    @discardableResult
    func removeEntitiesByQuery(_ query: Query) -> Int {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    @discardableResult
    func removeAllEntities() {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
}
