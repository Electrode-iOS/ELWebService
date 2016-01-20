//
//  WebService.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 2/16/15.
//  Copyright (c) 2015 TheHolyGrail. All rights reserved.
//

import Foundation

/**
 A `WebService` value provides a concise API for encoding a NSURLRequest object
 and processing the resulting `NSURLResponse` object.
*/
public final class WebService {
    /// Base URL of the web service.
    public let baseURLString: String
    
    /**
     Type responsible for creating a `NSURLSessionDataTask` based on a
     `NSURLRequest`.
    */
    public var dataTaskSource: SessionDataTaskDataSource?
    
    private var serviceDataTaskSource: SessionDataTaskDataSource {
        if let dataTaskSource = dataTaskSource {
            return dataTaskSource
        } else {
            return NSURLSession.sharedSession()
        }
    }
    
    // MARK: Initialization
    
    /**
     Initialize a web service value.
     - parameter baseURLString: URL string to use as the base URL of the web service.
    */
    public init(baseURLString: String) {
        self.baseURLString = baseURLString
    }
}

// MARK: - Web Service API

extension WebService {
    /**
    Create a service task for a `GET` HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - parameter parameters: Optional request parameters. The data is URL encoded as
    a query string for `GET` requests.
    - parameter options: Endpoint options used to configure the HTTP request.
    - returns: A ServiceTask instance that refers to the lifetime of processing
    a given request.
    */
    public func GET(path: String) -> ServiceTask {
        return request(.GET, path: path)
    }

    /**
    Create a service task for a `POST` HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - parameter parameters: Optional request parameters. The data is URL encoded and
    is set as the HTTP body for `POST` requests.
    - parameter options: Endpoint options used to configure the HTTP request.
    - returns: A ServiceTask instance that refers to the lifetime of processing
    a given request.
    */
    public func POST(path: String) -> ServiceTask {
        return request(.POST, path: path)
    }
    
    /**
    Create a service task for a PUT HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - parameter parameters: Optional request parameters. The data is URL encoded and
    is set as the HTTP body for `PUT` requests.
    - parameter options: Endpoint options used to configure the HTTP request.
    - returns: A ServiceTask instance that refers to the lifetime of processing
    a given request.
    */
    public func PUT(path: String) -> ServiceTask {
        return request(.PUT, path: path)
    }
    
    /**
    Create a service task for a DELETE HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - parameter parameters: Optional request parameters. The data is URL encoded and
    is set as the HTTP body for `DELETE` requests.
    - parameter options: Endpoint options used to configure the HTTP request.
    - returns: A ServiceTask instance that refers to the lifetime of processing
    a given request.
    */
    public func DELETE(path: String) -> ServiceTask {
        return request(.DELETE, path: path)
    }
    
    /**
    Create a service task for a HEAD HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - parameter parameters: Optional request parameters. The data is URL encoded as
    a query string for `HEAD` requests.
    - parameter options: Endpoint options used to configure the HTTP request.
    - returns: A ServiceTask instance that refers to the lifetime of processing
    a given request.
    */
    public func HEAD(path: String) -> ServiceTask {
        return request(.HEAD, path: path)
    }
}

extension WebService {
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
    func request(method: Request.Method, path: String) -> ServiceTask {
        let request = Request(method, url: absoluteURLString(path))
        return ServiceTask(request: request, dataTaskSource: serviceDataTaskSource)
    }
}

// MARK: - URL String Construction

extension WebService {
    /**
     Return an absolute URL string relative to the baseURLString value.
    
     - parameter string: URL string.
     - returns: An absoulte URL string relative to the value of `baseURLString`.
    */
    public func absoluteURLString(string: String) -> String {
        return constructURLString(string, relativeToURLString: baseURLString)
    }
    
    /**
     Return an absolute URL string relative to the baseURLString value.
    
     - parameter string: URL string value.
     - parameter relativeURLString: Value of relative URL string.
     - returns: An absolute URL string.
    */
    func constructURLString(string: String, relativeToURLString relativeURLString: String) -> String {
        let relativeURL = NSURL(string: relativeURLString)
        return NSURL(string: string, relativeToURL: relativeURL)!.absoluteString
    }
}
