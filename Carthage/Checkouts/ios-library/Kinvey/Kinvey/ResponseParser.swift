//
//  ResponseParser.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-09.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

internal protocol ResponseParser {
    
    var client: Client { get }
    
    func parse(_ data: Data?) -> JsonDictionary?
    func parseArray(_ data: Data?) -> [JsonDictionary]?
    func parseUser(_ data: Data?) -> User?
    func parseUsers(_ data: Data?) -> [User]?

}

extension ResponseParser {
    
    func isResponseOk(_ response: URLResponse?) -> Bool {
        if let response = response {
            if let httpResponse = response as? HTTPURLResponse {
                return 200 <= httpResponse.statusCode && httpResponse.statusCode < 300
            }
        }
        return false
    }
    
}
