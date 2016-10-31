//
//  FileCache.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-07-26.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

protocol FileCache {
    
    func save(_ file: File, beforeSave: (() -> Void)?)
    
    func remove(_ file: File)
    
    func get(_ fileId: String) -> File?
    
}
