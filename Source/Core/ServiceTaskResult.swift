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
