//
//  Mocking.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 3/1/16.
//  Copyright © 2016 WalmartLabs. All rights reserved.
//

import Foundation

// MARK: - MockableResponse

/// Defined an interface for mocking data task result data for a given request.
public protocol MockableDataTaskResult {
    /**
     Returns data that will be passed to the data task's completion handler
     - parameter request: The request that the data task result is responding to.
     - returns: Data that will be passed to the completion handler of the task.
    */
    func dataTaskResult(_ request: URLRequestEncodable) -> (Data?, URLResponse?, NSError?)
}

// MARK: - MockResponse

/// Encapsulates the meta and body data of a response.
public struct MockResponse {
    enum Error: ErrorProtocol {
        case invalidURL
    }
    
    /// HTTP status code.
    public let statusCode: Int
 
    /// Response body data
    public var data: Data?
    
    /// Response URL
    public var url: URL?
    
    /// HTTP header fields
    public var headers: [String : String]?
    
    /// Version of the HTTP response as represented by the server. Typically this is represented as "HTTP/1.1".
    public var version: String?
    
    /// Create a mock response with a given status code.
    public init(statusCode: Int) {
        self.statusCode = statusCode
    }
    
    /// Create a mock response with a status code and response body data.
    public init(statusCode: Int, data: Data) {
        self.init(statusCode: statusCode)
        self.data = data
    }
    
    /// Create a mocked response with a  JSON object to use as the stubbed response body data.
    public init(statusCode: Int, json: AnyObject) {
        self.init(statusCode: statusCode)
        self.data = try? JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions(rawValue: 0))
    }
}

extension MockResponse: MockableDataTaskResult {
    /// Creates a data task result from the mock response data
    public func dataTaskResult(_ request: URLRequestEncodable) -> (Data?, URLResponse?, NSError?) {
        guard let responseURL = url ?? request.urlRequestValue.url else {
            return (nil, nil, Error.invalidURL as NSError)
        }
        
        let response = HTTPURLResponse(url: responseURL, statusCode: statusCode, httpVersion: version, headerFields: headers)
        return (data, response, nil)
    }
}

extension URLResponse: MockableDataTaskResult {
    /// Creates a data task result with NSURLResponse instance as the response parameter
    public func dataTaskResult(_ request: URLRequestEncodable) -> (Data?, URLResponse?, NSError?) {
        return (nil, self, nil)
    }
}

// MARK: - Mocking Errors

extension NSError: MockableDataTaskResult {
    /// Creates a data task result with NSError instance as the error parameter
    public func dataTaskResult(_ request: URLRequestEncodable) -> (Data?, URLResponse?, NSError?) {
        return (nil, nil, self)
    }
}

// MARK: - MockSession

/// Implements the `Session` protocol and provides an API for adding mocked responses as stubs.
public class MockSession: Session {
    typealias Stub = (MockableDataTaskResult, (URLRequestEncodable) -> (Bool))
    lazy var stubs = [Stub]()
    
    public init() {
        
    }
    
    /// Creates a data task for a given request and calls the completion handler on a background queue.
    public func dataTask(request: URLRequestEncodable, completion: (Data?, URLResponse?, NSError?) -> Void) -> DataTask {
        requestSent(request)
        
        let (data, response, error) = stubbedResponse(request: request)
        
        DispatchQueue.global(attributes: DispatchQueue.GlobalAttributes.qosDefault).async {
            completion(data, response, error)
        }
        
        return MockDataTask()
    }
    
    public func requestSent(_ request: URLRequestEncodable) {
        
    }
    
    // MARK: Stubbing API
    
    /**
     Add a stub that will be used as the response of a request.
    
     - parameter response: A mockable data task result that provides the mocked 
     response value.
     - parameter requestMatcher: A matcher closure that determines if the mocked 
     response is used as a response stub for a given request.
    */
    public func addStub(_ response: MockableDataTaskResult, requestMatcher: (URLRequestEncodable) -> (Bool)) {
        stubs.append((response, requestMatcher))
    }

    /**
     Add a stub that will be used as the response of any request. 
     The added stub will match any request.
     
     - parameter response: A mockable data task result that provides the mocked
     response value.
    */
    public func addStub(_ response: MockableDataTaskResult) {
        stubs.append((response, { _ in return true}))
    }
    
    /**
     Retrieve a response stub for a given request.
     
     - parameter request: The request that needs a stubbed response.
     */
    public func stubbedResponse(request: URLRequestEncodable) -> (Data?, URLResponse?, NSError?) {
        for (response, matcher) in stubs.reversed() where matcher(request) {
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
    
    public override func requestSent(_ request: URLRequestEncodable) {
        recordedRequests.append(request)
    }
}

// MARK: - Data Task Mocking

/// A concrete implementation of DataTask for mocking purposes.
public final class MockDataTask: DataTask {
    private(set) public var state = URLSessionTask.State.suspended
    
    public init() {
        
    }
    
    public func suspend() {
        state = .suspended
    }
    
    public func resume() {
        state = .running
    }
    
    public func cancel() {
        state = .canceling
    }
}
