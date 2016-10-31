//
//  ObjC.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-04.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc(__KNVError)
internal class KinveyError: NSObject {
    
    internal static let ObjectIdMissing = Error.objectIdMissing.error
    internal static let InvalidResponse = Error.invalidResponse.error
    internal static let NoActiveUser = Error.noActiveUser.error
    internal static let RequestCancelled = Error.requestCancelled.error
    internal static let InvalidDataStoreType = Error.invalidDataStoreType.error
    
    fileprivate override init() {
    }
    
    internal static func buildUnknownError(_ error: String) -> NSError {
        return Error.buildUnknownError(error).error
    }
    
    internal static func buildUnknownJsonError(_ json: [String : Any]) -> NSError {
        return Error.buildUnknownJsonError(json).error
    }
    
}
