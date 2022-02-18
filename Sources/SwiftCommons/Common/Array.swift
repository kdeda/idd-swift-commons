//
//  Array.swift
//  SwiftCommons
//
//  Created by Klajd Deda on 12/26/19.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

import Foundation

extension Array where Element: Equatable {
    public func unique() -> Array {
        return reduce(Array()) { uniqueValues, element in
            uniqueValues.contains(element) ? uniqueValues : uniqueValues + [element]
        }
    }

    public func split(batchSize: Int) -> [[Element]] {
        var rv: [[Element]] = []

        for idx in stride(from: 0, to: count, by: batchSize) {
            let upperBound = Swift.min(idx + batchSize, count)
            
            rv.append(Array(self[idx..<upperBound]))
        }
        return rv
    }

    // safe
    // https://www.hackingwithswift.com/example-code/language/how-to-make-array-access-safer-using-a-custom-subscript
    //
    public subscript(safeIndex index: Int) -> Element? {
        guard index >= 0, index < endIndex else {
            return .none
        }
        
        return self[index]
    }
}
