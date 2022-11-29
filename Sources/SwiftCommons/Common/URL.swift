//
//  URL_IDDFoundation.swift
//  SwiftCommons
//
//  Created by Klajd Deda on 9/16/17.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift
#if os(macOS)
import Cocoa
#endif

extension URL {
    static public let logger: Logger = {
        return Log4swift.getLogger("URL")
    }()

    /**
     A URL identifying the user's home directory, typically in `/Users`.
     Calling `NSHomeDirectory()` from a sandboxed app will return an descendant of the app sandbox.
     This property on the other hand will return the actual home directory outside the sandbox.
     Note that access restrictions still apply, e.g. testing access to the returned URL will normally fail.
     http://zpasternack.org/accessing-the-real-home-folder-from-a-sandboxed-app/
     http://stackoverflow.com/questions/12153504/accessing-the-desktop-in-a-sandboxed-app
     */
    static public var iddHomeDirectory: URL = {
        if NSObject.isAppStoreBuild {
            if let home = getpwuid(getuid()), let homePtr = home.pointee.pw_dir {
                let homePath = FileManager.default.string(withFileSystemRepresentation: homePtr, length: Int(strlen(homePtr)))
                
                return URL.init(fileURLWithPath: homePath)
            }
        }

        return URL.init(fileURLWithPath: NSHomeDirectory())
    }()
    
    static public var homeLibraryCaches: URL = {
        return iddHomeDirectory.appendingPathComponent("Library/Caches")
    }()

    static public var systemLibraryCaches: URL = {
        return URL.init(fileURLWithPath: "/Library/Caches")
    }()
    
    static let trashDateFormatter: DateFormatter = {
        let rv = DateFormatter.init(withFormatString: "HH.mm.ss a", andPOSIXLocale: true)
        
        rv.amSymbol = "AM"
        rv.pmSymbol = "PM"
        return rv
    }()
    
    
    // MARK: - Private methods -
    private func _volumeUUID(_ mountedVolumes: Set<String>) -> String {
        var realURL = self
        
        if !realURL.isReadable {
            // will fail for unreadable urls,
            // crawl up to the root of the volume tree
            //
            while !realURL.isReadable && !mountedVolumes.contains(realURL.path) {
                realURL = realURL.deletingLastPathComponent()
            }
            
            if !realURL.isReadable {
                // we should not get here
                // unless even the mounted volumes are not readable
                //
                URL.logger.error("unreadable volume: '\(self.path)'")
            }
        }
        
        if let rv = (try? realURL.resourceValues(forKeys: [.volumeUUIDStringKey]))?.volumeUUIDString {
            return rv
        }

        // for some mounted volumes mainly SMB or AFP we don't get a uuid
        // this will attempt to fetch the mount point and map it to an md5
        // of course if we are not mounted the following will fail as well
        //
        if let rv = (try? realURL.resourceValues(forKeys: [.volumeURLForRemountingKey]))?.volumeURLForRemounting {
            URL.logger.error(".volumeUUIDStringKey failed, will default to the md5 hash for: '\(rv.absoluteString)'")
            return rv.absoluteString.md5
        }

        // WTF
        //
        URL.logger.error(".volumeUUIDStringKey and .volumeURLForRemountingKey failed, will default to the md5 hash for: '\(self.path)'")
        return self.path.md5
    }

    private func _sizeFrom(backupLog row: String) -> Int64 {
        let cleanedRow = row.trimmingCharacters(in: CharacterSet.whitespaces)
        let cleanedRow_ = cleanedRow.replacingOccurrences(of: "Zero", with: "0")
        let tokens = cleanedRow_.components(separatedBy: " ")
        var rv: Int64 = 0
        
        // logger.info("cleanedRow: '\(cleanedRow_)'")
        if URL.logger.isDebug {
            URL.logger.debug("tokens: '\(tokens.joined(separator: "', '"))'");
        }
        if tokens.count == 2 {
            var size = Double(tokens[0]) ?? 0.0
            let multiplier = tokens[1]
            
            if multiplier.caseInsensitiveCompare("GB") == .orderedSame {
                size *= 1000*1000*1000
            } else if multiplier.caseInsensitiveCompare("MB") == .orderedSame {
                size *= 1000*1000
            } else if multiplier.caseInsensitiveCompare("KB") == .orderedSame {
                size *= 1000
            }
            rv = Int64(size)
        }
        return rv
    }

    // MARK: - Instance methods -
    public var fileExist: Bool {
        do {
            return try self.checkResourceIsReachable()
        } catch {
            // let logger = Log4swift.getLogger(self)
            // logger.error("error: '\(error.localizedDescription)'")
        }
        return false
    }

#if os(macOS)
    public var fileIcon: NSImage {
        let resourceValues = try? self.resourceValues(forKeys: [.effectiveIconKey])
        
        if let fileIcon = resourceValues?.effectiveIcon as? NSImage {
            return fileIcon
        }
        return NSImage()
    }
#endif
    
    public var isDirectory: Bool {
        return (try? self.resourceValues(forKeys: [.isDirectoryKey]))?
            .isDirectory ?? false
    }

    public var isReadable: Bool {
        return (try? self.resourceValues(forKeys: [.isReadableKey]))?
            .isReadable ?? false
    }

    public var isExecutable: Bool {
        return (try? self.resourceValues(forKeys: [.isExecutableKey]))?
            .isExecutable ?? false
    }

    public var isWritable: Bool {
        let resourceValues = try? self.resourceValues(forKeys: [.isWritableKey])
        
        if resourceValues?.isWritable != nil {
            let parent = self.deletingLastPathComponent()
            let parentValues = try? parent.resourceValues(forKeys: [.isWritableKey])

            if parentValues?.isWritable != nil {
                return true
            }
        }
        return false
    }

    // will fail for unreadable urls
    //
    public var isVolume: Bool {
        return (try? self.resourceValues(forKeys: [.isVolumeKey]))?
            .isVolume ?? false
    }

#if os(macOS)
    public var fileSystemInfo: (fileSystemType: String, isRemovable: Bool) {
        var isLocalMount: Bool = false
        var isRemovable: ObjCBool = false
        var isWritable: ObjCBool = false
        var isUnmountable: ObjCBool = false
        var isMobileBackups: Bool = false
        var isFuse: Bool = false
        var description: NSString? = nil
        var type: NSString? = nil
        var fileSystemType = "unknown"

        _ = NSWorkspace.shared.getFileSystemInfo(forPath: self.path,
                                                 isRemovable: &isRemovable,
                                                 isWritable: &isWritable,
                                                 isUnmountable: &isUnmountable,
                                                 description: &description,
                                                 type: &type)
        if let fsType = type {
            fileSystemType = (fsType as String).lowercased()
            
            if fileSystemType == "fusefs" {
                isFuse = true
            } else if fileSystemType == "smbfs" {
                URL.logger.error("path: '\(self.path)' fileSystemType: '\(fileSystemType)' will be slow in performance")
            } else if fileSystemType == "msdos" {
                // URL.logger.error("path: '\(self.path)' fileSystemType: '\(fileSystemType)'")
            } else if fileSystemType == "exfat" {
                // URL.logger.error("path: '\(self.path)' fileSystemType: '\(fileSystemType)'")
            } else if fileSystemType == "mtmfs" {
                // this is actually an nfs mount of the .MobileBackups
                //
                isMobileBackups = true
            }
        }

        var fileStat : statfs = statfs()
        
        if statfs((self.path as NSString).fileSystemRepresentation, &fileStat) != 0 {
            let errorString = String(utf8String: strerror(errno)) ?? "Unknown error code"
            URL.logger.error("error: '\(errorString)' filePath: '\(self.path)'")
        } else {
            if (fileStat.f_flags & UInt32(MNT_LOCAL)) == UInt32(MNT_LOCAL) {
                isLocalMount = true
            }
        }
        
        URL.logger.info("path: '\(self.path)' isLocalMount: '\(isLocalMount)' isRemovable: '\(isRemovable)' isUnmountable: '\(isUnmountable)' isMobileBackups: '\(isMobileBackups)' isFuse: '\(isFuse)' description: '\(description ?? "unknown")' type: '\(type ?? "unknown")'")
        return (fileSystemType: fileSystemType, isRemovable: isRemovable.boolValue)
    }
#endif

    public var volumeUUID: String {
        let mountedVolumes = Set(FileManager.default.mountedVolumes(true))
        return self._volumeUUID(mountedVolumes)
    }

    public var volumeURL: URL {
        var realURL = self
        let mountedVolumes = Set(FileManager.default.mountedVolumes(true))
        let volumeUUID = realURL._volumeUUID(mountedVolumes)
        var crawlup = true

        repeat {
            if realURL.isVolume && volumeUUID == realURL._volumeUUID(mountedVolumes) {
                return realURL
            } else if !mountedVolumes.contains(realURL.path) {
                realURL = realURL.deletingLastPathComponent()
            } else {
                crawlup = false
            }
        } while crawlup
        
        // we should not get here ...
        //
        URL.logger.error("failed to fetch volume url for path: '\(self.path)'")
        return URL.init(fileURLWithPath: "/Volumes").appendingPathComponent("\(UUID.init().uuidString).iddAppKit")
    }

    public var volumeCapacity: Int {
        return (try? self.resourceValues(forKeys: [.volumeTotalCapacityKey]))?
            .volumeTotalCapacity ?? -1
    }

    public var volumeSupportsHardLinks: Bool {
        return (try? self.resourceValues(forKeys: [.volumeSupportsHardLinksKey]))?
            .volumeSupportsHardLinks ?? false
    }

    public var isRootVolume: Bool {
        if isVolume && self.path == "/" {
            return true
        }
        return false
    }

    // if the path is of the form
    // ${NSHomeDirectoryForUser(${USER_NAME})}/.Trash/...
    // ${VOLUME_ROOT/.Trashes/...
    //
    public var isInTrashCan: Bool {
        let pathComponents = self.pathComponents
        let path = self.path
        
        if pathComponents.firstIndex(of: ".Trashes") != nil {
            URL.logger.info("volumeTrash: '\(path)'")
            return true
        }

        if let index = pathComponents.firstIndex(of: ".Trash") {
            let userName = pathComponents[index - 1]
            let userHome = NSHomeDirectoryForUser(userName) ?? "/User/UnknownUserHome"
            
            if path.hasPrefix(userHome) {
                URL.logger.info("userTrash: '\(path)'")
                return true
            }
        }
        return false
    }

    // the receiver shall be the user trash url or some top of the level trash url
    // ie: '/Users/kdeda/.Trash'
    //
    public func uniqueTrashURL(at sourceURL: URL) -> URL {
        let fileName = sourceURL.lastPathComponent
        var rv = self.appendingPathComponent(fileName)

        if rv.fileExist {
            var stillWorking = true
            let pathExtension = (fileName as NSString).pathExtension
            let currentFileName = (fileName as NSString).deletingPathExtension
            var now = Date()
            
            repeat {
                // there is already a fileName here
                // add a time stap prefix 'HH.MM.SS AM/PM' to the original fileName and try again
                //
                now = now.addingTimeInterval(-1.0)
                var newFileName = currentFileName.appending(" ").appending(URL.trashDateFormatter.string(from: now))
                
                if pathExtension.count > 0 {
                    newFileName = (newFileName as NSString).appendingPathExtension(pathExtension)!
                }
                rv = self.appendingPathComponent(newFileName)
                stillWorking = rv.fileExist
            } while stillWorking
        }
        return rv
    }
    
    public var creationDate: Date {
        return (try? self.resourceValues(forKeys: [.creationDateKey]))?
            .creationDate ?? Date.distantPast
    }
    
    public var contentModificationDate: Date {
        return (try? self.resourceValues(forKeys: [.contentModificationDateKey]))?
            .contentModificationDate ?? Date.distantPast
    }
    
    // http://swiftrien.blogspot.com/2015/11/socket-programming-in-swift-part-3-bind.html
    //
    // proven accurate
    // maybe slower ...
    // create an ExFat file system and a file with a few bytes on it
    // /Volumes/TestExFat/crap
    // this will work
    //
    private var _fetchInodeUsingStat: UInt64 {
        var fileStat : stat = stat()

        if stat((self.path as NSString).fileSystemRepresentation, &fileStat) != 0 {
            let errorString = String(utf8String: strerror(errno)) ?? "Unknown error code"
            
            URL.logger.error("error: '\(errorString)' filePath: '\(self.path)'")
        } else {
            return fileStat.st_ino
        }
        // we should not get here ...
        //
        return 0
    }
    
    // wrong
    // create an ExFat file system and a file with a few bytes on it
    // /Volumes/TestExFat/crap
    // this will fail
    //
    private var _fetchInodeUsingIdentifier: UInt {
        let resourceValues = try? self.resourceValues(forKeys: [.fileResourceIdentifierKey])
        
        if let data = resourceValues?.fileResourceIdentifier as? NSData {
            var rv = 0

            data.getBytes(&rv, length: MemoryLayout<Int>.size)
            return UInt(rv)
        }
        // we should not get here ...
        //
        return 0
    }

    public var inode: UInt64 {
        return _fetchInodeUsingStat
    }

    public var pnode: UInt64 {
        let parent = self.deletingLastPathComponent()
        
        if parent.volumeUUID == self.volumeUUID {
            return parent.inode
        }
        // we should not get here ...
        //
        return 0
    }

    public var systemFileNumber: Int {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: self.path)
            
            if let rv = attributes[.systemFileNumber] as? Int {
                return rv
            }
        } catch {
            URL.logger.error("error: '\(error.localizedDescription)'")
        }

        return -1
    }

    public var typeIdentifier: String {
        return (try? self.resourceValues(forKeys: [.typeIdentifierKey]))?
            .typeIdentifier ?? ""
    }

    /*
     * returns the most recent instance by using the url's contentModificationDate
     */
    public func mostRecent(than otherURL: URL) -> URL {
        let systemDate = self.contentModificationDate
        let otherDate = otherURL.contentModificationDate
        let difference = systemDate.timeIntervalSince(otherDate)
        
        // positive if systemDate is more recent than otherDate
        //
        if (difference > 0) {
            return self
        }
        return otherURL
    }

    // these will fail for resource fork files ..
    //
    public var logicalSize: Int64 {
        return Int64((try? self.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
    }
    
    // these will fail for resource fork files ..
    //
    public var physicalSize: Int64 {
        return Int64((try? self.resourceValues(forKeys: [.fileAllocatedSizeKey]))?.fileAllocatedSize ?? 0)
    }

    @discardableResult
    public func chown(to ownerAccountName: String, recursive recurseToChildren: Bool) -> Bool {
        var rv = false
        
        URL.logger.info("path: '\(self.path)'")
        do {
            let newAttributes: [FileAttributeKey: Any] = {
                var rv = [FileAttributeKey: Any]()
                
                rv[FileAttributeKey.ownerAccountName] = ownerAccountName
                rv[FileAttributeKey.posixPermissions] = self.isDirectory ? 0o777 : 0o666
                return rv
            }()
            
            try FileManager.default.setAttributes(newAttributes, ofItemAtPath: self.path)
            if recurseToChildren && self.isDirectory {
                let children = try FileManager.default.contentsOfDirectory(
                    at: self,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsSubdirectoryDescendants, .skipsPackageDescendants]
                )
                children.forEach { $0.chown(to: ownerAccountName, recursive: recurseToChildren) }
            }
            rv = true
        } catch let error as NSError {
            URL.logger.error("error: '\(error)'")
            URL.logger.error("rootPath: '\(self.path)'")
        }
        return rv
    }
    
    @discardableResult
    public func update(attributes newAttributes: [FileAttributeKey : Any], recursive recurseToChildren: Bool) -> Bool {
        var rv = false
        
        do {
            var newAttributes_ = newAttributes
            
            newAttributes_[FileAttributeKey.posixPermissions] = self.isDirectory ? 0o777 : 0o666
            URL.logger.info("modifiedAttributes: '\(newAttributes_)'")
            URL.logger.info("path: '\(self.path)'")
            //            if URL.logger.isDebug {
            //                URL.logger.info("path: '\(self.path)'")
            //            }
            try FileManager.default.setAttributes(newAttributes_, ofItemAtPath: self.path)
            if recurseToChildren && self.isDirectory {
                let children = try FileManager.default.contentsOfDirectory(
                    at: self,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsSubdirectoryDescendants, .skipsPackageDescendants]
                )
                children.forEach { $0.update(attributes: newAttributes, recursive: recurseToChildren) }
            }
            rv = true
        } catch let error as NSError {
            URL.logger.error("error: '\(error)'")
            URL.logger.error("rootPath: '\(self.path)'")
        }
        return rv
    }

    /*
     * "/Users/kdeda/LargeWhatSizeTest copy 2.zip" -> "/Users/kdeda/LargeWhatSizeTest copy 2${stringValue}.zip"
     */
    public func appendingToFileName(_ stringValue: String) -> URL {
        let pathExtension = self.pathExtension
        let fileName = self.deletingPathExtension().lastPathComponent.appending(stringValue)
        var rv = self.deletingLastPathComponent().appendingPathComponent(fileName)
        
        if pathExtension.count > 0 {
            rv = rv.appendingPathExtension(pathExtension)
        }
        return rv
    }
    
    // true if a path component is hidden
    // ie: /Users/kdeda/.m2/repository/com/vaadin/vaadin-server
    //
    public var hasHiddenComponents: Bool {
        let pathComponents = self.pathComponents
        
        for i in 0..<pathComponents.count {
            // if any file name starts with . we have a hidden file
            //
            if pathComponents[i].hasPrefix(".") {
                return true
            }
        }
        return false
    }
    
    /*
     /usr/bin/tmutil uniquesize will simply tally files that have hardlink equal to 1
     it does some type of magic because it reports sizes that seem too small
     ie:
     tmutil listbackups | while read filename ; do sudo tmutil uniquesize "$filename" ; done

     what we do is look inside each baclup log and pluck the size that was written
     of course this code assumes you did not mock with the backup afterwards ...
     it better reflects the size really taken in disk and is super fast
     */
    public var timeMachineSliceSize: Int64 {
        var rv: Int64 = 0

        do {
            if !self.fileExist {
                // we will get here if we run in user space
                //
                URL.logger.error("path: '\(self.path)' is missing ...")
            } else if !self.isReadable {
                // we will get here if we run in user space
                //
                let details = (getuid() != 0) ? "this happens when we are running in user space" : "and you are running as root, hum ..."
                URL.logger.error("path: '\(self.path)' is not readable: '\(details)'")
            } else {
                var encoding: String.Encoding = .utf8
                let fileContent = try String.init(contentsOf: self, usedEncoding: &encoding)
                let rows = fileContent
                    .components(separatedBy: "\n")
                    .map { $0.trimmingCharacters(in: CharacterSet.whitespaces) }
                
                let sizes = rows.compactMap { (row) -> Int64? in
                    guard let endOfLine = row.substring(after: "Space needed for this backup:"),
                          let sizeString = endOfLine.substring(before: " (")
                    else { return .none }
                    // Space needed for this backup: 293.11 GB (71559933 blocks of size 4096)

                    return _sizeFrom(backupLog: sizeString)
                }
                rv = sizes.reduce(0, +)
                URL.logger.info("path: '\(self.path)' withSize: '\(rv)'")
            }
        } catch {
            URL.logger.error("error: '\(error.localizedDescription)'")
        }
        return rv
    }

    public var isHomeLibraryCaches: Bool {
        return self.path == URL.homeLibraryCaches.path
    }
    
    public var isSystemLibraryCaches: Bool {
        return self.path == URL.systemLibraryCaches.path
    }

    public func appendingQuery(withKey key: String, andValue value: String?) -> URL {
        guard var urlComponents = URLComponents(string: absoluteString),
              let queryValue = value, queryValue.count > 0
        else {return absoluteURL}

        var queryItems: [URLQueryItem] = urlComponents.queryItems ??  []
        let queryItem = URLQueryItem(name: key, value: queryValue)
        
        queryItems.append(queryItem)
        urlComponents.queryItems = queryItems
        return urlComponents.url!
    }
    
    public var mimeType: String? {
        let pathExtension = self.pathExtension
        
#if os(macOS)
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as CFString, nil)?.takeRetainedValue() {
            if let rv = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return rv as String
            }
        }
#endif

        return nil
    }

    // given a remote url, got fetch the data as string and return it await mode
    //
    public var fetchAsString: String {
        var rv = ""
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let request = URLRequest(url: self)
        let semaphore = DispatchSemaphore(value: 0)
        let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
            if let tempLocalUrl = tempLocalUrl, error == nil {
                // Success
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    URL.logger.info("Successfully downloaded. Status code: \(statusCode)")
                }
                
                rv = (try? String(contentsOf: tempLocalUrl)) ?? ""
            }
            else if let error = error {
                URL.logger.error("Error took place while downloading a file. Error description: '\(error.localizedDescription)'")
            }
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .distantFuture)
        return rv
    }

    public func ejectVolume() -> Bool {
#if os(macOS)
        do {
            try NSWorkspace.shared.unmountAndEjectDevice(at: self)
            return true
        } catch let error as NSError {
            URL.logger.error("error: '\(error)'")
            URL.logger.error("rootPath: '\(self.path)'")
        }
#endif
        return false
    }

    public var isRegularFile: Bool {
        return (try? self.resourceValues(forKeys: [.isRegularFileKey]))?
            .isRegularFile ?? false
    }

    public var isSymbolicLink: Bool {
        return (try? self.resourceValues(forKeys: [.isSymbolicLinkKey]))?
            .isSymbolicLink ?? false
    }

    public var linkCount: Int32 {
        Int32((try? self.resourceValues(forKeys: [.linkCountKey]))?.linkCount ?? 0)
    }

    /**
     Given a url with a lower case path, return a url with the proper canonical information.

     For Example:
     Given a lower case path '/volumes/case sensitive/screen shots'
     In a volume with case sensitive paths.
     Given that '/Volumes/Case Sensitive/screen shots' exists
     We should get '/Volumes/Case Sensitive/screen shots'

     OR:
     Given that '/Volumes/Case Sensitive/Screen Shots' exists
     We should get '/Volumes/Case Sensitive/Screen Shots'

     In a volume with case in sensitive paths.
     Given that '/Volumes/Case Sensitive/screen shots' exists
     We should get '/Volumes/Case Sensitive/screen shots'

     OR:
     Given that '/Volumes/Case Sensitive/Screen Shots' exists
     We should get '/Volumes/Case Sensitive/Screen Shots'
     */
    public var canonicalURL: URL {
        let resourceValues = try? self.resourceValues(forKeys: [.canonicalPathKey])

        if let canonicalPath = resourceValues?.canonicalPath as? String {
            return URL(fileURLWithPath: canonicalPath)
        }
        return self
    }
}

// MARK: - Array[URL] -
extension Array where Element == URL {
    
    // will clean up backwards
    // A/A1/A2 will be removed if A/A1/A2 is empty and we can remove it
    // A/A1 will be removed if A/A1 is empty and we can remove it
    // A1 will be removed if A is empty and we can remove it
    //
    public func removeEmptyFolders(crawlUpToLevel upLevel: Int ) {
        var levels = upLevel
        var parents = [URL]()
        
        levels -= 1
        for folderURL in self {
            if folderURL.fileExist && folderURL.isDirectory {
                do {
                    let children = try FileManager.default.contentsOfDirectory(
                        at: folderURL,
                        includingPropertiesForKeys: nil,
                        options: [.skipsHiddenFiles]
                    )
                    if children.isEmpty {
                        if FileManager.default.removeItemIfExist(at: folderURL) {
                            URL.logger.info("'\(folderURL.path)'")
                            parents.append(folderURL.deletingLastPathComponent())
                        }
                    }
                } catch {
                    URL.logger.error("error: '\(error.localizedDescription)'")
                }
            }
        }
        if parents.count > 0 && levels > 0 {
            parents.removeEmptyFolders(crawlUpToLevel: levels)
        }
    }
    
    public var uniquePathURLs: [URL] {
        self
            .reduce(into: Set<String>()) { partialResult, fileURL in
                // debug
                // on slow machines we get into trouble here so we notify the UI about changes ...
                // Thread.sleep(forTimeInterval: 0.001)
                //
                if let filePath = fileURL.path.removingPercentEncoding {
                    partialResult.insert(filePath)
                } else {
                    URL.logger.error("bad URL: '\(fileURL)'")
                }
            }
            .map(URL.init(fileURLWithPath:))
    }
}
