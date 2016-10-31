//
//  TaskRequest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-08-23.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

/// It holds the progress status of a request.
@objc(KNVProgressStatus)
open class ProgressStatus: NSObject {
    
    ///The number of bytes that the request has sent to the server in the request body. (read-only)
    open let countOfBytesSent: Int64
    
    ///The number of bytes that the request expects to send in the request body. (read-only)
    open let countOfBytesExpectedToSend: Int64
    
    ///The number of bytes that the request has received from the server in the response body. (read-only)
    open let countOfBytesReceived: Int64
    
    ///The number of bytes that the request expects to receive in the response body. (read-only)
    open let countOfBytesExpectedToReceive: Int64
    
    init(_ task: URLSessionTask) {
        countOfBytesSent = task.countOfBytesSent
        countOfBytesExpectedToSend = task.countOfBytesExpectedToSend
        countOfBytesReceived = task.countOfBytesReceived
        countOfBytesExpectedToReceive = task.countOfBytesExpectedToReceive
    }
    
}

/// Compare 2 ProgressStatus instances and returns `true` if they are equal
public func ==(lhs: ProgressStatus, rhs: ProgressStatus) -> Bool {
    return lhs.countOfBytesSent == rhs.countOfBytesSent &&
        lhs.countOfBytesExpectedToSend == rhs.countOfBytesExpectedToSend &&
        lhs.countOfBytesReceived == rhs.countOfBytesReceived &&
        lhs.countOfBytesExpectedToReceive == rhs.countOfBytesExpectedToReceive
}

/// Compare 2 ProgressStatus instances and returns `true` if they are not equal
public func !=(lhs: ProgressStatus, rhs: ProgressStatus) -> Bool {
    return lhs.countOfBytesSent != rhs.countOfBytesSent ||
        lhs.countOfBytesExpectedToSend != rhs.countOfBytesExpectedToSend ||
        lhs.countOfBytesReceived != rhs.countOfBytesReceived ||
        lhs.countOfBytesExpectedToReceive != rhs.countOfBytesExpectedToReceive
}

class TaskProgressRequest: NSObject {
    
    var task: URLSessionTask? {
        didSet {
            if let task = task {
                addObservers(task)
            } else {
                removeObservers(oldValue)
            }
        }
    }
    
    var progress: ((ProgressStatus) -> Void)? {
        didSet { addObservers(task) }
    }
    
    var progressObserving = false
    
    fileprivate let lock = NSLock()
    
    func addObservers(_ task: URLSessionTask?) {
        lock.lock()
        if let task = task {
            if !progressObserving && progress != nil {
                progressObserving = true
                task.addObserver(self, forKeyPath: "countOfBytesSent", options: [.new], context: nil)
                task.addObserver(self, forKeyPath: "countOfBytesExpectedToSend", options: [.new], context: nil)
                task.addObserver(self, forKeyPath: "countOfBytesReceived", options: [.new], context: nil)
                task.addObserver(self, forKeyPath: "countOfBytesExpectedToReceive", options: [.new], context: nil)
            }
        }
        lock.unlock()
    }
    
    func removeObservers(_ task: URLSessionTask?) {
        lock.lock()
        if let task = task {
            if progressObserving && progress != nil {
                progressObserving = false
                task.removeObserver(self, forKeyPath: "countOfBytesSent")
                task.removeObserver(self, forKeyPath: "countOfBytesExpectedToSend")
                task.removeObserver(self, forKeyPath: "countOfBytesReceived")
                task.removeObserver(self, forKeyPath: "countOfBytesExpectedToReceive")
            }
        }
        lock.unlock()
    }
    
    deinit {
        removeObservers(task)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let _ = object as? URLSessionTask, let keyPath = keyPath {
            switch keyPath {
            case "countOfBytesReceived":
                reportProgress()
            case "countOfBytesExpectedToReceive":
                reportProgress()
            case "countOfBytesSent":
                reportProgress()
            case "countOfBytesExpectedToSend":
                reportProgress()
            default:
                break
            }
        }
    }
    
    fileprivate var lastProgressStatus: ProgressStatus?
    
    fileprivate func reportProgress() {
        if let _ = progress,
            let task = task
        {
            let progressStatus = ProgressStatus(task)
            if (progressStatus.countOfBytesSent == progressStatus.countOfBytesExpectedToSend && progressStatus.countOfBytesReceived >= 0 && progressStatus.countOfBytesExpectedToReceive > 0) ||
                (progressStatus.countOfBytesSent >= 0 && progressStatus.countOfBytesExpectedToSend > 0)
            {
                DispatchQueue.main.async {
                    if self.lastProgressStatus == nil || (self.lastProgressStatus!) != progressStatus {
                        self.lastProgressStatus = progressStatus
                        self.progress?(progressStatus)
                    }
                }
            }
        }
    }
    
}
