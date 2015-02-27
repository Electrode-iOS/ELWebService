//
//  ServiceTask.swift
//  Swallow
//
//  Created by Angelo Di Paolo on 2/25/15.
//  Copyright (c) 2015 TheHolyGrail. All rights reserved.
//

import Foundation

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
        
        init(data theData: NSData?, response: NSURLResponse?, error: NSError?) {
            self.data = theData
            self.response = response
            self.error = error
        }
    }
    
    let request: Request
    let handlerQueue: dispatch_queue_t
    var result: Result?
    private var dataTask: NSURLSessionDataTask?
    
    // MARK: - Intialization
    
    /**
     Initialize a ServiceTask value to fulfill a Request.
     @param request Request value used to construct the resulting NSURLRequest
     @param dataTaskCreator Value responsible for creating NSURLSessionDataTask objects
    */
    init(request aRequest: Request, dataTaskCreator: DataTaskConstructible) {
        self.request = aRequest
        
        // TODO: replace direct calls to GCD with THGDispatch methods
        self.handlerQueue = {
            let queue = dispatch_queue_create(("com.THGWebService.ServiceTask" as NSString).UTF8String, DISPATCH_QUEUE_SERIAL)
            dispatch_suspend(queue)
            return queue
            }()
        
        
        let urlRequest = request.constructURLRequest()
        self.dataTask = dataTaskCreator.constructDataTask(urlRequest, completion: dataTaskCompletionHandler())
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
            dispatch_resume(self.handlerQueue)
        }
    }
    
    // MARK: - Response Handler API
    
    /**
     Add a response handler to be called once a successful response has been
     received.
    */
    public func response(handler: SuccessHandler) -> Self {
        dispatch_async(handlerQueue) {
            dispatch_async(dispatch_get_main_queue()) {
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
        dispatch_async(handlerQueue) {
            dispatch_async(dispatch_get_main_queue()) {
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
     Add a response handler to serialize the response body as a JSON object.
    */
    public func responseJSON(handler: JSONHandler) -> Self {
        return response() { data, response in
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
