//
//  NetworkStoreTests.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-15.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class NetworkStoreTests: StoreTestCase {
    
    override func setUp() {
        super.setUp()
        signUp()
        
        store = DataStore<Person>.collection()
    }
    
    override func assertThread() {
        XCTAssertTrue(Thread.isMainThread)
    }
    
    func testSaveEvent() {
        let store = DataStore<Event>.collection(.network)
        
        let event = Event()
        event.name = "Friday Party!"
        event.publishDate = Date(timeIntervalSince1970: 1468001397) // Fri, 08 Jul 2016 18:09:57 GMT
        event.location = "The closest pub!"
        
        event.acl?.globalRead.value = true
        event.acl?.globalWrite.value = true
        
        do {
            weak var expectationCreate = expectation(description: "Create")
            
            let request = store.save(event) { event, error in
                XCTAssertNotNil(event)
                XCTAssertNil(error)
                
                if let event = event {
                    XCTAssertNotNil(event.entityId)
                    XCTAssertNotNil(event.name)
                    XCTAssertNotNil(event.publishDate)
                    XCTAssertNotNil(event.location)
                }
                
                expectationCreate?.fulfill()
            }
            
            var uploadProgressCount = 0
            var uploadProgressSent: Int64? = nil
            var uploadProgressTotal: Int64? = nil
            
            var downloadProgressCount = 0
            var downloadProgressSent: Int64? = nil
            var downloadProgressTotal: Int64? = nil
            
            request.progress = {
                XCTAssertTrue(Thread.isMainThread)
                if $0.countOfBytesSent == $0.countOfBytesExpectedToSend && $0.countOfBytesExpectedToReceive > 0 {
                    if downloadProgressCount == 0 {
                        downloadProgressSent = $0.countOfBytesReceived
                        downloadProgressTotal = $0.countOfBytesExpectedToReceive
                    } else {
                        XCTAssertEqual(downloadProgressTotal, $0.countOfBytesExpectedToReceive)
                        XCTAssertGreaterThan($0.countOfBytesReceived, downloadProgressSent!)
                        downloadProgressSent = $0.countOfBytesReceived
                    }
                    downloadProgressCount += 1
                    print("Download: \($0.countOfBytesReceived)/\($0.countOfBytesExpectedToReceive)")
                } else {
                    if uploadProgressCount == 0 {
                        uploadProgressSent = $0.countOfBytesSent
                        uploadProgressTotal = $0.countOfBytesExpectedToSend
                    } else {
                        XCTAssertEqual(uploadProgressTotal, $0.countOfBytesExpectedToSend)
                        XCTAssertGreaterThan($0.countOfBytesSent, uploadProgressSent!)
                        uploadProgressSent = $0.countOfBytesSent
                    }
                    uploadProgressCount += 1
                    print("Upload: \($0.countOfBytesSent)/\($0.countOfBytesExpectedToSend)")
                }
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationCreate = nil
            }
            
            XCTAssertGreaterThan(uploadProgressCount, 0)
            XCTAssertGreaterThan(downloadProgressCount, 0)
        }
        
        XCTAssertNotNil(event.entityId)
        
        if let eventId = event.entityId {
            weak var expectationFind = expectation(description: "Find")
            
            let request = store.find(eventId) { event, error in
                XCTAssertNotNil(event)
                XCTAssertNil(error)
                
                if let event = event {
                    XCTAssertNotNil(event.entityId)
                    XCTAssertNotNil(event.name)
                    XCTAssertNotNil(event.publishDate)
                    XCTAssertNotNil(event.location)
                }
                
                expectationFind?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
        }
        
        do {
            class DelayURLProtocol: URLProtocol {
                
                static var delay: TimeInterval?
                
                override class func canInit(with request: URLRequest) -> Bool {
                    return true
                }
                
                override class func canonicalRequest(for request: URLRequest) -> URLRequest {
                    return request
                }
                
                override func startLoading() {
                    if let delay = DelayURLProtocol.delay {
                        Thread.sleep(forTimeInterval: delay)
                    }
                    
                    NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue()) { (response, data, error) in
                        self.client?.urlProtocol(self, didReceive: response!, cacheStoragePolicy: .notAllowed)
                        self.client?.urlProtocol(self, didLoad: data!)
                        if let delay = DelayURLProtocol.delay {
                            Thread.sleep(forTimeInterval: delay)
                        }
                        self.client?.urlProtocolDidFinishLoading(self)
                    }
                }
                
                override func stopLoading() {
                }
                
            }
            
            DelayURLProtocol.delay = 1
            
            setURLProtocol(DelayURLProtocol.self)
            defer {
                setURLProtocol(nil)
            }
            
            weak var expectationFind = expectation(description: "Find")
            
            let request = store.find() { (events, error) in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(events)
                XCTAssertNil(error)
                
                expectationFind?.fulfill()
            }
            
            var downloadProgressCount = 0
            var downloadProgressSent: Int64? = nil
            var downloadProgressTotal: Int64? = nil
            request.progress = {
                XCTAssertTrue(Thread.isMainThread)
                if downloadProgressCount == 0 {
                    downloadProgressSent = $0.countOfBytesReceived
                    downloadProgressTotal = $0.countOfBytesExpectedToReceive
                } else {
                    XCTAssertEqual(downloadProgressTotal, $0.countOfBytesExpectedToReceive)
                    XCTAssertGreaterThan($0.countOfBytesReceived, downloadProgressSent!)
                    downloadProgressSent = $0.countOfBytesReceived
                }
                downloadProgressCount += 1
                print("Download: \($0.countOfBytesReceived)/\($0.countOfBytesExpectedToReceive)")
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationFind = nil
            }
            
            XCTAssertGreaterThan(downloadProgressCount, 0)
        }
    }
    
    func testSaveAddress() {
        var person = Person()
        person.name = "Victor Barros"
        
        let address = Address()
        address.city = "Vancouver"
        
        person.address = address
        
        weak var expectationSave = expectation(description: "Save")
        
        store.save(person, writePolicy: .forceNetwork) { person, error in
            XCTAssertNotNil(person)
            XCTAssertNil(error)
            
            if let person = person {
                XCTAssertNotNil(person.address)
                
                if let address = person.address {
                    XCTAssertNotNil(address.city)
                }
            }
            
            expectationSave?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationSave = nil
        }
    }
    
    func testCount() {
        let store = DataStore<Event>.collection(.network)
        
        var eventsCount: Int? = nil
        
        do {
            weak var expectationCount = expectation(description: "Count")
            
            store.count { (count, error) in
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                if let count = count {
                    eventsCount = count
                }
                
                expectationCount?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationCount = nil
            }
        }
        
        XCTAssertNotNil(eventsCount)
        
        do {
            let event = Event()
            event.name = "Friday Party!"
            
            weak var expectationCreate = expectation(description: "Create")
            
            store.save(event) { event, error in
                XCTAssertNotNil(event)
                XCTAssertNil(error)
                
                expectationCreate?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationCreate = nil
            }
        }
        
        do {
            weak var expectationCount = expectation(description: "Count")
            
            store.count { (count, error) in
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                if let eventsCount = eventsCount, let count = count {
                    XCTAssertEqual(eventsCount + 1, count)
                }
                
                expectationCount?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationCount = nil
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
            var person = Person {
                $0.name = "Person \(i)"
            }
            
            weak var expectationSave = self.expectation(description: "Save")
            
            self.store.save(person, writePolicy: .forceNetwork) { person, error in
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
                $0.predicate = NSPredicate(format: "acl.creator == %@", user.userId)
                $0.skip = skip
                $0.limit = limit
                $0.ascending("name")
            }
            
            store.find(query, readPolicy: .forceNetwork) { results, error in
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
    
    class MethodNotAllowedError: URLProtocol {
        
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            let response = HTTPURLResponse(url: request.url!, statusCode: 405, httpVersion: "1.1", headerFields: [:])!
            client!.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            
            let responseBody = [
                "error": "MethodNotAllowed",
                "debug": "insert' method is not allowed for this collection.",
                "description": "The method is not allowed for this resource."
            ]
            let responseBodyData = try! JSONSerialization.data(withJSONObject: responseBody, options: [])
            client!.urlProtocol(self, didLoad: responseBodyData)
            
            client!.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {
        }
        
    }
    
    class DataLinkEntityNotFoundError: URLProtocol {
        
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: "1.1", headerFields: [:])!
            client!.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            
            let responseBody = [
                "error": "DataLinkEntityNotFound",
                "debug": "Error: Not Found",
                "description": "The data link could not find this entity"
            ]
            let responseBodyData = try! JSONSerialization.data(withJSONObject: responseBody, options: [])
            client!.urlProtocol(self, didLoad: responseBodyData)
            
            client!.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {
        }
        
    }
    
    func testGetDataLinkEntityNotFound() {
        setURLProtocol(DataLinkEntityNotFoundError.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find("sample-id", readPolicy: .forceNetwork) { person, error in
            XCTAssertNil(person)
            XCTAssertNotNil(error)
            XCTAssertTrue(error is Kinvey.Error)
            
            if let error = error as? Kinvey.Error {
                switch error {
                case .dataLinkEntityNotFound(let debug, let description):
                    XCTAssertEqual(debug, "Error: Not Found")
                    XCTAssertEqual(description, "The data link could not find this entity")
                default:
                    XCTFail()
                }
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testSaveMethodNotAllowed() {
        setURLProtocol(MethodNotAllowedError.self)
        defer {
            setURLProtocol(nil)
        }
        
        let person = Person()
        person.name = "Victor Barros"
        
        weak var expectationSave = expectation(description: "Save")
        
        store.save(person, writePolicy: .forceNetwork) { person, error in
            XCTAssertNil(person)
            XCTAssertNotNil(error)
            XCTAssertTrue(error is Kinvey.Error)
            
            if let error = error as? Kinvey.Error {
                switch error {
                case .methodNotAllowed(let debug, let description):
                    XCTAssertEqual(debug, "insert' method is not allowed for this collection.")
                    XCTAssertEqual(description, "The method is not allowed for this resource.")
                default:
                    XCTFail()
                }
            }
            
            expectationSave?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationSave = nil
        }
    }
    
    func testFindMethodNotAllowed() {
        setURLProtocol(MethodNotAllowedError.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find(readPolicy: .forceNetwork) { person, error in
            XCTAssertNil(person)
            XCTAssertNotNil(error)
            XCTAssertTrue(error is Kinvey.Error)
            
            if let error = error as? Kinvey.Error {
                switch error {
                case .methodNotAllowed(let debug, let description):
                    XCTAssertEqual(debug, "insert' method is not allowed for this collection.")
                    XCTAssertEqual(description, "The method is not allowed for this resource.")
                default:
                    XCTFail()
                }
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testGetMethodNotAllowed() {
        setURLProtocol(MethodNotAllowedError.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationFind = expectation(description: "Find")
        
        store.find("sample-id", readPolicy: .forceNetwork) { person, error in
            XCTAssertNil(person)
            XCTAssertNotNil(error)
            XCTAssertTrue(error is Kinvey.Error)
            
            if let error = error as? Kinvey.Error {
                switch error {
                case .methodNotAllowed(let debug, let description):
                    XCTAssertEqual(debug, "insert' method is not allowed for this collection.")
                    XCTAssertEqual(description, "The method is not allowed for this resource.")
                default:
                    XCTFail()
                }
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationFind = nil
        }
    }
    
    func testRemoveByIdMethodNotAllowed() {
        setURLProtocol(MethodNotAllowedError.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationRemove = expectation(description: "Remove")
        
        store.removeById("sample-id", writePolicy: .forceNetwork) { person, error in
            XCTAssertNil(person)
            XCTAssertNotNil(error)
            XCTAssertTrue(error is Kinvey.Error)
            
            if let error = error as? Kinvey.Error {
                switch error {
                case .methodNotAllowed(let debug, let description):
                    XCTAssertEqual(debug, "insert' method is not allowed for this collection.")
                    XCTAssertEqual(description, "The method is not allowed for this resource.")
                default:
                    XCTFail()
                }
            }
            
            expectationRemove?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationRemove = nil
        }
    }
    
    func testRemoveMethodNotAllowed() {
        setURLProtocol(MethodNotAllowedError.self)
        defer {
            setURLProtocol(nil)
        }
        
        weak var expectationRemove = expectation(description: "Remove")
        
        store.remove(writePolicy: .forceNetwork) { count, error in
            XCTAssertNil(count)
            XCTAssertNotNil(error)
            XCTAssertTrue(error is Kinvey.Error)
            
            if let error = error as? Kinvey.Error {
                switch error {
                case .methodNotAllowed(let debug, let description):
                    XCTAssertEqual(debug, "insert' method is not allowed for this collection.")
                    XCTAssertEqual(description, "The method is not allowed for this resource.")
                default:
                    XCTFail()
                }
            }
            
            expectationRemove?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationRemove = nil
        }
    }
    
}
