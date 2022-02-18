//
//  TitlebarAccessoryView.swift
//  SwiftCommons
//
//  Created by Klajd Deda on 10/7/17.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

import AppKit
import Log4swift

@objc public protocol TitlebarAccessoryViewDelegate: NSObjectProtocol {
    func accessoryViewActionAction(_ sender: TitlebarAccessoryView)
}

public class TitlebarAccessoryView: NSView {
    lazy var logger: Logger = {
        return Log4swift.getLogger(self)
    }()

    var tracking: NSView.TrackingRectTag = 0
    weak var delegate: TitlebarAccessoryViewDelegate?
    
    // MARK: - Overriden methods
    // MARK: -

    override public var acceptsFirstResponder: Bool {
        get {
            return true
        }
    }
    
    override public func resetCursorRects() {
        logger.info("frame: '\(self.frame)'")
        
        super.resetCursorRects()
        if let window = self.window {
            if !window.acceptsMouseMovedEvents {
                window.acceptsMouseMovedEvents = true
            }
        }
        if tracking != 0 {
            self.superview!.removeTrackingRect(tracking)
        }
        tracking = self.superview!.addTrackingRect(self.frame, owner: self, userData: nil, assumeInside: false)
    }
    
    /*
     */
    override public func mouseUp(with event: NSEvent) {
        logger.info("event: '\(event)'")
        
        let mouseClick = self.convert(event.locationInWindow, from: nil)

        if self.frame.contains(mouseClick) {
            logger.info("click: '\(event)'")
            
            if delegate != nil {
                delegate!.accessoryViewActionAction(self)
            }
//            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self._selectionDidChange), object: self)
//            self.perform(#selector(self._selectionDidChange), with: self, afterDelay: 0.25)
        }
        // super.mouseDown(with: event)
    }
}
