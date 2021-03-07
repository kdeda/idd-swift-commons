//
//  OpaqueGridScroller.swift
//  IDDAppKit
//
//  Created by Klajd Deda on 9/18/19.
//  Copyright (C) 1997-2018 id-design, inc. All rights reserved.
//

import AppKit

// https://stackoverflow.com/questions/4181029/how-to-draw-a-transparent-nsscroller
// https://stackoverflow.com/questions/51061738/how-to-make-scroller-background-transparent-in-nsscrollview/57996591#57996591
//
class OpaqueGridScroller: NSScroller {
    override func draw(_ dirtyRect: NSRect) {
        // NSColor.clear.set()
        // dirtyRect.fill()
        self.drawKnob()
    }
}
