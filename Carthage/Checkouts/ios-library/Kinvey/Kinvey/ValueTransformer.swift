//
//  ValueTransformer.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-01.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import ObjectiveC

protocol NSValueTransformerReverse {
    
    static func reverseTransformedValueClass() -> AnyClass
    
    func transformedValue(_ value: Any?) -> Any?
    func reverseTransformedValue(_ value: Any?) -> Any?
    
}

extension NSValueTransformerReverse where Self: Foundation.ValueTransformer {
    
    func isReverse() -> Bool {
        return false
    }
    
    static func allowsReverseTransformation() -> Bool {
        return true
    }
    
    func transformValue<T>(value: AnyObject?, destinationType: T.Type) -> T? {
        let valueTransformer = (self as Foundation.ValueTransformer)
        return type(of: valueTransformer).transformedValueClass() == destinationType ? valueTransformer.transformedValue(value) as? T : valueTransformer.reverseTransformedValue(value) as? T
    }
    
}

class ValueTransformer: Foundation.ValueTransformer {
    
    private static let separator = "->"
    private static var classTransformer = [String : NSValueTransformerReverse]()
    private static var reverseClassTransformer = [String : NSValueTransformerReverse]()
    
    private class func valueTransformerName(fromClass: String, toClass: String) -> String {
        return "\(fromClass)\(separator)\(toClass)"
    }
    
    class func setValueTransformer<T: Foundation.ValueTransformer>(transformer: T) where T: NSValueTransformerReverse {
        let transformedValueClass = NSStringFromClass(T.transformedValueClass())
        let reverseTransformedValueClass = NSStringFromClass(T.reverseTransformedValueClass())
        self.classTransformer[valueTransformerName(fromClass: transformedValueClass, toClass: reverseTransformedValueClass)] = transformer
        self.reverseClassTransformer[valueTransformerName(fromClass: reverseTransformedValueClass, toClass: transformedValueClass)] = transformer
        setValueTransformer(transformer, forName: NSValueTransformerName(NSStringFromClass(type(of: transformer).self)))
    }
    
    class func valueTransformer(fromClass: AnyClass, toClass: AnyClass) -> NSValueTransformerReverse? {
        var fromClass = NSStringFromClass(fromClass)
        let toClass = NSStringFromClass(toClass)
        var valueTransformer: NSValueTransformerReverse?
        repeat {
            valueTransformer = classTransformer[valueTransformerName(fromClass: fromClass, toClass: toClass)] ?? reverseClassTransformer[valueTransformerName(fromClass: fromClass, toClass: toClass)]
            if let cls = NSClassFromString(fromClass), let superClass = class_getSuperclass(cls) {
                fromClass = NSStringFromClass(superClass)
            } else {
                break
            }
        } while (valueTransformer == nil)
        return valueTransformer
    }
    
}
