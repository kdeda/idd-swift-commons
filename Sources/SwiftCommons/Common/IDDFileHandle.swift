//
//  IDDFileHandle.swift
//  SwiftCommons
//
//  Created by Klajd Deda on 10/16/17.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift

class IDDFileHandle: FileHandle {
    private let _workerLock = DispatchSemaphore(value: 1)

    override func write(_ data: Data) {
        _workerLock.wait()
        super.write(data)
        _workerLock.signal()
    }
}

