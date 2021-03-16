//
//  UserDefaults.swift
//  IDDAppKit
//
//  Created by Klajd Deda on 3/25/20.
//  Copyright (C) 1997-2018 id-design, inc. All rights reserved.
//

import Foundation

@propertyWrapper
public struct UserDefaultsBacked<Value> {
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
                return defaultValue
            }
            return value ?? defaultValue
        }
        set {
            storage.setValue(newValue, forKey: key)
            storage.synchronize()
        }
    }
}

public extension UserDefaults {
    @UserDefaultsBacked(key: "pathPrefix", defaultValue: "")
    static var pathPrefix: String
}
