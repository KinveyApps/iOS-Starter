//
//  FileTestCase.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-05-11.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
@testable import Kinvey

class FileTestCase: StoreTestCase {
    
    var file: File?
    
    lazy var fileStore: FileStore = {
        return FileStore.getInstance()
    }()
    
    override func tearDown() {
        if let file = file, let _ = file.fileId {
            weak var expectationRemove = expectation(description: "Remove")
            
            fileStore.remove(file) { (count, error) in
                XCTAssertNotNil(count)
                XCTAssertNil(error)
                
                if let count = count {
                    XCTAssertEqual(count, 1)
                }
                
                expectationRemove?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationRemove = nil
            }
        }
        
        super.tearDown()
    }
    
    fileprivate func reportMemory() -> Int64? {
        var info = task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int64(info.resident_size)
        }
        
        return nil
    }
    
    func testUpload() {
        signUp()
        
        let file = File() {
            $0.publicAccessible = true
        }
        self.file = file
        let path = Bundle(for: type(of: self)).path(forResource: "Caminandes 3 - TRAILER", ofType: "mp4")!
        
        weak var expectationUpload = expectation(description: "Upload")
        
        let memoryBefore = reportMemory()
        XCTAssertNotNil(memoryBefore)
        
        let request = fileStore.upload(file, path: path) { (file, error) in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNotNil(file)
            XCTAssertNil(error)
            
            let memoryNow = self.reportMemory()
            XCTAssertNotNil(memoryNow)
            if let memoryBefore = memoryBefore, let memoryNow = memoryNow {
                let diff = memoryNow - memoryBefore
                XCTAssertLessThan(diff, 10899706)
            }
            
            expectationUpload?.fulfill()
        }
        
        var uploadProgressCount = 0
        var uploadProgressSent: Int64? = nil
        var uploadProgressTotal: Int64? = nil
        request.progress = {
            XCTAssertTrue(Thread.isMainThread)
            if $0.countOfBytesSent == $0.countOfBytesExpectedToSend {
                //upload finished
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
        
        let memoryNow = reportMemory()
        XCTAssertNotNil(memoryNow)
        if let memoryBefore = memoryBefore, let memoryNow = memoryNow {
            let diff = memoryNow - memoryBefore
            XCTAssertLessThan(diff, 10899706)
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationUpload = nil
        }
        
        XCTAssertGreaterThan(uploadProgressCount, 0)
        
        XCTAssertNotNil(file.fileId)
        
        do {
            weak var expectationDownload = expectation(description: "Download")
            
            let request = fileStore.download(file) { (file, data: Data?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                
                if let data = data {
                    XCTAssertEqual(data.count, 10899706)
                }
                
                expectationDownload?.fulfill()
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
                expectationDownload = nil
            }
            
            XCTAssertGreaterThan(downloadProgressCount, 0)
        }
    }
    
    func testUploadAndResume() {
        signUp()
        
        let file = File() {
            $0.publicAccessible = true
        }
        self.file = file
        let path = Bundle(for: type(of: self)).path(forResource: "Caminandes 3 - TRAILER", ofType: "mp4")!
        
        do {
            weak var expectationUpload = expectation(description: "Upload")
            
            let request = fileStore.upload(file, path: path) { (file, error) in
                XCTFail()
            }
            
            let delayTime = DispatchTime.now() + Double(Int64(3 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                request.cancel()
                expectationUpload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUpload = nil
            }
        }
        
        XCTAssertNotNil(file.fileId)
        
        do {
            weak var expectationWait = expectation(description: "Wait")
            
            let delayTime = DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                expectationWait?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationWait = nil
            }
        }
        
        do {
            weak var expectationUpload = expectation(description: "Upload")
            
            fileStore.upload(file, path: path) { (file, error) in
                XCTAssertNotNil(file)
                XCTAssertNil(error)
                
                expectationUpload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUpload = nil
            }
        }
        
        do {
            weak var expectationDownload = expectation(description: "Download")
            
            fileStore.download(file) { (file, data: Data?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                
                if let data = data {
                    XCTAssertEqual(data.count, 10899706)
                }
                
                expectationDownload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDownload = nil
            }
        }
    }
    
    func testDownloadAndResume() {
        signUp()
        
        let file = File() {
            $0.publicAccessible = true
        }
        self.file = file
        let path = Bundle(for: type(of: self)).path(forResource: "Caminandes 3 - TRAILER", ofType: "mp4")!
        
        weak var expectationUpload = expectation(description: "Upload")
        
        fileStore.upload(file, path: path) { (file, error) in
            XCTAssertNotNil(file)
            XCTAssertNil(error)
            
            expectationUpload?.fulfill()
        }
        
        waitForExpectations(timeout: defaultTimeout) { error in
            expectationUpload = nil
        }
        
        XCTAssertNotNil(file.fileId)
        
        do {
            weak var expectationDownload = expectation(description: "Download")
            
            let request = fileStore.download(file) { (file, data: Data?, error) in
                XCTFail()
            }
            
            let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                request.cancel()
                expectationDownload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDownload = nil
            }
        }
        
        XCTAssertNotNil(file.resumeDownloadData)
        if let resumeData = file.resumeDownloadData {
            XCTAssertGreaterThan(resumeData.count, 0)
        }
        
        do {
            weak var expectationDownload = expectation(description: "Download")
            
            fileStore.download(file) { (file, data: Data?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(data)
                XCTAssertNil(error)
                
                if let data = data {
                    XCTAssertEqual(data.count, 10899706)
                }
                
                expectationDownload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDownload = nil
            }
        }
    }
    
    func testUploadDataDownloadPath() {
        signUp()
        
        let file = File() {
            $0.publicAccessible = true
        }
        self.file = file
        let data = "Hello".data(using: String.Encoding.utf8)!
        
        do {
            weak var expectationUpload = expectation(description: "Upload")
            
            fileStore.upload(file, data: data) { (file, error) in
                XCTAssertNotNil(file)
                XCTAssertNil(error)
                
                expectationUpload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUpload = nil
            }
        }
        
        XCTAssertNotNil(file.fileId)
        
        do {
            weak var expectationDownload = expectation(description: "Download")
            
            fileStore.download(file) { (file, url: URL?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(url)
                XCTAssertNil(error)
                
                if let url = url, let _data = try? Data(contentsOf: url) {
                    XCTAssertEqual(data.count, _data.count)
                }
                
                expectationDownload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDownload = nil
            }
        }
        
        do {
            weak var expectationCached = expectation(description: "Cached")
            weak var expectationDownload = expectation(description: "Download")
            
            fileStore.download(file) { (file, url: URL?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(url)
                XCTAssertNotNil(url?.path)
                XCTAssertNil(error)
                
                if let url = url {
                    XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
                    
                    if let dataTmp = try? Data(contentsOf: url) {
                        XCTAssertEqual(dataTmp.count, data.count)
                    } else {
                        XCTFail()
                    }
                } else {
                    XCTFail()
                }
                
                if let _ = expectationCached {
                    expectationCached?.fulfill()
                    expectationCached = nil
                } else {
                    expectationDownload?.fulfill()
                }
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationCached = nil
                expectationDownload = nil
            }
        }
        
        let data2 = "Hello World".data(using: String.Encoding.utf8)!
        
        do {
            weak var expectationUpload = expectation(description: "Upload")
            
            fileStore.upload(file, data: data2) { (file, error) in
                XCTAssertNotNil(file)
                XCTAssertNil(error)
                
                expectationUpload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUpload = nil
            }
        }
        
        do {
            weak var expectationCached = expectation(description: "Cached")
            weak var expectationDownload = expectation(description: "Download")
            
            fileStore.download(file) { (file, url: URL?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(url)
                XCTAssertNotNil(url?.path)
                XCTAssertNil(error)
                
                if let _ = expectationCached {
                    if let url = url,
                        let dataTmp = try? Data(contentsOf: url)
                    {
                        XCTAssertEqual(dataTmp.count, data.count)
                    } else {
                        XCTFail()
                    }
                    
                    expectationCached?.fulfill()
                    expectationCached = nil
                } else {
                    if let url = url,
                        let dataTmp = try? Data(contentsOf: url)
                    {
                        XCTAssertEqual(dataTmp.count, data2.count)
                    } else {
                        XCTFail()
                    }
                    
                    expectationDownload?.fulfill()
                }
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationCached = nil
                expectationDownload = nil
            }
        }
    }
    
    func testUploadPathDownloadPath() {
        signUp()
        
        let file = File() {
            $0.publicAccessible = true
        }
        self.file = file
        let data = "Hello".data(using: String.Encoding.utf8)!
        
        let path = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("upload")
        do {
            try data.write(to: path, options: [.atomic])
        } catch {
            XCTFail()
        }
        
        do {
            weak var expectationUpload = expectation(description: "Upload")
            
            fileStore.upload(file, path: path.path) { (file, error) in
                XCTAssertNotNil(file)
                XCTAssertNil(error)
                
                expectationUpload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUpload = nil
            }
        }
        
        XCTAssertNotNil(file.fileId)
        
        do {
            weak var expectationDownload = expectation(description: "Download")
            
            fileStore.download(file) { (file, url: URL?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(url)
                XCTAssertNil(error)
                
                if let url = url, let _data = try? Data(contentsOf: url) {
                    XCTAssertEqual(data.count, _data.count)
                }
                
                expectationDownload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDownload = nil
            }
        }
        
        do {
            weak var expectationCached = expectation(description: "Cached")
            weak var expectationDownload = expectation(description: "Download")
            
            fileStore.download(file) { (file, url: URL?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(url)
                XCTAssertNotNil(url?.path)
                XCTAssertNil(error)
                
                if let url = url,
                    let dataTmp = try? Data(contentsOf: url)
                {
                    XCTAssertEqual(dataTmp.count, data.count)
                } else {
                    XCTFail()
                }
                
                if let _ = expectationCached {
                    expectationCached?.fulfill()
                    expectationCached = nil
                } else {
                    expectationDownload?.fulfill()
                }
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationCached = nil
                expectationDownload = nil
            }
        }
        
        let data2 = "Hello World".data(using: String.Encoding.utf8)!
        do {
            try data2.write(to: path, options: [.atomic])
        } catch {
            XCTFail()
        }
        
        do {
            weak var expectationUpload = expectation(description: "Upload")
            
            fileStore.upload(file, path: path.path) { (file, error) in
                XCTAssertNotNil(file)
                XCTAssertNil(error)
                
                expectationUpload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUpload = nil
            }
        }
        
        do {
            weak var expectationCached = expectation(description: "Cached")
            weak var expectationDownload = expectation(description: "Download")
            
            fileStore.download(file) { (file, url: URL?, error) in
                XCTAssertNotNil(file)
                XCTAssertNotNil(url)
                XCTAssertNotNil(url?.path)
                XCTAssertNil(error)
                
                if let _ = expectationCached {
                    if let url = url,
                        let dataTmp = try? Data(contentsOf: url)
                    {
                        XCTAssertEqual(dataTmp.count, data.count)
                    } else {
                        XCTFail()
                    }
                    
                    expectationCached?.fulfill()
                    expectationCached = nil
                } else {
                    if let url = url,
                        let dataTmp = try? Data(contentsOf: url)
                    {
                        XCTAssertEqual(dataTmp.count, data2.count)
                    } else {
                        XCTFail()
                    }
                    
                    expectationDownload?.fulfill()
                }
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationCached = nil
                expectationDownload = nil
            }
        }
    }
    
    func testUploadTTLExpired() {
        signUp()
        
        let file = File() {
            $0.publicAccessible = false
        }
        self.file = file
        let data = "Hello".data(using: String.Encoding.utf8)!
        
        let beforeDate = Date()
        let ttl = TTL(10, .second)
        
        do {
            weak var expectationUpload = expectation(description: "Upload")
            
            fileStore.upload(file, data: data, ttl: ttl) { (file, error) in
                XCTAssertNotNil(file)
                XCTAssertNil(error)
                
                expectationUpload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUpload = nil
            }
        }
        
        XCTAssertNotNil(file.fileId)
        XCTAssertNotNil(file.expiresAt)
        
        if let expiresAt = file.expiresAt {
            XCTAssertGreaterThan(expiresAt.timeIntervalSince(beforeDate), ttl.1.toTimeInterval(ttl.0))
            
            let twentySecs = TTL(20, .second)
            XCTAssertLessThan(expiresAt.timeIntervalSince(beforeDate), twentySecs.1.toTimeInterval(twentySecs.0))
        }
    }
    
    func testDownloadTTLExpired() {
        signUp()
        
        let file = File() {
            $0.publicAccessible = false
        }
        self.file = file
        let data = "Hello".data(using: String.Encoding.utf8)!
        
        let ttl = TTL(10, .second)
        
        do {
            weak var expectationUpload = expectation(description: "Upload")
            
            fileStore.upload(file, data: data) { (file, error) in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(file)
                XCTAssertNil(error)
                
                expectationUpload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationUpload = nil
            }
        }
        
        XCTAssertNotNil(file.fileId)
        
        file.download = nil
        file.expiresAt = nil
        
        let beforeDate = Date()
        
        do {
            weak var expectationDownload = expectation(description: "Download")
            
            fileStore.download(file, ttl: ttl) { (file, url: URL?, error) in
                XCTAssertTrue(Thread.isMainThread)
                XCTAssertNotNil(file)
                XCTAssertNotNil(url)
                XCTAssertNil(error)
                
                if let url = url, let _data = try? Data(contentsOf: url) {
                    XCTAssertEqual(data.count, _data.count)
                }
                
                expectationDownload?.fulfill()
            }
            
            waitForExpectations(timeout: defaultTimeout) { error in
                expectationDownload = nil
            }
        }
        
        XCTAssertNotNil(file.expiresAt)
        
        if let expiresAt = file.expiresAt {
            XCTAssertGreaterThan(expiresAt.timeIntervalSince(beforeDate), ttl.1.toTimeInterval(ttl.0 - 1))
            
            let twentySecs = TTL(20, .second)
            XCTAssertLessThan(expiresAt.timeIntervalSince(beforeDate), twentySecs.1.toTimeInterval(twentySecs.0))
        }
    }
    
}
