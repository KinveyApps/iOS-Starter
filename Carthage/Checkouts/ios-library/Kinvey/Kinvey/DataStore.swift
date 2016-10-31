//
//  BaseStore.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-14.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

class DataStoreTypeTag: Hashable {
    
    let persistableType: Persistable.Type
    let tag: String
    let type: StoreType
    
    init(persistableType: Persistable.Type, tag: String, type: StoreType) {
        self.persistableType = persistableType
        self.tag = tag
        self.type = type
    }
    
    var hashValue: Int {
        var hash = NSDecimalNumber(value: 5)
        hash = 23 * hash + NSDecimalNumber(value: NSStringFromClass(persistableType as! AnyClass).hashValue)
        hash = 23 * hash + NSDecimalNumber(value: tag.hashValue)
        hash = 23 * hash + NSDecimalNumber(value: type.hashValue)
        return hash.hashValue
    }
    
}

func +(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> NSDecimalNumber {
    return lhs.adding(rhs)
}

func *(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> NSDecimalNumber {
    return lhs.multiplying(by: rhs)
}

func ==(lhs: DataStoreTypeTag, rhs: DataStoreTypeTag) -> Bool {
    return lhs.persistableType == rhs.persistableType &&
        lhs.tag == rhs.tag &&
        lhs.type == rhs.type
}

/// Class to interact with a specific collection in the backend.
open class DataStore<T: Persistable> where T: NSObject {
    
    public typealias ArrayCompletionHandler = ([T]?, Swift.Error?) -> Void
    public typealias ObjectCompletionHandler = (T?, Swift.Error?) -> Void
    public typealias IntCompletionHandler = (Int?, Swift.Error?) -> Void
    public typealias UIntErrorTypeArrayCompletionHandler = (UInt?, [Swift.Error]?) -> Void
    public typealias UIntArrayCompletionHandler = (UInt?, [T]?, [Swift.Error]?) -> Void
    
    fileprivate let readPolicy: ReadPolicy
    fileprivate let writePolicy: WritePolicy
    
    /// Collection name that matches with the name in the backend.
    open let collectionName: String
    
    /// Client instance attached to the DataStore.
    open let client: Client
    
    /// DataStoreType defines how the DataStore will behave.
    open let type: StoreType
    
    fileprivate let filePath: String?
    
    internal let cache: Cache<T>?
    internal let sync: Sync<T>?
    
    fileprivate var deltaSet: Bool
    
    /// TTL (Time to Live) defines a filter of how old the data returned from the DataStore can be.
    open var ttl: TTL? {
        didSet {
            if let cache = cache {
                cache.ttl = ttl != nil ? ttl!.1.toTimeInterval(ttl!.0) : nil
            }
        }
    }
    
    /**
     Deprecated method. Please use `collection()` instead.
     */
    @available(*, deprecated: 3.0.22, message: "Please use `collection()` instead")
    open class func getInstance(_ type: StoreType = .cache, deltaSet: Bool? = nil, client: Client = sharedClient, tag: String = defaultTag) -> DataStore {
        return collection(type, deltaSet: deltaSet, client: client, tag: tag)
    }

    /**
     Factory method that returns a `DataStore`.
     - parameter type: defines the data store type which will define the behavior of the `DataStore`. Default value: `Cache`
     - parameter deltaSet: Enables delta set cache which will increase performance and reduce data consumption. Default value: `false`
     - parameter client: define the `Client` to be used for all the requests for the `DataStore` that will be returned. Default value: `Kinvey.sharedClient`
     - parameter tag: A tag/nickname for your `DataStore` which will cache instances with the same tag name. Default value: `Kinvey.defaultTag`
     - returns: An instance of `DataStore` which can be a new instance or a cached instance if you are passing a `tag` parameter.
     */
    open class func collection(_ type: StoreType = .cache, deltaSet: Bool? = nil, client: Client = sharedClient, tag: String = defaultTag) -> DataStore {
        precondition(client.isInitialized(), "Client is not initialized. Call Kinvey.sharedClient.initialize(...) to initialize the client before creating a DataStore.")
        let key = DataStoreTypeTag(persistableType: T.self, tag: tag, type: type)
        var dataStore = client.dataStoreInstances[key] as? DataStore
        if dataStore == nil {
            let filePath = client.filePath(tag)
            dataStore = DataStore<T>(type: type, deltaSet: deltaSet ?? false, client: client, filePath: filePath, encryptionKey: client.encryptionKey)
            client.dataStoreInstances[key] = dataStore
        }
        return dataStore!
    }
    
    open func collection<NewType: Persistable>(newType: NewType.Type) -> DataStore<NewType> where NewType: NSObject {
        return DataStore<NewType>(type: type, deltaSet: deltaSet, client: client, filePath: filePath, encryptionKey: client.encryptionKey)
    }
    
    fileprivate init(type: StoreType, deltaSet: Bool, client: Client, filePath: String?, encryptionKey: Data?) {
        self.type = type
        self.deltaSet = deltaSet
        self.client = client
        self.filePath = filePath
        collectionName = T.collectionName()
        if type != .network, let _ = T.self as? Entity.Type {
            cache = client.cacheManager.cache(filePath: filePath, type: T.self)
            sync = client.syncManager.sync(filePath: filePath, type: T.self)
        } else {
            cache = nil
            sync = nil
        }
        readPolicy = type.readPolicy
        writePolicy = type.writePolicy
    }
    
    /**
     Gets a single record using the `_id` of the record.
     - parameter id: The `_id` value of the entity to be find
     - parameter readPolicy: Enforces a different `ReadPolicy` otherwise use the client's `ReadPolicy`. Default value: `nil`
     - parameter completionHandler: Completion handler to be called once the respose returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @discardableResult
    open func find(byId id: String, readPolicy: ReadPolicy? = nil, completionHandler: @escaping ObjectCompletionHandler) -> Request {
        return find(id, readPolicy: readPolicy, completionHandler: completionHandler)
    }
    
    /**
     Gets a single record using the `_id` of the record.
     
     PS: This method is just a shortcut for `findById()`
     - parameter id: The `_id` value of the entity to be find
     - parameter readPolicy: Enforces a different `ReadPolicy` otherwise use the client's `ReadPolicy`. Default value: `nil`
     - parameter completionHandler: Completion handler to be called once the respose returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @discardableResult
    open func find(_ id: String, readPolicy: ReadPolicy? = nil, completionHandler: @escaping ObjectCompletionHandler) -> Request {
        precondition(!id.isEmpty)
        let readPolicy = readPolicy ?? self.readPolicy
        let operation = GetOperation<T>(id: id, readPolicy: readPolicy, cache: cache, client: client)
        let request = operation.execute(dispatchAsyncMainQueue(completionHandler))
        return request
    }
    
    /**
     Gets a list of records that matches with the query passed by parameter.
     - parameter query: The query used to filter the results
     - parameter deltaSet: Enforces delta set cache otherwise use the client's `deltaSet` value. Default value: `false`
     - parameter readPolicy: Enforces a different `ReadPolicy` otherwise use the client's `ReadPolicy`. Default value: `nil`
     - parameter completionHandler: Completion handler to be called once the respose returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @discardableResult
    open func find(_ query: Query = Query(), deltaSet: Bool? = nil, readPolicy: ReadPolicy? = nil, completionHandler: @escaping ArrayCompletionHandler) -> Request {
        let readPolicy = readPolicy ?? self.readPolicy
        let deltaSet = deltaSet ?? self.deltaSet
        let operation = FindOperation<T>(query: Query(query: query, persistableType: T.self), deltaSet: deltaSet, readPolicy: readPolicy, cache: cache, client: client)
        let request = operation.execute(dispatchAsyncMainQueue(completionHandler))
        return request
    }
    
    /**
     Gets a count of how many records that matches with the (optional) query passed by parameter.
     - parameter query: The query used to filter the results
     - parameter readPolicy: Enforces a different `ReadPolicy` otherwise use the client's `ReadPolicy`. Default value: `nil`
     - parameter completionHandler: Completion handler to be called once the respose returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @discardableResult
    open func count(_ query: Query? = nil, readPolicy: ReadPolicy? = nil, completionHandler: IntCompletionHandler?) -> Request {
        let readPolicy = readPolicy ?? self.readPolicy
        let operation = CountOperation<T>(query: query, readPolicy: readPolicy, cache: cache, client: client)
        let request = operation.execute(dispatchAsyncMainQueue(completionHandler))
        return request
    }
    
    /// Creates or updates a record.
    @discardableResult
    open func save(_ persistable: inout T, writePolicy: WritePolicy? = nil, completionHandler: ObjectCompletionHandler?) -> Request {
        let writePolicy = writePolicy ?? self.writePolicy
        let operation = SaveOperation<T>(persistable: persistable, writePolicy: writePolicy, sync: sync, cache: cache, client: client)
        let request = operation.execute(dispatchAsyncMainQueue(completionHandler))
        return request
    }
    
    /// Creates or updates a record.
    @discardableResult
    open func save(_ persistable: T, writePolicy: WritePolicy? = nil, completionHandler: ObjectCompletionHandler?) -> Request {
        let writePolicy = writePolicy ?? self.writePolicy
        let operation = SaveOperation<T>(persistable: persistable, writePolicy: writePolicy, sync: sync, cache: cache, client: client)
        let request = operation.execute(dispatchAsyncMainQueue(completionHandler))
        return request
    }
    
    /// Deletes a record.
    @discardableResult
    open func remove(_ persistable: T, writePolicy: WritePolicy? = nil, completionHandler: IntCompletionHandler?) throws -> Request {
        guard let id = persistable.entityId else {
            throw Error.objectIdMissing
        }
        return removeById(id, writePolicy:writePolicy, completionHandler: completionHandler)
    }
    
    /// Deletes a list of records.
    @discardableResult
    open func remove(_ array: [T], writePolicy: WritePolicy? = nil, completionHandler: IntCompletionHandler?) -> Request {
        var ids: [String] = []
        for persistable in array {
            if let id = persistable.entityId {
                ids.append(id)
            }
        }
        return removeById(ids, writePolicy:writePolicy, completionHandler: completionHandler)
    }
    
    /// Deletes a record using the `_id` of the record.
    @discardableResult
    open func removeById(_ id: String, writePolicy: WritePolicy? = nil, completionHandler: IntCompletionHandler?) -> Request {
        precondition(!id.isEmpty)

        let writePolicy = writePolicy ?? self.writePolicy
        let operation = RemoveByIdOperation<T>(objectId: id, writePolicy: writePolicy, sync: sync, cache: cache, client: client)
        let request = operation.execute(dispatchAsyncMainQueue(completionHandler))
        return request
    }
    
    /// Deletes a list of records using the `_id` of the records.
    @discardableResult
    open func removeById(_ ids: [String], writePolicy: WritePolicy? = nil, completionHandler: IntCompletionHandler?) -> Request {
        precondition(ids.count > 0)
        let query = Query(format: "\(T.entityIdProperty()) IN %@", ids as AnyObject)
        return remove(query, writePolicy: writePolicy, completionHandler: completionHandler)
    }
    
    /// Deletes a list of records that matches with the query passed by parameter.
    @discardableResult
    open func remove(_ query: Query = Query(), writePolicy: WritePolicy? = nil, completionHandler: IntCompletionHandler?) -> Request {
        let writePolicy = writePolicy ?? self.writePolicy
        let operation = RemoveByQueryOperation<T>(query: Query(query: query, persistableType: T.self), writePolicy: writePolicy, sync: sync, cache: cache, client: client)
        let request = operation.execute(dispatchAsyncMainQueue(completionHandler))
        return request
    }
    
    /// Deletes all the records.
    @discardableResult
    open func removeAll(_ writePolicy: WritePolicy? = nil, completionHandler: IntCompletionHandler?) -> Request {
        return remove(writePolicy: writePolicy, completionHandler: completionHandler)
    }
    
    /// Sends to the backend all the pending records in the local cache.
    @discardableResult
    open func push(timeout: TimeInterval? = nil, completionHandler: UIntErrorTypeArrayCompletionHandler? = nil) -> Request {
        let completionHandler = dispatchAsyncMainQueue(completionHandler)
        if type == .network {
            completionHandler?(nil, [Error.invalidDataStoreType])
            return LocalRequest()
        }
        
        let operation = PushOperation<T>(sync: sync, cache: cache, client: client)
        let request = operation.execute(timeout: timeout, completionHandler: completionHandler)
        return request
    }
    
    /// Gets the records from the backend that matches with the query passed by parameter and saves locally in the local cache.
    @discardableResult
    open func pull(_ query: Query = Query(), deltaSet: Bool? = nil, completionHandler: DataStore<T>.ArrayCompletionHandler? = nil) -> Request {
        let completionHandler = dispatchAsyncMainQueue(completionHandler)
        if type == .network {
            completionHandler?(nil, Error.invalidDataStoreType)
            return LocalRequest()
        }
        
        if self.syncCount() > 0 {
            completionHandler?(nil, Error.invalidOperation(description: "You must push all pending sync items before new data is pulled. Call push() on the data store instance to push pending items, or purge() to remove them."))
            return LocalRequest()
        }
        
        let deltaSet = deltaSet ?? self.deltaSet
        let operation = PullOperation<T>(query: Query(query: query, persistableType: T.self), deltaSet: deltaSet, readPolicy: .forceNetwork, cache: cache, client: client)
        let request = operation.execute(completionHandler)
        return request
    }
    
    /// Returns the number of changes not synced yet.
    open func syncCount() -> UInt {
        if let sync = sync {
            return UInt(sync.pendingOperations().count)
        }
        return 0
    }
    
    /// Calls `push` and then `pull` methods, so it sends all the pending records in the local cache and then gets the records from the backend and saves locally in the local cache.
    @discardableResult
    open func sync(_ query: Query = Query(), deltaSet: Bool? = nil, completionHandler: UIntArrayCompletionHandler? = nil) -> Request {
        let completionHandler = dispatchAsyncMainQueue(completionHandler)
        if type == .network {
            completionHandler?(nil, nil, [Error.invalidDataStoreType])
            return LocalRequest()
        }
        
        let requests = MultiRequest()
        let request = push() { count, errors in
            if let count = count , errors == nil || errors!.isEmpty {
                let deltaSet = deltaSet ?? self.deltaSet
                let request = self.pull(query, deltaSet: deltaSet) { results, error in
                    completionHandler?(count, results, error != nil ? [error!] : nil)
                }
                requests.addRequest(request)
            } else {
                completionHandler?(count, nil, errors)
            }
        }
        requests.addRequest(request)
        return requests
    }
    
    /// Deletes all the pending changes in the local cache.
    @discardableResult
    open func purge(_ query: Query = Query(), completionHandler: DataStore<T>.IntCompletionHandler? = nil) -> Request {
        let completionHandler = dispatchAsyncMainQueue(completionHandler)
        
        if type == .network {
            completionHandler?(nil, Error.invalidDataStoreType)
            return LocalRequest()
        }
        
        let executor = Executor()
        
        let operation = PurgeOperation<T>(sync: sync, cache: cache, client: client)
        let request = operation.execute { (count, error: Swift.Error?) -> Void in
            if let count = count {
                executor.execute {
                    self.pull(query) { (results, error) -> Void in
                        completionHandler?(count, error)
                    }
                }
            } else {
                completionHandler?(count, error)
            }
        }
        return request
    }
    
    //MARK: Dispatch Async Main Queue
    
    fileprivate func dispatchAsyncMainQueue<R, E>(_ completionHandler: ((R?, E?) -> Void)?) -> ((R?, E?) -> Void)? {
        if let completionHandler = completionHandler {
            return { (obj1: R?, obj2: E?) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    completionHandler(obj1, obj2)
                })
            }
        }
        return nil
    }
    
    fileprivate func dispatchAsyncMainQueue<R1, R2, R3>(_ completionHandler: ((R1?, R2?, R3?) -> Void)?) -> ((R1?, R2?, R3?) -> Void)? {
        if let completionHandler = completionHandler {
            return { (obj1: R1?, obj2: R2?, obj3: R3?) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    completionHandler(obj1, obj2, obj3)
                })
            }
        }
        return nil
    }
    
    /// Clear all data for all collections.
    open class func clearCache(_ tag: String? = nil, client: Client = sharedClient) {
        client.cacheManager.clearAll(tag)
    }

    /// Clear all data for the collection attached to the DataStore.
    open func clearCache() {
        cache?.removeAllEntities()
        sync?.removeAllPendingOperations()
    }

}
