//
//  Date.swift
//  IDDAppKit
//
//  Created by Klajd Deda on 12/5/17.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//

import Foundation

extension Date {
    private static let _elapsedTimeFormater: NumberFormatter = {
        let rv = NumberFormatter()

        rv.locale = Locale.init(identifier: "en_US_POSIX")
        rv.maximumFractionDigits = 3
        rv.minimumFractionDigits = 3
        return rv
    }()
    public static let defaultFormatter = DateFormatter.init(withFormatString: "yyyy-MM-dd HH:mm:ss.SSS Z", andPOSIXLocale: true)

    public static func elapsedTime(for closure: (()-> Swift.Void)) -> String {
        let startDate = Date.init()
        closure()
        return startDate.elapsedTime
    }

    public static func elapsedTime(from elapsedTimeInMilliseconds: Double) -> String {
        return Date._elapsedTimeFormater.string(from: elapsedTimeInMilliseconds as NSNumber) ?? "0.1968"
    }
    
    // positive number if some time has elapsed since now
    //
    public var elapsedTimeInMilliseconds: Double {
        return -self.timeIntervalSinceNow * 1000.0
    }
    
    // positive number if some time has elapsed since now
    //
    public var elapsedTimeInSeconds: Double {
        return (-self.timeIntervalSinceNow)
    }

    public var elapsedTime: String {
        return Date.elapsedTime(from: elapsedTimeInMilliseconds)
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

