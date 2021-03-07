//
//  String.swift
//  WhatSize
//
//  Created by Klajd Deda on 7/4/17.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//  https://medium.com/@dcordero/a-different-way-to-deal-with-localized-strings-in-swift-3ea0da4cd143
//

import Foundation
import Log4swift

extension String {
    static let ZERO_CHAR = Character(UnicodeScalar(48)) // 0
    static let ONE_CHAR = Character(UnicodeScalar(49)) // 1
    static let logger: Logger = {
        return IDDLog4swift.getLogger("String")
    }()

    private func _nsRange(from range: Range<Index>?) -> NSRange {
        let utf16view = self.utf16
        
        if let range = range {
            if let from = range.lowerBound.samePosition(in: utf16view), let to = range.upperBound.samePosition(in: utf16view) {
                return NSMakeRange(utf16view.distance(from: utf16view.startIndex, to: from), utf16view.distance(from: from, to: to))
            }
        }
        
        return NSRange(location: 0, length: 0)
    }
    
    public func nsRange(of substring: String) -> NSRange {
        return _nsRange(from: self.range(of: substring))
    }

    public func lowerCaseFirstLetter() -> String {
        let first = String(self.prefix(1)).lowercased()
        let other = String(self.dropFirst())
        
        return first + other
    }

    public func capitalizingFirstLetter() -> String {
        let first = String(self.prefix(1)).capitalized
        let other = String(self.dropFirst())
        
        return first + other
    }
    
    mutating public func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }

    private func _splitBySpaceOrCamelCaseTwoWide() -> [String] {
        var rv = [String]()

        if self.count <= 2 {
            rv.append(self)
            rv.append(self)
        } else {
            let halfLength = self.count / 2
            let start = self.startIndex
            let middle = self.index(start, offsetBy: halfLength)
            let end = self.index(self.endIndex, offsetBy: -1)
            
            rv.append(String(self[start...middle]))
            rv.append(String(self[middle...end]))
        }
        return rv
    }
    
    // try the camel case
    // 20thCenturyWoodcut will split as
    // - 0 : "20th"
    // - 1 : "entury"
    // - 2 : "oodcut"
    //
    
    public func splitBySpaceOrCamelCaseTwoWide() -> [String] {
        var words = self.components(separatedBy: .uppercaseLetters)
        var camelCaseWords = [String]()
        
        words = words.filter { $0 != "" && $0.trimmingCharacters(in: .whitespacesAndNewlines).count > 1 }
        Self.logger.info("fontName: '\(self)' words: '\(words)'")
        if words.count < 2 {
            words = self.components(separatedBy: " ")
            words = words.filter { $0 != "" && $0.count > 1 }
            Self.logger.info("fontName: '\(self)' words: '\(words)'")
        }
        
        if (words.count >= 2) {
            var searchPosition = self.startIndex
            
            for word in words {
                if let range = self.range(of: word, range: searchPosition..<self.endIndex) {
                    let startPos = self.distance(from: self.startIndex, to: range.lowerBound)
                    let endPos = self.distance(from: self.startIndex, to: range.upperBound)
                    
                    Self.logger.info("startPos: '\(startPos)' endPos: '\(endPos)'")
                    if startPos > 0 {
                        let lo = self.index(range.lowerBound, offsetBy: -1)
                        let hi = self.index(range.lowerBound, offsetBy: 1) // we just want 2 chars
                        let subRange = lo ..< hi
                        
                        camelCaseWords.append(String(self[subRange]))
                    } else {
                        let lo = self.index(range.lowerBound, offsetBy: 0)
                        let hi = self.index(range.lowerBound, offsetBy: 2) // we just want 2 chars
                        let subRange = lo ..< hi
                        
                        camelCaseWords.append(String(self[subRange]))
                    }
                    searchPosition = range.upperBound
                }
            }
        } else {
            camelCaseWords = self.replacingOccurrences(of: " ", with: "")._splitBySpaceOrCamelCaseTwoWide()
        }
        Self.logger.info("self: '\(self)' camelCaseWords: '\(camelCaseWords)'")
        
        var rv = [String]()
        var index = 0
        
        for word in camelCaseWords {
            var word2Char = word
            
            if word.count > 2 {
                let start = word.startIndex
                word2Char = String(word[start ..< word.index(start, offsetBy: 2)])
            }
            rv.append(word2Char.lowercased().capitalizingFirstLetter())
            index += 1
            if index == 2 {
                break
            }
        }
        
        Self.logger.info("self: '\(self)' camelCaseWords: '\(rv)'")
        return rv
    }
    
    public var localized: String {
        return Localizer.shared.localize(self)
    }

    public var asciiArray: [UInt32] {
        return unicodeScalars.filter { $0.isASCII }.map { $0.value }
    }
    
    public func leftPadding(to length: Int, withPad character: Character) -> String {
        let stringLength = self.count
        
        if stringLength < length {
            return String(repeatElement(character, count: length - stringLength)) + self
        }
        return String(self.suffix(length))
    }
    
    // the character will be space
    //
    public func leftPadding(to length: Int) -> String {
        return self.leftPadding(to: length, withPad: Character(" "))
    }

    public var sqliteEscaped: String {
        return self.replacingOccurrences(of: "'", with: "''")
    }
    
    // receiver: 'Space needed for this backup: 732.21 GB (89381501 blocks of size 8192)'
    // partialString: 'Space needed for this backup:'
    // return: ' 732.21 GB (89381501 blocks of size 8192)'
    //
    public func substring(after partialString: String) -> String? {
        if let range = self.range(of: partialString) {
            return String(self[range.upperBound..<self.endIndex])
        }
        return nil
    }
    
    // receiver: 'Space needed for this backup: 732.21 GB (89381501 blocks of size 8192)'
    // partialString: '('
    // return: 'Space needed for this backup: 732.21 GB '
    //
    public func substring(before partialString: String) -> String? {
        if let range = self.range(of: partialString) {
            return String(self[self.startIndex..<range.lowerBound])
        }
        return nil
    }

    // the assumption is that self is a child of parentPath
    // ie: self == /Users/kdeda/Documents/Personal/Contracts/BenChute/LargeWhatSizeTest
    // ie: parentPath == /Users/kdeda/Documents
    // will return ../Personal/Contracts/BenChute/LargeWhatSizeTest
    // if not will return self
    //
    // will remove new lines or other weird control chars from string
    //
    public func pathRelative(from parentPath: String) -> String {
        let filePath = self.trimmingCharacters(in: CharacterSet.controlCharacters)
        
        if parentPath.count > 0 && parentPath != "/" {
            if filePath.count > parentPath.count {
                let startIndex = filePath.index(filePath.startIndex, offsetBy: parentPath.count + 1)
                
                return "../" + String(filePath[startIndex...])
            }
        }
        return filePath
    }

    /*
     * strip away any funky non ascii chars
     * we will strip invisible UTF8 chars
     * ie WHATSIZE­-3JWQ­-19FL­-GDTV­-9WXR­-7W99
     * has invisible dashes, if you paste it on terminal you should see them
     */
    public var registrationKey: String {
        var allowed = CharacterSet()
        
        allowed.formUnion(.alphanumerics)
        allowed.insert(charactersIn: "-")
        return self.trimmingCharacters(in: allowed.inverted)
    }
    
    public var cleanedEmailAddress: String {
        if !self.isEmpty {
            let tokens = self.components(separatedBy: " ").unique()

            if tokens.count > 1 {
                Self.logger.error("please do not enter spaces in the emailAddress: '\(self)'")
            }
            return tokens.joined(separator: "").lowercased()
        }
        return self
    }

    public var isValidEmailAddress: Bool {
        return EmailValidator.isValid(emailAddress: self)
    }

    /**
     returns a unique fingerprint
     ie: 2E79D73C-EAB5-44E0-9DEC-75602872402E
     */
    var md5: String {
        return (data(using: .utf8) ?? Data()).md5
    }
}

extension Character {
    var asciiValue: UInt32? {
        return String(self).unicodeScalars.filter{$0.isASCII}.first?.value
    }
}

/**
 valid emails are now _@foo.com
 */
struct EmailValidator {
    private static let __firstpart = "[A-Z0-9a-z_]([A-Z0-9a-z._%+-]{0,30}[A-Z0-9a-z])?"
    private static let __serverpart = "([A-Z0-9a-z]([A-Z0-9a-z-]{0,30}[A-Z0-9a-z])?\\.){1,5}"
    private static let __emailRegex = __firstpart + "@" + __serverpart + "[A-Za-z]{2,8}"
    private static let __emailPredicate = NSPredicate(format: "SELF MATCHES %@", __emailRegex)

    public static func isValid(emailAddress: String) -> Bool {
        if emailAddress.isEmpty {
            return false
        }
        return EmailValidator.__emailPredicate.evaluate(with: emailAddress)
    }
}
