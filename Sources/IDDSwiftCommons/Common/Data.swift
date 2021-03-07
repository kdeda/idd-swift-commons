//
//  Data.swift
//  WhatSize
//
//  Created by Klajd Deda on 9/17/17.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift
import CommonCrypto
import CryptoKit

// MARK: - Data
// MARK: -

extension Data {
    static public let logger: Logger = {
        return IDDLog4swift.getLogger("Data")
    }()

    /**
     I hate optionals
     */
    public init(withURL url: URL) {
        do {
            try self.init(contentsOf: url)
        } catch {
            self.init()
            Data.logger.error("error: '\(error.localizedDescription)' We will return empty data.")
        }
    }
    
    mutating public func appendString(_ string: String) {
        guard let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
            else { return }
        append(data)
    }
    
    private var md5_legacy: String {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        var digest = [UInt8](repeating: 0, count: length)

        _ = digest.withUnsafeMutableBytes { (digestBytes) -> Bool in
            self.withUnsafeBytes { (messageBytes) -> Bool in
                _ = CC_MD5(messageBytes.baseAddress, CC_LONG(self.count), digestBytes.bindMemory(to: UInt8.self).baseAddress)
                return true
            }
        }
        return (0..<length).reduce("") {
            $0 + String(format: "%02x", digest[$1])
        }
    }

    /**
     returns a unique fingerprint
     ie: 2E79D73C-EAB5-44E0-9DEC-75602872402E
     */
    var md5: String {
        if #available(macOS 10.15, *) {
            let digest = Insecure.MD5.hash(data: self)
            var tokens = digest.map { String(format: "%02hhx", $0) }
            
            if tokens.count == 16 {
                tokens.insert("-", at: 4)
                tokens.insert("-", at: 7)
                tokens.insert("-", at: 10)
                tokens.insert("-", at: 13)
                
                if let uuid = UUID(uuidString: tokens.joined(separator: "").uppercased()) {
                    return uuid.uuidString
                }
            }
            return tokens.joined(separator: "").uppercased()
        }
        
        return md5_legacy
    }
}
