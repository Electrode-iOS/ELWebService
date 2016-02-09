//
//  ServicePassthroughDelegate.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 2/8/16.
//  Copyright © 2016 WalmartLabs. All rights reserved.
//

import Foundation

/// Defines a delegate interface for hooking into service request/response events.
public protocol ServicePassthroughDelegate: class {
    /// Called before a request is to be sent
    func requestSent(request: NSURLRequest)
    
    /// Called after a NSURLSessionDataTask has completed
    func responseReceived(response: NSURLResponse?, data: NSData?, error: NSError?)
    
    /// Called before an updateUI handler is invoked
    func updateUIBegin(response: NSURLResponse?)
    
    /// Called after an updateUI handler has been invoked
    func updateUIEnd(response: NSURLResponse?)
    
    /// Called when a ServiceTask handler returns a .Failure(error) result
    func serviceResultFailure(error: ErrorType)
}
