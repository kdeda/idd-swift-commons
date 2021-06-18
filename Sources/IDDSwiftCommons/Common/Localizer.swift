//
//  Localizer.swift
//  IDDSwiftCommons
//
//  Created by Klajd Deda on 7/4/17.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//  https://medium.com/@dcordero/a-different-way-to-deal-with-localized-strings-in-swift-3ea0da4cd143
//
//  To see more turn debug mode
//  -Localizer D
//

import Foundation
import Log4swift

public class Localizer {
    static let shared = Localizer()

    lazy var logger: Logger = {
        return Log4swift.getLogger(self)
    }()

    lazy var localizableDictionary: Dictionary<String, Dictionary<String, String>> = {
        let rv = Dictionary<String, Dictionary<String, String>>.init()
        
        if let path = Bundle.main.path(forResource: "Localizer", ofType: "plist") {
            if let savedDictionary = NSDictionary(contentsOfFile: path) {
                return rv
            }
        }
        self.logger.error("Localizable file NOT found")
        return rv
    }()
    
    func localize(_ string: String) -> String {
        if let localizedEntry = localizableDictionary[string] {
            if let rv = localizedEntry["value"] {
                return rv
            }
        }
        logger.debug("Missing translation for: '\(string)'")
        
        var localizedEntry = Dictionary<String, String>.init()
        var rv = string
        
        if UserDefaults.standard.bool(forKey: "showLocalizedStrings") {
            rv = string.uppercased()
        }

        localizedEntry["value"] = rv
        localizedEntry["comment"] = "Comment"
        localizableDictionary[string] = localizedEntry
        return rv
    }
}
