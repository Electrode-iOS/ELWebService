//
//  ServiceTask.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 2/25/15.
//  Copyright (c) 2015 WalmartLabs. All rights reserved.
//

import Foundation

/**
 A lightweight wrapper around `NSURLSessionDataTask` that provides a chainable
 API for processing the result of a data task. A `ServiceTask` instance can be
 cancelled and suspended like a data task as well as queried for current state
 via the `state` property.
*/
@objc public final class ServiceTask: NSObject {
    public typealias ResponseProcessingHandler = (Data?, URLResponse?) throws -> ServiceTaskResult
    
    /// A closure type alias for a success handler.
    public typealias UpdateUIHandler = (Any?) -> Void

    /// A closure type alias for an error handler.
    public typealias ErrorHandler = (Error) -> Void
    
    /// State of the service task.
    public var state: URLSessionTask.State {
        if let state = dataTask?.state {
            return state
        }
        
        return .suspended
    }
    
    fileprivate(set) var metrics = ServiceTaskMetrics()
    
    fileprivate var request: Request
    
    lazy fileprivate var urlRequest: URLRequest = {
        return self.request.urlRequestValue as URLRequest
    }()
    
    /// Dispatch queue that queues up and dispatches handler blocks
    fileprivate let handlerQueue: OperationQueue
    
    /// Session data task that refers the lifetime of the request.
    fileprivate var dataTask: DataTask?
    
    /// Result of the service task
    fileprivate var taskResult: ServiceTaskResult? {
        didSet {
            // Use observer to watch for error result to send to passthrough
            guard let result = taskResult else { return }
            switch result {
            case .failure(let error):
                if responseError == nil {
                    passthroughDelegate?.serviceResultFailure(urlResponse, data: responseData, request: urlRequest, error: error)
                }
            case .empty, .value(_): return
            }
        }
    }
    
    /// Response body data
    fileprivate var responseData: Data?
    
    /// URL response
    fileprivate var urlResponse: URLResponse?
    
    fileprivate var responseError: Error?
    
    /// Type responsible for creating NSURLSessionDataTask objects
    fileprivate var session: Session?
    
    fileprivate var json: Any?
    
    fileprivate var metricsHandler: MetricsHandler?
    
    /// Delegate interface for handling raw response and request events
    internal weak var passthroughDelegate: ServicePassthroughDelegate?
    
    // MARK: Intialization
    
    /**
     Initialize a ServiceTask value to fulfill an HTTP request.
    
     - parameter urlRequestEncoder: Value responsible for encoding a NSURLRequest
       instance to send.
     - parameter dataTaskSource: Object responsible for creating a
       NSURLSessionDataTask used to send the NSURLRequset.
    */
    init(request: Request, session: Session) {
        self.request = request
        self.session = session
        self.handlerQueue = {
            let queue = OperationQueue()
            queue.maxConcurrentOperationCount = 1
            queue.isSuspended = true
            return queue
        }()
    }
    
    deinit {
        handlerQueue.cancelAllOperations()
    }
}

// MARK: - Request API

extension ServiceTask {
    
    /**
     Sets a boolean that indicates whether the receiver should use the default
     cookie handling for the request.
     
     - parameter handle: true if the receiver should use the default cookie
     handling for the request, false otherwise. The default is true.
     - returns: Self instance to support chaining.
     */
    @discardableResult public func setShouldHandleCookies(_ handle: Bool) -> Self {
        request.shouldHandleCookies = handle
        return self
    }
    
    /// TODO: Needs docs
    @discardableResult public func setParameters(_ parameters: [String: Any], encoding: Request.ParameterEncoding? = nil) -> Self {
        request.parameters = parameters
        request.parameterEncoding = encoding ?? .percent
        
        return self
    }
    
    /// TODO: Needs docs
    @discardableResult public func setBody(_ data: Data) -> Self {
        request.body = data
        return self
    }
    
    /// TODO: Needs docs
    @discardableResult public func setJSON(_ json: Any) -> Self {
        request.contentType = Request.ContentType.json
        request.body = try? JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions(rawValue: 0))
        return self
    }
    
    /// TODO: Needs docs
    @discardableResult public func setHeaders(_ headers: [String: String]) -> Self {
        request.headers = headers
        return self
    }
    
    /// TODO: Needs docs
    @discardableResult public func setHeaderValue(_ value: String, forName name: String) -> Self {
        request.headers[name] = value
        return self
    }
    
    /// TODO: Needs docs
    @discardableResult public func setCachePolicy(_ cachePolicy: NSURLRequest.CachePolicy) -> Self {
        request.cachePolicy = cachePolicy
        return self
    }
    
    /// TODO: Needs docs
    @discardableResult public func setParameterEncoding(_ encoding: Request.ParameterEncoding) -> Self {
        request.parameterEncoding = encoding
        return self
    }
    
    /// Sets the key/value pairs that will be encoded as the query in the URL.
    @discardableResult public func setQueryParameters(_ parameters: [String: Any]) -> Self {
        request.queryParameters = parameters
        return self
    }
    
    /**
     Sets the key/value pairs that will be encoded as the query in the URL.
     
     - parameter parameters: Query parameter data.
     - parameter handler: A callback that is invoked when the query parameters are encoded in the URL. Enables you to define custom encoding behavior.
     - returns: Self instance to support chaining.
    */
    @discardableResult public func setQueryParameters(_ parameters: [String: Any], encoder: @escaping QueryParameterEncoder) -> Self {
        setQueryParameters(parameters)
        request.queryParameterEncoder = encoder
        return self
    }
    
    /// Sets the key/value pairs that are encoded as form data in the request body.
    @discardableResult public func setFormParameters(_ parameters: [String: Any]) -> Self {
        request.formParameters = parameters
        return self
    }
}

// MARK: - NSURLSesssionDataTask

extension ServiceTask {
    /// Resume the underlying data task.
    @discardableResult public func resume() -> Self {
        if dataTask == nil {
            dataTask = session?.dataTask(request: urlRequest) { data, response, error in
                self.handleResponse(response, data: data, error: error)
            }
        }
        
        metrics.fetchStartDate = Date()
        dataTask?.resume()
        return self
    }
    
    /// Suspend the underlying data task.
    public func suspend() {
        dataTask?.suspend()
    }
    
    /// Cancel the underlying data task.
    public func cancel() {
        dataTask?.cancel()
    }
    
    /// Handle the response and kick off the handler queue
    internal func handleResponse(_ response: URLResponse?, data: Data?, error: Error?) {
        metrics.responseEndDate = Date()
        passthroughDelegate?.didFinishCollectingTaskMetrics(metrics: metrics, request: urlRequest, response: response, data: data, error: error)
        metricsHandler?(metrics, response)
        urlResponse = response
        responseData = data
        responseError = error
        
        if let responseError = responseError {
            taskResult = ServiceTaskResult.failure(responseError)
        }
        
        handlerQueue.isSuspended = false
    }
}

// MARK: - Response API

extension ServiceTask {
    /// A closure type alias for a result transformation handler.
    public typealias ResultTransformer = (Any?) throws -> ServiceTaskResult

    /**
     Add a response handler to be called on background thread after a successful
     response has been received.
    
     - parameter handler: Response handler to execute upon receiving a response.
     - returns: Self instance to support chaining.
    */
    public func response(_ handler: @escaping ResponseProcessingHandler) -> Self {
        handlerQueue.addOperation {
            if let taskResult = self.taskResult {
                switch taskResult {
                case .failure(_): return // bail out to avoid next handler from running
                case .empty, .value(_): break
                }
            }
            
            do {
                self.taskResult = try handler(self.responseData, self.urlResponse)
            } catch let error {
                self.taskResult = .failure(error)
            }
        }

        return self
    }
    
    /**
     Add a response handler to transform a (non-error) result produced by an earlier
     response handler.

     The handler can return any type of service task result, `.Empty`, `.Value` or
     `.Failure`. The result is propagated to later response handlers.

     - parameter handler: Transformation handler to execute.
     - returns: Self instance to support chaining.
     */
    public func transform(_ handler: @escaping ResultTransformer) -> Self {
        handlerQueue.addOperation {
            guard let taskResult = self.taskResult else {
                return
            }
            
            do {
                let resultValue = try taskResult.taskValue()
                self.taskResult = try handler(resultValue)
            } catch let error {
                self.taskResult = .failure(error)
            }
        }
        
        return self
    }

    /**
     Add a handler that runs on the main thread and is responsible for updating 
     the UI with a given value. The handler is only called if a previous response 
     handler in the chain does **not** return a `.Failure` value.
     
     If a response handler returns a value via ServiceTaskResult.Value the
     associated value will be passed to the update UI handler.
    
     - parameter handler: The closure to execute as the updateUI handler.
     - returns: Self instance to support chaining.
    */
    public func updateUI(_ handler: @escaping UpdateUIHandler) -> Self {
        handlerQueue.addOperation {
            guard let taskResult = self.taskResult else {
                return
            }
            
            do {
                let value = try taskResult.taskValue()
                
                DispatchQueue.main.sync {
                    self.passthroughDelegate?.updateUIBegin(self.urlResponse)
                    handler(value)
                    self.passthroughDelegate?.updateUIEnd(self.urlResponse)
                }
            } catch _ {
                return
            }
        }
        
        return self
    }
}

// MARK: - JSON

extension ServiceTask {
    /// A closure type alias for handling the response as JSON.
    public typealias JSONHandler = (Any, URLResponse?) throws -> ServiceTaskResult
    
    /**
     Add a response handler to serialize the response body as a JSON object. The
     handler will be dispatched to a background thread.
    
     - parameter handler: Response handler to execute upon receiving a response.
     - returns: Self instance to support chaining.
    */
    public func responseJSON(_ handler: @escaping JSONHandler) -> Self {
        return response { data, response in
            guard let data = data else {
                throw ServiceTaskError.jsonSerializationFailedNilResponseBody
            }
            
            if let json = self.json {
                return try handler(json, response)
            } else {
                let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
                self.json = json
                return try handler(json, response)
            }
        }
    }
}

// MARK: - Metrics

extension ServiceTask {
    public typealias MetricsHandler = (ServiceTaskMetrics, URLResponse?) -> Void
    
    /**
     Set a callback that will be invoked when service task metrics have been
     collected
     
     - parameter handler: Callback to invoke when metrics have been collected.
     - returns: Self instance to support chaining.
     */
    public func metricsCollected(_ handler: @escaping MetricsHandler) -> Self {
        metricsHandler = handler
        return self
    }
}

// MARK: - Error Handling

extension ServiceTask {
    /// A closure type alias for an error-recovery handler.
    public typealias ErrorRecoveryHandler = (Error) throws -> ServiceTaskResult

    /**
    Add a response handler to be called if a request results in an error.
    
    - parameter handler: Error handler to execute when an error occurs.
    - returns: Self instance to support chaining.
    */
    public func responseError(_ handler: @escaping ErrorHandler) -> Self {
        handlerQueue.addOperation {
            if let taskResult = self.taskResult {
                switch taskResult {
                case .failure(let error): handler(error)
                case .empty, .value(_): break
                }
            }
        }
        
        return self
    }
    
    /**
     Add a response handler to be called if a request results in an error. Handler
     will be called on the main thread.
     
     - parameter handler: Error handler to execute when an error occurs.
     - returns: Self instance to support chaining.
    */
    public func updateErrorUI(_ handler: @escaping ErrorHandler) -> Self {
        handlerQueue.addOperation {
            if let taskResult = self.taskResult {
                switch taskResult {
                case .failure(let error):
                    DispatchQueue.main.sync {
                        handler(error)
                    }
                case .empty, .value(_): break
                }
            }
        }
        
        return self
    }

    /**
     Add a response handler to recover from an error produced by an earlier response
     handler.
     
     The handler can return either a `.Value` or `.Empty`, indicating it was able to
     recover from the error, or an `.Failure`, indicating that it was not able to
     recover. The result is propagated to later response handlers.
     
     - parameter handler: Recovery handler to execute when an error occurs.
     - returns: Self instance to support chaining.
    */
    public func recover(_ handler: @escaping ErrorRecoveryHandler) -> Self {
        handlerQueue.addOperation {
            guard let taskResult = self.taskResult else {
                return
            }

            switch taskResult {
            case .failure(let error):
                do {
                    self.taskResult = try handler(error)
                } catch let error {
                    self.taskResult = .failure(error)
                }

            case .empty, .value(_):
                return // bail out; do not run this handler
            }
        }
        
        return self
    }
}

// MARK: - Errors

/// Errors that can occur when processing a response
public enum ServiceTaskError: Error {
    /// Failed to serialize a response body as JSON due to the data being nil.
    case jsonSerializationFailedNilResponseBody
}
