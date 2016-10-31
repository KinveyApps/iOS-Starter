//
//  HttpNetworkTransport.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

class HttpRequestFactory: RequestFactory {
    
    let client: Client
    
    required init(client: Client) {
        self.client = client
    }
    
    typealias CompletionHandler = (Data?, URLResponse?, NSError?) -> Void
    
    func buildUserSignUp(username: String? = nil, password: String? = nil) -> HttpRequest {
        let request = HttpRequest(httpMethod: .post, endpoint: Endpoint.user(client: client), client: client)
        
        request.request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var bodyObject = JsonDictionary()
        if let username = username {
            bodyObject["username"] = username
        }
        if let password = password {
            bodyObject["password"] = password
        }
        request.request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
        return request
    }
    
    func buildUserDelete(userId: String, hard: Bool) -> HttpRequest {
        
        
        let request = HttpRequest(httpMethod: .delete, endpoint: Endpoint.userDelete(client: client, userId: userId, hard: hard), credential: client.activeUser, client: client)

        //FIXME: make it configurable
        request.request.setValue("2", forHTTPHeaderField: "X-Kinvey-API-Version")
        return request
    }
    
    func buildUserSocialLogin(_ authSource: String, authData: [String : Any]) -> HttpRequest {
        let request = HttpRequest(httpMethod: .post, endpoint: Endpoint.user(client: client), client: client)
        request.request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let socialIdentity = [
            authSource : authData
        ]
        let bodyObject = [
            "_socialIdentity" : socialIdentity
        ]
        request.request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
        return request
    }
    
    func buildUserLogin(username: String, password: String) -> HttpRequest {
        let request = HttpRequest(httpMethod: .post, endpoint: Endpoint.userLogin(client: client), client: client)
        request.request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let bodyObject = [
            "username" : username,
            "password" : password
        ]
        request.request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
        return request
    }
    
    func buildUserExists(username: String) -> HttpRequest {
        let request = HttpRequest(httpMethod: .post, endpoint: Endpoint.userExistsByUsername(client: client), client: client)
        request.request.httpMethod = "POST"
        
        request.request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let bodyObject = ["username" : username]
        request.request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
        return request
    }
    
    func buildUserGet(userId: String) -> HttpRequest {
        let request = HttpRequest(endpoint: Endpoint.userById(client: client, userId: userId), credential: client.activeUser, client: client)
        return request
    }
    
    func buildUserSave(user: User) -> HttpRequest {
        return buildUserSave(user: user, newPassword: nil)
    }
    
    func buildUserSave(user: User, newPassword: String?) -> HttpRequest {
        let request = HttpRequest(httpMethod: .put, endpoint: Endpoint.userById(client: client, userId: user.userId), credential: client.activeUser, client: client)
        request.request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var bodyObject = user.toJSON()
        
        if let newPassword = newPassword {
            bodyObject["password"] = newPassword
        }
        
        request.request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
        return request
    }
    
    func buildUserLookup(user: User, userQuery: UserQuery) -> HttpRequest {
        let request = HttpRequest(httpMethod: .post, endpoint: Endpoint.userLookup(client: client), credential: client.activeUser, client: client)
        request.request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let bodyObject = userQuery.toJSON()
        
        request.request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
        return request
    }
    
    func buildUserResetPassword(usernameOrEmail: String) -> HttpRequest {
        let request = HttpRequest(httpMethod: .post, endpoint: Endpoint.userResetPassword(usernameOrEmail: usernameOrEmail, client: client), credential: client, client: client)
        return request
    }
    
    func buildUserForgotUsername(email: String) -> HttpRequest {
        let request = HttpRequest(httpMethod: .post, endpoint: Endpoint.userForgotUsername(client: client), credential: client, client: client)
        request.request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let bodyObject = ["email" : email]
        request.request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
        return request
    }
    
    func buildAppDataGetById(collectionName: String, id: String) -> HttpRequest {
        let request = HttpRequest(endpoint: Endpoint.appDataById(client: client, collectionName: collectionName, id: id), credential: client.activeUser, client: client)
        return request
    }
    
    func buildAppDataFindByQuery(collectionName: String, query: Query) -> HttpRequest {
        let request = HttpRequest(endpoint: Endpoint.appDataByQuery(client: client, collectionName: collectionName, query: query), credential: client.activeUser, client: client)
        return request
    }
    
    func buildAppDataCountByQuery(collectionName: String, query: Query?) -> HttpRequest {
        let request = HttpRequest(endpoint: Endpoint.appDataCount(client: client, collectionName: collectionName, query: query), credential: client.activeUser, client: client)
        return request
    }
    
    func buildAppDataSave<T: Persistable>(_ persistable: T) -> HttpRequest {
        let collectionName = T.collectionName()
        let bodyObject = Mapper<T>().toJSON(persistable)
        let objId = bodyObject[PersistableIdKey] as? String
        let isNewObj = objId == nil
        let request = HttpRequest(
            httpMethod: isNewObj ? .post : .put,
            endpoint: isNewObj ? Endpoint.appData(client: client, collectionName: collectionName) : Endpoint.appDataById(client: client, collectionName: collectionName, id: objId!),
            credential: client.activeUser,
            client: client
        )
        
        request.request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
        return request
    }
    
    func buildAppDataRemoveByQuery(collectionName: String, query: Query) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .delete,
            endpoint: Endpoint.appDataByQuery(client: client, collectionName: collectionName, query: query),
            credential: client.activeUser,
            client: client
        )
        return request
    }
    
    func buildAppDataRemoveById(collectionName: String, objectId: String) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .delete,
            endpoint: Endpoint.appDataById(client: client, collectionName: collectionName, id: objectId),
            credential: client.activeUser,
            client: client
        )
        return request
    }
    
    func buildPushRegisterDevice(_ deviceToken: Data) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .post,
            endpoint: Endpoint.pushRegisterDevice(client: client),
            credential: client.activeUser,
            client: client
        )
        
        let bodyObject = [
            "platform" : "ios",
            "deviceId" : deviceToken.hexString()
        ]
        request.request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
        return request
    }
    
    func buildPushUnRegisterDevice(_ deviceToken: Data) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .post,
            endpoint: Endpoint.pushUnRegisterDevice(client: client),
            credential: client.activeUser,
            client: client
        )
        
        let bodyObject = [
            "platform" : "ios",
            "deviceId" : deviceToken.hexString()
        ]
        request.request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
        return request
    }
    
    func buildBlobUploadFile(_ file: File) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: file.fileId == nil ? .post : .put,
            endpoint: Endpoint.blobUpload(client: client, fileId: file.fileId, tls: true),
            credential: client.activeUser,
            client: client
        )
        
        var bodyObject: [String : Any] = [
            "_public" : file.publicAccessible as AnyObject
        ]
        
        if let fileId = file.fileId {
            bodyObject["_id"] = fileId
        }
        
        if let fileName = file.fileName {
            bodyObject["_filename"] = fileName
        }
        
        if let size = file.size.value {
            bodyObject["size"] = String(size)
        }
        
        if let mimeType = file.mimeType {
            bodyObject["mimeType"] = mimeType
        }
        
        request.request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.request.setValue(file.mimeType ?? "application/octet-stream", forHTTPHeaderField: "X-Kinvey-Content-Type")
        request.request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
        return request
    }
    
    fileprivate func ttlInSeconds(_ ttl: TTL?) -> UInt? {
        if let ttl = ttl {
            return UInt(ttl.1.toTimeInterval(ttl.0))
        }
        return nil
    }
    
    func buildBlobDownloadFile(_ file: File, ttl: TTL?) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .get,
            endpoint: Endpoint.blobDownload(client: client, fileId: file.fileId!, query: nil, tls: true, ttlInSeconds: ttlInSeconds(ttl)),
            credential: client.activeUser,
            client: client
        )
        return request
    }
    
    func buildBlobDeleteFile(_ file: File) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .delete,
            endpoint: Endpoint.blobById(client: client, fileId: file.fileId!),
            credential: client.activeUser,
            client: client
        )
        return request
    }
    
    func buildBlobQueryFile(_ query: Query, ttl: TTL?) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .get,
            endpoint: Endpoint.blobDownload(client: client, fileId: nil, query: query, tls: true, ttlInSeconds: ttlInSeconds(ttl)),
            credential: client.activeUser,
            client: client
        )
        return request
    }
    
    func buildCustomEndpoint(_ name: String) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .post,
            endpoint: Endpoint.customEndpooint(client: client, name: name),
            credential: client.activeUser,
            client: client
        )
        return request
    }
    
    func buildSendEmailConfirmation(forUsername username: String) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .post,
            endpoint: Endpoint.sendEmailConfirmation(client: client, username: username),
            credential: client,
            client: client
        )
        return request
    }

}
