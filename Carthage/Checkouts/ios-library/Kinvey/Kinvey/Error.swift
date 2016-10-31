//
//  Error.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

/// Enum that contains all error types in the library.
public enum Error: Swift.Error {
    
    /// Constant for 401 responses where the credentials are not enough to complete the request.
    public static let InsufficientCredentials = "InsufficientCredentials"
    
    /// Constant for 401 responses where the credentials are not valid to complete the request.
    public static let InvalidCredentials = "InvalidCredentials"
    
    /// Error where Object ID is required.
    case objectIdMissing
    
    /// Error when a method is not allowed, usually when you are using a Data Link Connector (DLC).
    case methodNotAllowed(debug: String, description: String)
    
    /// Error when a Data Link endpoint is not found, usually when you are using a Data Link Connector (DLC).
    case dataLinkEntityNotFound(debug: String, description: String)
    
    /// Error when the type is unknow.
    case unknownError(error: String)
    
    /// Error when the type is unknow.
    case unknownJsonError(json: [String : Any])
    
    /// Error when a Invalid Response coming from the backend.
    case invalidResponse
    
    /// Error when a Unauthorized Response coming from the backend.
    case unauthorized(error: String, description: String)
    
    /// Error when calls a method that requires an active user.
    case noActiveUser
    
    /// Error when a request was cancelled.
    case requestCancelled
    
    /// Error when a request reached a timeout.
    case requestTimeout
    
    /// Error when calls a method not available for a specific data store type.
    case invalidDataStoreType
    
    /// Invalid operation
    case invalidOperation(description: String)
    
    /// Error when a `User` doen't have an email or username.
    case userWithoutEmailOrUsername
    
    var error: NSError {
        get {
            return self as NSError
        }
    }
    
    /// Error localized description.
    public var localizedDescription: String {
        get {
            let bundle = Bundle(for: Client.self)
            switch self {
            case .unauthorized(_, let description):
                return description
            case .invalidOperation(let description):
                return description
            default:
                return NSLocalizedString("Error.\(self)", bundle: bundle, comment: "")
            }
        }
    }
    
    static func buildUnknownError(_ error: String) -> Error {
        return unknownError(error: error)
    }
    
    static func buildUnknownJsonError(_ json: [String : Any]) -> Error {
        return unknownJsonError(json: json)
    }
    
    static func buildDataLinkEntityNotFound(_ json: [String : String]) -> Error {
        return dataLinkEntityNotFound(debug: json["debug"]!, description: json["description"]!)
    }
    
    static func buildMethodNotAllowed(_ json: [String : String]) -> Error {
        return methodNotAllowed(debug: json["debug"]!, description: json["description"]!)
    }
    
    static func buildUnauthorized(_ json: [String : String]) -> Error {
        return unauthorized(error: json["error"]!, description: json["description"]!)
    }
    
}
