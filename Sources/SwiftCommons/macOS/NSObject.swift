//
//  NSObject.swift
//  SwiftCommons
//
//  Created by Klajd Deda on 7/3/18.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
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
