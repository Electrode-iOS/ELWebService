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
    
    private struct DataTaskCreatorDelegate: DataTaskConstructible {
        func constructDataTask(request: NSURLRequest, completion: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask {
            let session = NSURLSession.sharedSession()
            let task = session.dataTaskWithRequest(request, completionHandler: completion);
            return task
        }
    }
    
    // MARK: Endpoint Configuration
    
    public struct EndpointOptions {
        var parameterEncoding: Request.ParameterEncoding = .URL
        var shouldCache: Bool = false
        var cacheTTL: Int? // some default?
    }
    
    public let baseURLString: String
    public var startTasksImmediately = true
    public var dataTaskCreator: DataTaskConstructible = DataTaskCreatorDelegate()
    
    // MARK: Initialization
    
    public init(baseURLString: String) {
        self.baseURLString = baseURLString
    }
    
    // MARK: Request API

    /**
     Create a service task for a GET HTTP request.
    */
    public func GET(path: String, parameters: Dictionary<String, String>? = nil, options: EndpointOptions? = nil) -> ServiceTask {
        return request(.GET, path: path, parameters: parameters, options: options)
    }

    public func POST(path: String, parameters: Dictionary<String, String>? = nil, options: EndpointOptions? = nil) -> ServiceTask {
        return request(.POST, path: path, parameters: parameters, options: options)
    }
    
    public func PUT(path: String, parameters: Dictionary<String, String>? = nil, options: EndpointOptions? = nil) -> ServiceTask {
        return request(.PUT, path: path, parameters: parameters, options: options)
    }
    
    public func DELETE(path: String, parameters: Dictionary<String, String>? = nil, options: EndpointOptions? = nil) -> ServiceTask {
        return request(.DELETE, path: path, parameters: parameters, options: options)
    }
    
    public func HEAD(path: String, parameters: Dictionary<String, String>? = nil, options: EndpointOptions? = nil) -> ServiceTask {
        return request(.HEAD, path: path, parameters: parameters, options: options)
    }
    
    // MARK: ServiceTask
    
    /**
     Create a service task to fulfill a service request. By default the service 
     task is started by calling resume(). To prevent service tasks from 
     automatically resuming set the `startTasksImmediately` of the WebService
     value to `false`.
    */
    private func request(method: Request.Method, path: String, parameters: Dictionary<String, String>? = nil, options: EndpointOptions?) -> ServiceTask {
        // TODO: use endpoint options to configure HTTP request
        let requestPath = constructRequestPath(relativePath: path)
        let absoluteURLString = constructURLString(requestPath, relativeToURLString: baseURLString)
        let request = constructRequest(method, url: absoluteURLString)
        return serviceTask(urlRequestEncoder: request)
    }
    
    private func serviceTask(#urlRequestEncoder: URLRequestEncodable) -> ServiceTask {
        let task = ServiceTask(urlRequestEncoder: urlRequestEncoder, dataTaskCreator: dataTaskCreator)
        
        if startTasksImmediately {
            task.resume()
        }
        
        return task
    }
    
    // MARK: Request Path Construction
    
    /**
     Override to customize how all web service request paths are constructed. 
     Useful for prefixing request endpoint paths.
    */
    public func constructRequestPath(relativePath aRelativePath: String) -> String {
        return aRelativePath
    }
    
    // MARK: Request
    
    /**
     Override to customize how all web service request objects are constructed.
    */
    public func constructRequest(method: Request.Method, url: String) -> Request {
        return Request(method, url: url)
    }
}

// MARK: - URL String Construction

extension WebService: URLStringConstructible {
    
    public func constructURLString(string: String, relativeToURLString relativeURLString: String) -> String {
        let relativeURL = NSURL(string: relativeURLString)
        return NSURL(string: string, relativeToURL: relativeURL)!.absoluteString!
    }
}

// MARK: - Protocols

public protocol DataTaskConstructible {
    func constructDataTask(request: NSURLRequest, completion: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask
}

public protocol URLStringConstructible {
    func constructURLString(string: String, relativeToURLString: String) -> String
}
