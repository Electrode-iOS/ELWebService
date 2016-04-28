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
    case Empty
    /// Defines a task result as a value
    case Value(Any)
    /// Defines a task resulting in an error
    case Failure(ErrorType)
}

// MARK: - Objective-C Interop

extension ServiceTaskResult {
    /// Initialize a service task result value from an Obj-C result
    init(objCHandlerResult result: ObjCHandlerResult?) {
        if let error = result?.error {
            self = .Failure(error)
        } else if let value = result?.value {
            self = .Value(value)
        } else {
            self = .Empty
        }
    }
}

/// Represents the result of a Obj-C response handler
@objc public final class ObjCHandlerResult: NSObject {
    /// The resulting value
    private(set) var value: AnyObject?
    
    /// The resulting error
    private(set) var error: NSError?
    
    public class func resultWithValue(value: AnyObject) -> ObjCHandlerResult {
        return ObjCHandlerResult(value: value)
    }
    
    public class func resultWithError(error: NSError) -> ObjCHandlerResult {
        return ObjCHandlerResult(error: error)
    }
    
    /// Initialize a result with a value
    private init(value: AnyObject) {
        self.value = value
    }
    
    /// Initialize a result with an error
    private init(error: NSError) {
        self.error = error
    }
    
    internal func valueOrError() throws -> Any? {
        if let error = error {
            throw error
        } else {
            return value
        }
    }
}
