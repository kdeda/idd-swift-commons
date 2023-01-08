//
//  NSColor.swift
//  SwiftCommons
//
//  Created by Klajd Deda on 6/3/19.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

#if os(macOS)

import Cocoa

public extension NSColor {
    
    static var windowBackground: NSColor {
        var rv = NSColor.init(red: 236.0/255.0, green: 236.0/255.0, blue: 236.0/255.0, alpha: 1.0)
        
        if NSApplication.shared.isDarkMode {
            rv = NSColor.init(red: 54.0/255.0, green: 54.0/255.0, blue: 54.0/255.0, alpha: 1.0)
        }
        return rv
    }

    static var magicBlue: NSColor {
        // magic blue for now
        //
        return NSColor.init(red: 0.0/255.0, green: 154.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    }
}

#endif
