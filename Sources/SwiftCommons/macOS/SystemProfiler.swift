//
//  SystemProfiler.swift
//  SwiftCommons
//
//  Created by Klajd Deda on 3/17/21.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

#if os(macOS)

import Foundation
import Log4swift

public struct SystemProfiler {
    public static let shared = SystemProfiler()
    public static let profilerPath = "/usr/sbin/system_profiler"
    public static let logger: Logger = {
        return Log4swift.getLogger("SystemProfiler")
    }()

    public var storageData: [SystemProfiler.StorageData] {
        let xml = Process.fetchString(task: SystemProfiler.profilerPath, arguments: ["-xml", "SPStorageDataType"], timeOut: 5.0)

        do {
            let decoder = PropertyListDecoder()
            let data = xml.data(using: .utf8) ?? Data()
            let rv = try decoder.decode([StorageData].self, from: data)
            
            // test
//            let volumeIDs = rv.flatMap(\.items).map(\.volumeUUID)
//
//            volumeIDs.forEach { (volumeID) in
//                if let item = rv.volumeInfo(volumeID) {
//                    SystemProfiler.logger.error("item: '\(item)'")
//                }
//            }
            return rv
        } catch let error {
            SystemProfiler.logger.error("xml: '\(xml)'")
            SystemProfiler.logger.error("error: '\(error)'")
        }
        return [StorageData]()
    }
}

extension SystemProfiler.Item {
    var isSSD: Bool {
        physicalDrive.mediumType == "ssd"
    }
}

extension Array where Element == SystemProfiler.StorageData {
    func volumeInfo(_ volumeID: String) -> SystemProfiler.Item? {
        let items = self.flatMap(\.items)
        return items.first { (storageData) -> Bool in
            storageData.volumeUUID == volumeID
        }
    }
}

extension SystemProfiler {
    // convert xml to json
    // https://wtools.io/convert-plist-to-json
    // than convert json to schema
    // https://app.quicktype.io
    
    // MARK: - SystemProfilerElement
    public struct StorageData: Codable {
        var spCommandLineArguments: [String]
        var spCompletionInterval, spResponseTime: Double
        var dataType: String
        var items: [Item]
        var parentDataType: String
        var properties: Properties
        var timeStamp: Date
        var versionInfo: VersionInfo
        
        enum CodingKeys: String, CodingKey {
            case spCommandLineArguments = "_SPCommandLineArguments"
            case spCompletionInterval = "_SPCompletionInterval"
            case spResponseTime = "_SPResponseTime"
            case dataType = "_dataType"
            case items = "_items"
            case parentDataType = "_parentDataType"
            case properties = "_properties"
            case timeStamp = "_timeStamp"
            case versionInfo = "_versionInfo"
        }
    }
    
    // MARK: - Item
    struct Item: Codable {
        var name, bsdName, fileSystem: String
        var freeSpaceInBytes: Int
        var ignoreOwnership, mountPoint: String
        var physicalDrive: PhysicalDrive
        var sizeInBytes: Int
        var volumeUUID, writable: String
        
        enum CodingKeys: String, CodingKey {
            case name = "_name"
            case bsdName = "bsd_name"
            case fileSystem = "file_system"
            case freeSpaceInBytes = "free_space_in_bytes"
            case ignoreOwnership = "ignore_ownership"
            case mountPoint = "mount_point"
            case physicalDrive = "physical_drive"
            case sizeInBytes = "size_in_bytes"
            case volumeUUID = "volume_uuid"
            case writable
        }
    }
    
    // MARK: - PhysicalDrive
    struct PhysicalDrive: Codable {
        var deviceName, isInternalDisk, mediaName, mediumType: String
        var partitionMapType, physicalDriveProtocol: String
        var smartStatus: String?
        
        enum CodingKeys: String, CodingKey {
            case deviceName = "device_name"
            case isInternalDisk = "is_internal_disk"
            case mediaName = "media_name"
            case mediumType = "medium_type"
            case partitionMapType = "partition_map_type"
            case physicalDriveProtocol = "protocol"
            case smartStatus = "smart_status"
        }
    }
    
    // MARK: - Properties
    struct Properties: Codable {
        var name: Name
        var bsdName: BSDName
        var comAppleCorestorageLV: COMAppleCorestorageLV
        var comAppleCorestorageLVBytesConverted: COMAppleCorestorage
        var comAppleCorestorageLVConversionState, comAppleCorestorageLVEncrypted, comAppleCorestorageLVEncryptionType, comAppleCorestorageLVLocked: COMAppleCorestorageLV
        var comAppleCorestorageLVRevertible, comAppleCorestorageLVUUID, comAppleCorestorageLvg: COMAppleCorestorageLV
        var comAppleCorestorageLvgFreeSpace: COMAppleCorestorage
        var comAppleCorestorageLvgName: COMAppleCorestorageLV
        var comAppleCorestorageLvgSize: COMAppleCorestorage
        var comAppleCorestorageLvgUUID, comAppleCorestoragePV: COMAppleCorestorageLV
        var comAppleCorestoragePVSize: COMAppleCorestorage
        var comAppleCorestoragePVStatus, comAppleCorestoragePVUUID, deviceName: COMAppleCorestorageLV
        var fileSystem: BSDName
        var freeSpaceInBytes: FreeSpaceInBytes
        var ignoreOwnership, isInternalDisk, mediaName, mediumType: COMAppleCorestorageLV
        var mountPoint: BSDName
        var opticalMediaType, partitionMapType, propertiesProtocol: COMAppleCorestorageLV
        var sizeInBytes: SizeInBytes
        var smartStatus, volumeUUID: COMAppleCorestorageLV
        var volumes: Volumes
        var writable: COMAppleCorestorageLV
        
        enum CodingKeys: String, CodingKey {
            case name = "_name"
            case bsdName = "bsd_name"
            case comAppleCorestorageLV = "com.apple.corestorage.lv"
            case comAppleCorestorageLVBytesConverted = "com.apple.corestorage.lv.bytesConverted"
            case comAppleCorestorageLVConversionState = "com.apple.corestorage.lv.conversionState"
            case comAppleCorestorageLVEncrypted = "com.apple.corestorage.lv.encrypted"
            case comAppleCorestorageLVEncryptionType = "com.apple.corestorage.lv.encryptionType"
            case comAppleCorestorageLVLocked = "com.apple.corestorage.lv.locked"
            case comAppleCorestorageLVRevertible = "com.apple.corestorage.lv.revertible"
            case comAppleCorestorageLVUUID = "com.apple.corestorage.lv.uuid"
            case comAppleCorestorageLvg = "com.apple.corestorage.lvg"
            case comAppleCorestorageLvgFreeSpace = "com.apple.corestorage.lvg.freeSpace"
            case comAppleCorestorageLvgName = "com.apple.corestorage.lvg.name"
            case comAppleCorestorageLvgSize = "com.apple.corestorage.lvg.size"
            case comAppleCorestorageLvgUUID = "com.apple.corestorage.lvg.uuid"
            case comAppleCorestoragePV = "com.apple.corestorage.pv"
            case comAppleCorestoragePVSize = "com.apple.corestorage.pv.size"
            case comAppleCorestoragePVStatus = "com.apple.corestorage.pv.status"
            case comAppleCorestoragePVUUID = "com.apple.corestorage.pv.uuid"
            case deviceName = "device_name"
            case fileSystem = "file_system"
            case freeSpaceInBytes = "free_space_in_bytes"
            case ignoreOwnership = "ignore_ownership"
            case isInternalDisk = "is_internal_disk"
            case mediaName = "media_name"
            case mediumType = "medium_type"
            case mountPoint = "mount_point"
            case opticalMediaType = "optical_media_type"
            case partitionMapType = "partition_map_type"
            case propertiesProtocol = "protocol"
            case sizeInBytes = "size_in_bytes"
            case smartStatus = "smart_status"
            case volumeUUID = "volume_uuid"
            case volumes, writable
        }
    }
    
    // MARK: - BSDName
    struct BSDName: Codable {
        var isColumn: Bool
        var order: String
        
        enum CodingKeys: String, CodingKey {
            case isColumn = "_isColumn"
            case order = "_order"
        }
    }
    
    // MARK: - COMAppleCorestorageLV
    struct COMAppleCorestorageLV: Codable {
        var order: String
        
        enum CodingKeys: String, CodingKey {
            case order = "_order"
        }
    }
    
    // MARK: - COMAppleCorestorage
    struct COMAppleCorestorage: Codable {
        var isByteSize: Bool
        var order: String
        
        enum CodingKeys: String, CodingKey {
            case isByteSize = "_isByteSize"
            case order = "_order"
        }
    }
    
    // MARK: - FreeSpaceInBytes
    struct FreeSpaceInBytes: Codable {
        var isByteSize, isColumn: Bool
        var order: String
        
        enum CodingKeys: String, CodingKey {
            case isByteSize = "_isByteSize"
            case isColumn = "_isColumn"
            case order = "_order"
        }
    }
    
    // MARK: - Name
    struct Name: Codable {
        var isColumn, order: String
        var suppressLocalization: Bool
        
        enum CodingKeys: String, CodingKey {
            case isColumn = "_isColumn"
            case order = "_order"
            case suppressLocalization = "_suppressLocalization"
        }
    }
    
    // MARK: - SizeInBytes
    struct SizeInBytes: Codable {
        var isByteSize: String
        var isColumn: Bool
        var order: String
        
        enum CodingKeys: String, CodingKey {
            case isByteSize = "_isByteSize"
            case isColumn = "_isColumn"
            case order = "_order"
        }
    }
    
    // MARK: - Volumes
    struct Volumes: Codable {
        var detailLevel: String
        
        enum CodingKeys: String, CodingKey {
            case detailLevel = "_detailLevel"
        }
    }
    
    // MARK: - VersionInfo
    struct VersionInfo: Codable {
        var comAppleSystemProfilerSPStorageReporter: String
        
        enum CodingKeys: String, CodingKey {
            case comAppleSystemProfilerSPStorageReporter = "com.apple.SystemProfiler.SPStorageReporter"
        }
    }
}

#endif
