  //
//  Persistable.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import CoreData

/// Protocol that turns a NSObject into a persistable class to be used in a `DataStore`.
public protocol Persistable: Mappable {
    
    /// Provides the collection name to be matched with the backend.
    static func collectionName() -> String
    
    /// Default Constructor.
    init()
    
    /// Override this method to tell how to map your own objects.
    mutating func propertyMapping(_ map: Map)
    
}

private func kinveyMappingType(left: String, right: String) {
    let currentThread = Thread.current
    if var kinveyMappingType = currentThread.threadDictionary[KinveyMappingTypeKey] as? [String : [String : String]],
        let className = kinveyMappingType.first?.0,
        var classMapping = kinveyMappingType[className]
    {
        classMapping[left] = right
        kinveyMappingType[className] = classMapping
        currentThread.threadDictionary[KinveyMappingTypeKey] = kinveyMappingType
    }
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- <T>(left: inout T, right: (String, Map)) {
    kinveyMappingType(left: right.0, right: right.1.currentKey!)
    left <- right.1
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- <T>(left: inout T?, right: (String, Map)) {
    kinveyMappingType(left: right.0, right: right.1.currentKey!)
    left <- right.1
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- <T>(left: inout T!, right: (String, Map)) {
    kinveyMappingType(left: right.0, right: right.1.currentKey!)
    left <- right.1
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- <T: Mappable>(left: inout T, right: (String, Map)) {
    kinveyMappingType(left: right.0, right: right.1.currentKey!)
    left <- right.1
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- <T: Mappable>(left: inout T?, right: (String, Map)) {
    kinveyMappingType(left: right.0, right: right.1.currentKey!)
    left <- right.1
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- <T: Mappable>(left: inout T!, right: (String, Map)) {
    kinveyMappingType(left: right.0, right: right.1.currentKey!)
    left <- right.1
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- <Transform: TransformType>(left: inout Transform.Object, right: (String, Map, Transform)) {
    kinveyMappingType(left: right.0, right: right.1.currentKey!)
    left <- (right.1, right.2)
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- <Transform: TransformType>(left: inout Transform.Object?, right: (String, Map, Transform)) {
    kinveyMappingType(left: right.0, right: right.1.currentKey!)
    left <- (right.1, right.2)
}

/// Override operator used during the `propertyMapping(_:)` method.
public func <- <Transform: TransformType>(left: inout Transform.Object!, right: (String, Map, Transform)) {
    kinveyMappingType(left: right.0, right: right.1.currentKey!)
    left <- (right.1, right.2)
}

internal let KinveyMappingTypeKey = "Kinvey Mapping Type"

extension Persistable {
    
    static func propertyMappingReverse() -> [String : [String]] {
        var results = [String : [String]]()
        for keyPair in propertyMapping() {
            var properties = results[keyPair.1]
            if properties == nil {
                properties = [String]()
            }
            properties!.append(keyPair.0)
            results[keyPair.1] = properties
        }
        return results
    }
    
    static func propertyMapping() -> [String : String] {
        let currentThread = Thread.current
        let className = StringFromClass(cls: self as! AnyClass)
        currentThread.threadDictionary[KinveyMappingTypeKey] = [className : [String : String]()]
        let obj = self.init()
        let _ = obj.toJSON()
        if let kinveyMappingType = currentThread.threadDictionary[KinveyMappingTypeKey] as? [String : [String : String]],
            let kinveyMappingClassType = kinveyMappingType[className]
        {
            return kinveyMappingClassType
        }
        return [:]
    }
    
    static func propertyMapping(_ propertyName: String) -> String? {
        return propertyMapping()[propertyName]
    }
    
    internal static func entityIdProperty() -> String {
        return propertyMappingReverse()[PersistableIdKey]!.last!
    }
    
    internal static func aclProperty() -> String? {
        return propertyMappingReverse()[PersistableAclKey]?.last
    }
    
    internal static func metadataProperty() -> String? {
        return propertyMappingReverse()[PersistableMetadataKey]?.last
    }
    
}

extension Persistable where Self: NSObject {
    
    public subscript(key: String) -> Any? {
        get {
            return self.value(forKey: key)
        }
        set {
            self.setValue(newValue, forKey: key)
        }
    }
    
    internal var entityId: String? {
        get {
            return self[type(of: self).entityIdProperty()] as? String
        }
        set {
            self[type(of: self).entityIdProperty()] = newValue
        }
    }
    
    internal var acl: Acl? {
        get {
            if let aclKey = type(of: self).aclProperty() {
                return self[aclKey] as? Acl
            }
            return nil
        }
        set {
            if let aclKey = type(of: self).aclProperty() {
                self[aclKey] = newValue
            }
        }
    }
    
    internal var metadata: Metadata? {
        get {
            if let kmdKey = type(of: self).metadataProperty() {
                return self[kmdKey] as? Metadata
            }
            return nil
        }
        set {
            if let kmdKey = type(of: self).metadataProperty() {
                self[kmdKey] = newValue
            }
        }
    }
    
}
