//
//  CenterToolBarHistory.swift
//  IDDSwiftCommons
//
//  Created by Klajd Deda on 1/14/19.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift
import IDDObjectiveCLegacy

public struct ToolBarHistoryItem: Codable, CustomStringConvertible {
    var date = Date()
    var message: String

    // MARK: - CustomStringConvertible
    // MARK: -
    
    public var description: String {
        var rv = ""
        
        rv = "<\(String(describing: type(of: self)))"
        rv += " date: '\(date.stringWithDefaultFormat)'"
        rv += " message: '\(self.message)'"
        rv += ">"
        return rv
    }
}

public class CenterToolBarHistory {
    public static let UpdateNotification = Notification.Name("CenterToolBarHistory_UpdateNotification")
    public static let shared = CenterToolBarHistory()
    public static let maxCount = 50
    
    lazy var logger: Logger = {
        return Log4swift.getLogger(self)
    }()
    
    // MARK: - Class methods
    // MARK: -

    public static func postUpdateNotification(_ message: String?) {
        guard let message = message
        else { return }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: CenterToolBarHistory.UpdateNotification,
                object: "CenterToolBarHistory",
                userInfo: ["historyMessage": message]
            )
        }
    }

    public static func postUpdateNotificationDistributed(_ message: String?) {
        guard let message = message
        else { return }

        DistributedNotificationCenter.default().postNotificationName(
            CenterToolBarHistory.UpdateNotification,
            object: "CenterToolBarHistory",
            userInfo: ["historyMessage": message],
            options: [.postToAllSessions, .deliverImmediately]
        )
    }
    
    // MARK: - Instance methods
    // MARK: -

    public private(set) var history = [ToolBarHistoryItem]()
    public var defaults: IDDUserDefaults? {
        didSet {
            history = defaults?.toolBarHistoryItems ?? []
        }
    }

    public var lastMessage: String {
        get {
            return history.last?.message ?? ""
        }
        set {
            logger.info("newValue: '\(newValue)'")
            history.insert(ToolBarHistoryItem(message: newValue), at: 0)
            // debug
            // (0...10).forEach { history.insert(ToolBarHistoryItem(message: newValue + " \(history.count)"), at: 0) }

            if history.count > CenterToolBarHistory.maxCount {
                _ = history.popLast()
            }
            defaults?.toolBarHistoryItems = history
        }
    }
        
    public func resetHistory() {
        if let defaults = defaults {
            defaults.common().setDefaultValue("", forKey: "history")
        }
        history.removeAll()
    }
}

// MARK: - IDDUserDefaults (Helper)
// MARK: -

extension IDDUserDefaults {
    static var logger: Logger = {
        return Log4swift.getLogger("IDDUserDefaults")
    }()

    /**
     There will always be an array with one object inside
     */
    fileprivate var toolBarHistoryItems: [ToolBarHistoryItem] {
        get {
            var rv: [ToolBarHistoryItem] = {
                do {
                    let existing = common().defaultValue(forKey: "history", nilValue: "") as? String
                    let data = existing?.data(using: .utf8) ?? Data()
                    let decoder = JSONDecoder()
                    
                    decoder.dateDecodingStrategy = .iso8601
                    return try decoder.decode([ToolBarHistoryItem].self, from: data)
                } catch {
                    Self.logger.error("error: '\(error.localizedDescription)'")
                }
                return []
            }()
            
            // sort and remove entries older than a week
            rv = rv
                .sorted { $0.date > $1.date }
                .filter { (entry) -> Bool in
                    return -entry.date.timeIntervalSinceNow < 24 * 3600 * 7
                }
            
            if rv.count > CenterToolBarHistory.maxCount {
                // most recent is on top
                rv = rv.dropLast(rv.count - CenterToolBarHistory.maxCount)
            }
            return rv
        }
        set {
            do {
                let encoder = JSONEncoder()
                
                encoder.outputFormatting = .prettyPrinted
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(newValue)
                let string = String(data: data, encoding: .utf8) ?? ""

                // Self.logger.error("string: '\(string)'")
                common().setDefaultValue(string, forKey: "history")
            } catch {
                Self.logger.error("error: '\(error.localizedDescription)'")
            }
        }
    }
}
