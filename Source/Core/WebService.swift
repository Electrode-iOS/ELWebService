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
    @objc public let baseURL: URL?

    /// Base URL of the web service (as String).
    @objc public var baseURLString: String {
        return baseURL?.absoluteString ?? ""
    }

    /**
     Default session that will be used by instances of WebService for their
     subsequent communications. This is broken out separately from the per-instance
     session so that application global configuration can be done, such as setting
     additionalHTTPHeaders, that will then apply throughout the application.
     */
    public static var defaultSession: Session = URLSession.shared
    
    /**
     The session is a lazy variable so that in the time between the creation of
     a WebService instance and the first request made to that service the
     defaultSession could be replaced and the instance would still use that
     default value rather than requiring the defaultSession to be configured
     before the WebService instance is even created.
     */
    public var session: Session {
        get {
            return _session
        }
        set {
            _session = newValue
            if let _ = _session as? MockSession {
                self.passthroughDelegate = nil
            }
        }
    }
    private lazy var _session: Session = WebService.defaultSession
    
    public weak var passthroughDelegate: ServicePassthroughDelegate?

    // MARK: Initialization

    /**
     Initialize a web service value.
     - parameter baseURL: URL to use as the base URL of the web service.
     */
    @objc public init(baseURL: URL? = nil) {
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
    @objc convenience public init(baseURLString: String) {
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
    @objc public func GET(_ path: String) -> ServiceTask {
        return request(.GET, path: path)
    }

    /**
    Create a service task for a `POST` HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - returns: A ServiceTask instance that refers to the lifetime of processing
    a given request.
    */
    @objc public func POST(_ path: String) -> ServiceTask {
        return request(.POST, path: path)
    }

    /**
    Create a service task for a PUT HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - returns: A ServiceTask instance that refers to the lifetime of processing
    a given request.
    */
    @objc public func PUT(_ path: String) -> ServiceTask {
        return request(.PUT, path: path)
    }

    /**
     Create a service task for a PATCH HTTP request.
     
     - parameter path: Request path. The value can be relative to the base URL string
     or absolute.
     - returns: A ServiceTask instance that refers to the lifetime of processing
     a given request.
     */
    @objc public func PATCH(path: String) -> ServiceTask {
        return request(.PATCH, path: path)
    }

    /**
    Create a service task for a DELETE HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - returns: A ServiceTask instance that refers to the lifetime of processing
    a given request.
    */
    @objc public func DELETE(_ path: String) -> ServiceTask {
        return request(.DELETE, path: path)
    }

    /**
    Create a service task for a HEAD HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - returns: A ServiceTask instance that refers to the lifetime of processing
    a given request.
    */
    @objc public func HEAD(_ path: String) -> ServiceTask {
        return request(.HEAD, path: path)
    }

    /**
     Create a service task to fulfill a service request. By default the service
     task is started by calling resume(). To prevent service tasks from
     automatically resuming set the `startTasksImmediately` of the WebService
     value to `false`.
     
     - parameter method: HTTP request method.
     - parameter path: Request path. The value can be relative to the base URL string
     or absolute.
     - returns: A ServiceTask instance that refers to the lifetime of processing
     a given request.
     */
    public func request(_ method: Request.Method, path: String) -> ServiceTask {
        return serviceTask(request: Request(method, url: absoluteURL(path)))
    }

    /// Create a service task to fulfill a given request.
    func serviceTask(request: Request) -> ServiceTask {
        let task = ServiceTask(request: request, session: self)
        task.passthroughDelegate = passthroughDelegate
        return task
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
    @objc dynamic public func absoluteURL(_ string: String) -> URL {
        return constructURL(string, relativeToURL: baseURL)!
    }

    /**
     Return an absolute URL string relative to the baseURLString value.
    
     - parameter string: URL string.
     - returns: An absolute URL string relative to the value of `baseURLString`.
    */
    @objc dynamic public func absoluteURLString(_ string: String) -> String {
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
