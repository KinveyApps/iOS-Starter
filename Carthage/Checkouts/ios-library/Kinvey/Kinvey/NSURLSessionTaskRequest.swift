//
//  NSURLSessionDownloadTaskRequest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-04.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit

@objc(__KNVNSURLSessionDownloadTaskRequest)
class NSURLSessionTaskRequest: TaskProgressRequest, Request {
    
    var executing: Bool {
        get {
            return task?.state == .running
        }
    }
    
    var cancelled: Bool {
        get {
            return task?.state == .canceling || (task?.error as? NSError)?.code == NSURLErrorCancelled
        }
    }
    
    let client: Client
    var url: URL
    var file: File?
    
    init(client: Client, url: URL) {
        self.client = client
        self.url = url
    }
    
    convenience init(client: Client, task: URLSessionTask) {
        self.init(client: client, url: task.originalRequest!.url!)
        self.task = task
        addObservers(task)
    }
    
    func cancel() {
        if let file = self.file, let downloadTask = task as? URLSessionDownloadTask {
            let lock = NSCondition()
            lock.lock()
            downloadTask.cancel { (data) -> Void in
                lock.lock()
                file.resumeDownloadData = data
                lock.signal()
                lock.unlock()
            }
            lock.wait()
            lock.unlock()
        } else {
            task?.cancel()
        }
    }
    
    fileprivate func downloadTask(_ url: URL?, response: URLResponse?, error: Swift.Error?, fulfill: ((Data, Response)) -> Void, reject: (Swift.Error) -> Void) {
        if let response = response as? HTTPURLResponse , 200 <= response.statusCode && response.statusCode < 300, let url = url, let data = try? Data(contentsOf: url) {
            fulfill((data, HttpResponse(response: response)))
        } else if let error = error {
            reject(error)
        } else {
            reject(Error.invalidResponse)
        }
    }
    
    fileprivate func downloadTask(_ url: URL?, response: URLResponse?, error: Swift.Error?, completionHandler: PathResponseCompletionHandler) {
        if let response = response as? HTTPURLResponse?, let httpResponse = HttpResponse(response: response) , httpResponse.isOK || httpResponse.isNotModified, let url = url {
            completionHandler(url, httpResponse, nil)
        } else if let error = error {
            completionHandler(nil, nil, error)
        } else {
            completionHandler(nil, nil, Error.invalidResponse)
        }
    }
    
    func downloadTaskWithURL(_ file: File, completionHandler: @escaping DataResponseCompletionHandler) {
        self.file = file
        Promise<(Data, Response)> { fulfill, reject in
            if let resumeData = file.resumeDownloadData {
                task = self.client.urlSession.downloadTask(withResumeData: resumeData) { (url, response, error) -> Void in
                    self.downloadTask(url, response: response, error: error, fulfill: fulfill, reject: reject)
                }
            } else {
                task = self.client.urlSession.downloadTask(with: url) { (url, response, error) -> Void in
                    self.downloadTask(url, response: response, error: error, fulfill: fulfill, reject: reject)
                }
            }
            task!.resume()
        }.then { data, response in
            completionHandler(data, response, nil)
        }.catch { error in
            completionHandler(nil, nil, error)
        }
    }
    
    func downloadTaskWithURL(_ file: File, completionHandler: @escaping PathResponseCompletionHandler) {
        self.file = file
        
        if let resumeData = file.resumeDownloadData {
            task = self.client.urlSession.downloadTask(withResumeData: resumeData) { (url, response, error) -> Void in
                self.downloadTask(url, response: response, error: error, completionHandler: completionHandler)
            }
        } else {
            var request = URLRequest(url: url)
            if let etag = file.etag {
                request.setValue(etag, forHTTPHeaderField: "If-None-Match")
            }
            task = self.client.urlSession.downloadTask(with: request) { (url, response, error) -> Void in
                self.downloadTask(url, response: response, error: error, completionHandler: completionHandler)
            }
        }
        task!.resume()
    }
    
}
