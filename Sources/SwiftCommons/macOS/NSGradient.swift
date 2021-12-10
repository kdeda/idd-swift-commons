//
//  NSGradient.swift
//  SwiftCommons
//
//  Created by Klajd Deda on 8/2/17.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//

import Cocoa

public extension NSGradient {
    static func appearanceDidChange() {
        _dividerGradient = nil
        _hoverGradient = nil
    }
    
    static private var _dividerGradient: NSGradient?
    static var dividerGradient: NSGradient {
        if _dividerGradient == nil {
            let beginColor = NSColor.windowBackground
            var middleColor = NSColor.init(calibratedWhite: 0.65, alpha: 1.0)
            
            if NSApplication.shared.isDarkMode {
                middleColor = NSColor.init(calibratedWhite: 0.5, alpha: 1.0)
            }
            let endColor = beginColor
            let colors: [NSColor] = [beginColor, middleColor, middleColor, endColor]
            let locations: [CGFloat] = [0.0, 0.3, 0.7, 1.0]
            
            _dividerGradient = NSGradient.init(colors: colors, atLocations: locations, colorSpace: NSColorSpace.genericRGB)!
        }
        return _dividerGradient!
    }
    
    static private var _hoverGradient: NSGradient?
    static var hoverGradient: NSGradient {
        if _hoverGradient == nil {
            let beginColor = NSColor.windowBackground
            var middleColor = NSColor.init(calibratedWhite: 0.8, alpha: 1.0)
            
            if NSApplication.shared.isDarkMode {
                middleColor = NSColor.init(calibratedWhite: 0.25, alpha: 1.0)
            }
            let endColor = beginColor
            let colors: [NSColor] = [beginColor, middleColor, middleColor, endColor]
            let locations: [CGFloat] = [0.0, 0.3, 0.7, 1.0]
            
            _hoverGradient = NSGradient.init(colors: colors, atLocations: locations, colorSpace: NSColorSpace.genericRGB)!
        }
        return _hoverGradient!
    }
}
