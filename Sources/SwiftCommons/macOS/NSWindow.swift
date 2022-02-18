//
//  Window.swift
//  SwiftCommons
//
//  Created by Klajd Deda on 10/5/17.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

import AppKit
import Log4swift

public protocol TitlebarAccessoryWindowDelegate : NSWindowDelegate {
    func windowAccessoryViewAction(_ sender: TitlebarAccessoryView)
}

extension NSWindow: TitlebarAccessoryViewDelegate {
    static let logger: Logger = {
        return Log4swift.getLogger("NSWindow")
    }()
    
    var heightOfTitleBar: CGFloat {
        get {
            if let contentView = self.contentView {
                let outerFrame = contentView.superview!.frame
                let contentViewRect = contentView.frame
                
                return outerFrame.size.height - contentViewRect.size.height
            }
            return 0.0
        }
    }
    
    // http://fredandrandall.com/blog/2011/09/14/adding-a-button-or-view-to-the-nswindow-title-bar/
    // this has since changed due to apple's new api NSTitlebarAccessoryViewController on 10.10
    //
    @objc public func pinToTheRightOfTitleBar(view viewToAdd: NSView) {
        if self.contentView != nil {
            var oldRect = viewToAdd.frame
    
            oldRect.size.width += 12.0
            viewToAdd.frame = oldRect
            
            let titleHeight = self.heightOfTitleBar
            let viewRect = NSRect.init(x: 0.0, y: 0.0, width: viewToAdd.frame.size.width + 10.0, height: titleHeight)
            
            if self.titlebarAccessoryViewControllers.count == 0 {
                let controller = NSTitlebarAccessoryViewController.init()
                let containerView = TitlebarAccessoryView.init(frame: viewRect)
        
                // debug
                //
                // containerView.wantsLayer = YES;
                // containerView.layer.backgroundColor = [[NSColor redColor] CGColor];
                containerView.addSubview(viewToAdd)
                viewToAdd.setFrameOrigin(NSPoint.init(x: 2.0, y: ((titleHeight - viewToAdd.frame.size.height) / 2.0)))
        
                controller.view = containerView
                controller.layoutAttribute = .right
                containerView.delegate = self
                
                self.addTitlebarAccessoryViewController(controller)
            }
            self.titlebarAccessoryViewControllers[0].view.frame = viewRect
        }
    }
    
    
    // MARK: - TitlebarAccessoryViewDelegate
    // MARK: -
    
    public func accessoryViewActionAction(_ sender: TitlebarAccessoryView) {
        NSWindow.logger.info("click: '\(sender)'")
        
        if let delegate = self.delegate as? TitlebarAccessoryWindowDelegate  {
            delegate.windowAccessoryViewAction(sender)
        }
    }

}
