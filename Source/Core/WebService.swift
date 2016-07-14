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
    /// Base URL of the web service.
    public let baseURL: URL
    
    public var session: Session = URLSession.shared()
    internal private(set) weak var passthroughDelegate: ServicePassthroughDelegate?
    
    // MARK: Initialization
    
    /**
     Initialize a web service value.
     - parameter baseURLString: URL string to use as the base URL of the web service.
    */
    public init(baseURL: URL) {
        self.baseURL = baseURL
        
        super.init()
        
        if let passthroughDataSource = self as? ServicePassthroughDataSource {
            passthroughDelegate = passthroughDataSource.servicePassthroughDelegate
        }
    }
    
    public convenience init(baseURL: URL, passthroughDelegate: ServicePassthroughDelegate) {
        self.init(baseURL: baseURL)
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
        return serviceTask(request: request(.get, path: path))
    }

    /**
    Create a service task for a `POST` HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - returns: A ServiceTask instance that refers to the lifetime of processing
    a given request.
    */
    public func POST(_ path: String) -> ServiceTask {
        
        return serviceTask(request: request(.post, path: path))
    }
    
    /**
    Create a service task for a PUT HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - returns: A ServiceTask instance that refers to the lifetime of processing
    a given request.
    */
    public func PUT(_ path: String) -> ServiceTask {
        return serviceTask(request: request(.put, path: path))
    }
    
    /**
    Create a service task for a DELETE HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - returns: A ServiceTask instance that refers to the lifetime of processing
    a given request.
    */
    public func DELETE(_ path: String) -> ServiceTask {
        return serviceTask(request: request(.delete, path: path))
    }
    
    /**
    Create a service task for a HEAD HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - returns: A ServiceTask instance that refers to the lifetime of processing
    a given request.
    */
    public func HEAD(_ path: String) -> ServiceTask {
        return serviceTask(request: request(.head, path: path))
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
    public func request(_ method: ServiceRequest.Method, path: String) -> ServiceRequest {
        return ServiceRequest(method, url: absoluteURL(string: path)!)
    }
    
    /// Create a service task to fulfill a given request.
    public func serviceTask(request: ServiceRequestProtocol) -> ServiceTask {
        let task = ServiceTask(request: request, session: self)
        task.passthroughDelegate = passthroughDelegate
        return task
    }
}

// MARK: - Session API

extension WebService: Session {
    typealias TaskHandler = (Data?, URLResponse?, NSError?) -> Void
    
    public func dataTask(request: URLRequestConvertible, completion: (Data?, URLResponse?, NSError?) -> Void) -> DataTask {
        return dataTask(session: session, request: request, completion: completion)
    }
    
    func dataTask(session: Session, request: URLRequestConvertible, completion: (Data?, URLResponse?, NSError?) -> Void) -> DataTask {
        let urlRequest = canonicalRequest(request: request).urlRequest
        
        passthroughDelegate?.requestSent(urlRequest)
        return session.dataTask(request: urlRequest, completion: onTaskCompletion(urlRequest, completionHandler: completion))
    }
    
    func canonicalRequest(request: URLRequestConvertible) -> URLRequestConvertible {
        let urlRequest = request.urlRequest
        
        if let modifiedRequest = passthroughDelegate?.modifiedRequest(urlRequest) {
            return modifiedRequest
        }
        
        return urlRequest
    }
    
    func onTaskCompletion(_ request: URLRequestConvertible, completionHandler: TaskHandler) -> TaskHandler {
        return { data, response, error in
            self.passthroughDelegate?.responseReceived(response, data: data, request: request.urlRequest, error: error)
            completionHandler(data, response, error)
        }
    }
}

// MARK: - Constructing the Fully-Qualified URL

extension WebService {
    /**
     Return an absolute URL string relative to the baseURL value.
    
     - parameter string: URL string.
     - returns: An absoulte URL string relative to the value of `baseURLString`.
    */
    public func absoluteURL(string: String) -> URL? {
        return URL(string: string, relativeTo: baseURL)?.absoluteURL
    }
}
