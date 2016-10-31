//
//  JsonResponseParser.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-09.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

class JsonResponseParser: ResponseParser {
    
    let client: Client
    
    init(client: Client) {
        self.client = client
    }
    
    func parseArray(_ data: Data?) -> [JsonDictionary]? {
        if let data = data , data.count > 0 {
            let result = try? JSONSerialization.jsonObject(with: data, options: []) as! [JsonDictionary]
            return result
        }
        return nil
    }
    
    func parse(_ data: Data?) -> JsonDictionary? {
        if let data = data , data.count > 0,
            let result = try? JSONSerialization.jsonObject(with: data, options: []) as? JsonDictionary,
            let json = result
        {
            return json
        }
        return nil
    }
    
    fileprivate func parseUser<U: User>(_ json: JsonDictionary, userType: U.Type) -> U? {
        let map = Map(mappingType: .fromJSON, JSON: json)
        let user = userType.init(map: map)
        user?.mapping(map: map)
        return user
    }
    
    func parseUser(_ data: Data?) -> User? {
        if let data = data , data.count > 0,
            let result = try? JSONSerialization.jsonObject(with: data, options: []) as? JsonDictionary,
            let json = result
        {
            let user = parseUser(json, userType: client.userType)
            return user
        }
        return nil
    }
    
    func parseUsers(_ data: Data?) -> [User]? {
        if let data = data , data.count > 0,
            let result = try? JSONSerialization.jsonObject(with: data, options: []) as? [JsonDictionary],
            let jsonArray = result
        {
            var users = [User]()
            for json in jsonArray {
                if let user = parseUser(json, userType: client.userType) {
                    users.append(user)
                }
            }
            return users
        }
        return nil
    }

}
