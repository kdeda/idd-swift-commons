//
//  IDDView.swift
//  SwiftCommons
//
//  Created by Klajd Deda on 7/3/18.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

#if os(macOS)

import Cocoa
import Log4swift

open class IDDView: NSView {    
    public lazy var logger: Logger = {
        return Log4swift.getLogger(self)
    }()
    
    @IBOutlet open var contentView: NSView!

    // MARK: - Overriden methods -

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadFromNib()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadFromNib()
    }

    // MARK: - Instance methods -

    open func loadFromNib() {
        self.wantsLayer = true
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let bundle = Bundle(for: type(of: self))
        let nibName = String(describing: type(of: self))
        let nib = NSNib(nibNamed: .init(nibName), bundle: bundle)!
        
        nib.instantiate(withOwner: self, topLevelObjects: nil)
        if contentView == nil {
            logger.error("please hook up the contentView on: '\(nibName).xib'")
        }
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.swiftPinToSuperViewSize()
    }
}

#endif
