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
    private var request: Request
    
    public typealias ResponseProcessingHandler = (NSData?, NSURLResponse?) -> ServiceTaskResult
    
    /// A closure type alias for a success handler.
    public typealias UpdateUIHandler = (Any?) -> Void

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
    private var taskResult: ServiceTaskResult?
    
    /// Response body data
    private var responseData: NSData?
    
    /// URL response
    private var urlResponse: NSURLResponse?
    
    private weak var dataTaskSource: SessionDataTaskDataSource?
    
    // MARK: Intialization
    
    /**
     Initialize a ServiceTask value to fulfill an HTTP request.
    
     - parameter urlRequestEncoder: Value responsible for encoding a NSURLRequest
      instance to send.
     - parameter dataTaskSource: Object responsible for creating a 
      NSURLSessionDataTask used to send the NSURLRequset.
    */
    
    init(request: Request, dataTaskSource: SessionDataTaskDataSource) {
        self.request = request
        self.dataTaskSource = dataTaskSource
        self.handlerQueue = {
            let queue = dispatch_queue_create(("com.ELWebService.ServiceTask" as NSString).UTF8String, DISPATCH_QUEUE_SERIAL)
            dispatch_suspend(queue)
            return queue
        }()
    }
}

// MARK: - Request API

extension ServiceTask {
    public func setParameters(parameters: [String: AnyObject], encoding: Request.ParameterEncoding? = nil) -> Self {
        request.parameters = parameters
        request.parameterEncoding = encoding ?? .Percent
        
        if encoding == .JSON {
            request.contentType = Request.ContentType.json
        }
        
        return self
    }
        
    public func setBody(data: NSData) -> Self {
        request.body = data
        return self
    }
    
    public func setJSON(json: AnyObject) -> Self {
        request.contentType = Request.ContentType.json
        request.body = try? NSJSONSerialization.dataWithJSONObject(json, options: NSJSONWritingOptions(rawValue: 0))
        return self
    }
    
    public func setHeaders(headers: [String: String]) -> Self {
        request.headers = headers
        return self
    }
    
    public func setHeaderValue(value: String, forName name: String) -> Self {
        request.headers[name] = value
        return self
    }
    
    public func setCachePolicy(cachePolicy: NSURLRequestCachePolicy) -> Self {
        request.cachePolicy = cachePolicy
        return self
    }
    
    public func setParameterEncoding(encoding: Request.ParameterEncoding) -> Self {
        request.parameterEncoding = encoding
        return self
    }
}

// MARK: NSURLSesssionDataTask

extension ServiceTask {
    /// Resume the underlying data task.
    public func resume() -> Self {
        if dataTask == nil {
            dataTask = dataTaskSource?.dataTaskWithRequest(request.urlRequestValue, completionHandler: dataTaskCompletionHandler())
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
    
    private func dataTaskCompletionHandler() -> (NSData?, NSURLResponse?, NSError?) -> Void {
        return { data, response, error in
            self.urlResponse = response
            self.responseData = data
            
            if let error = error {
                self.taskResult = ServiceTaskResult.Failure(error)
            }
            
            dispatch_resume(self.handlerQueue)
        }
    }
}

// MARK: - Response API

extension ServiceTask {
    /**
     Add a response handler to be called on background thread after a successful
     response has been received.
    
     - parameter handler: Response handler to execute upon receiving a response.
     - returns: Self instance to support chaining.
    */
    public func response(handler: ResponseProcessingHandler) -> Self {
        dispatch_async(handlerQueue) {
            if let taskResult = self.taskResult {
                switch taskResult {
                case .Failure(_): return // bail out to avoid next handler from running
                case .Value(_): break
                case .Empty: break
                }
            }
            
            self.taskResult = handler(self.responseData, self.urlResponse)
        }

        return self
    }
    
    /// TODO: add docs
    public func updateUI(handler: UpdateUIHandler) -> Self {
        dispatch_async(handlerQueue) {
            if let taskResult = self.taskResult {
                switch taskResult {
                case .Value(let value):
                    dispatch_async(dispatch_get_main_queue()) {
                        handler(value)
                    }
                case .Empty:
                    dispatch_async(dispatch_get_main_queue()) {
                        handler(nil)
                    }
                case .Failure(_): break
                }
            }
        }
        
        return self
    }
}

// MARK: - JSON

extension ServiceTask {
    /// A closure type alias for handling the response as JSON.
    public typealias JSONHandler = (AnyObject) -> ServiceTaskResult
    
    /**
     Add a response handler to serialize the response body as a JSON object. The
     handler will be dispatched to a background thread.
    
     - parameter handler: Response handler to execute upon receiving a response.
     - returns: Self instance to support chaining.
    */
    public func responseJSON(handler: JSONHandler) -> Self {
        return response { data, response in
            if let data = data {
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
                    return handler(json)
                } catch let jsonError as NSError {
                    return .Failure(jsonError)
                } catch {
                    fatalError()
                }
            } else {
                return .Failure(ServiceTaskError.JSONSerializationFailedNilResponseBody)
            }
        }
    }
}

// MARK: - Error Handling

extension ServiceTask {
    /**
    Add a response handler to be called if a request results in an error.
    
    - parameter handler: Error handler to execute when an error occurs.
    - returns: Self instance to support chaining.
    */
    public func responseError(handler: ErrorHandler) -> Self {
        dispatch_async(handlerQueue) {
            if let taskResult = self.taskResult {
                switch taskResult {
                case .Failure(let error): handler(error)
                case .Value(_): break
                case .Empty: break
                }
            }
        }
        
        return self
    }
    
    /**
     Add a response handler to be called if a request results in an error. Handler
     will be called on the main queue.
     
     - parameter handler: Error handler to execute when an error occurs.
     - returns: Self instance to support chaining.
     */
    public func updateErrorUI(handler: ErrorHandler) -> Self {
        dispatch_async(handlerQueue) {
            if let taskResult = self.taskResult {
                switch taskResult {
                case .Failure(let error):
                    dispatch_async(dispatch_get_main_queue()) {
                        handler(error)
                    }
                case .Value(_): break
                case .Empty: break
                }
            }
        }
        
        return self
    }
}

// MARK: - Errors

// TODO: needs docs
public enum ServiceTaskError: ErrorType {
    case JSONSerializationFailedNilResponseBody
}
