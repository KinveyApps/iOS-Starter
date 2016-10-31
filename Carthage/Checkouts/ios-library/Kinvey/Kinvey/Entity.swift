//
//  Entity.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-06-14.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

internal func StringFromClass(cls: AnyClass) -> String {
    var className = NSStringFromClass(cls)
    let regex = try! NSRegularExpression(pattern: "RLM.+_.+") // regex to catch Realm classnames like `RLMStandalone_`, `RLMUnmanaged_` or `RLMAccessor_`
    var nMatches = regex.numberOfMatches(in: className, range: NSRange(location: 0, length: className.characters.count))
    while nMatches > 0 {
        let classObj: AnyClass! = NSClassFromString(className)!
        let superClass: AnyClass! = class_getSuperclass(classObj)
        className = NSStringFromClass(superClass)
        nMatches = regex.numberOfMatches(in: className, range: NSRange(location: 0, length: className.characters.count))
    }
    return className
}

/// Base class for entity classes that are mapped to a collection in Kinvey.
open class Entity: Object, Persistable {
    
    /// Override this method and return the name of the collection for Kinvey.
    open class func collectionName() -> String {
        preconditionFailure("Method \(#function) must be overridden")
    }
    
    /// The `_id` property mapped in the Kinvey backend.
    public dynamic var entityId: String?
    
    /// The `_kmd` property mapped in the Kinvey backend.
    public dynamic var metadata: Metadata?
    
    /// The `_acl` property mapped in the Kinvey backend.
    public dynamic var acl: Acl?
    
    /// Constructor that validates if the map contains the required fields.
    public required init?(map: Map) {
        super.init()
    }
    
    /// Default Constructor.
    public required init() {
        super.init()
    }
    
    /**
     WARNING: This is an internal initializer not intended for public use.
     :nodoc:
     */
    public required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    /**
     WARNING: This is an internal initializer not intended for public use.
     :nodoc:
     */
    public required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    /// Override this method to tell how to map your own objects.
    open func propertyMapping(_ map: Map) {
        entityId <- ("entityId", map[PersistableIdKey])
        metadata <- ("metadata", map[PersistableMetadataKey])
        acl <- ("acl", map[PersistableAclKey])
    }
    
    /**
     WARNING: This is an internal initializer not intended for public use.
     :nodoc:
     */
    open override class func primaryKey() -> String? {
        return entityIdProperty()
    }
    
    /**
     WARNING: This is an internal initializer not intended for public use.
     :nodoc:
     */
    open override class func ignoredProperties() -> [String] {
        var properties = [String]()
        for property in ObjCRuntime.properties(self) {
            if !(ObjCRuntime.type(property.1, isSubtypeOf: NSDate.self) ||
                ObjCRuntime.type(property.1, isSubtypeOf: NSData.self) ||
                ObjCRuntime.type(property.1, isSubtypeOf: NSString.self) ||
                ObjCRuntime.type(property.1, isSubtypeOf: RLMObjectBase.self) ||
                ObjCRuntime.type(property.1, isSubtypeOf: RLMOptionalBase.self) ||
                ObjCRuntime.type(property.1, isSubtypeOf: RLMListBase.self) ||
                ObjCRuntime.type(property.1, isSubtypeOf: RLMCollection.self))
            {
                properties.append(property.0)
            }
        }
        return properties
    }
    
    /// This function is where all variable mappings should occur. It is executed by Mapper during the mapping (serialization and deserialization) process.
    public func mapping(map: Map) {
        let originalThread = Thread.current
        let runningMapping = originalThread.threadDictionary[KinveyMappingTypeKey] != nil
        if runningMapping {
            let operationQueue = OperationQueue()
            operationQueue.name = "Kinvey Property Mapping"
            operationQueue.maxConcurrentOperationCount = 1
            operationQueue.addOperation {
                let className = StringFromClass(cls: type(of: self))
                Thread.current.threadDictionary[KinveyMappingTypeKey] = [className : [String : String]()]
                self.propertyMapping(map)
                originalThread.threadDictionary[KinveyMappingTypeKey] = Thread.current.threadDictionary[KinveyMappingTypeKey]
            }
            operationQueue.waitUntilAllOperationsAreFinished()
        } else {
            self.propertyMapping(map)
        }
    }
    
}
