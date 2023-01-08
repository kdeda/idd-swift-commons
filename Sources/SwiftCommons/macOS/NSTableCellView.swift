//
//  NSTableCellView.swift
//  SwiftCommons
//
//  Created by Klajd Deda on 2/20/19.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

#if os(macOS)

import Cocoa

public extension NSTableCellView {
    
    // MARK: - Instance methods -
    
    var tableView: NSTableView? {
        if let tableView = self.superview?.superview as? NSTableView {
            return tableView
        } else if let scrollView = self.superview?.superview?.superview as? NSScrollView {
            if let tableView = scrollView.documentView as? NSTableView {
                return tableView
            }
        }
        return nil
    }
    
    // convenience so we call methods back to the tableView.delegate
    // example
    //    if let controller = tableViewDelegate as? NSTableCellView_NodeController {
    //        controller.deleteDuplicatesInPlace(self)
    //    }
    // where NSTableCellView_NodeController is a protocol our tableView delegate implements
    //
    var tableViewDelegate: NSTableViewDelegate? {
        if let tableView = tableView {
            return tableView.delegate
        }
        return nil
    }
}

#endif
