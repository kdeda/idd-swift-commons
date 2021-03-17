//
//  CenterToolBarViewController.swift
//  IDDSwiftCommons
//
//  Created by Klajd Deda on 11/13/17.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved
//

import AppKit
import Log4swift

// https://pompidev.net/2016/02/24/make-a-custom-nstoolbar-item-in-xcodes-interface-builder/#comment-16635
//
public class CenterToolBarItem: NSToolbarItem {
    override public func awakeFromNib() {
        if let view = self.view {
            view.addSubview(viewController.view)
            viewController.view.frame = view.bounds
            viewController.view.swiftPinToSuperViewSize()
            viewController.view.needsDisplay = true
        }
    }
    
    private var _viewController: CenterToolBarViewController?
    public var viewController: CenterToolBarViewController {
        if _viewController == nil {
            _viewController = CenterToolBarViewController.init()
        }
        return _viewController!
    }
}

public class CenterToolBarViewController: NSViewController {
    lazy var logger: Logger = {
        return IDDLog4swift.getLogger(self)
    }()

    static let outsideMargin = CGFloat(20.0)
    
    @IBOutlet var activityPI: NSProgressIndicator!
    @IBOutlet var pathPrefixTF: NSTextField!
    @IBOutlet var activityTF: NSTextField!
    @IBOutlet var activityButton: NSButton!
    @IBOutlet var activityCount: NSTextField!
    @IBOutlet var activityTFCenterY: NSLayoutConstraint!
    @IBOutlet var historyTF: NSTextField!

    // MARK: - Private methods
    // MARK: -
    
    // true to hide it
    // false to show it
    //
    private var _activityButtonIsHidden: Bool {
        get {
            return (activityButton.alphaValue <= 0.0)
        }
        set {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.25)
            CATransaction.setCompletionBlock({
            })
            if newValue {
                activityButton.animator().alphaValue = 0.0 // fade out
                activityCount.animator().alphaValue = 0.0 // fade out
            } else {
                activityButton.animator().alphaValue = 1.0 // fade in
                activityCount.animator().alphaValue = 1.0 // fade in
            }
            CATransaction.commit()
        }
    }

    @objc private func _eraseTitle(_ sender: Any) {
        logger.info("stringValue: '\(activityTF.stringValue)'")
        logger.debug("stringValue: '\(activityTF.stringValue)' animating out: '\(activityTF.frame.origin.y)'")

        self.view.layer!.removeAllAnimations()
        CATransaction.begin()
        CATransaction.setAnimationDuration(1.25)
        CATransaction.setCompletionBlock({
            self.activityTF.stringValue = ""
            self.activityTFCenterY.constant = -CenterToolBarViewController.outsideMargin
            self.activityCount.stringValue = String(CenterToolBarHistory.shared.history.count)
        })
        // animate upward to invisible
        //
        activityTFCenterY.animator().constant = CenterToolBarViewController.outsideMargin
        CATransaction.commit()
    }
    
    private func _updateHistory() {
        var messages = [String]()
        
        for item in CenterToolBarHistory.shared.history {
            let dateString = item.date.string(withFormat: "MMM dd, HH:mm:ss")
            
            messages.append("\(dateString) - \(item.message)")
        }
        
        historyTF.stringValue = messages.joined(separator: "\n")
    }
    
    // MARK: - NSApplication.AppearanceDidChange
    // MARK: -
    
    private func _appearanceDidChangeNotification() {
        (self.view as! NSView_CenterToolBarView).appearanceDidChangeNotification()
    }
    
    @objc private func _AppearanceDidChangeNotification(_ notification : NSNotification) {
        _appearanceDidChangeNotification()
    }

    // MARK: - Overriden methods
    // MARK: -
    
    convenience init() {
        self.init(nibName: "CenterToolBarViewController", bundle: .module)
        self.loadView()
    }

    private var _didAwakeFromNib = false
    override public func awakeFromNib() {
        if !_didAwakeFromNib {
            self.logger.info("")
            _didAwakeFromNib = true
            
            self.view.wantsLayer = true
            _appearanceDidChangeNotification()
            
            activityButton.image = NSImage.template(named: "CenterToolBarHistory_activityButton-mask", in: .module)
            activityButton.alphaValue = 1.0
            activityButton.target = self
            activityButton.action = #selector(self.activityButtonClick(_:))

            activityCount.stringValue = ""
            activityPI.usesThreadedAnimation = true
            activityPI.isDisplayedWhenStopped = false
            activityPI.isIndeterminate = true

            activityTF.stringValue = ""
            activityCount.stringValue = ""
            activityTFCenterY.constant = -CenterToolBarViewController.outsideMargin
            stringValue = ""

            pathPrefixTF.stringValue = UserDefaults.pathPrefix
            if pathPrefixTF.stringValue.uppercased().hasPrefix("USER") {
                pathPrefixTF.stringValue = UserDefaults.pathPrefix.uppercased().replacingOccurrences(of: "USER", with: "U").appending(":")
            }
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self._AppearanceDidChangeNotification),
                name: NSApplication.AppearanceDidChange,
                object: nil
            )
        }
    }

    // MARK: - Instance methods
    // MARK: -
    
    public func applicationDidResignActive(_ notification: Notification) {
        if logger.isDebug {
            logger.debug("")
        }
        activityTF.textColor = NSColor.tertiaryLabelColor
        activityTF.display()
        // activityTF.cell!.backgroundStyle = .dark
    }

    public func applicationDidBecomeActive(_ notification: Notification) {
        if logger.isDebug {
            logger.debug("")
        }
        activityTF.textColor = NSColor.labelColor
        activityTF.display()
        // activityTF.cell!.backgroundStyle = .light
    }

    public var stringValue: String {
        get {
            return activityTF.stringValue
        }
        set {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self._eraseTitle), object: self)

            activityTF.stringValue = newValue
            activityCount.stringValue = String(CenterToolBarHistory.shared.history.count)
            // logger.info("stringValue: '\(activityTF.stringValue)' activityTF.origin.y: '\(activityTF.frame.origin.y)'")
            if activityTFCenterY.constant == -CenterToolBarViewController.outsideMargin {
                // invisible text field, animate it upward to into visible location
                //
                logger.info("stringValue: '\(activityTF.stringValue)'")
                logger.debug("stringValue: '\(activityTF.stringValue)' animating in: '\(activityTF.frame.origin.y)'")
                CATransaction.begin()
                CATransaction.setAnimationDuration(0.25)
                CATransaction.setCompletionBlock({
                })
                activityTFCenterY.animator().constant = 0.0
                CATransaction.commit()
            }
            if _activityButtonIsHidden {
                // we are animating ...
                // do not erase ...
                //
            } else {
                self.perform(#selector(self._eraseTitle), with: self, afterDelay: 8.25)
            }
        }
    }

    @IBAction func activityButtonClick(_ sender: Any) {
        _updateHistory()
        view.window!.beginSheet(historyTF.window!) { (response: NSApplication.ModalResponse) in
            self.logger.info("")
        }
    }
    
    @IBAction func resetHistory(_ sender: Any) {
        view.window!.endSheet(historyTF.window!)
        CenterToolBarHistory.shared.resetHistory()
        activityCount.stringValue = ""
    }
    
    @IBAction func endHistorySheet(_ sender: Any) {
        view.window!.endSheet(historyTF.window!)
    }

    public func startAnimation(_ sender: Any?) {
        _activityButtonIsHidden = true
        activityPI.startAnimation(self)
    }
    
    public func stopAnimation(_ sender: Any?) {
        _activityButtonIsHidden = false
        activityPI.stopAnimation(self)
        self.perform(#selector(self._eraseTitle), with: self, afterDelay: 8.25)
    }
}
