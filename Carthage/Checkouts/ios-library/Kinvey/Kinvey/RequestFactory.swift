//
//  NetworkTransport.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

protocol RequestFactory {
    
    func buildUserSignUp(username: String?, password: String?) -> HttpRequest
    func buildUserDelete(userId: String, hard: Bool) -> HttpRequest
    func buildUserSocialLogin(_ authSource: String, authData: [String : Any]) -> HttpRequest
    func buildUserLogin(username: String, password: String) -> HttpRequest
    func buildUserExists(username: String) -> HttpRequest
    func buildUserGet(userId: String) -> HttpRequest
    func buildUserSave(user: User) -> HttpRequest
    func buildUserSave(user: User, newPassword: String?) -> HttpRequest
    func buildUserLookup(user: User, userQuery: UserQuery) -> HttpRequest
    func buildSendEmailConfirmation(forUsername: String) -> HttpRequest
    func buildUserResetPassword(usernameOrEmail: String) -> HttpRequest
    func buildUserForgotUsername(email: String) -> HttpRequest
    
    func buildAppDataGetById(collectionName: String, id: String) -> HttpRequest
    func buildAppDataFindByQuery(collectionName: String, query: Query) -> HttpRequest
    func buildAppDataCountByQuery(collectionName: String, query: Query?) -> HttpRequest
    func buildAppDataSave<T: Persistable>(_ persistable: T) -> HttpRequest
    func buildAppDataRemoveByQuery(collectionName: String, query: Query) -> HttpRequest
    func buildAppDataRemoveById(collectionName: String, objectId: String) -> HttpRequest
    
    func buildPushRegisterDevice(_ deviceToken: Data) -> HttpRequest
    func buildPushUnRegisterDevice(_ deviceToken: Data) -> HttpRequest
    
    func buildBlobUploadFile(_ file: File) -> HttpRequest
    func buildBlobDownloadFile(_ file: File, ttl: TTL?) -> HttpRequest
    func buildBlobDeleteFile(_ file: File) -> HttpRequest
    func buildBlobQueryFile(_ query: Query, ttl: TTL?) -> HttpRequest
    
    func buildCustomEndpoint(_ name: String) -> HttpRequest
    
}
