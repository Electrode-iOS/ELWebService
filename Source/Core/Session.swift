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
    func dataTask(request request: URLRequestEncodable, completion: (NSData?, NSURLResponse?, NSError?) -> Void) -> DataTask
}

extension NSURLSession: Session {
    public func dataTask(request request: URLRequestEncodable, completion: (NSData?, NSURLResponse?, NSError?) -> Void) -> DataTask {
        return dataTaskWithRequest(request.urlRequestValue, completionHandler: completion) as DataTask
    }
}

// MARK: - Data Task

public protocol DataTask {
    var state: NSURLSessionTaskState { get }
    
    func suspend()
    func resume()
    func cancel()
}

extension NSURLSessionDataTask: DataTask {}
