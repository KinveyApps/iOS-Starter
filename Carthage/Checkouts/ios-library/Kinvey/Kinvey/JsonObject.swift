//
//  JsonObject.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-09.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public typealias JsonDictionary = [String : Any]

/// Protocol used to serialize and deserialize JSON objects into objects.
@objc(KNVJsonObject)
public protocol JsonObject {
    
    /// Deserialize JSON object into object.
    @objc optional func fromJson(_ json: JsonDictionary)
    
    /// Serialize object to JSON.
    @objc optional func toJson() -> JsonDictionary

}

extension JsonObject {
    
    subscript(key: String) -> Any? {
        get {
            guard let this = self as? NSObject else {
                return nil
            }
            return this.value(forKey: key)
        }
        set {
            guard let this = self as? NSObject else {
                return
            }
            this.setValue(newValue, forKey: key)
        }
    }
    
    internal func _toJson() -> JsonDictionary {
        var json = JsonDictionary()
        let properties = ObjCRuntime.propertyNames(type(of: self))
        for property in properties {
            json[property] = self[property]
        }
        return json
    }
    
    internal func _fromJson(_ json: JsonDictionary) {
        for keyPair in json {
            self[keyPair.0] = keyPair.1
        }
    }
    
}

extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {
    
    fileprivate func translateValue(_ value: Any) -> Any {
        if let query = value as? Query, let predicate = query.predicate, let value = try? MongoDBPredicateAdaptor.queryDict(from: predicate) {
            return value
        } else if let dictionary = value as? JsonDictionary {
            let translated: JsonDictionary = dictionary.map { (key, value) -> (String, Any) in
                return (key, translateValue(value))
            }
            return translated
        } else if let array = value as? Array<Any> {
            return array.map({ (item) -> Any in
                return translateValue(item)
            })
        }
        return value
    }
    
    func toJson() -> JsonDictionary {
        var result = JsonDictionary()
        for item in self {
            result[item.0 as! String] = translateValue(item.1)
        }
        return result
    }
    
}
