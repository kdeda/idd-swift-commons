//
//  JASONHandler.swift
//  SwiftCommons
//
//  Created by Klajd Deda on 8/15/17.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//

// create an instance of this class for each server request
// to make life easier for the caller, which itself SHOULD be running on a thread
// we are going to use semaphores so that even though we work on threads we will return on the calling thread
// http://www.stefanovettor.com/2015/12/10/synchronous-requests-with-nsurlsession/
//

import Foundation
import Log4swift
#if os(iOS)
    import MobileCoreServices
#endif

enum JASONHandlerRequestType: Int {
    case unknown = 1
    case jsonRequest = 2
    case binaryRequest = 3
    case downloadFileRequest = 4
    case uploadFileRequest = 5
}

public class JASONHandler: NSObject {
    static public let DownloadProgressNotification = Notification.Name("JASONHandlerDownloadProgressNotification")
    static public let UploadProgressNotification = Notification.Name("JASONHandlerUploadProgressNotification")
    
    static public var rootPath: URL = {
        var rv = URL.init(fileURLWithPath: NSTemporaryDirectory())

        rv.appendPathComponent(Bundle.main.bundleIdentifier!)
        _ = FileManager.default.createDirectoryIfMissing(at: rv)
        return rv
    }()

    lazy var logger: Logger = {
        return Log4swift.getLogger(self)
    }()
    
    public let methodName: String
    public let serverURL: URL
    public var timeoutInterval: TimeInterval = 0.0

    private var _contentType = "text/xml; charset=UTF-8"
    private var _responseData = Data.init()
    private var _lastResponse: AnyObject?
    private var _lastError: JSONHandlerError?
    private var _semaphore = DispatchSemaphore(value: 0)
    private var _requestType: JASONHandlerRequestType = .unknown
    private var _totalBytesWritten: Int64?
    private var sentByteCount: Int64?
    
    public init(methodName aMethodName: String, serverURL aServerURL: URL) {
        methodName = aMethodName
        serverURL = aServerURL.appendingPathComponent(aMethodName)
    }
    
    
    // MARK: - Private methods -
    
    private func _createHTTPBody(withJsonData jsonData: Data, fileItems items: [JSONUploadFileItem], andBoundry boundry: String) throws -> Data {
        var rv = Data()
        let CRLF = "\r\n"
        let debug = self.logger.isTrace

        // construct the json part
        //
        rv.appendString("--" + boundry + CRLF)
        rv.appendString("Content-Disposition: form-data; name=\"jsonString\"" + CRLF)
        rv.appendString(CRLF)
        rv.append(jsonData)
        rv.appendString(CRLF)
                
        for fileItem in items {
            // construct the binary part
            //
            rv.appendString("--" + boundry + CRLF)
            rv.appendString("Content-Disposition: form-data; name=\"fileItems\"; fileName=\"\(fileItem.fileName)\"" + CRLF)
            rv.appendString("Content-Type: \(fileItem.mimeType)" + CRLF)
            rv.appendString("Content-Transfer-Encoding: binary" + CRLF);
            rv.appendString(CRLF)
            if debug {
                rv.appendString(fileItem.fileName)
            } else {
                rv.append(try fileItem.fileData() as Data)
            }
            rv.appendString(CRLF)
        }
        
        rv.appendString("--" + boundry + "--" + CRLF)

        if debug {
            self.logger.info("httpBody:\(String(data: rv as Data, encoding: .utf8)!)")
        }
        return rv as Data
    }

    // https://github.com/samwang0723/URLSessionUpload/blob/master/NSURLSessionUpload/ViewController.swift
    //
    private func _post(request aRequest: URLRequest) throws {
        let task = URLSession.shared.dataTask(with: aRequest) { data, response, error in
            guard let data = data else {
                self._lastError = JSONHandlerError.noData(methodName: self.methodName, errorDescription: "no data for: '\(self.serverURL.absoluteString)'")
                self._semaphore.signal()
                return
            }
            guard let urlResponse = response else {
                self._lastError = JSONHandlerError.noResponse(methodName: self.methodName, errorDescription: "no response for: '\(self.serverURL.absoluteString)'")
                self._semaphore.signal()
                return
            }
            guard error == nil else {
                let nsError = error! as NSError
                if nsError.code == NSURLErrorSecureConnectionFailed {
                    // no SSL, bah ...
                    self.logger.debug("error: '\(nsError)' for: '\(self.serverURL.absoluteString)'")
                }
                self._lastError = JSONHandlerError.dataTask(methodName: self.methodName, error: nsError)
                self._semaphore.signal()
                return
            }

            if let httpStatus = urlResponse as? HTTPURLResponse, httpStatus.statusCode != 200 {
                self.logger.info("statusCode should be: '200', but was: '\(httpStatus.statusCode)'")
                self.logger.info("response: '\(urlResponse)'")

                self._lastError = JSONHandlerError.http(methodName: self.methodName, statusCode: httpStatus.statusCode)
            } else {
                self.logger.debug("request completed with: '\(data.count) bytes'")
//                do {
                    self._responseData = data
                    // self._lastResponse = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
//                } catch let error as NSError {
//                    self._lastError = JSONHandlerError.json(methodName: self.methodName, data: data, error: error)
//                }
            }
            self._semaphore.signal()
        }
        task.resume()
    }
    
    // MARK: - Instance methods -
    
    /*
     Send json and receive json
     */
    public func jsonRequest<Value>(_ jsonObject: Value) -> Result<Data, JSONHandlerError> where Value: Codable {
        let startDate = Date()

        _requestType = .jsonRequest
        do {
            let coder: JSONEncoder = {
                let rv = JSONEncoder()
            
                rv.outputFormatting = .prettyPrinted
                return rv
            }()
            let httpBody = (try? coder.encode(jsonObject)) ?? Data()
            var request = URLRequest(url: self.serverURL)

            if self.logger.isDebug {
                let string = String(data: httpBody, encoding: .utf8) ?? "no value ..."
                self.logger.debug("url: '\(self.serverURL)' json: '\(string)'")
            }
            if timeoutInterval > 0 {
                request.timeoutInterval = timeoutInterval
            }

            request.httpMethod = "POST"
            request.httpBody = httpBody
            request.addValue(_contentType, forHTTPHeaderField: "Content-Type")
            request.addValue("\(httpBody.count)", forHTTPHeaderField: "Content-Length")
            request.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
            request.cachePolicy = .reloadIgnoringCacheData

            try _post(request: request)
            
            _ = _semaphore.wait(timeout: .distantFuture)
        } catch let handlerError as JSONHandlerError {
            self.logger.error("handlerError: '\(handlerError)'")
        } catch {
            self.logger.error("url: '\(self.serverURL.absoluteString)'")
            self.logger.error("error: '\(error.localizedDescription)'")
        }

        if startDate.elapsedTimeInMilliseconds > 100.0 {
            self.logger.info("url: '\(self.serverURL.absoluteString)' completed in: '\(startDate.elapsedTime) ms'")
        }
        
        if let lastError = self._lastError {
            return .failure(lastError)
        }
        if self.logger.isDebug {
            let string = String(data: _responseData, encoding: .utf8) ?? "no value ..."
            self.logger.debug("url: '\(self.serverURL.absoluteString)' jsonResponse: '\(string)'")
        }
        return .success(_responseData)
    }
    
    public func serverResponse<Response, Request>(
        _ type: Response.Type,
        from request: Request
    ) -> Result<Response, JSONHandlerError> where Response: Codable, Request: Codable {
        let result = jsonRequest(request)
        
        switch result {
        case let .success(data):
            if let response = serverResponse(type, from: data) {
                return .success(response)
            }
            if let serverException = serverResponse(ServerException.self, from: data) {
                self.logger.info("serverException: '\(serverException)'")
                return .failure(JSONHandlerError.serverException(serverException))
            }
            return .failure(JSONHandlerError.unknownResponse(methodName: methodName, response: self._lastResponse))
        case let .failure(error):
            return .failure(error)
        }
    }

    public func serverResponse<Value>(_ type: Value.Type, from data: Data) -> Value? where Value: Codable {
        let decoder = JSONDecoder()
        
        decoder.dateDecodingStrategy = .formatted(Date.defaultFormatter)
        do {
            return try decoder.decode(type, from: data)
        } catch {
            let json = String(data: data, encoding: .utf8) ?? "empty_json"
            
            self.logger.error("url: '\(self.serverURL.absoluteString)'")
            self.logger.error("error: '\(error.localizedDescription)' json: '\(json)'")
        }
        return nil
    }
    
    public func serverResponse<Value>(_ type: Value.Type, from result: Result<Data, JSONHandlerError>) -> Value? where Value: Codable {
        return serverResponse(type, from: (try? result.get()) ?? Data())
    }
    
    public func jsonRequest(withContext jsonObject: [String: Any]) -> Result<[String: Any], JSONHandlerError> {
        return .failure(JSONHandlerError.unknownResponse(methodName: methodName, response: self._lastResponse))
    }
    
    /*
     Send json and receive binary
     */
    public func binaryRequest(withContext jsonObject: [String: Any?]) throws -> Data? {
//        let startDate = Date()

        _requestType = .binaryRequest
        // TODO
//        do {
//            let httpBody = try JSONSerialization.data(withJSONObject: jsonObject.toJSON, options: .prettyPrinted)
//            var request = URLRequest(url: self.serverURL)
//
//            if self.logger.isDebug {
//                let string = String(data: httpBody, encoding: .utf8) ?? "no value ..."
//                self.logger.debug("url: '\(self.serverURL)' json: '\(string)'")
//            }
//            request.httpMethod = "POST"
//            request.httpBody = httpBody
//            request.addValue("text/xml; charset=UTF-8", forHTTPHeaderField: "Content-Type")
//            request.addValue("\(httpBody.count)", forHTTPHeaderField: "Content-Length")
//            request.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
//            request.cachePolicy = .reloadIgnoringCacheData
//
//            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
//            let task = session.downloadTask(with: request)
//
//            task.resume()
//            _ = _semaphore.wait(timeout: .distantFuture)
//        } catch {
//            self.logger.error("error: '\(error.localizedDescription)'")
//        }
//
//        if startDate.elapsedTimeInMilliseconds > 100.0 {
//            self.logger.info("completed in: '\(startDate.elapsedTime) ms'")
//        }
//        if let error = self._lastError {
//            throw error
//        }
        return _responseData
    }

    /*
     Send json and receive binary
     */
    public func download(withContext jsonObject: [String: Any]) throws -> AnyObject? {
//        let startDate = Date()
        
        _requestType = .downloadFileRequest
        // TODO
//        do {
//            let httpBody = try JSONSerialization.data(withJSONObject: jsonObject.toJSON, options: .prettyPrinted)
//            var request = URLRequest(url: self.serverURL)
//            
//            if self.logger.isDebug {
//                let string = String(data: httpBody, encoding: .utf8) ?? "no value ..."
//                self.logger.debug("url: '\(self.serverURL)' json: '\(string)'")
//            }
//            request.httpMethod = "POST"
//            request.httpBody = httpBody
//            request.addValue("text/xml; charset=UTF-8", forHTTPHeaderField: "Content-Type")
//            request.addValue("\(httpBody.count)", forHTTPHeaderField: "Content-Length")
//            request.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
//            request.cachePolicy = .reloadIgnoringCacheData
//            
//            _lastResponse = jsonObject as AnyObject
//            
//            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
//            let task = session.downloadTask(with: request)
//            
//            task.resume()
//            _ = _semaphore.wait(timeout: .distantFuture)
//        } catch {
//            self.logger.error("error: '\(error.localizedDescription)'")
//        }
//        
//        if startDate.elapsedTimeInMilliseconds > 100.0 {
//            self.logger.info("completed in: '\(startDate.elapsedTime) ms'")
//        }
//        if let error = self._lastError {
//            throw error
//        }
        return self._lastResponse
    }

    /*
     Send json and binary receive json
     */
    public func upload(fileItems items: [JSONUploadFileItem], withContext jsonObject: [String: Any]) throws -> AnyObject? {
//        let startDate = Date()

        _requestType = .uploadFileRequest
        // TODO
//        do {
//            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject.toJSON, options: .prettyPrinted)
//            var request = URLRequest(url: self.serverURL)
//            let boundry = "IDDBoundry-\(UUID().uuidString.uppercased())"
//            let httpBody = try _createHTTPBody(withJsonData: jsonData, fileItems: items, andBoundry: boundry)
//
//            if self.logger.isDebug {
//                let string = String(data: httpBody, encoding: .utf8) ?? "no value ..."
//                self.logger.debug("url: '\(self.serverURL)' json: '\(string)'")
//            }
//            request.httpMethod = "POST"
//            // request.httpBody = httpBody
//            request.httpBodyStream = InputStream(data: httpBody)
//            request.addValue("multipart/form-data; boundary=\(boundry)", forHTTPHeaderField: "Content-Type")
//            request.addValue("\(httpBody.count)", forHTTPHeaderField: "Content-Length")
//            request.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
//            request.cachePolicy = .reloadIgnoringCacheData
//
//            // let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
//            // let task = session.uploadTask(withStreamedRequest: request)
//            // let task = session.downloadTask(with: request)
//            // task.resume()
//            try _post(request: request)
//            _ = _semaphore.wait(timeout: .distantFuture)
//        } catch {
//            self.logger.error("error: '\(error.localizedDescription)'")
//        }
//
//        if startDate.elapsedTimeInMilliseconds > 100.0 {
//            self.logger.info("completed in: '\(startDate.elapsedTime) ms'")
//        }
//        if let error = self._lastError {
//            throw error
//        }
        return self._lastResponse
    }
}

// MARK: - JASONHandler (URLSessionDelegate) -
extension JASONHandler: URLSessionDelegate {
}

// MARK: - JASONHandler (URLSessionTaskDelegate) -
extension JASONHandler: URLSessionTaskDelegate {

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil {
            self.logger.error("session: '\(session)' occurred error: '\(error!.localizedDescription)'")
            //    if self.completionHandler != nil {
            //        DispatchQueue.main.async {
            //            self.completionHandler!(nil, error)
            //        }
            //    }
        } else {
            // self.logger.info("request completed with: '\(_responseData.count)) bytes'")
            // self.logger.info("session \(session) upload completed, response: '\(String(data: _responseData, encoding: .utf8)!)'")
            //if self.completionHandler != nil {
            //    do {
            //        let jsonResponse = try JSONSerialization.jsonObject(with: _responseData, options: .allowFragments) as? NSDictionary
            //
            //        for (key, value) in jsonResponse! {
            //            self.logger.info("\(key): '\(value)'")
            //        }
            //        DispatchQueue.main.async {
            //            self.completionHandler!(jsonResponse as! [String: Any?], nil)
            //        }
            //    } catch let error as NSError {
            //        self.logger.error("error: '\(error)'")
            //        self.logger.error("responseString: '\(String(data: _responseData, encoding: .utf8)!)'")
            //        DispatchQueue.main.async {
            //            self.completionHandler!(nil, error)
            //        }
            //    }
            //}
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let progress: Float = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        
        self.logger.debug("session: '\(session)' uploadProgress: '\(progress * 100)%.'")
    }

}

// MARK: - JASONHandler (URLSessionDataDelegate) -
extension JASONHandler: URLSessionDataDelegate {

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Swift.Void) {
        self.logger.info("session: '\(session)', received response: '\(response)'")
        
        completionHandler(.allow)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        _responseData.append(data)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Swift.Void) {
        self.logger.info("session: '\(session)', dataTask: '\(dataTask)'")
    }
}

// MARK: - JASONHandler (URLSessionDownloadDelegate) -
extension JASONHandler: URLSessionDownloadDelegate {

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // self.logger.info("location: '\(location)'")
        do {
            if _requestType == .binaryRequest {
                try _responseData.append(Data.init(contentsOf: location))
            } else if _requestType == .downloadFileRequest {
                let temporaryFileName = UUID().uuidString.uppercased().appending(location.lastPathComponent)
                let temporaryURL = JASONHandler.rootPath.appendingPathComponent(temporaryFileName)
                
                try FileManager.default.moveItem(at: location, to: temporaryURL)
                
                if var lastResponse = self._lastResponse as? [String: Any] {
                    lastResponse["downloadLocation"] = temporaryURL
                    self._lastResponse = lastResponse as AnyObject
                }
            } else {
                self.logger.error("unknown request type: '\(_requestType)'")
            }
        } catch {
            self._lastError = JSONHandlerError.downloadTask(methodName: self.methodName, error: error)
        }
        self._semaphore.signal()
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress: Float = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        self.logger.debug("session: '\(session)' downloadProgress: '\(progress * 100)%.'")

        var deltas: Int64 = 0
        
        if _totalBytesWritten == nil {
            deltas = totalBytesWritten
            _totalBytesWritten = totalBytesWritten
        } else {
            deltas = (totalBytesWritten - _totalBytesWritten!)
            _totalBytesWritten = totalBytesWritten
        }

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: JASONHandler.DownloadProgressNotification,
                                            object: deltas,
                                            userInfo: nil)
        }
    }
}

// MARK: - Extension [String: Any] -

extension Dictionary where Key == String, Value == Any {
    public var is666: Bool {
        guard let status = self["status"] as? String,
            status == "666"
            else { return false }
        return true
    }
    
    public func hasReturnCode(_ returnCode: String) -> Bool {
        guard let value = self["returnCode"] as? String,
            value == returnCode
            else { return false }
        return true
    }
}
