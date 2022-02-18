//  URL+FileLock.swift
//  
//
//  SwiftCommons
//
//  Created by Klajd Deda on 6/17/21.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

import Foundation

// MARK: - URL -
extension URL {
    public func createLock() {
        do {
            try "".write(to: self, atomically: true, encoding: .ascii)
            URL.logger.info("created database lock: '\(self.path)'")
        } catch {
            URL.logger.error("failed to create database lock: '\(self.path)'")
            URL.logger.error("error: '\(error)'")
        }
    }

    public func removeLock() {
        do {
            try FileManager.default.removeItem(at: self)
            URL.logger.info("removed database lock: '\(self.path)'")
        } catch {
            URL.logger.error("failed to remove database lock: '\(self.path)'")
            URL.logger.error("error: '\(error)'")
        }
    }
    
    public var hasLock: Bool {
        self.fileExist
    }
}

