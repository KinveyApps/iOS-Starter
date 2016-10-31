//
//  ObjCRuntime.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-05-10.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import ObjectiveC

@objc(__KNVObjCRuntime)
internal class ObjCRuntime: NSObject {
    
    fileprivate override init() {
    }
    
    internal class func type(_ target: AnyClass, isSubtypeOf cls: AnyClass) -> Bool {
        if target == cls {
            return true
        }
        
        if let superCls = class_getSuperclass(target) {
            return type(superCls, isSubtypeOf: cls)
        }
        return false
    }
    
    internal class func types(forType cls: AnyClass) -> [AnyClass] {
        var result = [AnyClass]()
        var classCount: UInt32 = 0
        let classList = objc_copyClassList(&classCount)
        for i in 0..<Int(classCount) {
            if let subCls = classList?[i] , type(subCls, isSubtypeOf: cls) {
                result.append(subCls)
            }
        }
        return result
    }
    
    internal class func propertyNamesForTypeInClass(_ cls: AnyClass, type: AnyClass) -> [String]? {
        var propertyNames = [String]()
        let regexClassName = try! NSRegularExpression(pattern: "@\"(\\w+)(?:<(\\w+)>)?\"", options: [])
        var propertyCount = UInt32(0)
        let properties = class_copyPropertyList(cls, &propertyCount)
        defer { free(properties) }
        for i in UInt32(0) ..< propertyCount {
            let property = properties?[Int(i)]
            if let propertyName = String(validatingUTF8: property_getName(property)) {
                var attributeCount = UInt32(0)
                let attributes = property_copyAttributeList(property, &attributeCount)
                defer { free(attributes) }
                for x in UInt32(0) ..< attributeCount {
                    let attribute = attributes?[Int(x)]
                    if let attributeName = String(validatingUTF8: (attribute?.name)!) , attributeName == "T",
                        let attributeValue = String(validatingUTF8: (attribute?.value)!),
                        let textCheckingResult = regexClassName.matches(in: attributeValue, options: [], range: NSMakeRange(0, attributeValue.characters.count)).first
                    {
                        let attributeValueNSString = attributeValue as NSString
                        let propertyTypeName = attributeValueNSString.substring(with: textCheckingResult.rangeAt(1))
                        if let propertyTypeNameClass = NSClassFromString(propertyTypeName) , propertyTypeNameClass == type {
                            propertyNames.append(propertyName)
                        }
                    }
                }
            }
        }
        return propertyNames.isEmpty ? nil : propertyNames
    }
    
    internal class func typeForPropertyName(_ cls: AnyClass, propertyName: String) -> AnyClass? {
        let regexClassName = try! NSRegularExpression(pattern: "@\"(\\w+)(?:<(\\w+)>)?\"", options: [])
        
        let property = class_getProperty(cls, propertyName)
        let attributeValueCString = property_copyAttributeValue(property, "T")
        defer { free(attributeValueCString) }
        if let attributeValue = String(validatingUTF8: attributeValueCString!),
            let textCheckingResult = regexClassName.matches(in: attributeValue, options: [], range: NSMakeRange(0, attributeValue.characters.count)).first
        {
            let attributeValueNSString = attributeValue as NSString
            let propertyTypeName = attributeValueNSString.substring(with: textCheckingResult.rangeAt(1))
            return NSClassFromString(propertyTypeName)
        }
        return nil
    }
    
    internal class func properties(_ cls: AnyClass) -> [String : AnyClass] {
        let regexClassName = try! NSRegularExpression(pattern: "@\"(\\w+)(?:<(\\w+)>)?\"", options: [])
        var cls: AnyClass? = cls
        var results = [String : AnyClass]()
        while cls != nil {
            var propertyCount = UInt32(0)
            let properties = class_copyPropertyList(cls, &propertyCount)
            defer { free(properties) }
            for i in UInt32(0) ..< propertyCount {
                let property = properties?[Int(i)]
                if let propertyName = String(validatingUTF8: property_getName(property))
                {
                    var attributeCount = UInt32(0)
                    let attributes = property_copyAttributeList(property, &attributeCount)
                    defer { free(attributes) }
                    for x in UInt32(0) ..< attributeCount {
                        let attribute = attributes?[Int(x)]
                        if let attributeName = String(validatingUTF8: (attribute?.name)!) , attributeName == "T",
                            let attributeValue = String(validatingUTF8: (attribute?.value)!),
                            let textCheckingResult = regexClassName.matches(in: attributeValue, options: [], range: NSMakeRange(0, attributeValue.characters.count)).first
                        {
                            let attributeValueNSString = attributeValue as NSString
                            let propertyTypeName = attributeValueNSString.substring(with: textCheckingResult.rangeAt(1))
                            if let propertyTypeNameClass = NSClassFromString(propertyTypeName) {
                                results[propertyName] = propertyTypeNameClass
                                break
                            }
                        }
                    }
                }
            }
            if cls == Entity.self {
                cls = nil
            } else {
                cls = class_getSuperclass(cls)
            }
        }
        return results
    }
    
    internal class func propertyNames(_ cls: AnyClass) -> [String] {
        let regexClassName = try! NSRegularExpression(pattern: "@\"(\\w+)(?:<(\\w+)>)?\"", options: [])
        var cls: AnyClass? = cls
        var results = [String]()
        while cls != nil {
            var propertyCount = UInt32(0)
            let properties = class_copyPropertyList(cls, &propertyCount)
            defer { free(properties) }
            for i in UInt32(0) ..< propertyCount {
                let property = properties?[Int(i)]
                if let propertyName = String(validatingUTF8: property_getName(property))
                {
                    results.append(propertyName)
                }
            }
            if cls == Entity.self {
                cls = nil
            } else {
                cls = class_getSuperclass(cls)
            }
        }
        return results
    }
    
    internal class func propertyDefaultValues(_ cls: AnyClass) -> [String : Any] {
        let regexClassName = try! NSRegularExpression(pattern: "@\"(\\w+)(?:<(\\w+)>)?\"", options: [])
        var cls: AnyClass? = cls
        var results = [String : Any]()
        while cls != nil {
            var propertyCount = UInt32(0)
            let properties = class_copyPropertyList(cls, &propertyCount)
            defer { free(properties) }
            for i in UInt32(0) ..< propertyCount {
                let property = properties?[Int(i)]
                if let propertyName = String(validatingUTF8: property_getName(property))
                {
                    var attributeCount = UInt32(0)
                    let attributes = property_copyAttributeList(property, &attributeCount)
                    defer { free(attributes) }
                    for x in UInt32(0) ..< attributeCount {
                        let attribute = attributes?[Int(x)]
                        if let attributeName = String(validatingUTF8: (attribute?.name)!) , attributeName == "T",
                            let attributeValue = String(validatingUTF8: (attribute?.value)!)
                        {
                            if let textCheckingResult = regexClassName.matches(in: attributeValue, options: [], range: NSMakeRange(0, attributeValue.characters.count)).first {
                                let attributeValueNSString = attributeValue as NSString
                                let propertyTypeName = attributeValueNSString.substring(with: textCheckingResult.rangeAt(1))
                                if let propertyTypeNameClass = NSClassFromString(propertyTypeName) {
                                    results[propertyName] = (propertyTypeNameClass as! NSObject.Type).init()
                                    break
                                }
                            } else if attributeValue.characters.count > 0 {
                                switch attributeValue.characters.first! {
                                case "q":
                                    results[propertyName] = Int(0)
                                    break
                                default:
                                    break
                                }
                            }
                        }
                    }
                }
            }
            if cls == Entity.self {
                cls = nil
            } else {
                cls = class_getSuperclass(cls)
            }
        }
        return results
    }
    
}
