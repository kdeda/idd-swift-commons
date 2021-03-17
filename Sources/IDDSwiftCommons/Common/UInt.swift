//
//  Int.swift
//  IDDSwiftCommons
//
//  Created by Klajd Deda on 9/17/17.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//

import Foundation

extension UInt {
    public func compare(_ object: UInt) -> ComparisonResult {
        let diff = Int(self - object)
        
        if diff == 0 {
            return ComparisonResult.orderedSame
        } else if diff > 0 {
            return ComparisonResult.orderedDescending
        }
            
        return ComparisonResult.orderedAscending
    }
}
