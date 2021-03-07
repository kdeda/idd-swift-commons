//
//  Date.swift
//  IDDAppKit
//
//  Created by Klajd Deda on 12/5/17.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//

import Foundation

extension NSNotification {

    public func intUserInfo(forKey key: String) -> Int? {
        if let rv = self.userInfo?[key] as? Int {
            return rv
        }
        return nil
    }
    
}
