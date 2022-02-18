//
//  IDDTimeBlock.swift
//  SwiftCommons
//
//  Created by Klajd Deda on 6/30/17.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

import Foundation

class BlockTime: NSObject {
    // return time elapsed in milliseconds
    //
    static func elapsed(_ block: () -> Void) -> TimeInterval {
        let methodStart = Date()

        block()
        return Date().timeIntervalSince(methodStart) * 1000.0
    }
}
