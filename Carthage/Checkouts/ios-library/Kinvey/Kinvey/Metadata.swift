//
//  Metadata.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

/// This class represents the metadata information for a record
public final class Metadata: Object, Mappable, BuilderType {
    
    /// Last Modification Time Key.
    open static let LmtKey = "lmt"
    
    /// Entity Creation Time Key.
    open static let EctKey = "ect"
    
    /// Last Read Time Key.
    internal static let LrtKey = "lrt"
    
    /// Authentication Token Key.
    open static let AuthTokenKey = "authtoken"
    
    internal dynamic var lmt: String?
    internal dynamic var ect: String?
    internal dynamic var lrt: Date = Date()
    
    /// Last Read Time
    open var lastReadTime: Date {
        get {
            return self.lrt
        }
        set {
            lrt = newValue
        }
    }
    
    /// Last Modification Time.
    open var lastModifiedTime: Date? {
        get {
            return self.lmt?.toDate()
        }
        set {
            lmt = newValue?.toString()
        }
    }
    
    /// Entity Creation Time.
    open var entityCreationTime: Date? {
        get {
            return self.ect?.toDate()
        }
        set {
            ect = newValue?.toString()
        }
    }
    
    /// Authentication Token.
    open internal(set) var authtoken: String?
    
    /// Constructor that validates if the map can be build a new instance of Metadata.
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
    
    /// This function is where all variable mappings should occur. It is executed by Mapper during the mapping (serialization and deserialization) process.
    open func mapping(map: Map) {
        lmt <- map[Metadata.LmtKey]
        ect <- map[Metadata.EctKey]
        authtoken <- map[Metadata.AuthTokenKey]
    }
    
    /**
     WARNING: This is an internal initializer not intended for public use.
     :nodoc:
     */
    open override class func ignoredProperties() -> [String] {
        return ["lastModifiedTime", "entityCreationTime", "lastReadTime"]
    }

}
