//
//  SyncedStoreTests.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-17.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class SyncStoreTests: StoreTestCase {
    
    class CheckForNetworkURLProtocol: URLProtocol {
        
        override class func canInit(with request: URLRequest) -> Bool {
            XCTFail()
            return false
        }
        
    }
    
    override func setUp() {
        super.setUp()
        
        signUp()
        
        store = DataStore<Person>.collection(.sync)
    }
    
    func testCustomTag() {
        let fileManager = FileManager.default
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        XCTAssertEqual(paths.count, 1)
        if let path = paths.first {
            let tag = "Custom Identifier"
            let customPath = "\(path)/\(client.appKey!)/\(tag).realm"
            
            let removeFiles: () -> Void = {
                if fileManager.fileExists(atPath: customPath) {
                    try! fileManager.removeItem(atPath: customPath)
                }
                
                let lockPath = (customPath as NSString).appendingPathExtension("lock")!
                if fileManager.fileExists(atPath: lockPath) {
                    try! fileManager.removeItem(atPath: lockPath)
                }
                
                let logPath = (customPath as NSString).appendingPathExtension("log")!
                if fileManager.fileExists(atPath: logPath) {
                    try! fileManager.removeItem(atPath: logPath)
                }
                
                let logAPath = (customPath as NSString).appendingPathExtension("log_a")!
                if fileManager.fileExists(atPath: logAPath) {
                    try! fileManager.removeItem(atPath: logAPath)
                }
                
                let logBPath = (customPath as NSString).appendingPathExtension("log_b")!
                if fileManager.fileExists(atPath: logBPath) {
                    try! fileManager.removeItem(atPath: logBPath)
                }
            }
            
            removeFiles()
            XCTAssertFalse(fileManager.fileExists(atPath: customPath))
            
            store = DataStore<Person>.collection(.sync, tag: tag)
            defer {
                removeFiles()
                XCTAssertFalse(fileManager.fileExists(atPath: customPath))
            }
            XCTAssertTrue(fileManager.fileExists(atPath: customPath))
        }
    }
    
    func testPurge() {
        save()
        
        XCTAssertEqual(store.syncCount(), 1)
        
        weak var expectationPurge = expectation(description: "Purge")
        
        let query = Query(format: "acl.creator == %@", client.activeUser!.userId)
        store.purge(query) { (count, error) -> Void in
            XCTAssertNotNil(count)
            XCTAssertNil(error)
            
            if let count = count {
                XCTAssertEqual(count, 1)
            }
            
            expectationPurge?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationPurge = nil
        }
        
        XCTAssertEqual(store.syncCount(), 0)
    }
    
    func testPurgeInvalidDataStoreType() {
        save()
        
        store = DataStore<Person>.collection(.network)
        
        weak var expectationPurge = expectation(description: "Purge")
        
        let query = Query(format: "acl.creator == %@", client.activeUser!.userId)
        store.purge(query) { (count, error) -> Void in
            self.assertThread()
            XCTAssertNil(count)
            XCTAssertNotNil(error)
            
            if let error = error as? NSError {
                XCTAssertEqual(error, Kinvey.Error.invalidDataStoreType.error)
            }
            
            expectationPurge?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationPurge = nil
        }
    }
    
    func testPurgeTimeoutError() {
        let person = save()
        person.age = person.age + 1
        save(person)
        
        setURLProtocol(TimeoutErrorURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationPurge = expectation(description: "Purge")
        
        let query = Query(format: "acl.creator == %@", client.activeUser!.userId)
        store.purge(query) { (count, error) -> Void in
            XCTAssertNil(count)
            XCTAssertNotNil(error)
            
            expectationPurge?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationPurge = nil
        }
    }
    
    func testSync() {
        save()
        
        XCTAssertEqual(store.syncCount(), 1)
        
        weak var expectationSync = expectation(description: "Sync")
        
        store.sync() { count, results, error in
            self.assertThread()
            XCTAssertNotNil(count)
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let count = count {
                XCTAssertEqual(Int(count), 1)
            }
            
            expectationSync?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationSync = nil
        }

        XCTAssertEqual(store.syncCount(), 0)

    }
    
    func testSyncInvalidDataStoreType() {
        save()
        
        store = DataStore<Person>.collection(.network)
        
        weak var expectationSync = expectation(description: "Sync")
        
        store.sync() { count, results, errors in
            self.assertThread()
            XCTAssertNil(count)
            XCTAssertNotNil(errors)
            
            if let errors = errors {
                if let error = errors.first as? Kinvey.Error {
                    switch error {
                    case .invalidDataStoreType:
                        break
                    default:
                        XCTFail()
                    }
                }
            }
            
            expectationSync?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationSync = nil
        }
    }
    
    func testSyncTimeoutError() {
        save()
        
        setURLProtocol(TimeoutErrorURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationSync = expectation(description: "Sync")
        
        store.sync() { count, results, error in
            self.assertThread()
            XCTAssertEqual(count, 0)
            XCTAssertNil(results)
            XCTAssertNotNil(error)
            
            expectationSync?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationSync = nil
        }
        XCTAssertEqual(store.syncCount(), 1)
    }
    
    func testSyncNoCompletionHandler() {
        save()
        
        let request = store.sync()
        
        XCTAssertTrue(request is NSObject)
        if let request = request as? NSObject {
            waitValueForObject(request, keyPath: "executing", expectedValue: false)
        }
    }
    
    func testPush() {
        save()
        
        XCTAssertEqual(store.syncCount(), 1)
        
        weak var expectationPush = expectation(description: "Push")
        
        store.push() { count, error in
            self.assertThread()
            XCTAssertNotNil(count)
            XCTAssertNil(error)
            
            if let count = count {
                XCTAssertEqual(Int(count), 1)
            }
            
            expectationPush?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationPush = nil
        }
        
        XCTAssertEqual(store.syncCount(), 0)
    }
    
    func testPushInvalidDataStoreType() {
        save()
        
        store = DataStore<Person>.collection(.network)
		defer {
            store.clearCache()
        }
        
        weak var expectationPush = expectation(description: "Push")
        
        store.push() { count, errors in
            self.assertThread()
            XCTAssertNil(count)
            XCTAssertNotNil(errors)
            
            if let errors = errors {
                if let error = errors.first as? Kinvey.Error {
                    switch error {
                    case .invalidDataStoreType:
                        break
                    default:
                        XCTFail()
                    }
                }
            }
            
            expectationPush?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationPush = nil
        }
    }
    
    func testPushNoCompletionHandler() {
        save()
        
        let request = store.push()
        
        XCTAssertTrue(request is NSObject)
        if let request = request as? NSObject {
            waitValueForObject(request, keyPath: "executing", expectedValue: false)
        }
    }
    
    func testPull() {
        MockKinveyBackend.kid = client.appKey!
        setURLProtocol(MockKinveyBackend.self)
        defer {
            setURLProtocol(nil)
        }
        
        let lmt = Date()
        
        MockKinveyBackend.appdata = [
            "Person" : [
                Person { $0.personId = "Victor"; $0.metadata = Metadata { $0.lastModifiedTime = lmt } }.toJSON(),
                Person { $0.personId = "Hugo"; $0.metadata = Metadata { $0.lastModifiedTime = lmt } }.toJSON(),
                Person { $0.personId = "Barros"; $0.metadata = Metadata { $0.lastModifiedTime = lmt } }.toJSON()
            ]
        ]
        
        do {
            weak var expectationPull = expectation(description: "Pull")
            
            store.clearCache()
            
            store.pull() { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, 3)
                    
                    let cacheCount = Int((self.store.cache?.count())!)
                    XCTAssertEqual(cacheCount, results.count)

                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        do {
            let query = Query(format: "personId == %@", "Victor")
            
            weak var expectationPull = expectation(description: "Pull")

			store.clearCache()
            
            store.pull(query) { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, 1)
                    
                    let cacheCount = Int((self.store.cache?.count())!)
                    XCTAssertEqual(cacheCount, results.count)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.personId, "Victor")
                    }
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        do {
            weak var expectationPull = expectation(description: "Pull")
            
            store.find() { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, 1)
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        MockKinveyBackend.appdata = [
            "Person" : [
                Person { $0.personId = "Hugo"; $0.metadata = Metadata { $0.lastModifiedTime = lmt } }.toJSON()
            ]
        ]
        
        do {
            let query = Query(format: "personId == %@", "Victor")
            
            weak var expectationPull = expectation(description: "Pull")
            
            store.clearCache()
            
            store.pull(query) { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, 0)
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        do {
            weak var expectationPull = expectation(description: "Pull")
            
            store.find() { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, 0)
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        MockKinveyBackend.appdata = [
            "Person" : [
                Person { $0.personId = "Victor"; $0.metadata = Metadata { $0.lastModifiedTime = lmt } }.toJSON()
            ]
        ]
        
        
        
        do {
            let query = Query(format: "personId == %@", "Victor")
            
            weak var expectationPull = expectation(description: "Pull")

			store.clearCache()
            
            store.pull(query) { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, 1)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.personId, "Victor")
                        
                        let cacheCount = Int((self.store.cache?.count())!)
                        XCTAssertEqual(cacheCount, results.count)

                    }
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
        
        do {
            weak var expectationPull = expectation(description: "Pull")
            
            store.find() { results, error in
                self.assertThread()
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, 1)
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPull = nil
            }
        }
    }
    
    func testPullPendingSyncItems() {
        save()
        
        weak var expectationPull = expectation(description: "Pull")
        
        store.pull() { results, error in
            self.assertThread()
            XCTAssertNil(results)
            XCTAssertNotNil(error)
            
            expectationPull?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationPull = nil
        }
        
    }
    func testPullInvalidDataStoreType() {
        //save()
        
        store = DataStore<Person>.collection(.network)
        
        weak var expectationPull = expectation(description: "Pull")
        
        store.pull() { results, error in
            self.assertThread()
            XCTAssertNil(results)
            XCTAssertNotNil(error)
            
            if let error = error as? NSError {
                XCTAssertEqual(error, Kinvey.Error.invalidDataStoreType.error)
            }
            
            expectationPull?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationPull = nil
        }
    }
    
    func testFindById() {
        let person = save()
        
        XCTAssertNotNil(person.personId)
        
        guard let personId = person.personId else { return }
        
        setURLProtocol(CheckForNetworkURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(personId) { result, error in
            self.assertThread()
            XCTAssertNotNil(result)
            XCTAssertNil(error)
            
            if let result = result {
                XCTAssertEqual(result.personId, personId)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testFindByQuery() {
        let person = save()
        
        XCTAssertNotNil(person.personId)
        
        guard let personId = person.personId else { return }
        
        setURLProtocol(CheckForNetworkURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        let query = Query(format: "personId == %@", personId)
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(query) { results, error in
            self.assertThread()
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let results = results {
                XCTAssertNotNil(results.first)
                if let result = results.first {
                    XCTAssertEqual(result.personId, personId)
                }
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testRemovePersistable() {
        let person = save()
        
        XCTAssertNotNil(person.personId)
        
        setURLProtocol(CheckForNetworkURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationRemove = expectation(description: "Remove")
        
        do {
            try store.remove(person) { count, error in
                self.assertThread()
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                if let count = count {
                    XCTAssertEqual(count, 1)
                }
                
                expectationRemove?.fulfill()
            }
        } catch {
            XCTFail()
            expectationRemove?.fulfill()
        }
            
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationRemove = nil
        }
    }
    
    func testRemovePersistableIdMissing() {
        let person = save()
        
        XCTAssertNotNil(person.personId)
        
        setURLProtocol(CheckForNetworkURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationRemove = expectation(description: "Remove")
        
        do {
            person.personId = nil
            try store.remove(person) { count, error in
                XCTFail()
                
                expectationRemove?.fulfill()
            }
            XCTFail()
        } catch {
            expectationRemove?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationRemove = nil
        }
    }
    
    func testRemovePersistableArray() {
        let person1 = save(newPerson)
        let person2 = save(newPerson)
        
        XCTAssertNotNil(person1.personId)
        XCTAssertNotNil(person2.personId)
        
        guard let personId1 = person1.personId, let personId2 = person2.personId else { return }
        
        XCTAssertNotEqual(personId1, personId2)
        
        setURLProtocol(CheckForNetworkURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationRemove = expectation(description: "Remove")
        
        store.remove([person1, person2]) { count, error in
            self.assertThread()
            XCTAssertNotNil(count)
            XCTAssertNil(error)
            
            if let count = count {
                XCTAssertEqual(count, 2)
            }
            
            expectationRemove?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationRemove = nil
        }
    }
    
    func testRemoveAll() {
        let person1 = save(newPerson)
        let person2 = save(newPerson)
        
        XCTAssertNotNil(person1.personId)
        XCTAssertNotNil(person2.personId)
        
        guard let personId1 = person1.personId, let personId2 = person2.personId else { return }
        
        XCTAssertNotEqual(personId1, personId2)
        
        setURLProtocol(CheckForNetworkURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationRemove = expectation(description: "Remove")
        
        store.removeAll() { count, error in
            self.assertThread()
            XCTAssertNotNil(count)
            XCTAssertNil(error)
            
            if let count = count {
                XCTAssertEqual(count, 2)
            }
            
            expectationRemove?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationRemove = nil
        }
    }
    
    func testExpiredTTL() {
        store.ttl = 1.seconds
        
        let person = save()
        
        XCTAssertNotNil(person.personId)
        
        Thread.sleep(forTimeInterval: 1)
        
        if let personId = person.personId {
            weak var expectationGet = expectation(description: "Get")
            
            let query = Query(format: "personId == %@", personId)
            store.find(query, readPolicy: .forceLocal) { (persons, error) -> Void in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, 0)
                }
                
                expectationGet?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationGet = nil
            }
        }
        
        store.ttl = nil
        
        if let personId = person.personId {
            weak var expectationGet = expectation(description: "Get")
            
            let query = Query(format: "personId == %@", personId)
            store.find(query, readPolicy: .forceLocal) { (persons, error) -> Void in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, 1)
                }
                
                expectationGet?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationGet = nil
            }
        }
    }
    
    func testSaveAndFind10SkipLimit() {
        XCTAssertNotNil(Kinvey.sharedClient.activeUser)
        
        guard let user = Kinvey.sharedClient.activeUser else {
            return
        }
        
        var i = 0
        
        measure {
            let person = Person {
                $0.name = "Person \(i)"
            }
            
            weak var expectationSave = self.expectation(description: "Save")
            
            self.store.save(person, writePolicy: .forceLocal) { person, error in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                expectationSave?.fulfill()
            }
            
            self.waitForExpectations(timeout: self.defaultTimeout) { error in
                expectationSave = nil
            }
            
            i += 1
        }
        
        var skip = 0
        let limit = 2
        
        for _ in 0 ..< 5 {
            weak var expectationFind = expectation(description: "Find")
            
            let query = Query {
                $0.skip = skip
                $0.limit = limit
                $0.ascending("name")
            }
            
            store.find(query, readPolicy: .forceLocal) { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, limit)
                    
                    XCTAssertNotNil(results.first)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Person \(skip)")
                    }
                    
                    XCTAssertNotNil(results.last)
                    
                    if let person = results.last {
                        XCTAssertEqual(person.name, "Person \(skip + 1)")
                    }
                }
                
                skip += limit
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
        
        do {
            weak var expectationFind = expectation(description: "Find")
            
            let query = Query {
                $0.limit = 5
                $0.ascending("name")
            }
            
            store.find(query, readPolicy: .forceLocal) { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, 5)
                    
                    XCTAssertNotNil(results.first)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Person 0")
                    }
                    
                    XCTAssertNotNil(results.last)
                    
                    if let person = results.last {
                        XCTAssertEqual(person.name, "Person 4")
                    }
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
        
        do {
            weak var expectationFind = expectation(description: "Find")
            
            let query = Query {
                $0.skip = 5
                $0.ascending("name")
            }
            
            store.find(query, readPolicy: .forceLocal) { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, 5)
                    
                    XCTAssertNotNil(results.first)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Person 5")
                    }
                    
                    XCTAssertNotNil(results.last)
                    
                    if let person = results.last {
                        XCTAssertEqual(person.name, "Person 9")
                    }
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
        
        do {
            weak var expectationFind = expectation(description: "Find")
            
            let query = Query {
                $0.skip = 6
                $0.limit = 6
                $0.ascending("name")
            }
            
            store.find(query, readPolicy: .forceLocal) { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, 4)
                    
                    XCTAssertNotNil(results.first)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Person 6")
                    }
                    
                    XCTAssertNotNil(results.last)
                    
                    if let person = results.last {
                        XCTAssertEqual(person.name, "Person 9")
                    }
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }

        
        do {
            weak var expectationFind = expectation(description: "Find")
            
            let query = Query {
                $0.skip = 10
                $0.ascending("name")
            }
            
            store.find(query, readPolicy: .forceLocal) { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, 0)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
        
        do {
            weak var expectationFind = expectation(description: "Find")
            
            let query = Query {
                $0.skip = 11
                $0.ascending("name")
            }
            
            store.find(query, readPolicy: .forceLocal) { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, 0)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
        
        do {
            weak var expectationPush = expectation(description: "Push")
            
            store.push { count, error in
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                if let count = count {
                    XCTAssertEqual(count, 10)
                }
                
                expectationPush?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationPush = nil
            }
        }
        
        skip = 0
        
        for _ in 0 ..< 5 {
            weak var expectationFind = expectation(description: "Find")
            
            let query = Query {
                $0.predicate = NSPredicate(format: "acl.creator == %@", user.userId)
                $0.skip = skip
                $0.limit = limit
                $0.ascending("name")
            }
            
            store.pull(query) { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertEqual(results.count, limit)
                    
                    XCTAssertNotNil(results.first)
                    
                    if let person = results.first {
                        XCTAssertEqual(person.name, "Person \(skip)")
                    }
                    
                    XCTAssertNotNil(results.last)
                    
                    if let person = results.last {
                        XCTAssertEqual(person.name, "Person \(skip + 1)")
                    }
                }
                
                skip += limit
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
    }
    
}
