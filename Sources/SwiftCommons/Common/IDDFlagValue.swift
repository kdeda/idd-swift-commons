//
//  IDDFlagValue.swift
//  SwiftCommons
//
//  Created by Klajd Deda on 6/11/18.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//
// http://stackoverflow.com/questions/4716734/how-to-use-binary-flags-in-core-data
/*
 0001
 0010
 0100
 
 binary AND
 0100 & 0100 = 0100
 0110 & 0100 = 0100
 0111 & 0100 = 0100
 0111 & 0010 = 0010
 
 binary OR
 0100 | 0100 = 0100
 */

import Foundation
import Log4swift

public class IDDFlagValue: NSNumber {
    lazy var logger: Logger = {
        return Log4swift.getLogger(self)
    }()
    
    private var _maxLength: Int = 0
    private var _stringValue: String = ""
    private var _number = NSNumber.init(value: 0)

    // MARK: - Private methods -

    /*
     * the int represetation is used for bitwise filtering
     * 000000000000, will be 0
     * 100000000000, will be 1
     * 010000000000, will be 2
     * 110000000000, will be 3
     * etc
     */
    private func _updateNSIntegerValue() {
        var buffer = 0
        let length = _stringValue.count
        
        if length > 32 {
            logger.error("_stringValue: '\(_stringValue)' isLongerThan:'\(length)'")
        } else {
            var bitMask = 1
            
            for (_, char) in _stringValue.enumerated() {
                if char == String.ONE_CHAR {
                    buffer |= bitMask
                }
                bitMask *= 2
            }
        }
        _number = NSNumber.init(value: buffer)
        //    IDDLogError(self, _cmd, @"flag:'%ld'", (long)(buffer & [NSPredicate bitMaskForFlag:12]));
        //    IDDLogError(self, _cmd, @"flag:'%ld'", (long)(buffer & [NSPredicate bitMaskForFlag:13]));
        //    IDDLogError(self, _cmd, @"flag:'%ld'", (long)(buffer & [NSPredicate bitMaskForFlag:14]));
        //    IDDLogError(self, _cmd, @"flag:'%ld'", (long)(buffer & [NSPredicate bitMaskForFlag:15]));
    }

    // MARK: - Class methods -

    public static func string(withFlag flagIndex: Int) -> String {
        let rv = "".createIDDFlag(withLength: 32)
        return rv.setFlag(atIndex: flagIndex, to: true)
    }

    // MARK: - Overriden methods -
    
    convenience public init(withString value: String, andLength length: Int) {
        self.init()
        _stringValue = value
        _maxLength = length
        if _stringValue.count == 0 {
            // should not realy get here
            //
            _stringValue = "".createIDDFlag(withLength: _maxLength)
        } else if _stringValue.count != _maxLength {
            // should not realy get here
            //
            logger.error("_stringValue: '\(_stringValue)' isLongerThan: '\(_maxLength)'")
        }
        _updateNSIntegerValue()
    }
    
    convenience public init(withLength length: Int) {
        self.init(withString: "".createIDDFlag(withLength: length), andLength: length)
        _updateNSIntegerValue()
    }
    
    override open var description: String {
        get {
            return description(withLocale: nil)
        }
    }
    
    override open func getValue(_ value: UnsafeMutableRawPointer) {
        _number.getValue(value)
    }
    
    override open var objCType: UnsafePointer<Int8> {
        return NSNumber.init(value: 1).objCType
    }
    
    override open var intValue: Int {
        return _number.intValue
    }
    
    override open var stringValue: String {
        return _stringValue
    }
    
    override open func isEqual(_ object: Any?) -> Bool {
        guard let right = object as? IDDFlagValue else {
            return false
        }
        return _number == right._number
    }

    override open func compare(_ otherNumber: NSNumber) -> ComparisonResult {
        if _number == otherNumber {
            return .orderedSame
        } else if _number.intValue < otherNumber.intValue {
            return .orderedAscending
        }
        return .orderedDescending
    }
    
//    func compare(_ otherObject: Any) -> ComparisonResult {
//        guard let right = otherObject as? IDDFlagValue else {
//            return .orderedAscending
//        }
//        if _number == right._number {
//            return .orderedSame
//        } else if _number.intValue < right._number.intValue {
//            return .orderedAscending
//        }
//        return .orderedDescending
//    }
    
    override open func description(withLocale locale: Any?) -> String {
        let objectID = String(format: "0x%lx", self)

        return "<\(String(describing: type(of: self))).\(objectID) stringValue: '\(_stringValue)' integerValue: '\(_number)'>"
    }
    
    // MARK: - Instance methods -

    public func has(flagAtIndex index: Int) -> Bool {
        if _stringValue.count == 0 {
            return false
        }
        return _stringValue.has(flagAtIndex: index)
    }
    
    public func setFlag(atIndex index: Int, to yesNo: Bool) {
        if _stringValue.count > 0 {
            let newValue = _stringValue.setFlag(atIndex: index, to: yesNo)
            
            if newValue != _stringValue {
                _stringValue = newValue
                _updateNSIntegerValue()
            }
        }
    }
    
    public func setFlag(atIndex index: Int) {
        self.setFlag(atIndex: index, to: true)
    }
    
    public func unsetFlag(atIndex index: Int) {
        self.setFlag(atIndex: index, to: false)
    }

    public func unsetFlags() {
        _stringValue = "".createIDDFlag(withLength: _maxLength)
        _updateNSIntegerValue()
    }

}

// MARK: - String (IDDFlagValue) -

extension String {
    // https://stackoverflow.com/questions/24092884/get-nth-character-of-a-string-in-swift-programming-language
    //
    
    public func createIDDFlag(withLength length: Int) -> String {
        let empty = 0
        let rv = String(format: "%032d", empty)
        let end = rv.index(rv.startIndex, offsetBy: length)

        return String(rv[rv.startIndex ..< end])
    }
    
    public func has(flagAtIndex index: Int) -> Bool {
        if index < self.count {
            let char = self[self.index(self.startIndex, offsetBy: index)]
            
            return char == String.ONE_CHAR
        } else {
            let logger = Log4swift.getLogger(self)
            logger.error("out of bounds: '\(index)' string: '\(self)'")
        }
        return false
    }
    
    public func setFlag(atIndex index: Int, to yesNo: Bool) -> String {
        if index < self.count {
            var rv = self
            let start = rv.index(rv.startIndex, offsetBy: index);
            let end = rv.index(rv.startIndex, offsetBy: index + 1);

            rv.replaceSubrange(start..<end, with: (yesNo ? "1" : "0"))
            return rv
        } else {
            let logger = Log4swift.getLogger(self)
            logger.error("out of bounds: '\(index)' string: '\(self)'")
        }
        return self
    }
}

// MARK: - NSString (IDDFlagValue) -

// glue to cocoa apps
//
extension NSString {
    public func createIDDFlag(withLength length: Int) -> String {
        return (self as String).createIDDFlag(withLength: length)
    }
    
    public func has(flagAtIndex index: Int) -> Bool {
        return (self as String).has(flagAtIndex: index)
    }
    
    public func setFlag(atIndex index: Int, to yesNo: Bool) -> String {
        return (self as String).setFlag(atIndex: index, to: yesNo)
    }
}
