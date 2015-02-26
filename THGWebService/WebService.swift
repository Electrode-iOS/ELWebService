//
//  WebService.swift
//  Swallow
//
//  Created by Angelo Di Paolo on 2/16/15.
//  Copyright (c) 2015 TheHolyGrail. All rights reserved.
//

import Foundation

protocol DataTaskConstructible {
    func constructDataTask(request: NSURLRequest, completion: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask
}

protocol URLStringConstructible {
    func constructURLString(string: String, relativeToURLString: String) -> String
}

public struct WebService {
    
    private struct DataTaskCreatorDelegate: DataTaskConstructible {
        func constructDataTask(request: NSURLRequest, completion: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask {
            let session = NSURLSession.sharedSession()
            let task = session.dataTaskWithRequest(request, completionHandler: completion);
            return task
        }
    }
    
    public struct EndpointOptions {
        var parameterEncoding: Request.ParameterEncoding = .URL
        var shouldCache: Bool = false
        var cacheTTL: Int? // some default?
    }
    
    let baseURLString: String
    var startTasksImmediately = true
    var dataTaskCreator: DataTaskConstructible = DataTaskCreatorDelegate()
    
    // MARK: - Initialization
    
    init(baseURLString: String) {
        self.baseURLString = baseURLString
    }
    
    // MARK: - Request API

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
    
    // MARK: - ServiceTask
    
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
        let request = Request(.GET, url: absoluteURLString)
        return serviceTask(request: request)
    }
    
    private func serviceTask(request aRequest: Request) -> ServiceTask {
        let task = ServiceTask(request: aRequest, dataTaskCreator: dataTaskCreator)
        
        if startTasksImmediately {
            task.resume()
        }
        
        return task
    }
    
    // MARK: - URL Construction
    
    /**
     Override to customize how all web service request paths are constructed. 
     Useful for prefixing request endpoint paths.
    */
    public func constructRequestPath(relativePath aRelativePath: String) -> String {
        return aRelativePath
    }
    
    // MARK: - Request Construction
    
    /**
     Override to customize how all web service request objects are constructed.
    */
    public func constructRequest(method: Method, url: String) -> Request {
        return Request(.GET, url: url)
    }
}

extension WebService: URLStringConstructible {
    func constructURLString(string: String, relativeToURLString relativeURLString: String) -> String {
        let relativeURL = NSURL(string: relativeURLString)
        return NSURL(string: string, relativeToURL: relativeURL)!.absoluteString!
    }
}
