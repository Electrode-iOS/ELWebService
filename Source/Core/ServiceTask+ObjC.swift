//
//  ServiceTask+ObjC.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 2/2/16.
//  Copyright © 2016 WalmartLabs. All rights reserved.
//

import Foundation

/// Response handler methods that add Obj-C interopability 
extension ServiceTask {
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
            return ServiceTaskResult(objCHandlerResult: handler(data, response))
        }
    }
    
    /**
     Add a response handler to serialize the response body as a JSON object. The
     handler will be dispatched to a background thread.
     
     - parameter handler: Response handler to execute upon receiving a response.
     - returns: Self instance to support chaining.
     */
    @objc public func responseJSONObjC(handler: (AnyObject) -> ObjCHandlerResult?) -> Self {
        return responseJSON { json in
            return ServiceTaskResult(objCHandlerResult: handler(json))
        }
    }
    
    // TODO: write docs
    @objc public func responseErrorObjC(handler: (NSError) -> Void) -> Self {
        return responseError { error in
            handler(error as NSError)
        }
    }
    
    // TODO: write docs
    @objc public func updateUIObjC(handler: (AnyObject?) -> Void) -> Self {
        return updateUI { value in
            if let value = value as? AnyObject {
                handler(value)
            }
        }
    }
    
    // TODO: write docs
    @objc public func updateErrorUIObjC(handler: (NSError) -> Void) -> Self {
        return updateErrorUI { error in
            handler(error as NSError)
        }
    }
}
