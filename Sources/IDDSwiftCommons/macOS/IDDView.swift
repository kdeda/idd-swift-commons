//
//  IDDView.swift
//  Test
//
//  Created by Klajd Deda on 7/3/18.
//  Copyright © 2018 Klajd Deda. All rights reserved.
//

import AppKit
import Log4swift

open class IDDView: NSView {    
    public lazy var logger: Logger = {
        return IDDLog4swift.getLogger(self)
    }()
    
    @IBOutlet open var contentView: NSView!

    // MARK: - Overriden methods
    // MARK: -

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadFromNib()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadFromNib()
    }

    // MARK: - Instance methods
    // MARK: -

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
