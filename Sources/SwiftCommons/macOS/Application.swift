//
//  Application.swift
//  SwiftCommons
//
//  Created by Klajd Deda on 6/9/18.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

#if os(macOS)

import Cocoa

public extension NSApplication {
    static let AppearanceDidChange = NSNotification.Name("NSApplication_AppearanceDidChange")
    private static var _observer: NSKeyValueObservation?
    private static var _isDarkMode: Bool?

    var currentOptionEvent: NSEvent? {
        if let currentEvent = NSApp.currentEvent {
            if currentEvent.modifierFlags.contains(.option) {
                return currentEvent
            }
        }
        return nil
    }
    
    var isOptionKey: Bool {
        return currentOptionEvent != nil
    }

    var currentShiftEvent: NSEvent? {
        if let currentEvent = NSApp.currentEvent {
            if currentEvent.modifierFlags.contains(.shift) {
                return currentEvent
            }
        }
        return nil
    }

    var isDarkMode: Bool {
        if #available(macOS 10.14, *) {
            if NSApplication._isDarkMode == nil {
                let appearanceName = effectiveAppearance.bestMatch(from: [NSAppearance.Name.darkAqua, NSAppearance.Name.aqua])
                
                NSApplication._isDarkMode = appearanceName == NSAppearance.Name.darkAqua
            }
            return NSApplication._isDarkMode!
        }
        return false
    }
    
    static func observeAppearanceDidChange() {
        if #available(macOS 10.14, *) {
            if _observer == nil {
                _observer = NSApplication.shared.observe(\.effectiveAppearance) { (app, _) in
                    NSApplication._isDarkMode = nil
                    NotificationCenter.default.post(name: NSApplication.AppearanceDidChange, object: app)
                }
            }
        }
    }
}

#endif
