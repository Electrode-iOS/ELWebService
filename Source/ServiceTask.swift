//
//  ServiceTask.swift
//  Swallow
//
//  Created by Angelo Di Paolo on 2/25/15.
//  Copyright (c) 2015 TheHolyGrail. All rights reserved.
//

import Foundation
import THGDispatch

public class ServiceTask {
    
    public typealias SuccessHandler = (NSData?, NSURLResponse?) -> Void
    public typealias ErrorHandler = (NSError?) -> Void
    
    /**
     Represents the result of a service task.
    */
    public struct Result {
        let data: NSData?
        let response: NSURLResponse?
        let error: NSError?
        
        /**
         Initialize a service task result.
        
         :param: data Optional response data.
         :param: data Optional response object.
         :param: data Optional error object.
        */
        public init(data: NSData?, response: NSURLResponse?, error: NSError?) {
            self.data = data
            self.response = response
            self.error = error
        }
    }
    
    private let handlerQueue: DispatchQueue
    private var dataTask: NSURLSessionDataTask?
    
    /**
     Result of the service task. If error contains a non-nil value then the 
     service task's error handler is called.
    */
    public var result: Result?
    
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
    
     :param: urlRequestEncoder Value responsible for encoding a NSURLRequest
      instance to send.
     :param: dataTaskSource Object responsible for creating a 
      NSURLSessionDataTask used to send the NSURLRequset.
    */
    init(urlRequestEncoder: URLRequestEncodable, dataTaskSource: SessionDataTaskDataSource) {
        self.handlerQueue = {
            let queue = DispatchQueue.createSerial("ServiceTask")
            Dispatch().suspend(queue)
            return queue
        }()

        self.dataTask = dataTaskSource.dataTaskWithRequest(urlRequestEncoder.encodeURLRequest(), completion: dataTaskCompletionHandler())
    }
    
    // MARK: NSURLSesssionDataTask
    
    /**
     Resume the underlying data task.
    */
    public func resume() {
        dataTask?.resume()
    }
    
    /**
     Suspend the underlying data task.
    */
    public func suspend() {
        dataTask?.suspend()
    }
    
    /**
     Cancel the underlying data task.
    */
    public func cancel() {
        dataTask?.cancel()
    }
    
    private func dataTaskCompletionHandler() -> (NSData?, NSURLResponse?, NSError?) -> Void {
        return { data, response, error in
            self.result = Result(data: data, response: response, error: error)
            Dispatch().resume(self.handlerQueue)
        }
    }
    
    // MARK: Response Handler API
    
    /**
     Add a response handler to be called on the main thread after a successful
     response has been received.
     
     :param: handler Response handler to execute upon receiving a response.
     :returns: Self instance to support chaining.
    */
    public func response(handler: SuccessHandler) -> Self {
        return response(.Main, handler: handler)
    }
    
    /**
    Add a response handler to be called once a successful response has been
    received.
    
    :param queue The DispatchQueue used to dispatch the response handler.
    :param: handler Response handler to execute upon receiving a response.
    :returns: Self instance to support chaining.
    */
    public func response(queue: DispatchQueue, handler: SuccessHandler) -> Self {
        Dispatch().async(handlerQueue) {
            Dispatch().async(queue) {
                if let result = self.result where result.error == nil {
                    handler(result.data, result.response)
                }
            }
        }
        
        return self
    }
    
    /**
    Add a response handler to be called if a request results in an error.
    
    :param: handler Error handler to execute when an error occurs.
    :returns: Self instance to support chaining.
    */
    public func responseError(handler: ErrorHandler) -> Self {
        Dispatch().async(handlerQueue) {
            Dispatch().async(.Main) {
                if let error = self.result?.error {
                    handler(error)
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
    
     :param: handler Response handler to execute upon receiving a response.
     :returns: Self instance to support chaining.
    */
    public func responseJSON(handler: JSONHandler) -> Self {
        return responseJSON(.Main, handler: handler)
    }
    
    /**
    Add a response handler to serialize the response body as a JSON object.
    
    :param: queue The DispatchQueue used to dispatch the response handler.
    :param: handler Response handler to execute upon receiving a response.
    :returns: Self instance to support chaining.
    */
    public func responseJSON(queue: DispatchQueue, handler: JSONHandler) -> Self {
        return response(queue) { data, response in
            if let data = data {
                var error: NSError?
                let json: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &error)
                
                if let error = error {
                    self.result = Result(data: nil, response: nil, error: error)
                } else {
                    handler(json)
                }
            }
        }
    }
}
