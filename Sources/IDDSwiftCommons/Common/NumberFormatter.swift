//
//  NumberFormatter.swift
//  
//
//  Created by Klajd Deda on 3/16/21.
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
        return NumberFormatter.formaterWith3digits.string(from: self as NSNumber) ?? "0.1968"
    }
}
