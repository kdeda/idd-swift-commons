//
//  NSAlert.swift
//  SwiftCommons
//
//  Created by Klajd Deda on 11/4/17.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

import AppKit
import Log4swift

extension NSAlert {
    static var waitingForUserToOK = 0
    static var popovers = [NSButton: NSPopover]()
    static let logger: Logger = {
        return Log4swift.getLogger("NSAlert")
    }()
    
    @objc static private func _popoverCompleted(_ sender: Any) {
        NSAlert.logger.info("")
        
        if let button = sender as? NSButton {
            if let popover = popovers[button] {
                popovers[button] = nil
                popover.close()
            }
        }
    }
    
    private static func _attachAlert(
        withStyle alertStyle: NSAlert.Style,
        message messageText: String,
        informative informativeText: String,
        buttons buttonNames: [String],
        toWindow window: NSWindow,
        completion: @escaping (NSApplication.ModalResponse) -> Swift.Void
    ) {
        let alert = NSAlert()
        
        alert.alertStyle = alertStyle
        alert.messageText = messageText
        alert.informativeText = informativeText
        // https://stackoverflow.com/questions/14820335/nsalert-resize-window
        //
        alert.accessoryView = NSView(frame: NSMakeRect(0, 0, 360, 0))

        buttonNames.forEach { (button) in
            alert.addButton(withTitle: button)
        }
        alert.beginSheetModal(for: window, completionHandler: completion)
    }
    
    static public func attachAlert(
        withStyle alertStyle: NSAlert.Style,
        message messageText: String,
        informative informativeText: String,
        buttons buttonNames: [String],
        toWindow window: NSWindow?,
        completion: @escaping (NSApplication.ModalResponse) -> Swift.Void
    ) {
        guard window != nil
            else {
                NSAlert.logger.error("no window !!!, informativeText: '\(informativeText)'")
                return
            }

        Self._attachAlert(
            withStyle: alertStyle,
            message: messageText,
            informative: informativeText,
            buttons: buttonNames,
            toWindow: window!,
            completion: completion
        )
    }
    
    /*
     * Convenience, attach the window and run modal
     */
    static public func modalAlert(
        withStyle alertStyle: NSAlert.Style,
        message messageText: String,
        informative informativeText: String,
        buttons buttonNames: [String],
        toWindow window: NSWindow?
    ) -> NSApplication.ModalResponse {
        guard window != nil
            else {
                NSAlert.logger.error("no window !!!, informativeText: '\(informativeText)'")
                return .cancel
            }
        var returnCode: NSApplication.ModalResponse = .cancel
        NSAlert.waitingForUserToOK = 747
        
        Self._attachAlert(
            withStyle: alertStyle,
            message: messageText,
            informative: informativeText,
            buttons: buttonNames,
            toWindow: window!
        ) { modalResponse in
            returnCode = modalResponse
            NSAlert.waitingForUserToOK = 0
            NSAlert.logger.info("returnCode: '\(returnCode)'")
        }
        while NSAlert.waitingForUserToOK == 747 {
            let checkDate = Date.init(timeIntervalSinceNow: 0.05)
            let nextEvent = NSApp.nextEvent(matching: .any, until: checkDate, inMode: RunLoop.Mode.modalPanel, dequeue: true)
            
            Thread.sleep(forTimeInterval: 0.05)
            if nextEvent != nil {
                NSApp.sendEvent(nextEvent!)
            }
        }
        
        return returnCode
    }
    
    /*
     * Convenience, attach the alert window as popover
     */
    static public func popover(
        withStyle alertStyle: NSAlert.Style,
        message messageText: String,
        informative informativeText: String,
        button buttonName: String,
        toView view: NSView,
        preferredEdge edge: NSRectEdge
    ) {
        let alert = NSAlert()
        
        NSAlert.logger.info("")
        alert.alertStyle = alertStyle
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.addButton(withTitle: buttonName)
        let button = alert.buttons[0]
        
        button.target = self
        button.action = #selector(self._popoverCompleted(_:))
        alert.layout()
        
        let controller = NSViewController.init()
        let popover = NSPopover.init()
        
        controller.view = alert.window.contentView!
        popover.contentViewController = controller
        
        popovers[button] = popover
        popover.show(relativeTo: view.bounds, of: view, preferredEdge: edge)
    }
}
