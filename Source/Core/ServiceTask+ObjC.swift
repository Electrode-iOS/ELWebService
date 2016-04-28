//
//  ServiceTask+ObjC.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 2/2/16.
//  Copyright © 2016 WalmartLabs. All rights reserved.
//

import Foundation

// MARK: - Obj-C Interop for Request API

extension ServiceTask {
    /**
     Set request parameter values and configure them to be JSON-encoded.
     
     This method is designed to only be called from Obj-C. Please use
     `setParameters(parameters: [String: AnyObject], encoding: Request.ParameterEncoding)`
     when calling from Swift.
     
     - parameter parameters: Request parameter values.
    */
    @objc public func setJSONEncodedParametersObjC(parameters: [String: AnyObject]) -> Self {
        setParameters(parameters, encoding: .JSON)
        return self
    }
    
    /**
     Set request parameter values and configure them to be Percent-encoded.
     
     This method is designed to be called from Obj-C only. Please use
     `setParameters(parameters: [String: AnyObject], encoding: Request.ParameterEncoding)`
     when calling from Swift.
     
     - parameter parameters: Request parameter values.
    */
    @objc public func setPercentEncodedParametersObjC(parameters: [String: AnyObject]) -> Self {
        setParameters(parameters, encoding: .Percent)
        return self
    }
        
    /**
     Configure the request parameters to be JSON-encoded.
    
     This method is designed to be called from Obj-C only. Please use
     `setParameterEncoding(encoding: .JSON)` when calling
     from Swift.
    */
    @objc public func setJSONParameterEncodingObjC() -> Self {
        setParameterEncoding(.JSON)
        return self
    }
    
    /**
     Configure the request parameters to be Percent-encoded.
     
     This method is designed to be called from Obj-C only. Please use
     `setParameterEncoding(encoding: .Percent)` when calling
     from Swift.
    */
    @objc public func setPercentParameterEncodingObjC() -> Self {
        setParameterEncoding(.Percent)
        return self
    }
}

// MARK: - Obj-C Interop for Response Handler API

extension ServiceTask {
    
    /// Response handler type for Obj-C
    typealias ObjCResponseHandler = (NSData?, NSURLResponse?) -> ObjCHandlerResult?

    /**
     Add a response handler to be called on a background thread after a successful
     response has been received. This method is designed to be called from Obj-C.
     Please use `response(handler: ResponseProcessingHandler) -> Self` when calling
     from Swift.
     
     - parameter handler: Response handler to execute upon receiving a response.
     - returns: Self instance to support chaining.
     */
    @objc public func responseObjC(handler: (NSData?, NSURLResponse?) -> ObjCHandlerResult?) -> Self {
        return response { data, response in
            return try handler(data, response)?.valueOrError()
        }
    }
    
    /**
     Add a response handler to serialize the response body as a JSON object. The
     handler will be dispatched to a background thread. This method is designed 
     to be called from Obj-C. Please use `responseJSON(handler: JSONHandler) -> Self` 
     when calling from Swift.
     
     - parameter handler: Response handler to execute upon receiving a response.
     - returns: Self instance to support chaining.
     */
    @objc public func responseJSONObjC(handler: (AnyObject, NSURLResponse?) -> ObjCHandlerResult?) -> Self {
        return responseJSON { json, response in
            return try handler(json, response)?.valueOrError()
        }
    }
    
    /**
     Add a response handler to be called if a request results in an error.
     
     This method is designed to be called from Obj-C. Please use 
     `responseError(handler: ErrorHandler)` when calling from Swift.
     
     - parameter handler: Error handler to execute when an error occurs.
     - returns: Self instance to support chaining.
    */
    @objc public func responseErrorObjC(handler: (NSError) -> Void) -> Self {
        return responseError { error in
            handler(error as NSError)
        }
    }
    
    /**
     Add a handler that runs on the main thread and is responsible for updating
     the UI with a given value. The handler is only called if a previous response
     handler in the chain does **not** return a `.Failure` value.
     
     If a response handler returns a value via `[ObjCHandlerResult resultWithValue:someValue]`
     the value will be passed to the update UI handler.
     
     This method is designed to be called from Obj-C. Please use
     `updateUI(handler: UpdateUIHandler) -> Self` when calling from Swift.
     
     - parameter handler: The closure to execute as the updateUI handler.
     - returns: Self instance to support chaining.
    */
    @objc public func updateUIObjC(handler: (AnyObject?) -> Void) -> Self {
        return updateUI { value in
            if let value = value as? AnyObject {
                handler(value)
            }
        }
    }
    
    /**
     Add a response handler to be called if a request results in an error. Handler
     will be called on the main thread.
     
     This method is designed to be called from Obj-C. Please use
     `updateErrorUIObjC(handler: (NSError) -> Void) -> Self` when calling from Swift.
     
     - parameter handler: Error handler to execute when an error occurs.
     - returns: Self instance to support chaining.
    */
    @objc public func updateErrorUIObjC(handler: (NSError) -> Void) -> Self {
        return updateErrorUI { error in
            handler(error as NSError)
        }
    }
}
