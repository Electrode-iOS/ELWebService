//
//  Mocking.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 3/1/16.
//  Copyright © 2016 WalmartLabs. All rights reserved.
//

import Foundation

public protocol MockSession: Session {
    func stubbedResponse(request request: URLRequestEncodable) -> (NSData?, NSURLResponse?, NSError?)
}

extension MockSession {
    public func dataTask(request request: URLRequestEncodable, completion: (NSData?, NSURLResponse?, NSError?) -> Void) -> DataTask {
        completion(stubbedResponse(request: request))
        return MockDataTask()
    }
}

public final class MockDataTask: DataTask {
    private(set) public var state = NSURLSessionTaskState.Suspended
    
    public func suspend() {
        state = .Suspended
    }
    
    public func resume() {
        state = .Running
    }
    
    public func cancel() {
        state = .Canceling
    }
}
