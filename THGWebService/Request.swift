//
//  Request.swift
//  Swallow
//
//  Created by Angelo Di Paolo on 2/25/15.
//  Copyright (c) 2015 TheHolyGrail. All rights reserved.
//

import Foundation

protocol URLRequestConstructible {
    func constructURLRequest() -> NSURLRequest
}

protocol URLConvertible {
    var URLValue: NSURL { get }
}

extension String: URLConvertible {
    public var URLValue: NSURL {
        return NSURL(string: self)!
    }
}

/**
 Encapsulates the model data of an HTTP request.
*/
public struct Request {
    
    public enum Method: String {
        case GET = "GET"
        case HEAD = "HEAD"
        case POST = "POST"
        case PUT = "PUT"
        case DELETE = "DELETE"
    }
    
    public enum ParameterEncoding {
        case URL
        case JSON
    }
    
    public let method: Method
    public let url: String
    public var parameters = Dictionary<String, String>()
    public var headers = Dictionary<String, String>()
    
    // MARK: - Initialization
    
    init(_ method: Method, url: String) {
        self.method = method
        self.url = url
    }
}

// MARK: - URLRequestConstructible

extension Request: URLRequestConstructible {
    public func constructURLRequest() -> NSURLRequest {
        // TODO: serialize URL parameters
        // TODO: serialize body parameters

        var urlRequest = NSMutableURLRequest(URL: url.URLValue)
        urlRequest.HTTPMethod = method.rawValue
        
        for (name, value) in headers {
            urlRequest.addValue(value, forHTTPHeaderField: name)
        }
        
        return urlRequest;
    }
}

