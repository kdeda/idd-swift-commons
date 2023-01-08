//
//  FileManager.swift
//  SwiftCommons
//
//  Created by Klajd Deda on 9/25/17.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift
#if os(macOS)
import Cocoa
#endif

extension FileManager {
    private static var mountedVolumes = [String]()
    private static var mountedVolumesLastFetchDate = Date.distantPast
    private static var registerForWorkSpaceNotifications = false

    static let logger: Logger = {
        return Log4swift.getLogger("FileManager")
    }()

    /**
     it will return false if the file exists and we could not remove it
     */
    public func removeItemIfExist(at pathURL: URL) -> Bool {
        do {
            if pathURL.fileExist {
                try FileManager.default.removeItem(at: pathURL)
            }
        } catch {
            Self.logger.error("failed to remove: '\(pathURL.path)'")
            Self.logger.error("error: '\(error.localizedDescription)'")
            return false
        }
        return true
    }
    
    public var hasFullDiskAccess: Bool {
        return hasFullDiskAccess(forHomeDirectory: URL.home)
    }

    // true if any of these files exist and are readable by the current app
    //
    public func hasFullDiskAccess(forHomeDirectory homeDirectory: URL) -> Bool {
        let userFiles = [
            "/Library/Application Support/AddressBook",
            "/Library/Application Support/CallHistoryDB",
            "/Library/Application Support/CallHistoryTransactions",
            "/Library/Application Support/com.apple.TCC",
            "/Pictures/Photos Library.photoslibrary",
            "/Library/Application Support/MobileSync",
            "/Library/Calendars",
            "/Library/Caches/CloudKit/com.apple.Safari",
            "/Library/Containers/com.apple.iChat",
            "/Library/Containers/com.apple.mail",
            "/Library/Caches/com.apple.Safari",
            "/Library/Caches/com.apple.safaridavclient",
            "/Library/Containers/com.apple.Safari",
            "/Library/Cookies",
            "/Library/IdentityServices",
            "/Library/HomeKit",
            "/Library/Mail",
            "/Library/Messages",
            "/Library/Metadata/com.apple.IntelligentSuggestions",
            "/Library/Metadata/CoreSpotlight",
            "/Library/PersonalizationPortrait",
            "/Library/Safari",
            "/Library/Suggestions"
        ]
        
        let inaccessibleURLs = userFiles
            .map { homeDirectory.appendingPathComponent($0) }
            .filter { $0.fileExist }
            .filter { !$0.isReadable }
        let rv = inaccessibleURLs.isEmpty
        
        // Self.logger.info("process: '\(ProcessInfo.processInfo.processName)' homeDirectory: '\(homeDirectory.path)' hasFullDiskAccess: '\(rv)'")
        if !rv {
            let inaccessiblePaths = inaccessibleURLs
                .map(\.path)
                .prefix(4)
                .joined(separator: "',\n\t'")
            Self.logger.info("process: '\(ProcessInfo.processInfo.processName)' homeDirectory: '\(homeDirectory.path)' hasFullDiskAccess: '\(rv)'")
            Self.logger.info("process: '\(ProcessInfo.processInfo.processName)' cantAccess: \n\t'\(inaccessiblePaths)'")
        }
        return rv
    }

    @discardableResult
    public func createDirectoryIfMissing(at pathURL: URL) -> Bool {
        guard !pathURL.fileExist
        else { return true }
        
        do {
            try FileManager.default.createDirectory(at: pathURL, withIntermediateDirectories: true, attributes: nil)
            return pathURL.fileExist
        } catch {
            Self.logger.error("failed to create: '\(pathURL.path)'")
            Self.logger.error("error: '\(error.localizedDescription)'")
        }
        return false
    }

    private func registerForWorkSpaceNotifications() {
#if os(macOS)
        guard !Self.registerForWorkSpaceNotifications
        else { return }
        
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.didMountNotification(_:)), name: NSWorkspace.didMountNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.didUnmountNotification(_:)), name: NSWorkspace.didUnmountNotification, object: nil)
        Self.registerForWorkSpaceNotifications = true
#endif
    }

    @objc private func didMountNotification(_ notification: NSNotification) {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        Self.logger.info("notification: '\(notification.userInfo ?? [AnyHashable: Any]())'")
        Self.mountedVolumesLastFetchDate = Date.distantPast
    }
    
    @objc  private func didUnmountNotification(_ notification: NSNotification) {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        Self.logger.info("notification: '\(notification.userInfo ?? [AnyHashable: Any]())'")
        Self.mountedVolumesLastFetchDate = Date.distantPast
    }

    /*
     * /dev
     * /home
     * /net
     * /Volumes/...
     */
    public func mountedVolumes(_ refetch: Bool) -> [String] {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }

        func fetchMountedVolumes() -> [String] {
            var statfs: UnsafeMutablePointer<statfs>?
            let count = Int(getmntinfo(&statfs, 0))

            func charPointerToString(_ pointer: UnsafePointer<Int8>) -> String {
               return String(cString: UnsafeRawPointer(pointer).assumingMemoryBound(to: CChar.self))
            }

            if let volumesArray = statfs, count > 0 {
                return (0..<count).map { (index) -> String in
                    var volume = volumesArray[index]
                    let mountTo = charPointerToString(&volume.f_mntonname.0)
                    //    let mountFrom = charPointerToString(&volume.f_mntfromname.0)
                    //    let fileSystemType = charPointerToString(&volume.f_fstypename.0)
                    return mountTo
                }
                .sorted(by: >)
            }
            return [String]()
        }

        // when refetch is true
        // do not really fetch unless a second has elapsed since last fetch
        //
        guard refetch,
              -Self.mountedVolumesLastFetchDate.timeIntervalSinceNow * 1000 > 1000
        else {
            // Self.logger.info("cache: '\(-Self.mountedVolumesLastFetchDate.timeIntervalSinceNow * 1000)'")
            return Self.mountedVolumes }
        
        // Self.logger.info("fetch: '\(-Self.mountedVolumesLastFetchDate.timeIntervalSinceNow * 1000)'")
        registerForWorkSpaceNotifications()
        Self.mountedVolumes = fetchMountedVolumes()
        Self.mountedVolumesLastFetchDate = Date()
        return Self.mountedVolumes
    }
    
    public func isMountedVolume(_ basePath: String) -> Bool {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        return Self.mountedVolumes.firstIndex(where: { $0 == basePath}) != nil
    }
}
