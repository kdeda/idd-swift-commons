//
//  NumberFormatter.swift
//  SwiftCommons
//
//  Created by Klajd Deda on 3/16/21.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation

extension NumberFormatter {
    public static let formaterWith3digits: NumberFormatter = {
        let rv = NumberFormatter()
        
        rv.locale = Locale.init(identifier: "en_US_POSIX")
        rv.maximumFractionDigits = 3
        rv.minimumFractionDigits = 3
        return rv
    }()
}

extension Double {
    public var with3Digits: String {
        return NumberFormatter.formaterWith3digits.string(from: self as NSNumber) ?? "0.196"
    }
}

extension NumberFormatter {
    public static let formaterWith2digits: NumberFormatter = {
        let rv = NumberFormatter()

        rv.locale = Locale.init(identifier: "en_US_POSIX")
        rv.maximumFractionDigits = 2
        rv.minimumFractionDigits = 2
        return rv
    }()
}

extension Double {
    public var with2Digits: String {
        return NumberFormatter.formaterWith2digits.string(from: self as NSNumber) ?? "0.19"
    }
}
