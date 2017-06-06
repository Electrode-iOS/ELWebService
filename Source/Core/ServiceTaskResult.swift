//
//  ServiceTaskResult.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 11/5/15.
//  Copyright © 2015 WalmartLabs. All rights reserved.
//

import Foundation

/// Represents the result of a service task.
public enum ServiceTaskResult {
    /// Defines an empty task result
    case empty
    /// Defines a task result as a value
    case value(Any)
    /// Defines a task resulting in an error
    case failure(Error)
    
    func taskValue() throws -> Any? {
        switch self {
        case .failure(let error): throw error
        case .empty: return nil
        case .value(let value): return value
        }
    }
}

// MARK: - Objective-C Interop

extension ServiceTaskResult {
    /// Initialize a service task result value from an Obj-C result
    init(objCHandlerResult result: ObjCHandlerResult?) {
        if let error = result?.error {
            self = .failure(error)
        } else if let value = result?.value {
            self = .value(value)
        } else {
            self = .empty
        }
    }
}

/// Represents the result of a Obj-C response handler
@objc public final class ObjCHandlerResult: NSObject {
    /// The resulting value
    fileprivate(set) var value: AnyObject?
    
    /// The resulting error
    fileprivate(set) var error: NSError?
    
    @objc dynamic public class func resultWithValue(_ value: AnyObject) -> ObjCHandlerResult {
        return ObjCHandlerResult(value: value)
    }
    
    @objc dynamic public class func resultWithError(_ error: NSError) -> ObjCHandlerResult {
        return ObjCHandlerResult(error: error)
    }
    
    /// Initialize a result with a value
    fileprivate init(value: AnyObject) {
        self.value = value
    }
    
    /// Initialize a result with an error
    fileprivate init(error: NSError) {
        self.error = error
    }
}
