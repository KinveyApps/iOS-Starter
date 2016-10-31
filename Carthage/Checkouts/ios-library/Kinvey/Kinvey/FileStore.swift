//
//  FileStore.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-04.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


/// Class to interact with the `Files` collection in the backend.
open class FileStore {
    
    public typealias FileCompletionHandler = (File?, Swift.Error?) -> Void
    public typealias FileDataCompletionHandler = (File?, Data?, Swift.Error?) -> Void
    public typealias FilePathCompletionHandler = (File?, URL?, Swift.Error?) -> Void
    public typealias UIntCompletionHandler = (UInt?, Swift.Error?) -> Void
    public typealias FileArrayCompletionHandler = ([File]?, Swift.Error?) -> Void
    
    fileprivate let client: Client
    fileprivate let cache: FileCache?
    
    /// Factory method that returns a `FileStore`.
    open class func getInstance(_ client: Client = sharedClient) -> FileStore {
        return FileStore(client: client)
    }
    
    fileprivate init(client: Client) {
        self.client = client
        self.cache = client.cacheManager.fileCache(filePath: client.filePath())
    }

#if os(iOS)
    /// Uploads a `UIImage` in a PNG format.
    @discardableResult
    open func upload(_ file: File, image: UIImage, ttl: TTL? = nil, completionHandler: FileCompletionHandler? = nil) -> Request {
        let data = UIImagePNGRepresentation(image)!
        file.mimeType = "image/png"
        return upload(file, data: data, ttl: ttl, completionHandler: completionHandler)
    }
#endif
    
    /// Uploads a file using the file path.
    @discardableResult
    open func upload(_ file: File, path: String, ttl: TTL? = nil, completionHandler: FileCompletionHandler? = nil) -> Request {
        return upload(file, fromData: nil, fromFile: URL(fileURLWithPath: path), ttl: ttl, completionHandler: completionHandler)
    }
    
    /// Uploads a file using a input stream.
    @discardableResult
    open func upload(_ file: File, stream: InputStream, ttl: TTL? = nil, completionHandler: FileCompletionHandler? = nil) -> Request {
        let data = NSMutableData()
        stream.open()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: buffer.count)
            data.append(buffer, length: read)
        }
        stream.close()
        return upload(file, data: data as Data, ttl: ttl, completionHandler: completionHandler)
    }
    
    fileprivate func fillFile(_ file: File, json: JsonDictionary) {
        if let fileId = json["_id"] as? String {
            file.fileId = fileId
        }
        if let filename = json["_filename"] as? String {
            file.fileName = filename
        }
        if let publicAccessible = json["_public"] as? Bool {
            file.publicAccessible = publicAccessible
        }
        if let acl = json["_acl"] as? [String : AnyObject] {
            file.acl = Acl(JSON: acl)
        }
        if let kmd = json["_kmd"] as? [String : AnyObject] {
            file.metadata = Metadata(JSON: kmd)
        }
        if let uploadURL = json["_uploadURL"] as? String {
            file.uploadURL = URL(string: uploadURL)
        }
        if let downloadURL = json["_downloadURL"] as? String {
            file.download = downloadURL
        }
        if let requiredHeaders = json["_requiredHeaders"] as? [String : String] {
            file.uploadHeaders = requiredHeaders
        }
        if let expiresAt = json["_expiresAt"] as? String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            file.expiresAt = dateFormatter.date(from: expiresAt)
        } else {
            file.expiresAt = nil
        }
    }
    
    fileprivate func getFileMetadata(_ file: File, ttl: TTL? = nil) -> (Request, Promise<File>) {
        let request = self.client.networkRequestFactory.buildBlobDownloadFile(file, ttl: ttl)
        return (request, Promise<File> { fulfill, reject in
            request.execute({ (data, response, error) -> Void in
                if let response = response , response.isOK, let json = self.client.responseParser.parse(data) {
                    self.fillFile(file, json: json)
                    fulfill(file)
                } else {
                    reject(buildError(data, response, error, self.client))
                }
            })
        })
    }
    
    /// Uploads a file using a `NSData`.
    @discardableResult
    open func upload(_ file: File, data: Data, ttl: TTL? = nil, completionHandler: FileCompletionHandler? = nil) -> Request {
        return upload(file, fromData: data, fromFile: nil, ttl: ttl, completionHandler: completionHandler)
    }
    
    /// Uploads a file using a `NSData`.
    fileprivate func upload(_ file: File, fromData: Data?, fromFile: URL?, ttl: TTL? = nil, completionHandler: FileCompletionHandler? = nil) -> Request {
        let requests = MultiRequest()
        Promise<(file: File, skip: Int?)> { fulfill, reject in //creating bucket
            let createUpdateFileEntry = {
                let request = self.client.networkRequestFactory.buildBlobUploadFile(file)
                requests += request
                request.execute { (data, response, error) -> Void in
                    if let response = response , response.isOK, let json = self.client.responseParser.parse(data) {
                        self.fillFile(file, json: json)
                        fulfill((file: file, skip: nil))
                    } else {
                        reject(buildError(data, response, error, self.client))
                    }
                }
            }
            
            if let _ = file.fileId {
                var request = URLRequest(url: file.uploadURL!)
                request.httpMethod = "PUT"
                if let uploadHeaders = file.uploadHeaders {
                    for header in uploadHeaders {
                        request.setValue(header.1, forHTTPHeaderField: header.0)
                    }
                }
                request.setValue("0", forHTTPHeaderField: "Content-Length")
                if let data = fromData {
                    request.setValue("bytes */\(data.count)", forHTTPHeaderField: "Content-Range")
                } else if let fromFile = fromFile,
                    let attrs = try? FileManager.default.attributesOfItem(atPath: (fromFile.path as NSString).expandingTildeInPath),
                    let fileSize = attrs[FileAttributeKey.size] as? UInt
                {
                    request.setValue("bytes */\(fileSize)", forHTTPHeaderField: "Content-Range")
                }
                
                if self.client.logNetworkEnabled {
                    do {
                        print("\(request)")
                    }
                }
                
                let dataTask = self.client.urlSession.dataTask(with: request) { (data, response, error) in
                    if self.client.logNetworkEnabled, let response = response as? HTTPURLResponse {
                        do {
                            print("\(response.description(data))")
                        }
                    }
                    
                    let regexRange = try! NSRegularExpression(pattern: "[bytes=]?(\\d+)-(\\d+)", options: [])
                    if let response = response as? HTTPURLResponse , 200 <= response.statusCode && response.statusCode < 300 {
                        createUpdateFileEntry()
                    } else if let response = response as? HTTPURLResponse
                        , response.statusCode == 308,
                        let rangeString = response.allHeaderFields["Range"] as? String,
                        let textCheckingResult = regexRange.matches(in: rangeString, options: [], range: NSMakeRange(0, rangeString.characters.count)).first
                        , textCheckingResult.numberOfRanges == 3
                    {
                        let rangeNSString = rangeString as NSString
                        let endRangeString = rangeNSString.substring(with: textCheckingResult.rangeAt(2))
                        if let endRange = Int(endRangeString) {
                            fulfill((file: file, skip: endRange))
                        } else {
                            reject(Error.invalidResponse)
                        }
                    } else {
                        reject(buildError(data, HttpResponse(response: response), error, self.client))
                    }
                }
                requests += NSURLSessionTaskRequest(client: client, task: dataTask)
                dataTask.resume()
            } else {
                createUpdateFileEntry()
            }
        }.then { file, skip in //uploading data
            return Promise<File> { fulfill, reject in
                var request = URLRequest(url: file.uploadURL!)
                request.httpMethod = "PUT"
                if let uploadHeaders = file.uploadHeaders {
                    for header in uploadHeaders {
                        request.setValue(header.1, forHTTPHeaderField: header.0)
                    }
                }
                
                let handle: (Data?, URLResponse?, Swift.Error?) -> Void = { data, response, error in
                    if let response = response as? HTTPURLResponse , 200 <= response.statusCode && response.statusCode < 300 {
                        fulfill(file)
                    } else {
                        reject(buildError(data, HttpResponse(response: response), error, self.client))
                    }
                }
                
                if let data = fromData {
                    let uploadData: Data
                    if let skip = skip {
                        let startIndex = skip + 1
                        uploadData = data.subdata(in: startIndex ..< data.count - startIndex)
                        request.setValue("bytes \(startIndex)-\(data.count - 1)/\(data.count)", forHTTPHeaderField: "Content-Range")
                    } else {
                        uploadData = data
                    }
                    
                    let uploadTask = self.client.urlSession.uploadTask(with: request, from: uploadData) { (data, response, error) -> Void in
                        handle(data, response, error)
                    }
                    requests += (NSURLSessionTaskRequest(client: self.client, task: uploadTask), addProgress: true)
                    uploadTask.resume()
                } else if let fromFile = fromFile {
                    let uploadTask = self.client.urlSession.uploadTask(with: request, fromFile: fromFile) { (data, response, error) -> Void in
                        handle(data, response, error)
                    }
                    requests += (NSURLSessionTaskRequest(client: self.client, task: uploadTask), addProgress: true)
                    uploadTask.resume()
                } else {
                    reject(Error.invalidResponse)
                }
            }
        }.then { file in //fetching download url
            return self.getFileMetadata(file, ttl: ttl).1
        }.then { file in
            completionHandler?(file, nil)
        }.catch { error in
            completionHandler?(file, error)
        }
        return requests
    }
    
    /// Refresh a `File` instance.
    @discardableResult
    open func refresh(_ file: File, ttl: TTL? = nil, completionHandler: FileCompletionHandler? = nil) -> Request {
        let fileMetadata = getFileMetadata(file, ttl: ttl)
        let request = fileMetadata.0
        fileMetadata.1.then { file in
            completionHandler?(file, nil)
        }.catch { error in
            completionHandler?(file, error)
        }
        return request
    }
    
    @discardableResult
    fileprivate func downloadFile(_ file: File, storeType: StoreType = .cache, downloadURL: URL, completionHandler: FilePathCompletionHandler? = nil) -> NSURLSessionTaskRequest {
        let downloadTaskRequest = NSURLSessionTaskRequest(client: client, url: downloadURL)
        Promise<URL> { fulfill, reject in
            let executor = Executor()
            downloadTaskRequest.downloadTaskWithURL(file) { (url: URL?, response, error) in
                if let response = response , response.isOK || response.isNotModified, let url = url {
                    if storeType == .cache {
                        var pathURL: URL? = nil
                        var fileId: String? = nil
                        executor.executeAndWait {
                            fileId = file.fileId
                            pathURL = file.pathURL
                        }
                        if let pathURL = pathURL , response.isNotModified {
                            fulfill(pathURL)
                        } else {
                            let fileManager = FileManager()
                            if let fileId = fileId,
                                let baseFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
                            {
                                do {
                                    var baseFolderURL = URL(fileURLWithPath: baseFolder)
                                    baseFolderURL = baseFolderURL.appendingPathComponent(self.client.appKey!).appendingPathComponent("files")
                                    if !fileManager.fileExists(atPath: baseFolderURL.path) {
                                        try fileManager.createDirectory(at: baseFolderURL, withIntermediateDirectories: true, attributes: nil)
                                    }
                                    let toURL = baseFolderURL.appendingPathComponent(fileId)
                                    if fileManager.fileExists(atPath: toURL.path) {
                                        do {
                                            try fileManager.removeItem(atPath: toURL.path)
                                        }
                                    }
                                    try fileManager.moveItem(at: url, to: toURL)
                                    
                                    if let cache = self.cache {
                                        cache.save(file) {
                                            file.path = NSString(string: toURL.path).abbreviatingWithTildeInPath
                                            file.etag = response.etag
                                        }
                                    }
                                    
                                    fulfill(toURL)
                                } catch let error {
                                    reject(error)
                                }
                            } else {
                                reject(Error.invalidResponse)
                            }
                        }
                    } else {
                        fulfill(url)
                    }
                } else {
                    reject(buildError(nil, response, error, self.client))
                }
            }
        }.then { url in
            completionHandler?(file, url, nil)
        }.catch { error in
            completionHandler?(file, nil, error)
        }
        return downloadTaskRequest
    }
    
    @discardableResult
    fileprivate func downloadFile(_ file: File, downloadURL: URL, completionHandler: FileDataCompletionHandler? = nil) -> NSURLSessionTaskRequest {
        let downloadTaskRequest = NSURLSessionTaskRequest(client: client, url: downloadURL)
        Promise<Data> { fulfill, reject in
            downloadTaskRequest.downloadTaskWithURL(file) { (data: Data?, response, error) -> Void in
                if let response = response , response.isOK, let data = data {
                    fulfill(data)
                } else {
                    reject(buildError(data, response, error, self.client))
                }
            }
        }.then { data in
            completionHandler?(file, data, nil)
        }.catch { error in
            completionHandler?(file, nil, error)
        }
        return downloadTaskRequest
    }
    
    /// Returns the cached file, if exists.
    open func cachedFile(_ fileId: String) -> File? {
        if let cache = cache {
            return cache.get(fileId)
        }
        return nil
    }
    
    /// Returns the cached file, if exists.
    open func cachedFile(_ file: inout File) {
        guard let fileId = file.fileId else {
            fatalError("File.fileId is required")
        }
        
        if let cachedFile = cachedFile(fileId) {
            file = cachedFile
        }
    }
    
    /// Downloads a file using the `downloadURL` of the `File` instance.
    @discardableResult
    open func download(_ file: File, storeType: StoreType = .cache, ttl: TTL? = nil, completionHandler: FilePathCompletionHandler? = nil) -> Request {
        var file = file
        return download(&file, storeType: storeType, ttl: ttl, completionHandler: completionHandler)
    }
    
    fileprivate func requiresFileId(_ file: inout File) {
        guard let _ = file.fileId else {
            fatalError("File.fileId is required")
        }
    }
    
    /// Downloads a file using the `downloadURL` of the `File` instance.
    @discardableResult
    open func download(_ file: inout File, storeType: StoreType = .cache, ttl: TTL? = nil, completionHandler: FilePathCompletionHandler? = nil) -> Request {
        requiresFileId(&file)
        
        if storeType == .sync || storeType == .cache, let fileId = file.fileId, let cachedFile = cachedFile(fileId) {
            file = cachedFile
            DispatchQueue.main.async { [file] in
                completionHandler?(file, file.pathURL, nil)
            }
        }
        
        if storeType == .cache || storeType == .network {
            if let downloadURL = file.downloadURL , file.publicAccessible || file.expiresAt?.timeIntervalSinceNow > 0 {
                return downloadFile(file, storeType: storeType, downloadURL: downloadURL as URL, completionHandler: completionHandler)
            } else {
                let (request, promise) = getFileMetadata(file, ttl: ttl)
                promise.then(execute: { file -> Void in
                    if let downloadURL = file.downloadURL , file.publicAccessible || file.expiresAt?.timeIntervalSinceNow > 0 {
                        self.downloadFile(file, storeType: storeType, downloadURL: downloadURL, completionHandler: completionHandler)
                    } else {
                        completionHandler?(file, nil, Error.invalidResponse)
                    }
                }).catch { [file] error in
                    completionHandler?(file, nil, error)
                }
                return request
            }
        } else {
            return LocalRequest()
        }
    }
    
    /// Downloads a file using the `downloadURL` of the `File` instance.
    @discardableResult
    open func download(_ file: File, ttl: TTL? = nil, completionHandler: FileDataCompletionHandler? = nil) -> Request {
        var file = file
        return download(&file, ttl: ttl, completionHandler: completionHandler)
    }
    
    /// Downloads a file using the `downloadURL` of the `File` instance.
    @discardableResult
    open func download(_ file: inout File, ttl: TTL? = nil, completionHandler: FileDataCompletionHandler? = nil) -> Request {
        requiresFileId(&file)
        
        if let fileId = file.fileId, let cachedFile = cachedFile(fileId), let path = file.path, let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            file = cachedFile
            DispatchQueue.main.async { [file] in
                completionHandler?(file, data, nil)
            }
        }
        
        if let downloadURL = file.downloadURL , file.publicAccessible || file.expiresAt?.timeIntervalSinceNow > 0 {
            return downloadFile(file, downloadURL: downloadURL as URL, completionHandler: completionHandler)
        } else {
            let fileMetadata = getFileMetadata(file, ttl: ttl)
            fileMetadata.1.then { file in
                return Promise {
                    if let downloadURL = file.downloadURL , file.publicAccessible || file.expiresAt?.timeIntervalSinceNow > 0 {
                        self.downloadFile(file, downloadURL: downloadURL, completionHandler: completionHandler)
                    } else {
                        completionHandler?(file, nil, Error.invalidResponse)
                    }
                }
            }.catch { [file] error in
                completionHandler?(file, nil, error)
            }
            return fileMetadata.0
        }
    }
    
    /// Deletes a file instance in the backend.
    @discardableResult
    open func remove(_ file: File, completionHandler: UIntCompletionHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildBlobDeleteFile(file)
        Promise<UInt> { fulfill, reject in
            request.execute({ (data, response, error) -> Void in
                if let response = response , response.isOK,
                    let json = self.client.responseParser.parse(data),
                    let count = json["count"] as? UInt
                {
                    if let cache = self.cache {
                        cache.remove(file)
                    }
                    
                    fulfill(count)
                } else {
                    reject(buildError(data, response, error, self.client))
                }
            })
        }.then { count in
            completionHandler?(count, nil)
        }.catch { error in
            completionHandler?(nil, error)
        }
        return request
    }
    
    /// Gets a list of files that matches with the query passed by parameter.
    @discardableResult
    open func find(_ query: Query = Query(), ttl: TTL? = nil, completionHandler: FileArrayCompletionHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildBlobQueryFile(query, ttl: ttl)
        Promise<[File]> { fulfill, reject in
            request.execute({ (data, response, error) -> Void in
                if let response = response , response.isOK,
                    let jsonArray = self.client.responseParser.parseArray(data)
                {
                    var files: [File] = []
                    for json in jsonArray {
                        let file = File()
                        self.fillFile(file, json: json)
                        files.append(file)
                    }
                    fulfill(files)
                } else {
                    reject(buildError(data, response, error, self.client))
                }
            })
        }.then { files in
            completionHandler?(files, nil)
        }.catch { error in
            completionHandler?(nil, error)
        }
        return request
    }
    
    /**
     Clear cached files from local storage.
     */
    open func clearCache() {
        client.cacheManager.clearAll()
    }
    
}
