//
//  IOService.swift
//  IDDSwiftCommons
//
//  Created by Klajd Deda on 5/9/20.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift

public struct IOService {
    static var logger: Logger = {
        return Log4swift.getLogger("IOService")
    }()

    public static func test() {
        // debug
        IOService.logger.info("serialNumber: '\(IOService.serialNumber)'")
        let deviceName = "disk1s1"
        IOService.logger.info("serialNumber: '\(IOService.isEncrypted(deviceName: deviceName))'")
    }
    
    public static var serialNumber: String {
        let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        guard platformExpert > 0
            else { return "" }
        
        guard let pointer = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0),
            let stringValue = pointer.takeUnretainedValue() as? String
            else { return "" }
        
        IOObjectRelease(platformExpert)
        return stringValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
  
    // let APFS_DEVICE_NAME = "disk1s1"
    public static func isEncrypted(deviceName: String) -> Bool {
        let PROPERTY_NAME = "Encrypted"
        
        if let diskRef = IOBSDNameMatching(kIOMasterPortDefault, 0,  deviceName) {
            let diskService = IOServiceGetMatchingService(kIOMasterPortDefault, diskRef)
            
            guard let pointer = IORegistryEntryCreateCFProperty(diskService, PROPERTY_NAME as CFString, kCFAllocatorDefault, 0),
                let boolValue = pointer.takeUnretainedValue() as? Bool
                else { return false }
            return boolValue
        }
        
        return false
    }

    // https://developer.apple.com/library/archive/documentation/DriversKernelHardware/Conceptual/DiskArbitrationProgGuide/ManipulatingDisks/ManipulatingDisks.html
    //
    public static func diskInfo(url: URL) -> [String: AnyObject] {
        guard let session = DASessionCreate(nil),
            let disk = DADiskCreateFromVolumePath(nil, session, url as CFURL),
            var diskInfo = DADiskCopyDescription(disk) as? [String: CFTypeRef]
            else { return [String: AnyObject]() }

        if diskInfo["DADiskRoles"] == nil {
            diskInfo["DADiskRoles"] = diskRoles(url: url) as AnyObject
        }
        if diskInfo.isEmpty {
            let fileSystemInfo = url.fileSystemInfo

            if diskInfo["DAVolumeType"] == nil {
                diskInfo["DAVolumeType"] = fileSystemInfo.fileSystemType as AnyObject
            }
            if diskInfo["DAMediaEjectable"] == nil {
                diskInfo["DAMediaEjectable"] = fileSystemInfo.isRemovable as AnyObject
            }
        }

        //    // debug
        //    desc.forEach { (key: String, value: CFTypeRef) in
        //        IOService.logger.info("url: '\(url.path)' \(key): '\(value)'")
        //    }
        return diskInfo
    }

    // https://forums.developer.apple.com/thread/122011#379679
    // https://eclecticlight.co/2019/10/08/macos-catalina-boot-volume-layout/
    // ... the read-only system volume as having the role APFS_VOL_ROLE_SYSTEM ('System'),
    // and the writeable user volume has the role APFS_VOL_ROLE_DATA ('Data') ...
    // we also want to filter out APFS_VOL_ROLE_RECOVERY
    //
    public static func diskRoles(url: URL) -> [String] {
        let PROPERTY_NAME = "Role"
        
        guard let session = DASessionCreate(nil),
            let disk = DADiskCreateFromVolumePath(nil, session, url as CFURL)
            else { return [] }
        
        let diskService = DADiskCopyIOMedia(disk)
        guard let pointer = IORegistryEntryCreateCFProperty(diskService, PROPERTY_NAME as CFString, kCFAllocatorDefault, 0),
            let stringValues = pointer.takeUnretainedValue() as? [String]
            else { return [] }
        return stringValues
    }
}
