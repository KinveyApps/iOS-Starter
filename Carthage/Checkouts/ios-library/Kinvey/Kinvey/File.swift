//
//  File.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-04.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import RealmSwift
import Realm

/// Class that represents a file in the backend holding all metadata of the file, but don't hold the data itself.
open class File: Object {
    
    /// `_id` property of the file.
    open dynamic var fileId: String?
    
    /// `_filename` property of the file.
    open dynamic var fileName: String?
    
    /// `size` property of the file.
    open let size = RealmOptional<Int64>()
    
    /// `mimeType` property of the file.
    open dynamic var mimeType: String?
    
    /// `_public` property of the file, which represents if the file is accessible without need of credentials.
    open dynamic var publicAccessible = false
    
    /// `_acl` property of the file.
    open dynamic var acl: Acl?
    
    /// `_kmd` property of the file.
    open dynamic var metadata: Metadata?
    
    /// Temporary download URL String of the file.
    open dynamic var download: String?
    
    /// Temporary download URL of the file.
    open dynamic var downloadURL: URL? {
        get {
            if let download = download {
                return URL(string: download)
            }
            return nil
        }
        set {
            download = newValue?.absoluteString
        }
    }
    
    /// Expiration data of the `downloadURL`.
    open dynamic var expiresAt: Date?
    
    dynamic var etag: String?
    
    dynamic var path: String?
    
    dynamic var pathURL: URL? {
        get {
            if let path = path {
                return URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
            }
            return nil
        }
        set {
            path = newValue?.path
        }
    }
    
    /// Temporary upload URL of the file.
    var uploadURL: URL?
    
    /// Headers needed to submit the request to the `uploadURL`.
    var uploadHeaders: [String : String]?
    
    var resumeDownloadData: Data?
    
    /// Default Constructor
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
    
    /// Constructor of a file instance.
    public init(_ block: (File) -> Void) {
        super.init()
        block(self)
    }
    
    /**
     WARNING: This is an internal initializer not intended for public use.
     :nodoc:
     */
    open override class func primaryKey() -> String? {
        return "fileId"
    }
    
    /**
     WARNING: This is an internal initializer not intended for public use.
     :nodoc:
     */
    open override class func ignoredProperties() -> [String] {
        return [
            "downloadURL",
            "pathURL",
            "uploadURL",
            "uploadHeaders",
            "resumeDownloadData"
        ]
    }
    
}
