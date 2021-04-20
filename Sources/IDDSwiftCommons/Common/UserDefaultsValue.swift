//
//  UserDefaultsValue.swift
//  IDDSwiftCommons
//
//  Created by Klajd Deda on 3/25/20.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//

import Foundation

@propertyWrapper
public struct UserDefaultsValue<Value>: Equatable where Value: Equatable, Value: Codable {
    let key: String
    let defaultValue: Value
    var storage: UserDefaults = .standard

    public init(key: String, defaultValue: Value) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    // if the value is nil return defaultValue
    // if the value empty return defaultValue
    // otherwise return the value
    //
    public var wrappedValue: Value {
        get {
            let value = storage.value(forKey: key) as? Value
            if let stringValue = value as? String, stringValue.isEmpty {
                // for string values we want to equate nil with empty string as well
                return defaultValue
            }
            return value ?? defaultValue
        }
        set {
            storage.setValue(newValue, forKey: key)
        }
    }
}

public extension UserDefaults {
    @UserDefaultsValue(key: "pathPrefix", defaultValue: "")
    static var pathPrefix: String
}
