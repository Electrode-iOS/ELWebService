//
//  Request.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 2/25/15.
//  Copyright (c) 2015 WalmartLabs. All rights reserved.
//

import Foundation

/// Defines an interface for encoding a `NSURLRequest`.
public protocol URLRequestEncodable {
    var urlRequestValue: URLRequest {get}
}

public typealias QueryParameterEncoder = (_ url: URL?, _ parameters: [String: Any]) -> URL?

/**
 Encapsulates the data required to send an HTTP request.
*/
public struct Request {
    
    /// The `Method` enum defines the supported HTTP methods.
    public enum Method: String {
        case GET = "GET"
        case HEAD = "HEAD"
        case POST = "POST"
        case PUT = "PUT"
        case PATCH = "PATCH"
        case DELETE = "DELETE"

        /**
         Whether requests using this method should encode parameters in the URL, instead of the body.

         `GET`, `HEAD` and `DELETE` requests encode parameters in the URL, `PUT`, `POST` and `PATCH` encode
         them in the body.
         */
        func encodesParametersInURL() -> Bool {
            switch self {
            case .GET, .HEAD, .DELETE:
                return true
            default:
                return false
            }
        }
    }
    
    // MARK: Parameter Encodings
    
    /// A `ParameterEncoding` value defines how to encode request parameters
    public enum ParameterEncoding {
        /// Encode parameters with percent encoding
        case percent
        /// Encode parameters as JSON
        case json
        
        /**
         Encode query parameters in an existing URL.
        
         - parameter url: Query string will be appended to this NSURL value.
         - parameter parameters: Query parameters to be encoded as a query string.
         - returns: A NSURL value with query string parameters encoded.
        */
        // TODO: remove this function in 4.0.0
        public func encodeURL(_ url: URL, parameters: [String : Any]) -> URL? {
            switch self {
            case .percent:
                return url.URLByAppendingQueryItems(parameters.queryItems)
            
            case .json:
                assertionFailure("Cannot encode URL parameters using JSON encoding")
                return nil // <-- unreachable
            }
        }
        
        /**
         Encode query parameters into a NSData value for request body.
        
         - parameter parameters: Query parameters to be encoded as HTTP body.
         - returns: NSData value with containing encoded parameters.
        */
        public func encodeBody(_ parameters: [String : Any], allowedCharacters: CharacterSet? = nil) -> Data? {
            switch self {
            case .percent:
                return parameters.percentEncodedQueryString(with: allowedCharacters)?.data(using: String.Encoding.utf8, allowLossyConversion: false)
            case .json:
                return try? JSONSerialization.data(withJSONObject: parameters, options: JSONSerialization.WritingOptions())
            }
        }
    }
    
    /// A group of static constants for referencing HTTP header field names.
    public struct Headers {
        public static let userAgent = "User-Agent"
        public static let contentType = "Content-Type"
        public static let contentLength = "Content-Length"
        public static let accept = "Accept"
        public static let cacheControl = "Cache-Control"
    }
    
    /// A group of static constants for referencing supported HTTP 
    /// `Content-Type` header values.
    public struct ContentType {
        public static let formEncoded = "application/x-www-form-urlencoded"
        public static let json = "application/json"
    }
        
    /// The HTTP method of the request.
    public let method: Method
    
    public let requestURL: URL

    /// The URL string of the HTTP request.
    public var url: String {
        return requestURL.absoluteString
    }

    /// The body of the HTTP request.
    public var body: Data?
    
    /// The Boolean to indicate if default cookies should be set for request.
    public var shouldHandleCookies: Bool = true

    /**
     The parameters to encode in the HTTP request. Request parameters are percent
     encoded and are appended as a query string or set as the request body 
     depending on the HTTP request method.
    */
    // TODO: remove `parameters` in 4.0.0
    public var parameters = [String : Any]()
    
    /// The key/value pairs that will be encoded as the query in the URL.
    public var queryParameters: [String : Any]?
    
    /// The key/value pairs that are encoded as form data in the request body.
    public var formParameters: [String : Any]? {
        didSet {
            if let formData = formParameters?.percentEncodedData(with: formParametersAllowedCharacters) {
                body = formData
                contentType = ContentType.formEncoded
            }
        }
    }
    
    public var queryParameterEncoder: QueryParameterEncoder = { (url, parameters) -> URL? in
        return url?.URLByAppendingQueryItems(parameters.queryItems)
    }

    /**
    If form parameters are specified, characters not in this set will be percent-encoded
    */
    public var formParametersAllowedCharacters: CharacterSet? = nil

    /**
     The HTTP header fields of the request. Each key/value pair represents a 
     HTTP header field value using the key as the field name.
    */
    internal(set) var headers = [String : String]()
    
    /// The cache policy of the request. See NSURLRequestCachePolicy.
    internal(set) var cachePolicy = NSURLRequest.CachePolicy.useProtocolCachePolicy
    
    /// The type of parameter encoding to use when encoding request parameters.
    public var parameterEncoding = ParameterEncoding.percent {
        didSet {
            if parameterEncoding == .json {
                contentType = ContentType.json
            }
        }
    }
    
    /// The HTTP `Content-Type` header field value of the request.
    internal(set) var contentType: String? {
        set { headers[Headers.contentType] = newValue }
        get { return headers[Headers.contentType] }
    }
    
    /// The HTTP `User-Agent` header field value of the request.
    internal(set) var userAgent: String? {
        set { headers[Headers.userAgent] = newValue }
        get { return headers[Headers.userAgent] }
    }
    
    // MARK: Initialization
    
    /**
     Intialize a request value.

     - parameter method: The HTTP request method.
     - parameter url: The URL string of the HTTP request.
     */
    init(_ method: Method, url: URL) {
        self.method = method
        self.requestURL = url
    }

    /**
     Intialize a request value.
     
     - parameter method: The HTTP request method.
     - parameter url: The URL string of the HTTP request.
    */
    init(_ method: Method, url urlString: String) {
        let aURL = URL(string: urlString)!
        self.init(method, url: aURL)
    }
}

// MARK: - URLRequestEncodable

extension Request: URLRequestEncodable {
    /**
     Encode a NSURLRequest based on the value of Request.
     
     - returns: A NSURLRequest encoded based on the Request data.
    */
    public var urlRequestValue: URLRequest {
        let urlRequest = NSMutableURLRequest(url: URL(string: url)!)
        urlRequest.httpMethod = method.rawValue
        urlRequest.cachePolicy = cachePolicy
        urlRequest.httpShouldHandleCookies = shouldHandleCookies
        
        for (name, value) in headers {
            urlRequest.addValue(value, forHTTPHeaderField: name)
        }
        
        if parameters.count > 0 {
            if method.encodesParametersInURL() {
                if let encodedURL = queryParameterEncoder(urlRequest.url, parameters) {
                    urlRequest.url = encodedURL
                }
            } else {
                if let data = parameterEncoding.encodeBody(parameters) {
                    urlRequest.httpBody = data
                    
                    if urlRequest.value(forHTTPHeaderField: Headers.contentType) == nil {
                        urlRequest.setValue(ContentType.formEncoded, forHTTPHeaderField: Headers.contentType)
                    }
                }
            }
        }
        
        // body property value overwrites any previously encoded body value
        if let body = body {
            urlRequest.httpBody = body
        }
        
        // queryParameters property overwrite any previously encoded query values
        if let queryParameters = queryParameters,
            let encodedURL = queryParameterEncoder(urlRequest.url, queryParameters) {
            urlRequest.url = encodedURL
        }
        
        return urlRequest.copy() as! URLRequest
    }
}

extension URLRequest: URLRequestEncodable {
    public var urlRequestValue: URLRequest {
        return self
    }
}

// MARK: - Query String

extension Dictionary {

    var queryItems: [URLQueryItem] {
        var items = [URLQueryItem]()
        
        for (name, value) in self {
            var encodedValue = "\(value)"
            
            // With Swift 3 we moved from `AnyObject` to `Any` for parameter values
            // and `Any` boolean values get stringified as "true" or "false" via
            // CustomStringConvertible. This conditional maintains the previous
            // behavior of encoding a boolean parameter value as "1" or "0".
            if let boolValue = value as? Bool {
                encodedValue = boolValue ? "1" : "0"
            }
            
            let item = URLQueryItem(name: "\(name)", value: encodedValue)
            items.append(item)
        }
        
        return items
    }
    
    // Default encoding
    var percentEncodedData: Data? {
        return percentEncodedData(with: nil)
    }

    // Encoding with custom allowed character set
    func percentEncodedData(with allowedCharacters: CharacterSet?) -> Data? {
        return percentEncodedQueryString(with: allowedCharacters)?.data(using: String.Encoding.utf8, allowLossyConversion: false)
    }

    /// Return an encoded query string using the elements in the dictionary.

    // Default encoding
    var percentEncodedQueryString: String? {
        return percentEncodedQueryString(with: nil)
    }

    // Encoding with custom allowed character set
    func percentEncodedQueryString(with allowedCharacters: CharacterSet?) -> String? {
        var components = URLComponents(string: "")
        components?.queryItems = queryItems
        if let allowedCharacters = allowedCharacters {
            components?.queryItems = queryItems.map { item in
                URLQueryItem(name: item.name,
                             value: item.value?.addingPercentEncoding(withAllowedCharacters: allowedCharacters))
            }
            return components?.query
        }
        return components?.url?.query
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
