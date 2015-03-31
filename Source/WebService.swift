//
//  WebService.swift
//  Swallow
//
//  Created by Angelo Di Paolo on 2/16/15.
//  Copyright (c) 2015 TheHolyGrail. All rights reserved.
//

import Foundation

public struct WebService {
    
    // MARK: NSURLSessionDataTask
    
    private struct DataTaskDataSource: SessionDataTaskDataSource {
        func dataTaskWithRequest(request: NSURLRequest, completion: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask {
            let session = NSURLSession.sharedSession()
            let task = session.dataTaskWithRequest(request, completionHandler: completion);
            return task
        }
    }
    
    // MARK: Endpoint Configuration
    
    public struct EndpointOptions {
        public var parameterEncoding: Request.ParameterEncoding = .Percent
        public var shouldCache: Bool = false
        public var cacheTTL: Int? // some default?
        
        public init() {
            
        }
    }
    
    public let baseURLString: String
    public var startTasksImmediately = true
    public var dataTaskSource: SessionDataTaskDataSource = DataTaskDataSource()
    
    // MARK: Initialization
    
    public init(baseURLString: String) {
        self.baseURLString = baseURLString
    }
    
    // MARK: Web Service API

    /**
     Create a service task for a GET HTTP request.
    */
    public func GET(path: String, parameters: [String : AnyObject]? = nil, options: EndpointOptions? = nil) -> ServiceTask {
        return request(.GET, path: path, parameters: parameters, options: options)
    }

    public func POST(path: String, parameters: [String : AnyObject]? = nil, options: EndpointOptions? = nil) -> ServiceTask {
        return request(.POST, path: path, parameters: parameters, options: options)
    }
    
    public func PUT(path: String, parameters: [String : AnyObject]? = nil, options: EndpointOptions? = nil) -> ServiceTask {
        return request(.PUT, path: path, parameters: parameters, options: options)
    }
    
    public func DELETE(path: String, parameters: [String : AnyObject]? = nil, options: EndpointOptions? = nil) -> ServiceTask {
        return request(.DELETE, path: path, parameters: parameters, options: options)
    }
    
    public func HEAD(path: String, parameters: [String : AnyObject]? = nil, options: EndpointOptions? = nil) -> ServiceTask {
        return request(.HEAD, path: path, parameters: parameters, options: options)
    }
    
    // MARK: ServiceTask
    
    /**
     Create a service task to fulfill a service request. By default the service 
     task is started by calling resume(). To prevent service tasks from 
     automatically resuming set the `startTasksImmediately` of the WebService
     value to `false`.
    */
    private func request(method: Request.Method, path: String, parameters: [String : AnyObject]? = nil, options: EndpointOptions? = nil) -> ServiceTask {
        let urlString = absoluteURLString(requestPath(relativePath: path))
        let request = constructRequest(method, url: urlString, parameters: parameters, options: options)
        return serviceTask(urlRequestEncoder: request)
    }
    
    private func serviceTask(#urlRequestEncoder: URLRequestEncodable) -> ServiceTask {
        let task = ServiceTask(urlRequestEncoder: urlRequestEncoder, dataTaskSource: dataTaskSource)
        
        if startTasksImmediately {
            task.resume()
        }
        
        return task
    }
    
    // MARK: Request Path
    
    /**
     Override to customize how all web service request paths are constructed. 
     Useful for prefixing request endpoint paths.
    */
    public func requestPath(#relativePath: String) -> String {
        return relativePath
    }
    
    // MARK: Request
    
    /**
     Override to customize how all web service request objects are constructed.
    */
    public func constructRequest(method: Request.Method, url: String, parameters: [String : AnyObject]? = nil, options: EndpointOptions? = nil) -> Request {
        var request = Request(method, url: url)
        
        if let parameters = parameters {
            request.parameters = parameters
        }
        
        if let options = options {
            request.parameterEncoding = options.parameterEncoding
        }
        
        return request
    }
}

// MARK: - URL String Construction

extension WebService: URLStringConstructible {
    
    public func absoluteURLString(string: String) -> String {
        return constructURLString(string, relativeToURLString: baseURLString)
    }
    
    public func constructURLString(string: String, relativeToURLString relativeURLString: String) -> String {
        let relativeURL = NSURL(string: relativeURLString)
        return NSURL(string: string, relativeToURL: relativeURL)!.absoluteString!
    }
}

// MARK: - Protocols

public protocol SessionDataTaskDataSource {
    func dataTaskWithRequest(request: NSURLRequest, completion: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask
}

public protocol URLStringConstructible {
    func constructURLString(string: String, relativeToURLString: String) -> String
}
