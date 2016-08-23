//
//  Request.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 2/25/15.
//  Copyright (c) 2015 WalmartLabs. All rights reserved.
//

import Foundation

public protocol URLRequestConvertible {
    var urlRequest: URLRequest {get}
}

public protocol ServiceRequestProtocol: URLRequestConvertible {
    var url: URL {get}
    var method: ServiceRequest.Method {get}
    var body: Data? {get}
}

extension ServiceRequestProtocol {
    var method: ServiceRequest.Method {
        return .get
    }
    
    var body: Data? {
        return nil
    }
}

public protocol ParameterizedServiceRequest {
    var queryParameters: [String : Any]? {get}
    var formParameters: [String : Any]? {get}
}

/**
 Encapsulates the data required to send an HTTP request.
*/
public struct ServiceRequest: ServiceRequestProtocol, ParameterizedServiceRequest {
    /// Defines the supported HTTP methods.
    public enum Method: String {
        case get = "GET"
        case head = "HEAD"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }
    
    
    /// A group of static constants for referencing HTTP header field names.
    public enum Headers: String {
        case userAgent = "User-Agent"
        case contentType = "Content-Type"
        case contentLength = "Content-Length"
        case accept = "Accept"
        case cacheControl = "Cache-Control"
    }
    
    /// A group of static constants for referencing supported HTTP
    /// `Content-Type` header values.
    public enum ContentType: String {
        case formEncoded = "application/x-www-form-urlencoded"
        case json = "application/json"

    }
    
    /// The HTTP method of the request.
    public let method: ServiceRequest.Method
    
    /// The URL string of the HTTP request.
    public let url: URL
    
    /// The body of the HTTP request.
    public var body: Data?
    
    /// The key/value pairs that will be encoded as the query in the URL.
    public var queryParameters: [String : Any]?
    
    /// The key/value pairs that are encoded as form data in the request body.
    public var formParameters: [String : Any]? {
        didSet {
            if let formData = formParameters?.percentEncodedData {
                body = formData
                contentType = ContentType.formEncoded.rawValue
            }
        }
    }

    /**
     The HTTP header fields of the request. Each key/value pair represents a 
     HTTP header field value using the key as the field name.
    */
    public var headers = [String : String]()
    
    /// The HTTP `Content-Type` header field value of the request.
    public var contentType: String? {
        set { headers[Headers.contentType.rawValue] = newValue }
        get { return headers[Headers.contentType.rawValue] }
    }
    
    /// The HTTP `User-Agent` header field value of the request.
    public var userAgent: String? {
        set { headers[Headers.userAgent.rawValue] = newValue }
        get { return headers[Headers.userAgent.rawValue] }
    }
    
    // MARK: Initialization
    
    /**
     Intialize a request value.
     
     - parameter method: The HTTP request method.
     - parameter url: The URL string of the HTTP request.
    */
    public init(_ method: ServiceRequest.Method, url: URL) {
        self.method = method
        self.url = url
    }
    
    public init?(_ method: ServiceRequest.Method, urlString: String) {
        guard let url = URL(string: urlString)
        else { return nil }
        
        self.init(method, url: url)
    }
}

extension ServiceRequest {
    /**
     Encode a NSURLRequest based on the value of Request.
     
     - returns: A NSURLRequest encoded based on the Request data.
    */
    public var urlRequest: URLRequest {
        let urlRequest = NSMutableURLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        
        for (name, value) in headers {
            urlRequest.addValue(value, forHTTPHeaderField: name)
        }
        
        // body property value overwrites any previously encoded body value
        if let body = body {
            urlRequest.httpBody = body
        }
        
        // queryParameters property overwrite and previously encoded query values
        if let queryParameters = queryParameters,
            let encodedURL = urlRequest.url?.URLByAppendingQueryItems(queryParameters.queryItems) {
            urlRequest.url = encodedURL
        }
        
        return urlRequest.copy() as! URLRequest
    }
}

extension URLRequest: URLRequestConvertible {
    public var urlRequest: URLRequest {
        return self
    }
}

// MARK: - Query String

extension Dictionary {
    /// Return an encoded query string using the elements in the dictionary.
    var percentEncodedQueryString: String? {
        var components = URLComponents(string: "")
        components?.queryItems = queryItems
        return components?.url?.query
    }
    
    var queryItems: [URLQueryItem] {
        var items = [URLQueryItem]()
        
        for (name, value) in self {
            let item = URLQueryItem(name: "\(name)", value: "\(value)")
            items.append(item)
        }
        
        return items
    }
    
    var percentEncodedData: Data? {
        return percentEncodedQueryString?.data(using: String.Encoding.utf8, allowLossyConversion: false)
    }
}

extension URL {
    func URLByAppendingQueryItems(_ newItems: [URLQueryItem]) -> URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.appendQueryItems(newItems)
        return components?.url
    }
}

// MARK: - Percent Encoded Query

extension URLComponents {
    /// Append an array of query items to the existing `queryItems` property value.
    mutating func appendQueryItems(_ newItems: [URLQueryItem]) {
        if let existingQueryItems = queryItems {
            queryItems = existingQueryItems + newItems
        } else {
            queryItems = newItems
        }
    }
}
