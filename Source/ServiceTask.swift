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
        
        public init(data theData: NSData?, response: NSURLResponse?, error: NSError?) {
            self.data = theData
            self.response = response
            self.error = error
        }
    }
    
    private let handlerQueue: DispatchQueue
    private var dataTask: NSURLSessionDataTask?
    public var result: Result?
    public var state: NSURLSessionTaskState {
        if let state = dataTask?.state {
            return state
        } else {
            return .Suspended
        }
    }
    
    // MARK: - Intialization
    
    /**
     Initialize a ServiceTask value to fulfill an HTTP request.
     @param urlRequestCreator Value responsible for constructing a NSURLRequest 
     instance
     @param dataTaskCreator Value responsible for creating the
     NSURLSessionDataTask that sends the NSURLRequest
    */
    init(urlRequestCreator: URLRequestConstructible, dataTaskCreator: DataTaskConstructible) {
        self.handlerQueue = {
            let queue = DispatchQueue.createSerial("com.THGWebService.ServiceTask")
            Dispatch().suspend(queue)
            return queue
        }()

        self.dataTask = dataTaskCreator.constructDataTask(urlRequestCreator.constructURLRequest(), completion: dataTaskCompletionHandler())
    }
    
    // MARK: - NSURLSesssionDataTask
    
    /**
     Call to resume the underlying data task.
    */
    public func resume() {
        dataTask?.resume()
    }
    
    /**
    Call to suspend the underlying data task.
    */
    public func suspend() {
        dataTask?.suspend()
    }
    
    /**
    Call to cancel the underlying data task.
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
    
    // MARK: - Response Handler API
    
    /**
     Add a response handler to be called on the main thread after a successful
     response has been received.
     @param handler Response handler to execute upon receiving a response.
    */
    public func response(handler: SuccessHandler) -> Self {
        return response(.Main, handler: handler)
    }
    
    /**
    Add a response handler to be called once a successful response has been
    received.
    @param queue The DispatchQueue used to dispatch the response handler.
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

extension ServiceTask {
    
    public typealias JSONHandler = (AnyObject?) -> Void
    
    /**
     Add a response handler to serialize the response body as a JSON object. The
     handler will be dispatched to the main thread.
    */
    public func responseJSON(handler: JSONHandler) -> Self {
        return responseJSON(.Main, handler: handler)
    }
    
    /**
    Add a response handler to serialize the response body as a JSON object.
    @param queue The DispatchQueue used to dispatch the response handler.
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
