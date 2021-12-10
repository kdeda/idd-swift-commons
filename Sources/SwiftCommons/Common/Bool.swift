//
//  Int.swift
//  SwiftCommons
//
//  Created by Klajd Deda on 9/17/17.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//

import Foundation

extension Bool {
    /*
     * true, false orderedDescending
     * false, true orderedAscending
     */
    public func compare(_ object: Bool) -> ComparisonResult {        
        if object == self {
            return ComparisonResult.orderedSame
        } else if !self && object {
            return ComparisonResult.orderedDescending
        }
            
        return ComparisonResult.orderedAscending
    }
}
