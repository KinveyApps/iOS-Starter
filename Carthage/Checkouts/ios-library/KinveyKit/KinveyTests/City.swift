//
//  City.swift
//  KinveyKit
//
//  Created by Victor Barros on 2015-05-08.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

import Foundation

class City: NSObject {
    
    var objectId: String?
    var name: String!
    var metadata: KCSMetadata?
    
    override func hostToKinveyPropertyMapping() -> [NSObject : AnyObject]! {
        return [
            "objectId" : KCSEntityKeyId,
            "name" : "name",
            "metadata" : KCSEntityKeyMetadata
        ]
    }
    
    override init() {
    }
    
    init(name: String) {
        self.name = name
    }
    
}
