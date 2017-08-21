//
//  WebService.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 2/16/15.
//  Copyright (c) 2015 WalmartLabs. All rights reserved.
//

import Foundation

/**
 A `WebService` value provides a concise API for encoding a NSURLRequest object
 and processing the resulting `NSURLResponse` object.
*/
@objc public final class WebService: NSObject {
    /**
        Base URL of the web service.
        If the base URL is nil, the path is interpreted as an absolute URL.
     */
    public let baseURL: URL?

    /// Base URL of the web service (as String).
    public var baseURLString: String {
        return baseURL?.absoluteString ?? ""
    }

    public var session: Session = URLSession.shared
    public weak var passthroughDelegate: ServicePassthroughDelegate?

    // MARK: Initialization

    /**
     Initialize a web service value.
     - parameter baseURL: URL to use as the base URL of the web service.
     */
    public init(baseURL: URL? = nil) {
        self.baseURL = baseURL
        super.init()
        if let passthroughDataSource = self as? ServicePassthroughDataSource {
            passthroughDelegate = passthroughDataSource.servicePassthroughDelegate
        }
    }

    /**
     Initialize a web service value.
     - parameter baseURL: URL to use as the base URL of the web service.
     - parameter passthroughDelegate: ServicePassthroughDelegate to use for hooking into service request/response events.
     */
    public convenience init(baseURL: URL?, passthroughDelegate: ServicePassthroughDelegate) {
        self.init(baseURL: baseURL)
        self.passthroughDelegate = passthroughDelegate
    }

    /**
     Initialize a web service value.
     - parameter baseURLString: URL string to use as the base URL of the web service.
     - note:
     This initializer can cause a runtime crash if the `baseURLString` cannot convert to a URL.
     It is better to use `init(baseURL: URL)` in place of this.
    */
    convenience public init(baseURLString: String) {
        let baseURL = URL(string: baseURLString)
        self.init(baseURL: baseURL)
    }

    /**
     Initialize a web service value.
     - parameter baseURL: URL to use as the base URL of the web service.
     - parameter passthroughDelegate: ServicePassthroughDelegate to use for hooking into service request/response events.
     - note:
     This initializer can cause a runtime crash if the `baseURLString` cannot convert to a URL.
     It is better to use `init(baseURL: URL, passthroughDelegate: ServicePassthroughDelegate)` in place of this.
     */
    public convenience init(baseURLString: String, passthroughDelegate: ServicePassthroughDelegate) {
        self.init(baseURLString: baseURLString)
        self.passthroughDelegate = passthroughDelegate
    }
}

// MARK: - Request API

extension WebService {
    /**
    Create a service task for a `GET` HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - returns: A ServiceTask instance that refers to the lifetime of processing
    a given request.
    */
    public func GET(_ path: String) -> ServiceTask {
        return serviceTask(.GET, path: path)
    }

    /**
    Create a service task for a `POST` HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - returns: A ServiceTask instance that refers to the lifetime of processing
    a given request.
    */
    public func POST(_ path: String) -> ServiceTask {
        return serviceTask(.POST, path: path)
    }

    /**
    Create a service task for a PUT HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - returns: A ServiceTask instance that refers to the lifetime of processing
    a given request.
    */
    public func PUT(_ path: String) -> ServiceTask {
        return serviceTask(.PUT, path: path)
    }

    /**
     Create a service task for a PATCH HTTP request.
     
     - parameter path: Request path. The value can be relative to the base URL string
     or absolute.
     - returns: A ServiceTask instance that refers to the lifetime of processing
     a given request.
     */
    public func PATCH(path: String) -> ServiceTask {
        return serviceTask(.PATCH, path: path)
    }

    /**
    Create a service task for a DELETE HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - returns: A ServiceTask instance that refers to the lifetime of processing
    a given request.
    */
    public func DELETE(_ path: String) -> ServiceTask {
        return serviceTask(.DELETE, path: path)
    }

    /**
    Create a service task for a HEAD HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - returns: A ServiceTask instance that refers to the lifetime of processing
    a given request.
    */
    public func HEAD(_ path: String) -> ServiceTask {
        return serviceTask(.HEAD, path: path)
    }

    /**
     Create a service task to fulfill a service request.
     
     - parameter method: HTTP request method.
     - parameter path: Request path. The value can be relative to the base URL string
     or absolute.
     - returns: A request.
    */
    public func request(_ method: Request.Method, path: String) -> Request {
        return Request(method, url: absoluteURL(path))
    }
    
    /**
     Create a service task to fulfill a service request.
     
     - parameter method: HTTP request method.
     - parameter path: Request path. The value can be relative to the base URL string
     or absolute.
     - returns: A ServiceTask instance that refers to the lifetime of processing
     a given request.
    */
    public func serviceTask(request: Request) -> ServiceTask {
        let task = ServiceTask(request: request, session: self)
        task.passthroughDelegate = passthroughDelegate
        return task
    }
    
    public func sessionTask(request: URLRequestEncodable) -> SessionTask {
        let task = SessionTask(urlRequestEncodable: request, session: self)
        task.passthroughDelegate = passthroughDelegate
        return task
    }
    
    func serviceTask(_ method: Request.Method, path: String) -> ServiceTask {
        return serviceTask(request: request(method, path: path))
    }
}

// MARK: - Session API

extension WebService: Session {
    typealias TaskHandler = (Data?, URLResponse?, Error?) -> Void

    public func dataTask(request: URLRequestEncodable, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> DataTask {
        return dataTask(session: session, request: request, completion: completion)
    }

    func dataTask(session: Session, request: URLRequestEncodable, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> DataTask {
        let urlRequest = canonicalRequest(request: request).urlRequestValue

        passthroughDelegate?.requestSent(urlRequest)
        return session.dataTask(request: urlRequest, completion: onTaskCompletion(urlRequest, completionHandler: completion))
    }

    func canonicalRequest(request: URLRequestEncodable) -> URLRequestEncodable {
        let urlRequest = request.urlRequestValue

        if let modifiedRequest = passthroughDelegate?.modifiedRequest(urlRequest) {
            return modifiedRequest
        }

        return urlRequest
    }

    func onTaskCompletion(_ request: URLRequestEncodable, completionHandler: @escaping TaskHandler) -> TaskHandler {
        return { data, response, error in
            self.passthroughDelegate?.responseReceived(response, data: data, request: request.urlRequestValue, error: error)
            completionHandler(data, response, error)
        }
    }
}

// MARK: - URL String Construction

extension WebService {
    /**
     Return an absolute URL string relative to the baseURLString value.

     - parameter string: URL string.
     - returns: An absolute URL string relative to the value of `baseURLString`.
     */
    dynamic public func absoluteURL(_ string: String) -> URL {
        return constructURL(string, relativeToURL: baseURL)!
    }

    /**
     Return an absolute URL string relative to the baseURLString value.
    
     - parameter string: URL string.
     - returns: An absolute URL string relative to the value of `baseURLString`.
    */
    dynamic public func absoluteURLString(_ string: String) -> String {
        return absoluteURL(string).absoluteString
    }

    /**
     Return an absolute URL string relative to the baseURLString value.

     - parameter string: URL string value.
     - parameter relativeURLString: Value of relative URL string.
     - returns: An absolute URL string.
     */
    func constructURL(_ string: String, relativeToURL: URL?) -> URL? {
        guard string != "" else { // if string is empty then just return the baseURL
            return baseURL
        }
        let url = URL(string: string, relativeTo: relativeToURL)
        return url
    }
}
