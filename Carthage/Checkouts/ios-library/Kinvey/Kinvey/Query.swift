//
//  Query.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

/// Class that represents a query including filters and sorts.
@objc(KNVQuery)
public final class Query: NSObject, BuilderType {
    
    /// Fields to be included in the results of the query.
    open var fields: Set<String>?
    
    /// `NSPredicate` used to filter records.
    open var predicate: NSPredicate?
    
    /// Array of `NSSortDescriptor`s used to sort records.
    open var sortDescriptors: [NSSortDescriptor]?
    
    /// Skip a certain amount of records in the results of the query.
    open var skip: Int?
    
    /// Impose a limit of records in the results of the query.
    open var limit: Int?
    
    fileprivate func translateExpression(_ expression: NSExpression) -> NSExpression {
        switch expression.expressionType {
        case .keyPath:
            var keyPath = expression.keyPath
            var persistableType = self.persistableType
            if keyPath.contains(".") {
                var keyPaths = [String]()
                for item in keyPath.components(separatedBy: ".") {
                    keyPaths.append(persistableType?.propertyMapping(item) ?? item)
                    if let persistableTypeTmp = persistableType {
                        persistableType = ObjCRuntime.typeForPropertyName(persistableTypeTmp as! AnyClass, propertyName: item) as? Persistable.Type
                    }
                }
                keyPath = keyPaths.joined(separator: ".")
            } else if let translatedKeyPath = persistableType?.propertyMapping(keyPath) {
                keyPath = translatedKeyPath
            }
            return NSExpression(forKeyPath: keyPath)
        default:
            return expression
        }
    }
    
    fileprivate func translatePredicate(_ predicate: NSPredicate) -> NSPredicate {
        if let predicate = predicate as? NSComparisonPredicate {
            return NSComparisonPredicate(
                leftExpression: translateExpression(predicate.leftExpression),
                rightExpression: translateExpression(predicate.rightExpression),
                modifier: predicate.comparisonPredicateModifier,
                type: predicate.predicateOperatorType,
                options: predicate.options
            )
        } else if let predicate = predicate as? NSCompoundPredicate {
            var subpredicates = [NSPredicate]()
            for predicate in predicate.subpredicates as! [NSPredicate] {
                subpredicates.append(translatePredicate(predicate))
            }
            return NSCompoundPredicate(type: predicate.compoundPredicateType, subpredicates: subpredicates)
        }
        return predicate
    }
    
    func isEmpty() -> Bool {
        return self.predicate == nil && self.sortDescriptors == nil
    }
    
    fileprivate var queryStringEncoded: String? {
        get {
            if let predicate = predicate {
                let translatedPredicate = translatePredicate(predicate)
                let queryObj = try! MongoDBPredicateAdaptor.queryDict(from: translatedPredicate)
                
                let data = try! JSONSerialization.data(withJSONObject: queryObj, options: [])
                var queryStr = String(data: data, encoding: String.Encoding.utf8)!
                queryStr = queryStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                return queryStr.trimmingCharacters(in: CharacterSet.whitespaces)
            }
            
            return nil
        }
    }
    
    internal var queryParams: [String : String] {
        get {
            var queryParams = [String : String]()
            
            if let queryParam = queryStringEncoded , !queryParam.isEmpty {
                queryParams["query"] = queryParam
            }
            
            if let sortDescriptors = sortDescriptors {
                var sorts = [String : Int]()
                for sortDescriptor in sortDescriptors {
                    sorts[sortDescriptor.key!] = sortDescriptor.ascending ? 1 : -1
                }
                let data = try! JSONSerialization.data(withJSONObject: sorts)
                queryParams["sort"] = String(data: data, encoding: String.Encoding.utf8)!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            }
            
            if let fields = fields {
                queryParams["fields"] = fields.joined(separator: ",").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            }
            
            if let skip = skip {
                queryParams["skip"] = String(skip)
            }
            
            if let limit = limit {
                queryParams["limit"] = String(limit)
            }
            
            return queryParams
        }
    }
    
    var persistableType: Persistable.Type?
    
    init(predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?, persistableType: Persistable.Type? = nil) {
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        self.persistableType = persistableType
    }
    
    convenience init(query: Query, persistableType: Persistable.Type) {
        self.init(query) {
            $0.persistableType = persistableType
        }
    }
    
    /// Default Constructor.
    public override convenience required init() {
        self.init(predicate: nil, sortDescriptors: nil, persistableType: nil)
    }
    
    /// Constructor using a `NSPredicate` to filter records.
    public convenience init(predicate: NSPredicate) {
        self.init(predicate: predicate, sortDescriptors: nil, persistableType: nil)
    }
    
    /// Constructor using an array of `NSSortDescriptor`s to sort records.
    public convenience init(sortDescriptors: [NSSortDescriptor]) {
        self.init(predicate: nil, sortDescriptors: sortDescriptors, persistableType: nil)
    }
    
    /// Constructor using a `NSPredicate` to filter records and an array of `NSSortDescriptor`s to sort records.
    public convenience init(predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]? = nil) {
        self.init(predicate: predicate, sortDescriptors: sortDescriptors, persistableType: nil)
    }
    
    /// Constructor using a similar way to construct a `NSPredicate`.
    public convenience init(format: String, _ args: Any...) {
        self.init(format: format, argumentArray: args)
    }
    
    /// Constructor using a similar way to construct a `NSPredicate`.
    public convenience init(format: String, args: CVarArg) {
        self.init(predicate: NSPredicate(format: format, args))
    }
    
    /// Constructor using a similar way to construct a `NSPredicate`.
    public convenience init(format: String, argumentArray: [Any]?) {
        self.init(predicate: NSPredicate(format: format, argumentArray: argumentArray))
    }
    
    /// Constructor using a similar way to construct a `NSPredicate`.
    public convenience init(format: String, arguments: CVaListPointer) {
        self.init(predicate: NSPredicate(format: format, arguments: arguments))
    }
    
    /// Copy Constructor.
    public convenience init(_ query: Query) {
        self.init() {
            $0.fields = query.fields
            $0.predicate = query.predicate
            $0.sortDescriptors = query.sortDescriptors
            $0.skip = query.skip
            $0.limit = query.limit
            $0.persistableType = query.persistableType
        }
    }
    
    /// Copy Constructor.
    public convenience init(_ query: Query, _ block: ((Query) -> Void)) {
        self.init(query)
        block(self)
    }
    
    let sortLock = NSLock()
    
    fileprivate func addSort(_ property: String, ascending: Bool) {
        sortLock.lock()
        if sortDescriptors == nil {
            sortDescriptors = []
        }
        sortLock.unlock()
        sortDescriptors!.append(NSSortDescriptor(key: property, ascending: ascending))
    }
    
    /// Adds ascending properties to be sorted.
    open func ascending(_ properties: String...) {
        for property in properties {
            addSort(property, ascending: true)
        }
    }
    
    /// Adds descending properties to be sorted.
    open func descending(_ properties: String...) {
        for property in properties {
            addSort(property, ascending: false)
        }
    }

}

extension Dictionary where Key: ExpressibleByStringLiteral, Value: ExpressibleByStringLiteral {
    
    internal var urlQueryEncoded: String {
        get {
            var queryParams = [String]()
            for (key, value) in self {
                queryParams.append("\(key)=\(value)")
            }
            return queryParams.joined(separator: "&")
        }
    }
    
}

@objc(__KNVQuery)
internal class __KNVQuery: NSObject {
    
    class func query(_ query: Query, persistableType: Persistable.Type) -> Query {
        return Query(query: query, persistableType: persistableType)
    }
    
}
