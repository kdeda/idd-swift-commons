//
//  SortDescriptor.swift
//  SwiftCommons
//
//  Created by Klajd Deda on 5/9/20.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation

// http://chris.eidhof.nl/post/sort-descriptors-in-swift/
//
public typealias SortDescriptor<Element> = (Element, Element) -> Bool

public struct Sort {
    public static func sortDescriptor<Element, Value>(
        key: @escaping (Element) -> Value,
        ascending: Bool,
        comparator: @escaping (Value) -> (Value) -> ComparisonResult
    ) -> SortDescriptor<Element> {
        return { left, right in
            let order: ComparisonResult = ascending ? .orderedAscending : .orderedDescending
            return comparator(key(left))(key(right)) == order
        }
    }
}

