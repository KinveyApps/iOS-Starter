//
//  Endpoint.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal enum Endpoint {
    
    case user(client: Client)
    case userById(client: Client, userId: String)
    case userDelete(client: Client, userId: String, hard: Bool)
    case userLookup(client: Client)
    case userExistsByUsername(client: Client)
    case userLogin(client: Client)
    case sendEmailConfirmation(client: Client, username: String)
    case userResetPassword(usernameOrEmail: String, client: Client)
    case userForgotUsername(client: Client)
    
    case oAuthAuth(client: Client, redirectURI: Foundation.URL)
    case oAuthToken(client: Client)
    
    case appData(client: Client, collectionName: String)
    case appDataById(client: Client, collectionName: String, id: String)
    case appDataByQuery(client: Client, collectionName: String, query: Query)
    case appDataCount(client: Client, collectionName: String, query: Query?)
    
    case pushRegisterDevice(client: Client)
    case pushUnRegisterDevice(client: Client)
    
    case blobById(client: Client, fileId: String)
    case blobUpload(client: Client, fileId: String?, tls: Bool)
    case blobDownload(client: Client, fileId: String?, query: Query?, tls: Bool, ttlInSeconds: UInt?)
    case blobByQuery(client: Client, query: Query)
    
    case URL(url: Foundation.URL)
    case customEndpooint(client: Client, name: String)
    
    func url() -> Foundation.URL {
        switch self {
        case .user(let client):
            return client.apiHostName.appendingPathComponent("/user/\(client.appKey!)")
        case .userById(let client, let userId):
            return client.apiHostName.appendingPathComponent("/user/\(client.appKey!)/\(userId)")
        case .userDelete(let client, let userId, let hard):
            let url = client.apiHostName.appendingPathComponent("/user/\(client.appKey!)/\(userId)")
            if hard {
                return Foundation.URL(string: url.absoluteString + "?hard=true")!
            }
            return url
        case .userLookup(let client):
            return client.apiHostName.appendingPathComponent("/user/\(client.appKey!)/_lookup")
        case .userExistsByUsername(let client):
            return client.apiHostName.appendingPathComponent("/rpc/\(client.appKey!)/check-username-exists")
        case .userLogin(let client):
            return client.apiHostName.appendingPathComponent("/user/\(client.appKey!)/login")
        case .sendEmailConfirmation(let client, let username):
            return client.apiHostName.appendingPathComponent("/rpc/\(client.appKey!)/\(username)/user-email-verification-initiate")
        case .userResetPassword(let usernameOrEmail, let client):
            return client.apiHostName.appendingPathComponent("/rpc/\(client.appKey!)/\(usernameOrEmail)/user-password-reset-initiate")
        case .userForgotUsername(let client):
            return client.apiHostName.appendingPathComponent("/rpc/\(client.appKey!)/user-forgot-username")
        case .oAuthAuth(let client, let redirectURI):
            var characterSet = CharacterSet.urlQueryAllowed
            characterSet.remove(charactersIn: ":#[]@!$&'()*+,;=")
            let redirectURIEncoded = redirectURI.absoluteString.addingPercentEncoding(withAllowedCharacters: characterSet) ?? redirectURI.absoluteString
            let query = "?client_id=\(client.appKey!)&redirect_uri=\(redirectURIEncoded)&response_type=code"
            return Foundation.URL(string: client.authHostName.appendingPathComponent("/oauth/auth").absoluteString + query)!
        case .oAuthToken(let client):
            return client.authHostName.appendingPathComponent("/oauth/token")
        case .appData(let client, let collectionName):
            return client.apiHostName.appendingPathComponent("/appdata/\(client.appKey!)/\(collectionName)")
        case .appDataById(let client, let collectionName, let id):
            return client.apiHostName.appendingPathComponent("/appdata/\(client.appKey!)/\(collectionName)/\(id)")
        case .appDataByQuery(let client, let collectionName, let query):
            let url = client.apiHostName.appendingPathComponent("/appdata/\(client.appKey!)/\(collectionName)/").absoluteString
            if (query.isEmpty()){
                return Foundation.URL(string: url)!
            }
            
            let queryParams = query.queryParams
            if queryParams.count > 0 {
                return Foundation.URL(string: "\(url)?\(queryParams.urlQueryEncoded)")!
            }
            
            return Foundation.URL(string: url)!
        case .appDataCount(let client, let collectionName, let query):
            let url = client.apiHostName.appendingPathComponent("/appdata/\(client.appKey!)/\(collectionName)/_count").absoluteString
            if let query = query {
                let queryParams = query.queryParams
                if queryParams.count > 0 {
                    return Foundation.URL(string: "\(url)?\(queryParams.urlQueryEncoded)")!
                }
            }
            return Foundation.URL(string: url)!
        case .pushRegisterDevice(let client):
            return client.apiHostName.appendingPathComponent("/push/\(client.appKey!)/register-device")
        case .pushUnRegisterDevice(let client):
            return client.apiHostName.appendingPathComponent("/push/\(client.appKey!)/unregister-device")
        case .blobById(let client, let fileId):
            return Endpoint.blobDownload(client: client, fileId: fileId, query: nil, tls: false, ttlInSeconds: nil).url()
        case .blobUpload(let client, let fileId, let tls):
            return Endpoint.blobDownload(client: client, fileId: fileId, query: nil, tls: tls, ttlInSeconds: nil).url()
        case .blobDownload(let client, let fileId, let query, let tls, let ttlInSeconds):
            let url = client.apiHostName.appendingPathComponent("/blob/\(client.appKey!)/\(fileId ?? "")").absoluteString
            
            var queryParams = [String : String]()
            
            if tls {
                queryParams["tls"] = "true"
            }
            
            if let ttlInSeconds = ttlInSeconds {
                queryParams["ttl_in_seconds"] = String(ttlInSeconds)
            }
            
            if let query = query , query.queryParams.count > 0 {
                for (key, value) in query.queryParams {
                    queryParams[key] = value
                }
            }
            
            if queryParams.count > 0 {
                return Foundation.URL(string: "\(url)?\(queryParams.urlQueryEncoded)")!
            }
            return Foundation.URL(string: url)!
        case .blobByQuery(let client, let query):
            return Endpoint.blobDownload(client: client, fileId: nil, query: query, tls: true, ttlInSeconds: nil).url()
        case .URL(let url):
            return url
        case .customEndpooint(let client, let name):
            return client.apiHostName.appendingPathComponent("/rpc/\(client.appKey!)/custom/\(name)")
        }
    }
    
}
