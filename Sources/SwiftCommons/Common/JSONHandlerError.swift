//
//  JSONHandlerError.swift
//  SwiftCommons
//
//  Created by Klajd Deda on 8/16/17.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift

// MARK: - ServerException(IDDException) -

public struct ServerException: Codable {
//
//    "objectClassName": "IDDException",
//    "userInfo": "{\"argument1\":\"3\",\"argument2\":\"perpCount:2\",\"errorCode\":\"LICENSE_OVERUSE\",\"argument0\":\"4\"}",
//    "errorName": "IDDService",
//    "errorType": "LICENSE_OVERUSE",
//    "errorReason": "LICENSE_OVERUSE"
//
//
    public var userInfo: String // old dictionary format ...
    public var errorName: String
    public var errorType: String
    public var errorReason: String

    public var userInfoDictionary: [String: Any] {
        let data = userInfo.data(using: .utf8) ?? Data()
        let rv = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        return rv ?? [String: Any]()
    }
}

// MARK: - JSONHandlerError -

public enum JSONHandlerError: LocalizedError {
    case http(methodName: String, statusCode: Int)
    case json(methodName: String, data: Data, error: Error)
    case dataTask(methodName: String, error: Error)
    case downloadTask(methodName: String, error: Error)
    case noData(methodName: String, errorDescription: String)
    case noResponse(methodName: String, errorDescription: String)
    case unknownResponse(methodName: String, response: AnyObject?)
    case serverException(ServerException)
}

public extension JSONHandlerError {
    var desccription: String {
//    self.logger.error("error: '\(self._lastError!)'")
//    self.logger.error("responseString: '\(String(data: data, encoding: .utf8)!)'")
        return "foo"
    }
}

//
//@objcMembers
//public class JSONHandlerError: NSObject, LocalizedError {
//    var statusCode = 0
//    var methodName: String
//
//    init(_ statusCode: Int, methodName aMethodName: String) {
//        self.statusCode = statusCode
//        self.methodName = aMethodName
//    }
//
//    override public var description: String {
//        switch statusCode {
//        case 404:
//            let statusFormat = "Server method: '%@' not found".localized
//
//            return String(format: statusFormat, methodName)
//        default:
//            let statusFormat = "Unkwown statusCode: '%ld' method: '%@'".localized
//
//            return String(format: statusFormat, statusCode, methodName)
//        }
//    }
//
//    //You need to implement `errorDescription`, not `localizedDescription`.
//    public var errorDescription: String? {
//        get {
//            return self.description
//        }
//    }
//}
