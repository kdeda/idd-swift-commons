//
//  NSImage.swift
//  IDDSwiftCommons
//
//  Created by Klajd Deda on 8/2/17.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//

import AppKit
import Log4swift

public extension NSImage {
    static let logger: Logger = {
        return IDDLog4swift.getLogger("NSImage")
    }()

    static func template(named imageName: NSImage.Name) -> NSImage? {
        let rv = NSImage.init(named: imageName)

        rv?.isTemplate = true
        return rv
    }

    static func template(named imageName: NSImage.Name, in bundle: Bundle?) -> NSImage? {
        let rv = bundle?.image(forResource: imageName)

        rv?.isTemplate = true
        return rv
    }

    // https://stackoverflow.com/questions/45028530/set-image-color-of-a-template-image
    //
    func tint(withColor color: NSColor) -> NSImage {
        let rv = self.copy() as! NSImage
        
        rv.lockFocus()
        color.set()
        
        let imageRect = NSRect(origin: NSZeroPoint, size: self.size)
        imageRect.fill(using: .sourceAtop)
        
        rv.unlockFocus()
        return rv
    }

}
