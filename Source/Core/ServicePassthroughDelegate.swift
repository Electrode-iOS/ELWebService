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
    func requestSent(_ request: URLRequest)
    
    /// Called after a NSURLSessionDataTask has completed
    func responseReceived(_ response: URLResponse?, data: Data?, request: URLRequest?, error: Error?)
    
    /// Called before an updateUI handler is invoked
    func updateUIBegin(_ response: URLResponse?)
    
    /// Called after an updateUI handler has been invoked
    func updateUIEnd(_ response: URLResponse?)
    
    /// Called when a ServiceTask handler returns a .Failure(error) result
    func serviceResultFailure(_ response: URLResponse?, data: Data?, request: URLRequest?, error: Error)
    
    func modifiedRequest(_ request: URLRequest) -> URLRequest?
}

extension ServicePassthroughDelegate {
    func modifiedRequest(_ request: URLRequest) -> URLRequest? {
        return nil
    }
}

public protocol ServicePassthroughDataSource {
    var servicePassthroughDelegate: ServicePassthroughDelegate {get}
}
