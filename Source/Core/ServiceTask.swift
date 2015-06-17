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
    
    /// A closure type alias for a success handler.
    public typealias SuccessHandler = (NSData?, NSURLResponse?) -> Void
    
    /// A closure type alias for an error handler.
    public typealias ErrorHandler = (ErrorType) -> Void
    
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
    
    private let handlerQueue: dispatch_queue_t
    private var dataTask: NSURLSessionDataTask?
    
    /**
     Result of the service task. If error contains a non-nil value then the 
     service task's error handler is called.
    */
    private var result: Result?
    
    /**
     State of the service task.
    */
    public var state: NSURLSessionTaskState {
        if let state = dataTask?.state {
            return state
        } else {
            return .Suspended
        }
    }
    
    // MARK: Intialization
    
    /**
     Initialize a ServiceTask value to fulfill an HTTP request.
    
     - parameter urlRequestEncoder: Value responsible for encoding a NSURLRequest
      instance to send.
     - parameter dataTaskSource: Object responsible for creating a 
      NSURLSessionDataTask used to send the NSURLRequset.
    */
    init(urlRequestEncoder: URLRequestEncodable, dataTaskSource: SessionDataTaskDataSource) {
        self.handlerQueue = {
            let queue = dispatch_queue_create(("com.THGWebService.ServiceTask" as NSString).UTF8String, DISPATCH_QUEUE_SERIAL)
            dispatch_suspend(queue)
            return queue
        }()

        self.dataTask = dataTaskSource.dataTaskWithRequest(urlRequestEncoder.encodeURLRequest(), completion: dataTaskCompletionHandler())
    }
    
    // MARK: NSURLSesssionDataTask
    
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
    
    // MARK: Response Handler API
    
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
    
     :param queue The target dispatch queue to which the response handler is
      submitted.
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
    
    public typealias JSONHandler = (AnyObject?) -> Void
    
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
                var error: NSError?
                let json: AnyObject?
                do {
                    json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
                } catch let jsonError as NSError {
                    error = jsonError
                    json = nil
                } catch {
                    fatalError()
                }
                
                if let error = error {
                    self.throwError(error)
                } else {
                    handler(json)
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
