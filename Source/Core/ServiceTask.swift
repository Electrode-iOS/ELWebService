//
//  ServiceTask.swift
//  Swallow
//
//  Created by Angelo Di Paolo on 2/25/15.
//  Copyright (c) 2015 TheHolyGrail. All rights reserved.
//

import Foundation

/**
 A lightweight wrapper around `NSURLSessionDataTask` that provides a chainable 
 API for processing the result of a data task. A `ServiceTask` instance can be
 cancelled and suspended like a data task as well as queried for current state
 via the `state` property.
*/
public final class ServiceTask {
    /// Represents the result of a service task.
    private enum Result {
        case Success(NSData?, NSURLResponse?)
        case Failure(NSError)
        
        init(data: NSData?, response: NSURLResponse?, error: NSError?) {
            if let error = error {
                self = .Failure(error)
            } else {
                self = .Success(data, response)
            }
            
        }
    }
    
    /// A closure type alias for a success handler.
    public typealias SuccessHandler = (NSData?, NSURLResponse?) -> Void
    
    /// A closure type alias for an error handler.
    public typealias ErrorHandler = (ErrorType) -> Void
    
    /// State of the service task.
    public var state: NSURLSessionTaskState {
        if let state = dataTask?.state {
            return state
        } else {
            return .Suspended
        }
    }
    
    /// Dispatch queue that queues up and dispatches handler blocks
    private let handlerQueue: dispatch_queue_t
    
    /// Session data task that refers the lifetime of the request.
    private var dataTask: NSURLSessionDataTask?
    
    /// Result of the service task
    private var result: Result?
    
    // MARK: Intialization
    
    /**
     Initialize a ServiceTask value to fulfill an HTTP request.
    
     - parameter urlRequestEncoder: Value responsible for encoding a NSURLRequest
      instance to send.
     - parameter dataTaskSource: Object responsible for creating a 
      NSURLSessionDataTask used to send the NSURLRequset.
    */
    init(urlRequestEncodable: URLRequestEncodable, dataTaskSource: SessionDataTaskDataSource) {
        self.handlerQueue = {
            let queue = dispatch_queue_create(("com.THGWebService.ServiceTask" as NSString).UTF8String, DISPATCH_QUEUE_SERIAL)
            dispatch_suspend(queue)
            return queue
        }()

        self.dataTask = dataTaskSource.dataTaskWithRequest(urlRequestEncodable.urlRequestValue, completion: dataTaskCompletionHandler())
    }
}

// MARK: NSURLSesssionDataTask

extension ServiceTask {
    
    /// Resume the underlying data task.
    public func resume() {
        dataTask?.resume()
    }
    
    /// Suspend the underlying data task.
    public func suspend() {
        dataTask?.suspend()
    }
    
    /// Cancel the underlying data task.
    public func cancel() {
        dataTask?.cancel()
    }
    
    private func dataTaskCompletionHandler() -> (NSData?, NSURLResponse?, NSError?) -> Void {
        return { data, response, error in
            self.result = Result(data: data, response: response, error: error)
            dispatch_resume(self.handlerQueue)
        }
    }
}

// MARK: - Response API

extension ServiceTask {
    /**
    Add a response handler to be called on the main thread after a successful
    response has been received.
    
    - parameter handler: Response handler to execute upon receiving a response.
    - returns: Self instance to support chaining.
    */
    public func response(handler: SuccessHandler) -> Self {
        return response(dispatch_get_main_queue(), handler: handler)
    }
    
    /**
    Add a response handler to be called once a successful response has been
    received.
    
    - parameter queue: The target dispatch queue to which the response handler
    is submitted.
    - parameter handler: Response handler to execute upon receiving a response.
    - returns: Self instance to support chaining.
    */
    public func response(queue: dispatch_queue_t, handler: SuccessHandler) -> Self {
        dispatch_async(handlerQueue) {
            dispatch_async(queue) {
                if let result = self.result {
                    switch result {
                    case .Success(let data, let response):
                        handler(data, response)
                    default:
                        break
                    }
                }
            }
        }
        
        return self
    }
}

// MARK: - JSON

extension ServiceTask {
    /// A closure type alias for handling the response as JSON.
    public typealias JSONHandler = (AnyObject) -> Void
    
    /**
     Add a response handler to serialize the response body as a JSON object. The
     handler will be dispatched to the main thread.
    
     - parameter handler: Response handler to execute upon receiving a response.
     - returns: Self instance to support chaining.
    */
    public func responseJSON(handler: JSONHandler) -> Self {
        return responseJSON(dispatch_get_main_queue(), handler: handler)
    }
    
    /**
     Add a response handler to serialize the response body as a JSON object.
    
     - parameter queue: The DispatchQueue used to dispatch the response handler.
     - parameter handler: Response handler to execute upon receiving a response.
     - returns: Self instance to support chaining.
    */
    public func responseJSON(queue: dispatch_queue_t, handler: JSONHandler) -> Self {
        return response(queue) { data, response in
            if let data = data {
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
                    handler(json)
                } catch let jsonError as NSError {
                    self.throwError(jsonError)
                } catch {
                    fatalError()
                }
            }
        }
    }
}

// MARK: - Error Handling

extension ServiceTask {
    /**
    Add a response handler to be called if a request results in an error.
    
    :param: handler Error handler to execute when an error occurs.
    :returns: Self instance to support chaining.
    */
    public func responseError(handler: ErrorHandler) -> Self {
        dispatch_async(handlerQueue) {
            dispatch_async(dispatch_get_main_queue()) {
                if let result = self.result {
                    switch result {
                    case .Failure(let error):
                        handler(error)
                    default:
                        break
                    }
                }
                
            }
        }
        
        return self
    }
    
    /**
     Call to indicate that an error occured during the processing of a response.
     Causes responseError handlers to be called.
    */
    public func throwError(error: NSError) {
        self.result = Result(data: nil, response: nil, error: error)
    }
}
