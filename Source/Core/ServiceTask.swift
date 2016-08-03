//
//  ServiceTask.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 2/25/15.
//  Copyright (c) 2015 WalmartLabs. All rights reserved.
//

import Foundation

protocol ServiceTaskDelegate: class {
    
}

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
    
    weak var delegate: ServiceTaskDelegate?
    
    /// State of the service task.
    public var state: URLSessionTask.State {
        if let state = dataTask?.state {
            return state
        }
        
        return .suspended
    }
    
    private var request: URLRequestConvertible
    
    /// Dispatch queue that queues up and dispatches handler blocks
    private let handlerQueue: OperationQueue
    
    /// Session data task that refers the lifetime of the request.
    private var dataTask: DataTask?
    
    /// Result of the service task
    private var taskResult: ServiceTaskResult? {
        didSet {
            // Use observer to watch for error result to send to passthrough
            guard let result = taskResult else { return }
            switch result {
            case .failure(let error):
                if responseError == nil {
                    passthroughDelegate?.serviceResultFailure(urlResponse, data: responseData, request: request.urlRequest, error: error)
                }
            case .empty, .Value(_): return
            }
        }
    }
    
    /// Response body data
    private var responseData: Data?
    
    /// URL response
    private var urlResponse: URLResponse?
    
    private var responseError: NSError?
    
    /// Type responsible for creating NSURLSessionDataTask objects
    private var session: Session?
    
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
    init(request: URLRequestConvertible, session: Session) {
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

// MARK: - NSURLSesssionDataTask

extension ServiceTask {
    /// Resume the underlying data task.
    @discardableResult public func resume() -> Self {
        if dataTask == nil {
            dataTask = session?.dataTask(request: request.urlRequest) { data, response, error in
                self.handleResponse(response, data: data, error: error)
            }
        }
        
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
    internal func handleResponse(_ response: URLResponse?, data: Data?, error: NSError?) {
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
    public func response(_ handler: ResponseProcessingHandler) -> Self {
        handlerQueue.addOperation {
            if let taskResult = self.taskResult {
                switch taskResult {
                case .failure(_): return // bail out to avoid next handler from running
                case .empty, .Value(_): break
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
    public func transform(_ handler: ResultTransformer) -> Self {
        handlerQueue.addOperation {
            guard let taskResult = self.taskResult else {
                return
            }
            
            do {
                let resultValue = try taskResult.value()
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
    public func updateUI(_ handler: UpdateUIHandler) -> Self {
        handlerQueue.addOperation {
            guard let taskResult = self.taskResult else {
                return
            }
            
            do {
                let value = try taskResult.value()
                
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
    public typealias JSONHandler = (AnyObject, URLResponse?) throws -> ServiceTaskResult
    
    /**
     Add a response handler to serialize the response body as a JSON object. The
     handler will be dispatched to a background thread.
    
     - parameter handler: Response handler to execute upon receiving a response.
     - returns: Self instance to support chaining.
    */
    public func responseJSON(_ handler: JSONHandler) -> Self {
        return response { data, response in
            guard let data = data else {
                throw ServiceTaskError.jsonSerializationFailedNilResponseBody
            }
            
            let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
            return try handler(json, response)
        }
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
    public func responseError(_ handler: ErrorHandler) -> Self {
        handlerQueue.addOperation {
            if let taskResult = self.taskResult {
                switch taskResult {
                case .failure(let error): handler(error)
                case .empty, .Value(_): break
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
    public func updateErrorUI(_ handler: ErrorHandler) -> Self {
        handlerQueue.addOperation {
            if let taskResult = self.taskResult {
                switch taskResult {
                case .failure(let error):
                    DispatchQueue.main.sync {
                        handler(error)
                    }
                case .empty, .Value(_): break
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
    public func recover(_ handler: ErrorRecoveryHandler) -> Self {
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

            case .empty, .Value(_):
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
