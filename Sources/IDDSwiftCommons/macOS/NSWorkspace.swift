//
//  NSWorkSpace.swift
//  IDDSwiftCommons
//
//  Created by Klajd Deda on 11/8/17.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//

import AppKit
import Log4swift

extension NSWorkspace {
    public static let logger: Logger = {
        return IDDLog4swift.getLogger("NSWorkSpace")
    }()

    private static var _notifyAbout_DS_Store_Files = true
    // https://apple.stackexchange.com/questions/299138/show-hidden-files-files-in-finder-except-ds-store/300210#300210
    //

    // MARK: - Class methods
    // MARK: -

    private static var _minorOSVersion: Int = -1
    public static var minorOSVersion: Int = {
        if _minorOSVersion == -1 {
            if let versionInfo = NSDictionary.init(contentsOfFile: "/System/Library/CoreServices/SystemVersion.plist") {
                if let productVersion = versionInfo["ProductVersion"] as? String {
                    var tokens = productVersion.components(separatedBy: ".")
                    
                    while tokens.count > 2 {
                        tokens.removeLast()
                    }
                    if tokens.count == 2 {
                        if let version = Int(tokens[1]) {
                            _minorOSVersion = version
                        }
                    }
                }
            }
        }
        return _minorOSVersion
    }()
    
    // MARK: - Private methods
    // MARK: -

    private var _showHiddenFilesInFinder: Bool {
        if let defaults = UserDefaults.standard.persistentDomain(forName: "com.apple.finder") {
            if let showAllFiles = defaults["AppleShowAllFiles"] as? String {
                return showAllFiles.uppercased() == "TRUE" || showAllFiles.uppercased() == "YES"
            }
        }
        return false
    }

    // MARK: - Instance methods
    // MARK: -

    public func killPID(_ pid: Int32) {
        if (pid > 0) {
            let task = Process.init()
            
            task.launchPath = "/bin/kill"
            task.arguments = ["-9", "\(pid)"]
            task.launch()
            task.waitUntilExit()
            NSWorkspace.logger.info("killed: '\(pid)' withStatus: '\(task.terminationStatus)'")
            task.terminate()
        }
    }

    public func terminate(_ bundleIdentifiers: [String]) {
        // kill the other instance first
        //
        self.runningApplications.forEach { (runningApplication) in
            if let runningBundleIdentifier = runningApplication.bundleIdentifier {
                NSWorkspace.logger.debug("found: '\(runningBundleIdentifier).\(runningApplication.processIdentifier)'")
                
                if bundleIdentifiers.contains(runningBundleIdentifier) {
                    let runningProcessIdentifier = runningApplication.processIdentifier
                    
                    // we found one to kill
                    //
                    if runningProcessIdentifier != ProcessInfo.processInfo.processIdentifier {
                        // don't kill us
                        //
                        NSWorkspace.logger.info("terminate: '\(runningBundleIdentifier).\(runningProcessIdentifier)'")
                        runningApplication.terminate()
                        Thread.sleep(forTimeInterval: 1.0)
                        // fucking die bitch,
                        // apple seems to fail to terminate often
                        //
                        self.killPID(runningProcessIdentifier)
                    }
                }
            }
        }
    }
    
    public var showHiddenFilesInFinder: Bool {
        get {
            return _showHiddenFilesInFinder
        }
        set {
            if _showHiddenFilesInFinder != newValue {
                if var defaults = UserDefaults.standard.persistentDomain(forName: "com.apple.finder") {
                    defaults["AppleShowAllFiles"] = newValue ? "true" : "false"
                    UserDefaults.standard.setPersistentDomain(defaults, forName: "com.apple.finder")
                    UserDefaults.standard.synchronize()
                    // reboot Finder
                    //
                    Process.string(fromTask: "/usr/bin/killall", arguments: ["Finder"])
                }
            }
        }
    }

    /*
     * For certain files this will fail.
     * for example all invisible files/folders starting with .
     * [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:nil]
     * Added mechanism for switching to PathFinder or some other app.
     *
     * We need to enable Finder to show hidden files.
     * http://lifehacker.com/188892/show-hidden-files-in-finder
     *
     * defaults write com.apple.finder AppleShowAllFiles true
     * defaults write com.apple.finder AppleShowAllFiles false
     * killall Finder
     */
    public func reveal(inFinder pathURL: URL, inWindow window: NSWindow) {
        NSWorkspace.logger.info("path: '\(pathURL.path)'")
        
        if pathURL.path.hasSuffix(".DS_Store") {
            if NSWorkspace.minorOSVersion >= 12 && NSWorkspace._notifyAbout_DS_Store_Files {
                NSWorkspace._notifyAbout_DS_Store_Files = false
                
                NSAlert.attachAlert(
                    withStyle: .warning,
                    message: "Warning".localized,
                    informative: "Unfortunately Apple has configured Finder to never show .DS_Store files.\n".localized,
                    buttons: ["OK".localized],
                    toWindow: window
                ) { _ in }
                return
            }
        }
    
        if pathURL.hasHiddenComponents && !showHiddenFilesInFinder {
            let message = "To reveal hidden files we need to configure Finder to show hidden files. Are you ok with that ?".localized
            let responseCode = NSAlert.modalAlert(
                withStyle: .warning,
                message: "Warning".localized,
                informative: message,
                buttons: ["OK", "Cancel"],
                toWindow: window
            )
            
            switch responseCode {
            case .alertFirstButtonReturn:
                self.showHiddenFilesInFinder = true
                break
            default:
                NSWorkspace.logger.error("unmanaged returnCode: '\(responseCode)'")
            }
        }

        if !pathURL.fileExist {
            let format = "The file at: '%@' is not accessible or not longer exist.\n\nPlease refresh your measures.".localized
            
            NSAlert.attachAlert(
                withStyle: .warning,
                message: "Warning".localized,
                informative: String(format: format, pathURL.path),
                buttons: ["OK".localized],
                toWindow: window
            ) { _ in }
            return
        }
            
        /* this will probably default to Finder !!
         * some people use PathFinder as a replacement.
         */
        if !self.selectFile(pathURL.path, inFileViewerRootedAtPath: "") {
            // should not get here ...
            //
            NSWorkspace.logger.error("Could not select: '\(pathURL.path)'")
        }
    }

}

