//
//  ServiceTask.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 2/25/15.
//  Copyright (c) 2015 WalmartLabs. All rights reserved.
//

import Foundation

/**
 A subclass of `SessionTask` that provides a request building API.
 This API is only intended for backward compatibility. It is recommended
 to build a `Request` independently from `ServiceTask` and send it with `SessionTask`
*/
@objc public final class ServiceTask: SessionTask {
    fileprivate var request: Request
    
    // MARK: Intialization
    
    /**
     Initialize a ServiceTask value to fulfill an HTTP request.
    
     - parameter urlRequestEncoder: Value responsible for encoding a NSURLRequest
       instance to send.
     - parameter dataTaskSource: Object responsible for creating a
       NSURLSessionDataTask used to send the NSURLRequset.
    */
    init(request: Request, session: Session) {
        self.request = request
        super.init(urlRequestEncodable: request, session: session)
    }
}

// MARK: - Request API

extension ServiceTask {
    /// TODO: Needs docs
    @discardableResult public func setParameters(_ parameters: [String: Any], encoding: Request.ParameterEncoding? = nil) -> Self {
        request.parameters = parameters
        request.parameterEncoding = encoding ?? .percent
        
        return self
    }
    
    /// TODO: Needs docs
    @discardableResult public func setBody(_ data: Data) -> Self {
        request.body = data
        return self
    }
    
    /// TODO: Needs docs
    @discardableResult public func setJSON(_ json: Any) -> Self {
        request.contentType = Request.ContentType.json
        request.body = try? JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions(rawValue: 0))
        return self
    }
    
    /// TODO: Needs docs
    @discardableResult public func setHeaders(_ headers: [String: String]) -> Self {
        request.headers = headers
        return self
    }
    
    /// TODO: Needs docs
    @discardableResult public func setHeaderValue(_ value: String, forName name: String) -> Self {
        request.headers[name] = value
        return self
    }
    
    /// TODO: Needs docs
    @discardableResult public func setCachePolicy(_ cachePolicy: NSURLRequest.CachePolicy) -> Self {
        request.cachePolicy = cachePolicy
        return self
    }
    
    /// TODO: Needs docs
    @discardableResult public func setParameterEncoding(_ encoding: Request.ParameterEncoding) -> Self {
        request.parameterEncoding = encoding
        return self
    }
    
    /// Sets the key/value pairs that will be encoded as the query in the URL.
    @discardableResult public func setQueryParameters(_ parameters: [String: Any]) -> Self {
        request.queryParameters = parameters
        return self
    }
    
    /**
     Sets the key/value pairs that will be encoded as the query in the URL.
     
     - parameter parameters: Query parameter data.
     - parameter handler: A callback that is invoked when the query parameters are encoded in the URL. Enables you to define custom encoding behavior.
     - returns: Self instance to support chaining.
    */
    @discardableResult public func setQueryParameters(_ parameters: [String: Any], encoder: @escaping QueryParameterEncoder) -> Self {
        setQueryParameters(parameters)
        request.queryParameterEncoder = encoder
        return self
    }
    
    /// Sets the key/value pairs that are encoded as form data in the request body.
    @discardableResult public func setFormParameters(_ parameters: [String: Any]) -> Self {
        request.formParameters = parameters
        return self
    }
}
