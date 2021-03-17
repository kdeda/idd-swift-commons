//
//  SortDescriptor.swift
//  IDDSwiftCommons
//
//  Created by Klajd Deda on 5/9/20.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//

import Foundation

// http://chris.eidhof.nl/post/sort-descriptors-in-swift/
//
public typealias SortDescriptor<Value> = (Value, Value) -> Bool

public struct Sort {
    public static func sortDescriptor<Value, Key>(
        key: @escaping (Value) -> Key,
        ascending: Bool,
        comparator: @escaping (Key) -> (Key) -> ComparisonResult
    ) -> SortDescriptor<Value> {
        return { left, right in
            let order: ComparisonResult = ascending ? .orderedAscending : .orderedDescending
            return comparator(key(left))(key(right)) == order
        }
    }
}

