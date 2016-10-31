//
//  DeltaSetCacheTestCase.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-16.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class DeltaSetCacheTestCase: KinveyTestCase {
    
    override func tearDown() {
        if let activeUser = client.activeUser {
            let store = DataStore<Person>.collection(.network)
            let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", activeUser.userId)
            
            weak var expectationRemoveAll = expectation(description: "Remove All")
            
            store.remove(query) { (count, error) -> Void in
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                expectationRemoveAll?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationRemoveAll = nil
            }
        }
        
        super.tearDown()
    }
    
    func testComputeDelta() {
        let date = Date()
        let cache = MemoryCache<Person>()
        do {
            let person = Person()
            person.personId = "update"
            person.metadata = Metadata(JSON: [Metadata.LmtKey : date.toString()])
            cache.saveEntity(person)
        }
        do {
            let person = Person()
            person.personId = "noChange"
            person.metadata = Metadata(JSON: [Metadata.LmtKey : date.toString()])
            cache.saveEntity(person)
        }
        do {
            let person = Person()
            person.personId = "delete"
            person.metadata = Metadata(JSON: [Metadata.LmtKey : date.toString()])
            cache.saveEntity(person)
        }
        let operation = Operation(cache: cache, client: client)
        let query = Query()
        let refObjs: [JsonDictionary] = [
            [
                PersistableIdKey : "create",
                PersistableMetadataKey : [
                    Metadata.LmtKey : date.toString(),
                ]
            ],
            [
                PersistableIdKey : "update",
                PersistableMetadataKey : [
                    Metadata.LmtKey : Date(timeInterval: 1, since: date).toString()
                ]
            ],
            [
                PersistableIdKey : "noChange",
                PersistableMetadataKey : [
                    Metadata.LmtKey : date.toString()
                ]
            ]
        ]
        
        let idsLmts = operation.reduceToIdsLmts(refObjs)
        let deltaSet = operation.computeDeltaSet(query, refObjs: idsLmts)
        
        XCTAssertEqual(deltaSet.created.count, 1)
        XCTAssertEqual(deltaSet.created.first, "create")
        
        XCTAssertEqual(deltaSet.updated.count, 1)
        XCTAssertEqual(deltaSet.updated.first, "update")
        
        XCTAssertEqual(deltaSet.deleted.count, 1)
        XCTAssertEqual(deltaSet.deleted.first, "delete")
    }
    
    func testCreate() {
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        guard let activeUser = client.activeUser else {
            return
        }
        
        let store = DataStore<Person>.collection()
        
        let person = Person()
        person.name = "Victor"
        
        do {
            weak var expectationSave = expectation(description: "Save")
            
            store.save(person) { (person, error) -> Void in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                expectationSave?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationSave = nil
            }
        }
        
        XCTAssertNotNil(person.personId)
        
        do {
            let person = Person()
            person.name = "Victor Barros"
            
            weak var expectationCreate = expectation(description: "Create")
            
            let createOperation = SaveOperation<Person>(persistable: person, writePolicy: .forceNetwork, client: client)
            createOperation.execute { (results, error) -> Void in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                expectationCreate?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationCreate = nil
            }
        }
        
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", activeUser.userId)
        query.ascending("name")
        
        do {
            weak var expectationRead = expectation(description: "Read")
            
            store.find(query, readPolicy: .forceLocal) { persons, error in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, 1)
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor")
                    }
                }
                
                expectationRead?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationRead = nil
            }
        }
        
        do {
            weak var expectationFind = expectation(description: "Find")
            
            store.find(query, readPolicy: .forceNetwork) { persons, error in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, 2)
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor")
                    }
                    if let person = persons.last {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationFind = nil
            }
        }
    }
    
    func testUpdate() {
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        guard let activeUser = client.activeUser else {
            return
        }
        
        let store = DataStore<Person>.collection()
        
        let person = Person()
        person.name = "Victor"
        
        do {
            weak var expectationSave = expectation(description: "Save")
            
            store.save(person) { (person, error) -> Void in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                expectationSave?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationSave = nil
            }
        }
        
        XCTAssertNotNil(person.personId)
        guard let personId = person.personId else {
            return
        }
        
        do {
            let person = Person()
            person.personId = personId
            person.name = "Victor Barros"
            
            weak var expectationUpdate = expectation(description: "Update")
            
            let updateOperation = SaveOperation(persistable: person, writePolicy: .forceNetwork, client: client)
            updateOperation.execute { (results, error) -> Void in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                expectationUpdate?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationUpdate = nil
            }
        }
        
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", activeUser.userId)
        query.ascending("name")
        
        do {
            weak var expectationRead = expectation(description: "Read")
            
            store.find(query, readPolicy: .forceLocal) { persons, error in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, 1)
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor")
                    }
                }
                
                expectationRead?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationRead = nil
            }
        }
        
        do {
            weak var expectationFind = expectation(description: "Find")
            
            store.find(query, readPolicy: .forceNetwork) { persons, error in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, 1)
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor Barros")
                    }
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationFind = nil
            }
        }
    }
    
    func testDelete() {
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        guard let activeUser = client.activeUser else {
            return
        }
        
        let store = DataStore<Person>.collection()
        
        let person = Person()
        person.name = "Victor"
        
        do {
            weak var expectationSave = expectation(description: "Save")
            
            store.save(person) { (person, error) -> Void in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                expectationSave?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationSave = nil
            }
        }
        
        XCTAssertNotNil(person.personId)
        guard let personId = person.personId else {
            return
        }
        
        do {
            weak var expectationDelete = expectation(description: "Delete")
            
            let query = Query(format: "personId == %@", personId)
            query.persistableType = Person.self
            let createRemove = RemoveByQueryOperation<Person>(query: query, writePolicy: .forceNetwork, client: client)
            createRemove.execute { (count, error) -> Void in
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                XCTAssertEqual(count, 1)
                
                expectationDelete?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationDelete = nil
            }
        }
        
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", activeUser.userId)
        query.ascending("name")
        
        do {
            weak var expectationRead = expectation(description: "Read")
            
            store.find(query, readPolicy: .forceLocal) { persons, error in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, 1)
                    if let person = persons.first {
                        XCTAssertEqual(person.name, "Victor")
                    }
                }
                
                expectationRead?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationRead = nil
            }
        }
        
        do {
            weak var expectationFind = expectation(description: "Find")
            
            store.find(query, readPolicy: .forceNetwork) { persons, error in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, 0)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationFind = nil
            }
        }
    }
    
    func testPull() {
        signUp()
        
        XCTAssertNotNil(client.activeUser)
        guard let activeUser = client.activeUser else {
            return
        }
        
        let save: (Int) -> Void = { i in
            let person = Person()
            person.name = String(format: "Person %02d", i)
            
            weak var expectationCreate = self.expectation(description: "Create")
            
            let createOperation = SaveOperation(persistable: person, writePolicy: .forceNetwork, client: self.client)
            createOperation.execute { (results, error) -> Void in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                expectationCreate?.fulfill()
            }
            
            self.waitForExpectations(timeout: self.defaultTimeout) { (error) -> Void in
                expectationCreate = nil
            }
        }
        
        let saveAndCache: (Int) -> Void = { i in
            let person = Person()
            person.name = String(format: "Person Cached %02d", i)
            let store = DataStore<Person>.collection()
            
            weak var expectationSave = self.expectation(description: "Save")
            
            store.save(person, writePolicy: .forceNetwork) { (person, error) -> Void in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                expectationSave?.fulfill()
            }
            
            self.waitForExpectations(timeout: self.defaultTimeout) { (error) -> Void in
                expectationSave = nil
            }
        }
        
        for i in 1...10 {
            save(i)
        }
        
        for i in 1...5 {
            saveAndCache(i)
        }
        
        let store = DataStore<Person>.collection(.sync)
        
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", activeUser.userId)
        query.ascending("name")
        
        do {
            weak var expectationRead = expectation(description: "Read")
            
            store.find(query, readPolicy: .forceLocal) { persons, error in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, 5)
                    
                    for (i, person) in persons.enumerated() {
                        XCTAssertEqual(person.name, String(format: "Person Cached %02d", i + 1))
                    }
                }
                
                expectationRead?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationRead = nil
            }
        }
        
        do {
            weak var expectationPull = expectation(description: "Pull")
            
            store.pull(query) { (persons, error) -> Void in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, 15)
                    if persons.count == 15 {
                        for (i, person) in persons[0..<10].enumerated() {
                            XCTAssertEqual(person.name, String(format: "Person %02d", i + 1))
                        }
                        for (i, person) in persons[10..<persons.count].enumerated() {
                            XCTAssertEqual(person.name, String(format: "Person Cached %02d", i + 1))
                        }
                    }
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) -> Void in
                expectationPull = nil
            }
        }
    }
    
    func perform(countBackend: Int, countLocal: Int) {
        self.signUp()
        
        XCTAssertNotNil(self.client.activeUser)
        guard let activeUser = self.client.activeUser else {
            return
        }
        
        let save: (Int) -> Void = { n in
            for i in 1...n {
                let person = Person()
                person.name = String(format: "Person %03d", i)
                
                weak var expectationCreate = self.expectation(description: "Create")
                
                let createOperation = SaveOperation(persistable: person, writePolicy: .forceNetwork, client: self.client)
                createOperation.execute { (results, error) -> Void in
                    XCTAssertNotNil(results)
                    XCTAssertNil(error)
                    
                    expectationCreate?.fulfill()
                }
                
                self.waitForExpectations(timeout: self.defaultTimeout) { (error) -> Void in
                    expectationCreate = nil
                }
            }
        }
        
        let saveAndCache: (Int) -> Void = { n in
            let store = DataStore<Person>.collection()
            
            for i in 1...n {
                let person = Person()
                person.name = String(format: "Person Cached %03d", i)
                
                weak var expectationSave = self.expectation(description: "Save")
                
                store.save(person) { (person, error) -> Void in
                    XCTAssertNotNil(person)
                    XCTAssertNil(error)
                    
                    expectationSave?.fulfill()
                }
                
                self.waitForExpectations(timeout: self.defaultTimeout) { (error) -> Void in
                    expectationSave = nil
                }
            }
        }
        
        saveAndCache(countLocal)
        save(countBackend)
        
        let store = DataStore<Person>.collection(.sync)
        
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", activeUser.userId)
        query.ascending("name")
        
        do {
            weak var expectationRead = self.expectation(description: "Read")
            
            store.find(query, readPolicy: .forceLocal) { persons, error in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, countLocal)
                    
                    for (i, person) in persons.enumerated() {
                        XCTAssertEqual(person.name, String(format: "Person Cached %03d", i + 1))
                    }
                }
                
                expectationRead?.fulfill()
            }
            
            self.waitForExpectations(timeout: self.defaultTimeout) { (error) -> Void in
                expectationRead = nil
            }
        }
        
        self.startMeasuring()
        
        do {
            weak var expectationFind = self.expectation(description: "Find")
            
            store.find(query, readPolicy: .forceNetwork) { (persons, error) -> Void in
                XCTAssertNotNil(persons)
                XCTAssertNil(error)
                
                if let persons = persons {
                    XCTAssertEqual(persons.count, countBackend + countLocal)
                    if persons.count > 0 {
                        for (i, person) in persons[0..<countBackend].enumerated() {
                            XCTAssertEqual(person.name, String(format: "Person %03d", i + 1))
                        }
                        for (i, person) in persons[countBackend..<persons.count].enumerated() {
                            XCTAssertEqual(person.name, String(format: "Person Cached %03d", i + 1))
                        }
                    }
                }
                
                expectationFind?.fulfill()
            }
            
            self.waitForExpectations(timeout: self.defaultTimeout) { (error) -> Void in
                expectationFind = nil
            }
        }
        
        self.stopMeasuring()
        
        self.tearDown()
    }
    
    func testPerformance_1_9() {
        measureMetrics(type(of: self).defaultPerformanceMetrics(), automaticallyStartMeasuring: false) { () -> Void in
            self.perform(countBackend: 1, countLocal: 9)
        }
    }
    
    func testPerformance_9_1() {
        measureMetrics(type(of: self).defaultPerformanceMetrics(), automaticallyStartMeasuring: false) { () -> Void in
            self.perform(countBackend: 9, countLocal: 1)
        }
    }
    
    func testFindEmpty() {
        signUp()
        
        let store = DataStore<Person>.collection()
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", client.activeUser!.userId)
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(query, readPolicy: .forceNetwork) { results, error in
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let results = results {
                XCTAssertEqual(results.count, 0)
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationFind = nil
        }
    }
    
    func testPullAllRecords() {
        signUp()
        
        let store = DataStore<Person>.collection(.sync)
        
        let person = Person()
        person.name = "Victor"
        
        do {
            weak var expectationSave = expectation(description: "Save")
            
            store.save(person) { person, error in
                XCTAssertNotNil(person)
                XCTAssertNil(error)
                
                if let person = person {
                    XCTAssertEqual(person.name, "Victor")
                }
                
                expectationSave?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationSave = nil
            }
        }
        
        do {
            weak var expectationPush = expectation(description: "Push")
            
            store.push() { count, error in
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                if let count = count {
                    XCTAssertEqual(count, 1)
                }
                
                expectationPush?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationPush = nil
            }
        }
        
        do {
            weak var expectationPull = expectation(description: "Pull")
            
            store.pull(deltaSet: true) { results, error in
                XCTAssertNotNil(results)
                XCTAssertNil(error)
                
                if let results = results {
                    XCTAssertGreaterThanOrEqual(results.count, 1)
                }
                
                expectationPull?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { (error) in
                expectationPull = nil
            }
        }
    }
    
    func testFindOneRecord() {
        signUp()
        
        let store = DataStore<Person>.collection()
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", client.activeUser!.userId)
        
        class OnePersonURLProtocol: URLProtocol {
            
            static var userId = ""
            
            override class func canInit(with request: URLRequest) -> Bool {
                return true
            }
            
            override class func canonicalRequest(for request: URLRequest) -> URLRequest {
                return request
            }
            
            override func startLoading() {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                client!.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                
                let object = [
                    [
                        "_id": UUID().uuidString,
                        "name": "Person 1",
                        "_acl": [
                            "creator": OnePersonURLProtocol.userId
                        ],
                        "_kmd": [
                            "lmt": "2016-03-18T17:48:14.875Z",
                            "ect": "2016-03-18T17:48:14.875Z"
                        ]
                    ]
                ]
                let data = try! JSONSerialization.data(withJSONObject: object, options: [])
                client!.urlProtocol(self, didLoad: data)
                
                client!.urlProtocolDidFinishLoading(self)
            }
            
            override func stopLoading() {
            }
            
        }
        
        OnePersonURLProtocol.userId = client.activeUser!.userId
        
        setURLProtocol(OnePersonURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(query, readPolicy: .forceNetwork) { results, error in
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let results = results {
                XCTAssertEqual(results.count, 1)
                
                if let person = results.first {
                    XCTAssertEqual(person.name, "Person 1")
                }
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationFind = nil
        }
    }
    
    func testFindOneRecordDeltaSet() {
        signUp()
        
        let store = DataStore<Person>.collection(.sync, deltaSet: true)
        
        let person = Person()
        person.name = "Victor"
        
        weak var expectationSave = expectation(description: "Save")
        
        store.save(person) { (person, error) in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNotNil(person)
            XCTAssertNil(error)
            
            expectationSave?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationSave = nil
        }
        
        weak var expectationPush = expectation(description: "Push")
        
        store.push() { (count, error) in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNotNil(count)
            XCTAssertNil(error)
            
            expectationPush?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationPush = nil
        }
        
        let query = Query(format: "\(Person.aclProperty() ?? PersistableAclKey).creator == %@", client.activeUser!.userId)
        
        class OnePersonURLProtocol: URLProtocol {
            
            static var userId = ""
            static var urlProtocolCalled = false
            
            override class func canInit(with request: URLRequest) -> Bool {
                return !urlProtocolCalled
            }
            
            override class func canonicalRequest(for request: URLRequest) -> URLRequest {
                return request
            }
            
            override func startLoading() {
                OnePersonURLProtocol.urlProtocolCalled = true
                
                var queryParams = [String : String]()
                let components = request.url?.query?.components(separatedBy: "&")
                XCTAssertNotNil(components)
                if let components = components {
                    for component in components {
                        let keyValuePair = component.components(separatedBy: "=")
                        queryParams[keyValuePair[0]] = keyValuePair[1]
                    }
                    let fields = queryParams["fields"]
                    XCTAssertNotNil(fields)
                    if let fields = fields {
                        let fieldsArray = fields.components(separatedBy: ",").sorted()
                        XCTAssertGreaterThanOrEqual(fieldsArray.count, 2)
                        if fieldsArray.count >= 2 {
                            XCTAssertEqual(fieldsArray[0], "_id")
                            XCTAssertEqual(fieldsArray[1], "_kmd.lmt")
                        }
                    }
                }
                
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type" : "application/json; charset=utf-8"])!
                client!.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                
                let object = [
                    [
                        "_id": UUID().uuidString,
                        "name": "Victor",
                        "_acl": [
                            "creator": OnePersonURLProtocol.userId
                        ],
                        "_kmd": [
                            "lmt": "2016-03-18T17:48:14.875Z",
                            "ect": "2016-03-18T17:48:14.875Z"
                        ]
                    ]
                ]
                let data = try! JSONSerialization.data(withJSONObject: object, options: [])
                client!.urlProtocol(self, didLoad: data)
                
                client!.urlProtocolDidFinishLoading(self)
            }
            
            override func stopLoading() {
            }
            
        }
        
        OnePersonURLProtocol.userId = client.activeUser!.userId
        
        setURLProtocol(OnePersonURLProtocol.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(query, readPolicy: .forceNetwork) { results, error in
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let results = results {
                XCTAssertEqual(results.count, 1)
                
                if let person = results.first {
                    XCTAssertEqual(person.name, "Victor")
                }
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { (error) in
            expectationFind = nil
        }
        
        XCTAssertTrue(OnePersonURLProtocol.urlProtocolCalled)
    }
    
}
