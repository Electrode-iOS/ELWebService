//
//  Request.swift
//  Swallow
//
//  Created by Angelo Di Paolo on 2/25/15.
//  Copyright (c) 2015 TheHolyGrail. All rights reserved.
//

import Foundation

/**
 Encapsulates the data required to send an HTTP request.
*/
public struct Request {
    
    // MARK: HTTP Methods

    public enum Method: String {
        case GET = "GET"
        case HEAD = "HEAD"
        case POST = "POST"
        case PUT = "PUT"
        case DELETE = "DELETE"
    }
    
    // MARK: Parameter Encodings
    
    public enum ParameterEncoding: ParameterEncodable {
        case URL
        case JSON
        
        public func encodeURL(url: NSURL, parameters: Dictionary<String, String>) -> NSURL? {
            if let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false) {
                components.appendPercentEncodedQuery(parameters.queryString)
                return components.URL
            }
            
            return nil
        }
        
        public func encodeBody(parameters: Dictionary<String, String>) -> NSData? {
            switch self {
            case .URL:
                return parameters.encodedQueryString?.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            case .JSON:
                return NSJSONSerialization.dataWithJSONObject(parameters, options: NSJSONWritingOptions.allZeros, error: nil)
            }
        }
    }
    
    // MARK: HTTP Headers
    
    public struct Headers {
        public static let userAgent = "User-Agent"
        public static let contentType = "Content-Type"
        public static let accept = "Accept"
        public static let cacheControl = "Cache-Control"
    }
    
    // MARK: Request Properties
    
    public let method: Method
    public let url: String
    public var parameters = Dictionary<String, String>()
    public var headers = Dictionary<String, String>()
    public var parameterEncoding = ParameterEncoding.URL
    
    public var contentType: String? {
        set { headers[Headers.contentType] = newValue }
        get { return headers[Headers.contentType] }
    }
    
    public var userAgent: String? {
        set { headers[Headers.userAgent] = newValue }
        get { return headers[Headers.userAgent] }
    }
    
    // MARK: Initialization
    
    public init(_ method: Method, url: String) {
        self.method = method
        self.url = url
    }
}

// MARK: - URLRequestEncodable

extension Request: URLRequestEncodable {
    
    public func encodeURLRequest() -> NSURLRequest {

        var urlRequest = NSMutableURLRequest(URL: url.URLValue)
        urlRequest.HTTPMethod = method.rawValue
        
        for (name, value) in headers {
            urlRequest.addValue(value, forHTTPHeaderField: name)
        }
        
        if method != .GET {
            if let data = parameterEncoding.encodeBody(parameters) {
                urlRequest.HTTPBody = data
            }
        } else {
            if let url = urlRequest.URL,
                encodedURL = parameterEncoding.encodeURL(url, parameters: parameters) {
                urlRequest.URL = encodedURL
            }
        }

        return urlRequest
    }
}

// MARK: - Protocols

// MARK: Parameter Encoding

public protocol ParameterEncodable {
    func encodeURL(url: NSURL, parameters: Dictionary<String, String>) -> NSURL?
    func encodeBody(parameters: Dictionary<String, String>) -> NSData?
}

// MARK: NSURLRequest Encoding

public protocol URLRequestEncodable {
    func encodeURLRequest() -> NSURLRequest
}

// MARK: NSURL Value

protocol URLConvertible {
    var URLValue: NSURL { get }
}

// MARK: - Extensions

// MARK: String to NSURL

extension String: URLConvertible {
    
    public var URLValue: NSURL {
        return NSURL(string: self)!
    }
}

// MARK: Query String

extension Dictionary {
    
    var queryString: String {
        var components = [String]()
        
        for (name, value) in self {
            components.append("\(name)=\(value)")
        }
        
        return "&".join(components)
    }
    
    var encodedQueryString: String? {
        if let components = NSURLComponents(string: queryString) {
            return components.percentEncodedQuery
        }
        
        return nil
    }
}

// MARK: Percent Encoded Query

extension NSURLComponents {
    
    func appendPercentEncodedQuery(query: String) {
        if percentEncodedQuery == nil {
            percentEncodedQuery = query
        } else {
            percentEncodedQuery = "\(percentEncodedQuery)&\(query)"
        }
    }
}
