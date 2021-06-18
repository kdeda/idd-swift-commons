//
//  JSONUploadFileItem.swift
//  IDDSwiftCommons
//
//  Created by Klajd Deda on 8/21/17.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift
#if os(iOS)
    import MobileCoreServices
#endif

@objcMembers
public class JSONUploadFileItem: NSObject {
    lazy var logger: Logger = {
        return Log4swift.getLogger(self)
    }()

    public var fileLocation: URL?
    private var _fileData: Data?
    public var fileName: String
    private var _mimeType: String!

    public init(_ fileData: Data, fileName fileName_: String) {
        _fileData = fileData
        fileName = fileName_
    }

    public init(_ fileLocation: URL) {
        self.fileLocation = fileLocation
        fileName = fileLocation.lastPathComponent as String
    }

    convenience init(with fileLocation: URL, fileName fileName_: String) {
        self.init(fileLocation)
        fileName = fileName_
    }

    public var mimeType: String {
        if _mimeType == nil {
            _mimeType = fetchMimeType()
        }
        return _mimeType!
    }
    
    public func fileData() throws -> Data {
        if _fileData == nil {
            if fileLocation != nil {
                _fileData = try Data.init(contentsOf: fileLocation! as URL)
            }
        }
        return _fileData!
    }
    
    private func fetchMimeType() -> String {
        if let fileURL = fileLocation {
            return fileURL.mimeType ?? "application/octet-stream"
        }
        return "application/octet-stream"
    }

}
