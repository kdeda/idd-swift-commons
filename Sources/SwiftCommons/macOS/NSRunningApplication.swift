//
//  NSRunningApplication.swift
//  SwiftCommons
//
//  Created by Klajd Deda on 7/26/18.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

#if os(macOS)

import Cocoa

public extension NSRunningApplication {
    
    static func isRunning(withBundleIdentifier bundleIdentifier: String, orPID processPID: Int) -> Bool {
        let applications = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
        
        // logger.debug("applications: '\(applications)'")
        if applications.count > 0 {
            return true
        }
        
        // for some reason our dear apple bs is hitting the fan
        // we get an empty array of running applications
        // but the app is running allright
        // somehow magically my old code works ...
        //
        // TODO
        // We could port this to straight swift, but for now will use old obj-c code
        // https://github.com/mattgallagher/CwlUtils/blob/master/Sources/CwlUtils/CwlSysctl.swift
        // https://developer.apple.com/forums/thread/101874?answerId=309633022#309633022
        //
//        if Host.processArguments(processPID).count > 0 {
//            return true
//        }
        return false
    }
}

#endif
