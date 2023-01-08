//
//  CoalescingQueue.swift
//  SwiftCommons
//
//  Created by Klajd Deda on 9/10/19.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation
import Log4swift

public class CoalescingQueue<Element> {
    lazy var logger: Logger = {
        return Log4swift.getLogger(self)
    }()
    
    public typealias CoalescingQueueAction = (_ updates: [Element]) -> Swift.Void
    public var coalesceInterval = 1000.0
    public var batchSize = 0 // define a value greater than zero to batch

    private var _callback: CoalescingQueueAction
    private var _pendingUpdates = [Element]()
    private var _scheduledDate = Date.distantPast
    private let _workerQueue: OperationQueue = {
        let rv = OperationQueue.init()
        
        rv.maxConcurrentOperationCount = 1
        return rv
    }()
    
    // MARK: - Private methods
    // MARK: -
    
    private func _popUpdates() -> [Element] {
        var rv = [Element]()

        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        
        if batchSize > 0 {
            // batches
            //
            while rv.count < batchSize && self._pendingUpdates.count > 0 {
                rv.append(_pendingUpdates.remove(at: 0))
            }
        } else {
            // pluck em all
            //
            rv.append(contentsOf: _pendingUpdates)
            _pendingUpdates.removeAll()
        }
        
        _scheduledDate = Date.init()
        return rv
    }
    
    private func _flushPendingUpdates() {
        // self.logger.info("time to fire: '\(_workerQueue.operationCount)' time: '\(_scheduledDate.elapsedTimeInMilliseconds)'")
        _workerQueue.cancelAllOperations()
        if self._pendingUpdates.count > 0 {
            let updates = _popUpdates()
            
            if self.logger.isDebug {
                self.logger.debug("updates: '\(updates.count)' out of '\(self._pendingUpdates.count)'")
            }
            
            if updates.count > 0 {
                _callback(updates)
            }
            if self._pendingUpdates.count > 0 {
                self._flushPendingUpdatesAfterDeadline()
            }
        }
    }
    
    private var _postpone: Bool {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        
        if _scheduledDate.elapsedTimeInMilliseconds < coalesceInterval {
            return true
        }
        return false
    }
    
    // to coalesce a bunch of post(updates:) together look at the _scheduledDate
    // if we waited too long, than process all existing updates
    // if else postpone until deadline gets hit, which is a maximum of .5 seconds
    //
    private func _flushPendingUpdatesAfterDeadline() {
        _workerQueue.addOperation {
            // wait for 50 milliseconds in case multiple calls come in fast succession
            //
            Thread.sleep(forTimeInterval: 0.05)
            
            if self._postpone {
                self._flushPendingUpdatesAfterDeadline()
            } else {
                self._flushPendingUpdates()
            }
        }
    }
    
    // MARK: - Instance methods -

    public init(_ callBack: @escaping CoalescingQueueAction) {
        self._callback = callBack
    }

    public var count: Int {
        return _pendingUpdates.count
    }
    
    public func enqueue(_ newElement: Element) {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        _pendingUpdates.append(newElement)
        _flushPendingUpdatesAfterDeadline()
    }
    
    public func enqueue(contentsOf newElements: [Element]) {
        if newElements.count > 0 {
            objc_sync_enter(self)
            defer {
                objc_sync_exit(self)
            }
            _pendingUpdates.append(contentsOf: newElements)
            _flushPendingUpdatesAfterDeadline()
        }
    }
}
