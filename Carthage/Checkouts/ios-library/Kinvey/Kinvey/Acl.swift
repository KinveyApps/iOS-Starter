//
//  Acl.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

class AclTransformType: TransformType {
    
    typealias Object = [String]
    typealias JSON = String
    
    func transformFromJSON(_ value: Any?) -> [String]? {
        if let value = value as? String,
            let data = value.data(using: String.Encoding.utf8),
            let json = try? JSONSerialization.jsonObject(with: data, options: []),
            let array = json as? [String]
        {
            return array
        }
        return nil
    }
    
    func transformToJSON(_ value: [String]?) -> String? {
        if let value = value,
            let data = try? JSONSerialization.data(withJSONObject: value, options: []),
            let json = String(data: data, encoding: String.Encoding.utf8)
        {
            return json
        }
        return nil
    }

}

/// This class represents the ACL (Access Control List) for a record.
public final class Acl: Object, Mappable, BuilderType {
    
    static let CreatorKey = "creator"
    static let GlobalReadKey = "gr"
    static let GlobalWriteKey = "gw"
    static let ReadersKey = "r"
    static let WritersKey = "w"
    
    /// The `userId` of the `User` used to create the record.
    open dynamic var creator: String?
    
    /// The `userId` of the `User` used to create the record.
    open let globalRead = RealmOptional<Bool>()
    
    /// The `userId` of the `User` used to create the record.
    open let globalWrite = RealmOptional<Bool>()
    
    fileprivate dynamic var readersValue: String?
    
    /// Specifies the list of user _ids that are explicitly allowed to read the entity.
    open var readers: [String]? {
        get {
            if let value = readersValue,
                let array = AclTransformType().transformFromJSON(value as AnyObject?)
            {
                return array
            }
            return nil
        }
        set {
            if let value = newValue {
                readersValue = AclTransformType().transformToJSON(value)
            } else {
                readersValue = nil
            }
        }
    }
    
    fileprivate dynamic var writersValue: String?
    
    /// Specifies the list of user _ids that are explicitly allowed to modify the entity.
    open var writers: [String]? {
        get {
            if let value = writersValue,
                let array = AclTransformType().transformFromJSON(value as AnyObject?)
            {
                return array
            }
            return nil
        }
        set {
            if let value = newValue {
                writersValue = AclTransformType().transformToJSON(value)
            } else {
                writersValue = nil
            }
        }
    }
    
    /// Constructs an Acl instance with the `userId` of the `User` used to create the record.
    public init(
        creator: String,
        globalRead: Bool? = nil,
        globalWrite: Bool? = nil,
        readers: [String]? = nil,
        writers: [String]? = nil
    ) {
        self.creator = creator
        self.globalRead.value = globalRead
        self.globalWrite.value = globalWrite
        super.init()
        self.readers = readers
        self.writers = writers
    }
    
    /// Constructor that validates if the map contains at least the creator.
    public required convenience init?(map: Map) {
        var creator: String?
        
        creator <- map[Acl.CreatorKey]
        
        guard let creatorValue = creator else {
            self.init()
            return nil
        }
        
        self.init(creator: creatorValue)
    }
    
    /// Default Constructor.
    public required init() {
        super.init()
    }
    
    /**
     WARNING: This is an internal initializer not intended for public use.
     :nodoc:
     */
    public required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    /**
     WARNING: This is an internal initializer not intended for public use.
     :nodoc:
     */
    public required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    /// This function is where all variable mappings should occur. It is executed by Mapper during the mapping (serialization and deserialization) process.
    open func mapping(map: Map) {
        creator <- map[Acl.CreatorKey]
        globalRead.value <- map[Acl.GlobalReadKey]
        globalWrite.value <- map[Acl.GlobalWriteKey]
        readers <- (map[Acl.ReadersKey], AclTransformType())
        writers <- (map[Acl.WritersKey], AclTransformType())
    }
    
    /**
     WARNING: This is an internal initializer not intended for public use.
     :nodoc:
     */
    open override class func ignoredProperties() -> [String] {
        return ["readers", "writers"]
    }

}
