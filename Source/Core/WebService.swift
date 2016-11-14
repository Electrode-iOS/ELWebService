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
    public let baseURLString: String
    
    public var session: Session = URLSession.shared
    internal fileprivate(set) weak var passthroughDelegate: ServicePassthroughDelegate?
    
    // MARK: Initialization
    
    /**
     Initialize a web service value.
     - parameter baseURLString: URL string to use as the base URL of the web service.
    */
    public init(baseURLString: String) {
        self.baseURLString = baseURLString
        
        super.init()
        
        if let passthroughDataSource = self as? ServicePassthroughDataSource {
            passthroughDelegate = passthroughDataSource.servicePassthroughDelegate
        }
    }
    
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
        return request(.GET, path: path)
    }

    /**
    Create a service task for a `POST` HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - returns: A ServiceTask instance that refers to the lifetime of processing
    a given request.
    */
    public func POST(_ path: String) -> ServiceTask {
        return request(.POST, path: path)
    }
    
    /**
    Create a service task for a PUT HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - returns: A ServiceTask instance that refers to the lifetime of processing
    a given request.
    */
    public func PUT(_ path: String) -> ServiceTask {
        return request(.PUT, path: path)
    }
    
    /**
     Create a service task for a PATCH HTTP request.
     
     - parameter path: Request path. The value can be relative to the base URL string
     or absolute.
     - returns: A ServiceTask instance that refers to the lifetime of processing
     a given request.
     */
    public func PATCH(path: String) -> ServiceTask {
        return request(.PATCH, path: path)
    }
    
    /**
    Create a service task for a DELETE HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - returns: A ServiceTask instance that refers to the lifetime of processing
    a given request.
    */
    public func DELETE(_ path: String) -> ServiceTask {
        return request(.DELETE, path: path)
    }
    
    /**
    Create a service task for a HEAD HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - returns: A ServiceTask instance that refers to the lifetime of processing
    a given request.
    */
    public func HEAD(_ path: String) -> ServiceTask {
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
    func request(_ method: Request.Method, path: String) -> ServiceTask {
        return serviceTask(request: Request(method, url: absoluteURLString(path)))
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
     - returns: An absoulte URL string relative to the value of `baseURLString`.
    */
    public func absoluteURLString(_ string: String) -> String {
        return constructURLString(string, relativeToURLString: baseURLString)
    }
    
    /**
     Return an absolute URL string relative to the baseURLString value.
    
     - parameter string: URL string value.
     - parameter relativeURLString: Value of relative URL string.
     - returns: An absolute URL string.
    */
    func constructURLString(_ string: String, relativeToURLString relativeURLString: String) -> String {
        let relativeURL = URL(string: relativeURLString)
        return URL(string: string, relativeTo: relativeURL)!.absoluteString
    }
}
