//
//  Date.swift
//  IDDSwiftCommons
//
//  Created by Klajd Deda on 12/5/17.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//

import Foundation

extension Date {
    public static let defaultFormatter = DateFormatter.init(withFormatString: "yyyy-MM-dd HH:mm:ss.SSS Z", andPOSIXLocale: true)

    public static func elapsedTime(for closure: (()-> Swift.Void)) -> String {
        let startDate = Date.init()
        closure()
        return startDate.elapsedTime
    }

    public static func elapsedTime(from elapsedTimeInMilliseconds: Double) -> String {
        elapsedTimeInMilliseconds.with3Digits
    }
    
    // positive number if some time has elapsed since now
    //
    public var elapsedTimeInMilliseconds: Double {
        return -self.timeIntervalSinceNow * 1000.0
    }
    
    // positive number if some time has elapsed since now
    //
    public var elapsedTimeInSeconds: Double {
        (-self.timeIntervalSinceNow)
    }

    public var elapsedTime: String {
        elapsedTimeInMilliseconds.with3Digits
    }

    public func string(withFormat formatString: String) -> String {
        let dateFormatter = DateFormatter.init(withFormatString: formatString, andPOSIXLocale: true)
        return dateFormatter.string(from: self)
    }

    public var stringWithDefaultFormat: String {
        return Date.defaultFormatter.string(from: self)
    }
    
    // if numberOfDays is positive return date is us but numberOfDays in the future
    // if numberOfDays is negative return date is us but numberOfDays in the past
    //
    public func date(shiftedByDays numberOfDays: Int) -> Date {
        return Date.init(timeInterval: Double(numberOfDays * 24 * 3600), since: self)
    }
}

extension String {
    
    public var dateWithDefaultFormat: Date? {
        return Date.defaultFormatter.date(from: self)
    }
}

