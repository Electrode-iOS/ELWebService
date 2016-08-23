//
//  Session.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 2/29/16.
//  Copyright © 2016 WalmartLabs. All rights reserved.
//

import Foundation

// MARK: - Session

public protocol Session {
    func dataTask(request: URLRequestConvertible, completion: @escaping (Data?, URLResponse?, NSError?) -> Void) -> DataTask
}

extension URLSession: Session {
    public func dataTask(request: URLRequestConvertible, completion: @escaping (Data?, URLResponse?, NSError?) -> Void) -> DataTask {
        return dataTask(request: request.urlRequest, completion: completion) as DataTask
    }
}

// MARK: - Data Task

public protocol DataTask {
    var state: URLSessionTask.State { get }
    
    func suspend()
    func resume()
    func cancel()
}

extension URLSessionDataTask: DataTask {}
