//
//  NSView.swift
//  SwiftCommons
//
//  Created by Klajd Deda on 8/2/17.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

#if os(macOS)

import Cocoa
import Log4swift

public extension NSView {
    static let logger: Logger = {
        return Log4swift.getLogger("NSView")
    }()
    
    func swiftPinToSuperViewSize(_ constant: CGFloat) {
        if let superview = self.superview {
            if NSView.logger.isDebug {
                NSView.logger.debug("constraints: '\(superview.constraints)'")
            }
            superview.addConstraint(NSLayoutConstraint.init(item: self,
                                                            attribute: .top,
                                                            relatedBy: .equal,
                                                            toItem: superview,
                                                            attribute: .top,
                                                            multiplier: 1.0,
                                                            constant: constant))
            
            superview.addConstraint(NSLayoutConstraint.init(item: self,
                                                            attribute: .leading,
                                                            relatedBy: .equal,
                                                            toItem: superview,
                                                            attribute: .leading,
                                                            multiplier: 1.0,
                                                            constant: constant))
            
            superview.addConstraint(NSLayoutConstraint.init(item: self,
                                                            attribute: .bottom,
                                                            relatedBy: .equal,
                                                            toItem: superview,
                                                            attribute: .bottom,
                                                            multiplier: 1.0,
                                                            constant: constant))
            
            superview.addConstraint(NSLayoutConstraint.init(item: self,
                                                            attribute: .trailing,
                                                            relatedBy: .equal,
                                                            toItem: superview,
                                                            attribute: .trailing,
                                                            multiplier: 1.0,
                                                            constant: constant))
        }
    }
    
    /**
     Setsup the receiver to stretch with the superview size
     */
    func swiftPinToSuperViewSize() {
        self.swiftPinToSuperViewSize(0.0)
    }
    
    /**
     Setsup the receiver to center horizontally to superview
     */
    func swiftPinToSuperViewHorizontal() {
        if let superview = self.superview {
            self.centerXAnchor.constraint(equalTo: superview.centerXAnchor).isActive = true
        }
    }

    /**
     Setsup the receiver to center vertically to superview
     */
    func swiftPinToSuperViewVertical() {
        if let superview = self.superview {
            self.centerYAnchor.constraint(equalTo: superview.centerYAnchor).isActive = true
        }
    }
}

#endif
