//
//  Mocking.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 3/1/16.
//  Copyright © 2016 WalmartLabs. All rights reserved.
//

import Foundation

// MARK: - MockableResponse

public protocol MockableDataTaskResult {
    func dataTaskResult(request: URLRequestEncodable) -> (NSData?, NSURLResponse?, NSError?)
}

// MARK: - MockResponse

public struct MockResponse {
    enum Error: ErrorType {
        case InvalidURL
    }
    
    public let statusCode: Int
    public var data: NSData?
    public var url: NSURL?
    public var headers: [String : String]?
    public var version: String?
    
    public init(statusCode: Int) {
        self.statusCode = statusCode
    }
    
    public init(statusCode: Int, data: NSData) {
        self.init(statusCode: statusCode)
        self.data = data
    }
    
    /// Defines a stubbed JSON object to use as the stubbed response body data.
    public init(statusCode: Int, json: AnyObject) {
        self.init(statusCode: statusCode)
        self.data = try? NSJSONSerialization.dataWithJSONObject(json, options: NSJSONWritingOptions(rawValue: 0))
    }
}

extension MockResponse: MockableDataTaskResult {
    public func dataTaskResult(request: URLRequestEncodable) -> (NSData?, NSURLResponse?, NSError?) {
        guard let responseURL = url ?? request.urlRequestValue.URL else {
            return (nil, nil, Error.InvalidURL as NSError)
        }
        
        let response = NSHTTPURLResponse(URL: responseURL, statusCode: statusCode, HTTPVersion: version, headerFields: headers)
        return (data, response, nil)
    }
}

// MARK: - Mocking Errors

extension NSError: MockableDataTaskResult {
    public func dataTaskResult(request: URLRequestEncodable) -> (NSData?, NSURLResponse?, NSError?) {
        return (nil, nil, self)
    }
}

// MARK: - MockSession

public class MockSession: Session {
    typealias Stub = (MockableDataTaskResult, (URLRequestEncodable) -> (Bool))
    lazy var stubs = [Stub]()
    
    public init() {
        
    }
    
    public func dataTask(request request: URLRequestEncodable, completion: (NSData?, NSURLResponse?, NSError?) -> Void) -> DataTask {
        requestSent(request)
        
        let response = stubbedResponse(request: request)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            completion(response)
        }
        
        return MockDataTask()
    }
    
    public func requestSent(request: URLRequestEncodable) {
        
    }
    
    // MARK: Stubbing API
    
    public func addStub(response: MockableDataTaskResult, requestMatcher: (URLRequestEncodable) -> (Bool)) {
        stubs.append((response, requestMatcher))
    }
    
    public func addStub(response: MockableDataTaskResult) {
        stubs.append((response, { _ in return true}))
    }
    
    public func stubbedResponse(request request: URLRequestEncodable) -> (NSData?, NSURLResponse?, NSError?) {
        for (response, matcher) in stubs.reverse() where matcher(request) {
            return response.dataTaskResult(request)
        }
        
        return (nil, nil, nil)
    }
}

// MARK: - Mocked Sessions

/// A MockableSession that records all of the requests that are sent during its lifetime.
public class RequestRecordingSession: MockSession {
    /// The requests that were sent during the lifetime of the session.
    public private(set) var recordedRequests = [URLRequestEncodable]()
    
    public override func requestSent(request: URLRequestEncodable) {
        recordedRequests.append(request)
    }
}

// MARK: - Data Task Mocking

public final class MockDataTask: DataTask {
    private(set) public var state = NSURLSessionTaskState.Suspended
    
    public init() {
        
    }
    
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
