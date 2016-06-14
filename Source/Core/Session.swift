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
    func dataTask(request: URLRequestEncodable, completion: (Data?, URLResponse?, NSError?) -> Void) -> DataTask
}

extension URLSession: Session {
    public func dataTask(request: URLRequestEncodable, completion: (Data?, URLResponse?, NSError?) -> Void) -> DataTask {
        return self.dataTask(request: request.urlRequestValue, completion: completion) as DataTask
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
