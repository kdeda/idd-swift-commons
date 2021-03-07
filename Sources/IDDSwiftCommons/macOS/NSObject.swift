//
//  NSObject.swift
//  IDDAppKit
//
//  Created by Klajd Deda on 7/3/18.
//  Copyright © 2018 id design, inc. All rights reserved.
//

import Cocoa

extension NSObject {
    static public var isAppStoreBuild: Bool {
        get {
            var rv = false
            
            #if APPLE_STORE_BUILD
                rv = true
            #else
            #endif // APPLE_STORE_BUILD
            
            return rv
        }
    }
}
