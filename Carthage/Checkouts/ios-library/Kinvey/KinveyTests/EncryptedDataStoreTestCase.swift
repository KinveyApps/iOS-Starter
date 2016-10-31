//
//  EncryptedDataStoreTestCase.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-22.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class EncryptedDataStoreTestCase: StoreTestCase {
    
    lazy var filePath: NSString = {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        var filePath = paths.first! as NSString
        filePath = filePath.appendingPathComponent("com.kinvey.\(appInitialize.appKey)_cache.realm") as NSString
        return filePath
    }()
    
    override func setUp() {
        encrypted = true
        
        deleteAllDocumentFiles()
        
        super.setUp()
    }
    
    func testEncryptedDataStore() {
        signUp()
        
        store = DataStore<Person>.collection(.network, client: client)
        
        save(newPerson)
    }
    
    override func tearDown() {
        super.tearDown()
        
        store = nil
        
        deleteAllDocumentFiles()
    }
    
    fileprivate func deleteAllDocumentFiles() {
        let fileManager = FileManager.default
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if let path = paths.first {
            let url = URL(fileURLWithPath: path)
            for url in try! fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [], options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]) {
                if fileManager.fileExists(atPath: url.path) {
                    try! fileManager.removeItem(at: url)
                }
            }
        }
    }
    
}
