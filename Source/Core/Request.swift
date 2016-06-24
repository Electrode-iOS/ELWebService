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
    var urlRequestValue: NSURLRequest {get}
}

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
        case DELETE = "DELETE"

        /**
         Whether requests using this method should encode parameters in the URL, instead of the body.

         `GET`, `HEAD` and `DELETE` requests encode parameters in the URL, `PUT` and `POST` encode
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

    public enum ParameterEncodingTransformer {
        case URL((url: NSURL, parameters: [String : AnyObject]) -> NSURL?)
        case Body((parameters: [String : AnyObject]) -> NSData?, contentType: String)
    }

    /// A `ParameterEncoding` value defines how to encode request parameters
    public enum ParameterEncoding {
        /// Encode parameters with percent encoding
        case Percent
        /// Encode parameters as JSON
        case JSON
        /// Custom encoding
        case Custom(transformer: ParameterEncodingTransformer)
        
        /**
         Encode query parameters in an existing URL.
        
         - parameter url: Query string will be appended to this NSURL value.
         - parameter parameters: Query parameters to be encoded as a query string.
         - returns: A NSURL value with query string parameters encoded.
        */
        // TODO: remove this function in 4.0.0
        public func encodeURL(url: NSURL, parameters: [String : AnyObject]) -> NSURL? {
            switch self {
            case .Percent:
                return url.URLByAppendingQueryItems(parameters.queryItems)
            
            case .JSON:
                assertionFailure("Cannot encode URL parameters using JSON encoding")
                return nil // <-- unreachable

            case .Custom(let transformer):
                switch transformer {
                case .URL(let converter):
                    return converter(url: url, parameters: parameters)
                case .Body:
                    assertionFailure("Cannot custom encode URL parameters using ParameterEncodingTransformer.Body")
                    return nil // <-- unreachable
                }
            }

        }
        
        /**
         Encode query parameters into a NSData value for request body.
        
         - parameter parameters: Query parameters to be encoded as HTTP body.
         - returns: NSData value with containing encoded parameters.
        */
        public func encodeBody(parameters: [String : AnyObject]) -> NSData? {
            switch self {
            case .Percent:
                return parameters.percentEncodedQueryString?.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            case .JSON:
                return try? NSJSONSerialization.dataWithJSONObject(parameters, options: NSJSONWritingOptions())

            case .Custom(let transformer):
                switch transformer {
                case .URL:
                    assertionFailure("Cannot custom encode Body using ParameterEncodingTransformer.URL")
                    return nil // <-- unreachable
                case .Body(let converter, _):
                    return converter(parameters: parameters)
                }
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
    
    /// The URL string of the HTTP request.
    public let url: String
    
    /// The body of the HTTP request.
    public var body: NSData?
    
    /**
     The parameters to encode in the HTTP request. Request parameters are percent
     encoded and are appended as a query string or set as the request body 
     depending on the HTTP request method.
    */
    // TODO: remove `parameters` in 4.0.0
    public var parameters = [String : AnyObject]()
    
    /// The key/value pairs that will be encoded as the query in the URL.
    public var queryParameters: [String : AnyObject]?
    
    /// The key/value pairs that are encoded as form data in the request body.
    public var formParameters: [String : AnyObject]? {
        didSet {
            if let formData = formParameters?.percentEncodedData {
                body = formData
                contentType = ContentType.formEncoded
            }
        }
    }

    /**
     The HTTP header fields of the request. Each key/value pair represents a 
     HTTP header field value using the key as the field name.
    */
    internal(set) var headers = [String : String]()
    
    /// The cache policy of the request. See NSURLRequestCachePolicy.
    internal(set) var cachePolicy = NSURLRequestCachePolicy.UseProtocolCachePolicy
    
    /// The type of parameter encoding to use when encoding request parameters.
    public var parameterEncoding = ParameterEncoding.Percent {
        didSet {
            switch parameterEncoding {
            case .Percent:
                break // nothing to see here, move along
            case .JSON:
                contentType = ContentType.json
            case .Custom(let transformer):
                if case let .Body(_, customContentType) = transformer {
                    contentType = customContentType
                }
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
    init(_ method: Method, url: String) {
        self.method = method
        self.url = url
    }
}

// MARK: - URLRequestEncodable

extension Request: URLRequestEncodable {
    /**
     Encode a NSURLRequest based on the value of Request.
     
     - returns: A NSURLRequest encoded based on the Request data.
    */
    public var urlRequestValue: NSURLRequest {
        let urlRequest = NSMutableURLRequest(URL: NSURL(string: url)!)
        urlRequest.HTTPMethod = method.rawValue
        urlRequest.cachePolicy = cachePolicy
        
        for (name, value) in headers {
            urlRequest.addValue(value, forHTTPHeaderField: name)
        }
        
        if parameters.count > 0 {
            if method.encodesParametersInURL() {
                if let url = urlRequest.URL {
                    urlRequest.URL = parameterEncoding.encodeURL(url, parameters: parameters)
                }
            } else {
                if let data = parameterEncoding.encodeBody(parameters) {
                    urlRequest.HTTPBody = data
                    
                    if urlRequest.valueForHTTPHeaderField(Headers.contentType) == nil {
                        urlRequest.setValue(ContentType.formEncoded, forHTTPHeaderField: Headers.contentType)
                    }
                }
            }
        }
        
        // body property value overwrites any previously encoded body value
        if let body = body {
            urlRequest.HTTPBody = body
        }
        
        // queryParameters property overwrite and previously encoded query values
        if let queryParameters = queryParameters {
            if let url = urlRequest.URL {
                urlRequest.URL = parameterEncoding.encodeURL(url, parameters: queryParameters)
            }
        }
        
        return urlRequest.copy() as! NSURLRequest
    }
}

extension NSURLRequest: URLRequestEncodable {
    public var urlRequestValue: NSURLRequest {
        return self
    }
}

// MARK: - Query String

public extension Dictionary {
    /// Return an encoded query string using the elements in the dictionary.
    public var percentEncodedQueryString: String? {
        let components = NSURLComponents(string: "")
        components?.queryItems = queryItems
        return components?.URL?.query
    }
    
    public var queryItems: [NSURLQueryItem] {
        var items = [NSURLQueryItem]()
        
        for (name, value) in self {
            let item = NSURLQueryItem(name: "\(name)", value: "\(value)")
            items.append(item)
        }
        
        return items
    }
    
    public var percentEncodedData: NSData? {
        return percentEncodedQueryString?.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
    }
}

extension NSURL {
    func URLByAppendingQueryItems(newItems: [NSURLQueryItem]) -> NSURL? {
        let components = NSURLComponents(URL: self, resolvingAgainstBaseURL: false)
        components?.appendQueryItems(newItems)
        return components?.URL
    }
}

// MARK: - Percent Encoded Query

extension NSURLComponents {
    /// Append an array of query items to the existing `queryItems` property value.
    func appendQueryItems(newItems: [NSURLQueryItem]) {
        if let existingQueryItems = queryItems {
            queryItems = existingQueryItems + newItems
        } else {
            queryItems = newItems
        }
    }
}
