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
public struct Request: URLRequestConstructible {
    
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
    
    let method: Method
    let url: String
    var parameters: Dictionary<String, String>?
    var headers: Dictionary<String, String>?
    
    // MARK: - Initialization
    
    init(_ method: Method, url: String) {
        self.method = method
        self.url = url
    }
    
    // MARK: - URLRequestConstructible
    
    public func constructURLRequest() -> NSURLRequest {
        // TODO: serialize URL parameters
        // TODO: serialize body parameters
        // TODO: add headers
        var urlRequest = NSMutableURLRequest(URL: url.URLValue)
        urlRequest.HTTPMethod = method.rawValue
        return urlRequest;
    }
}
