//
//  UserDefaultsValue.swift
//  IDDSwiftCommons
//
//  Created by Klajd Deda on 3/25/20.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//
//  TODO
//  @propertyWrapper do break TCA
//

import Foundation
import Log4swift

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
            let storedValue = storage.value(forKey: key) as? String
            let encoder = JSONDecoder()
            
            encoder.dateDecodingStrategy = .iso8601
            // Log4swift[Self].info("loaded raw value \(self.key): '\(storedValue ?? "unknown ...")'")
            let data = storedValue?.data(using: .utf8) ?? Data()
            let value = try? encoder.decode(Value.self, from: data)
            if let stringValue = value as? String, stringValue.isEmpty {
                // for string values we want to equate nil with empty string as well
                return defaultValue
            }
            // Log4swift[Self].info("loaded \(self.key): '\(value ?? defaultValue)'")
            return value ?? defaultValue
        }
        set {
            do {
                let encoder = JSONEncoder()
                
                encoder.outputFormatting = .prettyPrinted
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(newValue)
                let storedValue = String(data: data, encoding: .utf8) ?? ""
                
                storage.setValue(storedValue, forKey: key)
                // Log4swift[Self].info("stored \(self.key): '\(storedValue)'")
            } catch {
                Log4swift[Self].error("error: '\(error.localizedDescription)'")
            }
        }
    }
}

public extension UserDefaults {
    @UserDefaultsValue(key: "pathPrefix", defaultValue: "")
    static var pathPrefix: String
}
