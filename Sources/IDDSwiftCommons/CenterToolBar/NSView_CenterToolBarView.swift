//
//  NSView_CenterToolBarView.swift
//  IDDAppKit
//
//  Created by Klajd Deda on 5/23/19.
//  Copyright (C) 1997-2018 id-design, inc. All rights reserved.
//
//  https://www.raywenderlich.com/1101-core-graphics-on-macos-tutorial
//

import AppKit
import Log4swift

open class NSView_CenterToolBarView: NSView {
    lazy var logger: Logger = {
        return IDDLog4swift.getLogger(self)
    }()
    
    private var _cell: NSButtonCell = {
        var rv = NSButtonCell.init(textCell: "")
        
        rv.setButtonType(.momentaryPushIn)
        rv.bezelStyle = .texturedRounded
        return rv
    }()
    
    public var backgroundColor = NSColor.controlColor
    public var borderColor = NSColor.black.withAlphaComponent(0.2)

    func appearanceDidChangeNotification() {
        backgroundColor = NSColor.controlColor
        borderColor = NSColor.black.withAlphaComponent(0.2)
        
        if NSApplication.shared.isDarkMode {
            backgroundColor = NSColor.init(red: 93.0/255.0, green: 95.0/255.0, blue: 97.0/255.0, alpha: 1.0)
            borderColor = NSColor.white.withAlphaComponent(0.2)
        }
        self.needsDisplay = true
    }

    // MARK: - Overriden methods
    // MARK: -
    
    override open func draw(_ dirtyRect: NSRect) {
        let rect = NSInsetRect(self.frame, 0.5, 0.5)
        let path = NSBezierPath.init(roundedRect: rect, xRadius: 4.0, yRadius: 4.0)
        
        path.lineWidth = 1.0
        borderColor.set()
        path.stroke()

        backgroundColor.set()
        path.fill()
    }

}


