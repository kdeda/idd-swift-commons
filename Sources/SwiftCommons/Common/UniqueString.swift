//
//  UniqueString.swift
//  SwiftCommons
//
//  Created by Klajd Deda on 9/17/17.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift

public class UniqueString {
    static var shared: UniqueString = {
        var rv = UniqueString()
        
        rv.cache["/"] = 0
        return rv
    }()
    lazy var logger: Logger = {
        return Log4swift.getLogger(self)
    }()

    var cache = [String: Int]()
    
//    func binarySearch<T:Comparable>(inputArray array:Array<T>, item searchItem: T) -> Int? {
//        var lowerIndex = 0;
//        var upperIndex = array.count - 1
//        
//        if upperIndex < 0 {
//            return nil
//        }
//        while (true) {
//            let currentIndex = (lowerIndex + upperIndex)/2
//            
//            if(array[currentIndex] == searchItem) {
//                return currentIndex
//            } else if (lowerIndex > upperIndex) {
//                return nil
//            } else {
//                if (array[currentIndex] > searchItem) {
//                    upperIndex = currentIndex - 1
//                } else {
//                    lowerIndex = currentIndex + 1
//                }
//            }
//        }
//    }
    
    func index(ofString aString: String) -> Int? {
        if let value = cache[aString] {
            return value
        }

        let index = cache.count
        cache[aString] = index
//        if let index = binarySearch(inputArray: cache, item: aString) {
//            logger.info("index: '\(index)'");
//            return index
//        }
//        
//        cache.append(aString)
//        cache.sort(by: {$0 < $1})
//        return index(ofString: aString)
        return index
    }
    
    func index(ofURL url: URL) -> [Int]? {
        let components = url.pathComponents
        var rv = [Int]()
        
        for pathComponent in components {
            rv.append(index(ofString: pathComponent)!)
        }
        
        return rv
    }
}
