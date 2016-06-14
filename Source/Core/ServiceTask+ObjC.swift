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
    @discardableResult  @objc public func setJSONEncodedParametersObjC(_ parameters: [String: AnyObject]) -> Self {
        // TODO: `let _ =` should not be needed here. @discardableResult does not appear to be resolving the unused Self warning
        let _ = setParameters(parameters, encoding: .json)
        return self
    }
    
    /**
     Set request parameter values and configure them to be Percent-encoded.
     
     This method is designed to be called from Obj-C only. Please use
     `setParameters(parameters: [String: AnyObject], encoding: Request.ParameterEncoding)`
     when calling from Swift.
     
     - parameter parameters: Request parameter values.
    */
    @discardableResult  @objc public func setPercentEncodedParametersObjC(_ parameters: [String: AnyObject]) -> Self {
        // TODO: `let _ =` should not be needed here. @discardableResult does not appear to be resolving the unused Self warning
        let _ = setParameters(parameters, encoding: .percent)
        return self
    }
        
    /**
     Configure the request parameters to be JSON-encoded.
    
     This method is designed to be called from Obj-C only. Please use
     `setParameterEncoding(encoding: .JSON)` when calling
     from Swift.
    */
    @discardableResult  @objc public func setJSONParameterEncodingObjC() -> Self {
        // TODO: `let _ =` should not be needed here. @discardableResult does not appear to be resolving the unused Self warning
        let _ = setParameterEncoding(.json)
        return self
    }
    
    /**
     Configure the request parameters to be Percent-encoded.
     
     This method is designed to be called from Obj-C only. Please use
     `setParameterEncoding(encoding: .Percent)` when calling
     from Swift.
    */
    @discardableResult @objc public func setPercentParameterEncodingObjC() -> Self {
        // TODO: `let _ =` should not be needed here. @discardableResult does not appear to be resolving the unused Self warning
        let _ = setParameterEncoding(.percent)
        return self
    }
}

// MARK: - Obj-C Interop for Response Handler API

extension ServiceTask {
    
    /// Response handler type for Obj-C
    typealias ObjCResponseHandler = (Data?, URLResponse?) -> ObjCHandlerResult?

    /**
     Add a response handler to be called on a background thread after a successful
     response has been received. This method is designed to be called from Obj-C.
     Please use `response(handler: ResponseProcessingHandler) -> Self` when calling
     from Swift.
     
     - parameter handler: Response handler to execute upon receiving a response.
     - returns: Self instance to support chaining.
     */
    @objc public func responseObjC(_ handler: (Data?, URLResponse?) -> ObjCHandlerResult?) -> Self {
        return response { data, response in
            return ServiceTaskResult(objCHandlerResult: handler(data, response))
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
    @objc public func responseJSONObjC(_ handler: (AnyObject, URLResponse?) -> ObjCHandlerResult?) -> Self {
        return responseJSON { json, response in
            return ServiceTaskResult(objCHandlerResult: handler(json, response))
        }
    }
    
    /**
     Add a response handler to transform a (non-error) result produced by an earlier
     response handler.

     This method is designed to be called from Obj-C. Please use
     `transform(handler: ResultTransformer)` when calling from Swift.

     The handler can return any type of service task result, `.Empty`, `.Value` or
     `.Failure`. The result is propagated to later response handlers.

     - parameter handler: Transformation handler to execute.
     - returns: Self instance to support chaining.
     */
    @objc public func transformObjC(_ handler: (AnyObject?) -> ObjCHandlerResult?) -> Self {
        return transform { value in
            return ServiceTaskResult(objCHandlerResult: handler(value as! AnyObject?))
        }
    }

    /**
     Add a response handler to recover from an error produced by an earlier response
     handler.
     
     This method is designed to be called from Obj-C. Please use
     `recover(handler: ErrorRecoveryHandler)` when calling from Swift.

     The handler can return either a `.Value` or `.Empty`, indicating it was able to
     recover from the error, or an `.Failure`, indicating that it was not able to
     recover. The result is propagated to later response handlers.

     - parameter handler: Recovery handler to execute when an error occurs.
     - returns: Self instance to support chaining.
     */
    @objc public func recoverObjC(_ handler: (NSError) -> ObjCHandlerResult?) -> Self {
        return recover { error in
            return ServiceTaskResult(objCHandlerResult: handler(error as NSError))
        }
    }

    /**
     Add a response handler to be called if a request results in an error.
     
     This method is designed to be called from Obj-C. Please use 
     `responseError(handler: ErrorHandler)` when calling from Swift.
     
     - parameter handler: Error handler to execute when an error occurs.
     - returns: Self instance to support chaining.
    */
    @objc public func responseErrorObjC(_ handler: (NSError) -> Void) -> Self {
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
    @objc public func updateUIObjC(_ handler: (AnyObject?) -> Void) -> Self {
        return updateUI { value in
            handler(value as! AnyObject?)
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
    @objc public func updateErrorUIObjC(_ handler: (NSError) -> Void) -> Self {
        return updateErrorUI { error in
            handler(error as NSError)
        }
    }
}
