//
//  Client.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

private let lockEncryptionKey = NSLock()

/// This class provides a representation of a Kinvey environment holding App ID and App Secret. Please *never* use a Master Secret in a client application.
@objc(__KNVClient)
open class Client: NSObject, NSCoding, Credential {

    /// Shared client instance for simplicity. Use this instance if *you don't need* to handle with multiple Kinvey environments.
    open static let sharedClient = Client()
    
    typealias UserChangedListener = (User?) -> Void
    var userChangedListener: UserChangedListener?
    
    /// It holds the `User` instance after logged in. If this variable is `nil` means that there's no logged user, which is necessary for some calls to in a Kinvey environment.
    open internal(set) var activeUser: User? {
        willSet (newActiveUser) {
            let userDefaults = Foundation.UserDefaults.standard
            if let activeUser = newActiveUser {
                var json = activeUser.toJSON()
                if var kmd = json[PersistableMetadataKey] as? [String : Any] {
                    kmd.removeValue(forKey: Metadata.AuthTokenKey)
                    json[PersistableMetadataKey] = kmd
                }
                userDefaults.set(json, forKey: appKey!)
                userDefaults.synchronize()
                
                KCSKeychain2.setKinveyToken(
                    activeUser.metadata?.authtoken,
                    user: activeUser.userId,
                    appKey: appKey,
                    accessible: KCSKeychain2.accessibleString(for: KCSDataProtectionLevel.completeUntilFirstLogin) //TODO: using default value for now
                )
                if let authtoken = activeUser.metadata?.authtoken {
                    keychain.authtoken = authtoken
                }
            } else if let appKey = appKey {
                userDefaults.removeObject(forKey: appKey)
                userDefaults.synchronize()
                
                KCSKeychain2.deleteTokens(
                    forUser: activeUser?.userId,
                    appKey: appKey
                )
                
                CacheManager(persistenceId: appKey, encryptionKey: encryptionKey as Data?).clearAll()
                do {
                    try Keychain(appKey: appKey).removeAll()
                } catch {
                    //do nothing
                }
                dataStoreInstances.removeAll()
            }
        }
        didSet {
            userChangedListener?(activeUser)
        }
    }
    
    fileprivate var keychain: Keychain {
        get {
            return Keychain(appKey: appKey!)
        }
    }
    
    internal var urlSession = URLSession(configuration: URLSessionConfiguration.default) {
        willSet {
            urlSession.invalidateAndCancel()
        }
    }
    
    /// Holds the App ID for a specific Kinvey environment.
    open fileprivate(set) var appKey: String?
    
    /// Holds the App Secret for a specific Kinvey environment.
    open fileprivate(set) var appSecret: String?
    
    /// Holds the `Host` for a specific Kinvey environment. The default value is `https://baas.kinvey.com/`
    open fileprivate(set) var apiHostName: URL
    
    /// Holds the `Authentication Host` for a specific Kinvey environment. The default value is `https://auth.kinvey.com/`
    open fileprivate(set) var authHostName: URL
    
    /// Cache policy for this client instance.
    open var cachePolicy: NSURLRequest.CachePolicy = .useProtocolCachePolicy
    
    /// Timeout interval for this client instance.
    open var timeoutInterval: TimeInterval = 60
    
    /// App version for this client instance.
    open var clientAppVersion: String?
    
    /// Custom request properties for this client instance.
    open var customRequestProperties: [String : String] = [:]
    
    /// The default value for `apiHostName` variable.
    open static let defaultApiHostName = URL(string: "https://baas.kinvey.com/")!
    
    /// The default value for `authHostName` variable.
    open static let defaultAuthHostName = URL(string: "https://auth.kinvey.com/")!
    
    var networkRequestFactory: RequestFactory!
    var responseParser: ResponseParser!
    
    var encryptionKey: Data?
    
    /// Set a different schema version to perform migrations in your local cache.
    open fileprivate(set) var schemaVersion: CUnsignedLongLong = 0
    
    internal fileprivate(set) var cacheManager: CacheManager!
    internal fileprivate(set) var syncManager: SyncManager!
    
    /// Use this variable to handle push notifications.
    open fileprivate(set) var push: Push!
    
    /// Set a different type if you need a custom `User` class. Extends from `User` allows you to have custom properties in your `User` instances.
    open var userType = User.self
    
    ///Default Value for DataStore tag
    open static let defaultTag = Kinvey.defaultTag
    
    var dataStoreInstances = [DataStoreTypeTag : AnyObject]()
    
    /// Enables logging for any network calls.
    open var logNetworkEnabled = false {
        didSet {
            KCSClient.configureLogging(
                withNetworkEnabled: logNetworkEnabled,
                debugEnabled: false,
                traceEnabled: false,
                warningEnabled: false,
                errorEnabled: false
            )
        }
    }
    
    /// Stores the MIC API Version to be used in MIC calls 
    open var micApiVersion: String? = "v1"
    
    /// Default constructor. The `initialize` method still need to be called after instanciate a new instance.
    public override init() {
        apiHostName = Client.defaultApiHostName
        authHostName = Client.defaultAuthHostName
        
        super.init()
        
        push = Push(client: self)
        networkRequestFactory = HttpRequestFactory(client: self)
        responseParser = JsonResponseParser(client: self)
    }
    
    /// Constructor that already initialize the client. The `initialize` method is called automatically.
    public convenience init(appKey: String, appSecret: String, apiHostName: URL = Client.defaultApiHostName, authHostName: URL = Client.defaultAuthHostName) {
        self.init()
        initialize(appKey: appKey, appSecret: appSecret, apiHostName: apiHostName, authHostName: authHostName)
    }
    
    /// Initialize a `Client` instance with all the needed parameters and requires a boolean to encrypt or not any store created using this client instance.
    open func initialize(appKey: String, appSecret: String, apiHostName: URL = Client.defaultApiHostName, authHostName: URL = Client.defaultAuthHostName, encrypted: Bool, schemaVersion: CUnsignedLongLong = 0, migrationHandler: Migration.MigrationHandler? = nil) {
        precondition((!appKey.isEmpty && !appSecret.isEmpty), "Please provide a valid appKey and appSecret. Your app's key and secret can be found on the Kinvey management console.")

        var encryptionKey: Data? = nil
        if encrypted {
            lockEncryptionKey.lock()
            
            let keychain = Keychain(appKey: appKey)
            if let key = keychain.defaultEncryptionKey {
                encryptionKey = key as Data
            } else {
                let numberOfBytes = 64
                var bytes = [UInt8](repeating: 0, count: numberOfBytes)
                let result = SecRandomCopyBytes(kSecRandomDefault, numberOfBytes, &bytes)
                if result == 0 {
                    let key = Data(bytes: bytes)
                    keychain.defaultEncryptionKey = key
                    encryptionKey = key
                }
            }
            
            lockEncryptionKey.unlock()
        }
        
        initialize(appKey: appKey, appSecret: appSecret, apiHostName: apiHostName, authHostName: authHostName, encryptionKey: encryptionKey, schemaVersion: schemaVersion, migrationHandler: migrationHandler)
    }
    
    /// Initialize a `Client` instance with all the needed parameters.
    open func initialize(appKey: String, appSecret: String, apiHostName: URL = Client.defaultApiHostName, authHostName: URL = Client.defaultAuthHostName, encryptionKey: Data? = nil, schemaVersion: CUnsignedLongLong = 0, migrationHandler: Migration.MigrationHandler? = nil) {
        precondition((!appKey.isEmpty && !appSecret.isEmpty), "Please provide a valid appKey and appSecret. Your app's key and secret can be found on the Kinvey management console.")
        self.encryptionKey = encryptionKey
        self.schemaVersion = schemaVersion
        cacheManager = CacheManager(persistenceId: appKey, encryptionKey: encryptionKey as Data?, schemaVersion: schemaVersion, migrationHandler: migrationHandler)
        syncManager = SyncManager(persistenceId: appKey, encryptionKey: encryptionKey as Data?)
        
        var apiHostName = apiHostName
        if let apiHostNameString = apiHostName.absoluteString as String? , apiHostNameString.characters.last == "/" {
            apiHostName = URL(string: apiHostNameString.substring(to: apiHostNameString.characters.index(before: apiHostNameString.characters.endIndex)))!
        }
        var authHostName = authHostName
        if let authHostNameString = authHostName.absoluteString as String? , authHostNameString.characters.last == "/" {
            authHostName = URL(string: authHostNameString.substring(to: authHostNameString.characters.index(before: authHostNameString.characters.endIndex)))!
        }
        self.apiHostName = apiHostName
        self.authHostName = authHostName
        self.appKey = appKey
        self.appSecret = appSecret
        
        //legacy initilization
        KCSClient.shared().initializeKinveyService(forAppKey: appKey, withAppSecret: appSecret, usingOptions: nil)
        
        if let json = Foundation.UserDefaults.standard.object(forKey: appKey) as? [String : AnyObject] {
            let user = Mapper<User>().map(JSON: json)
            if let user = user, let metadata = user.metadata, let authtoken = keychain.authtoken {
                user.client = self
                metadata.authtoken = authtoken
                activeUser = user
            }
        }
    }
    
    /// Autorization header used for calls that don't requires a logged `User`.
    open var authorizationHeader: String? {
        get {
            var authorization: String? = nil
            if let appKey = appKey, let appSecret = appSecret {
                let appKeySecret = "\(appKey):\(appSecret)".data(using: String.Encoding.utf8)?.base64EncodedString(options: [])
                if let appKeySecret = appKeySecret {
                    authorization = "Basic \(appKeySecret)"
                }
            }
            return authorization
        }
    }

    internal func isInitialized () -> Bool {
        return self.appKey != nil && self.appSecret != nil
    }
    
    internal func filePath(_ tag: String = defaultTag) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let path = paths.first! as NSString
        var filePath = path.appendingPathComponent(self.appKey!)
        
        let fileManager = FileManager.default
        do {
            let filePath = filePath as String
            if !fileManager.fileExists(atPath: filePath) {
                try! fileManager.createDirectory(atPath: filePath, withIntermediateDirectories: true, attributes: nil)
            }
        }
        
        filePath = (filePath as NSString).appendingPathComponent("\(tag).realm")
        return filePath
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        guard
            let appKey = aDecoder.decodeObject(of: NSString.self, forKey: "appKey") as? String,
            let appSecret = aDecoder.decodeObject(of: NSString.self, forKey: "appSecret") as? String,
            let apiHostName = aDecoder.decodeObject(of: NSURL.self, forKey: "apiHostName") as? URL,
            let authHostName = aDecoder.decodeObject(of: NSURL.self, forKey: "authHostName") as? URL
        else {
                return nil
        }
        self.init(appKey: appKey, appSecret: appSecret, apiHostName: apiHostName, authHostName: authHostName)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(appKey, forKey: "appKey")
        aCoder.encode(appSecret, forKey: "appSecret")
        aCoder.encode(apiHostName, forKey: "apiHostName")
        aCoder.encode(authHostName, forKey: "authHostName")
    }
}
