//
//  IDDClick.swift
//  SwiftCommons
//
//  Created by Klajd Deda on 6/11/18.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

public typealias IDDClick = (_ sender: Any) -> Swift.Void
public typealias IDDDoubleClick = (_ sender: Any) -> Swift.Void
public typealias IDDAction<Type, Input> = (Type) -> (Input) -> Void

public protocol IDDTargetAction {
    var targetAction: IDDTarget { get }
    func sendAction(_ sender: Any)
}

public struct IDDTarget {
    public weak var target: AnyObject?
    public var click: IDDClick?
    public var doubleClick: IDDDoubleClick?
    private var observations = [(Any) -> Void]()

    public init() {
    }
    
    public mutating func addTarget<T: AnyObject>(_ target: T, action: @escaping IDDAction<T, Any>) {
        // We take care of the weak/strong dance for the target, making the API
        // much easier to use and removes the danger of causing retain cycles
        //
        observations.append { [weak target] sender in
            guard let target = target
                else { return }

            // Generate an instance method using the action closure and call it
            //
            action(target)(sender)
        }
    }

    public func sendAction(_ sender: Any) -> Bool {
        if observations.count > 0 {
            observations.forEach { (iddAction) in
                iddAction(sender)
            }
            return true
        }

        // If the observer is no longer in memory, we do nothing
        //
        return false
    }
}
