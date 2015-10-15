//
//  RequestBuilder.swift
//  Swallow
//
//  Created by Andrew Finnell on 10/15/15.
//  Copyright © 2015 TheHolyGrail. All rights reserved.
//

import Foundation



public struct RequestBuilder {
    
    /// The HTTP method of the request.
    public var method = Request.Method.GET
    
    /// The URL string of the HTTP request.
    public var url: String
    
    /// The body of the HTTP request.
    public var body: NSData?
    
    /**
    The parameters to encode in the HTTP request. Request parameters are percent
    encoded and are appended as a query string or set as the request body
    depending on the HTTP request method.
    */
    public var parameters = [String : AnyObject]()
    
    /**
    The HTTP header fields of the request. Each key/value pair represents a
    HTTP header field value using the key as the field name.
    */
    public var headers = [String : String]()
    
    /// The cache policy of the request. See NSURLRequestCachePolicy.
    public var cachePolicy = NSURLRequestCachePolicy.UseProtocolCachePolicy
    
    /// The type of parameter encoding to use when encoding request parameters.
    public var parameterEncoding = Request.ParameterEncoding.Percent {
        didSet {
            if parameterEncoding == .JSON {
                contentType = Request.ContentType.json
            }
        }
    }
    
    /// The HTTP `Content-Type` header field value of the request.
    public var contentType: String? {
        set { headers[Request.Headers.contentType] = newValue }
        get { return headers[Request.Headers.contentType] }
    }
    
    /// The HTTP `User-Agent` header field value of the request.
    public var userAgent: String? {
        set { headers[Request.Headers.userAgent] = newValue }
        get { return headers[Request.Headers.userAgent] }
    }
    
    public var request: Request {
        return Request(method: method, url: url, body: body, parameters: parameters, headers: headers, cachePolicy: cachePolicy, parameterEncoding: parameterEncoding)
    }

    // MARK: Initialization
    
    /**
    Intialize a request builder value.
    
    - parameter url: The URL string of the HTTP request.
    */
    public init(url: String) {
        self.url = url
    }
}

extension RequestBuilder {
    /**
    Create a request builder for a `GET` HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - parameter parameters: Optional request parameters. The data is URL encoded as
    a query string for `GET` requests.
    - parameter options: Endpoint options used to configure the HTTP request.
    - returns: A RequestBuilder instance that contains the update request configuration
    */
    public func GET(path: String, parameters: [String : AnyObject]? = nil, options: [RequestBuilder.Option]? = nil) -> RequestBuilder {
        return requestBuilder(.GET, path: path, parameters: parameters, options: options)
    }
    
    /**
    Create a request builder for a `POST` HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - parameter parameters: Optional request parameters. The data is URL encoded and
    is set as the HTTP body for `POST` requests.
    - parameter options: Endpoint options used to configure the HTTP request.
    - returns: A RequestBuilder instance that contains the update request configuration
    */
    public func POST(path: String, parameters: [String : AnyObject]? = nil, options: [RequestBuilder.Option]? = nil) -> RequestBuilder {
        return requestBuilder(.POST, path: path, parameters: parameters, options: options)
    }
    
    /**
    Create a request builder for a PUT HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - parameter parameters: Optional request parameters. The data is URL encoded and
    is set as the HTTP body for `PUT` requests.
    - parameter options: Endpoint options used to configure the HTTP request.
    - returns: A RequestBuilder instance that contains the update request configuration
    */
    public func PUT(path: String, parameters: [String : AnyObject]? = nil, options: [RequestBuilder.Option]? = nil) -> RequestBuilder {
        return requestBuilder(.PUT, path: path, parameters: parameters, options: options)
    }
    
    /**
    Create a request builder for a DELETE HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - parameter parameters: Optional request parameters. The data is URL encoded and
    is set as the HTTP body for `DELETE` requests.
    - parameter options: Endpoint options used to configure the HTTP request.
    - returns: A RequestBuilder instance that contains the update request configuration
    */
    public func DELETE(path: String, parameters: [String : AnyObject]? = nil, options: [RequestBuilder.Option]? = nil) -> RequestBuilder {
        return requestBuilder(.DELETE, path: path, parameters: parameters, options: options)
    }
    
    /**
    Create a request builder for a HEAD HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - parameter parameters: Optional request parameters. The data is URL encoded as
    a query string for `HEAD` requests.
    - parameter options: Endpoint options used to configure the HTTP request.
    - returns: A RequestBuilder instance that contains the update request configuration
    */
    public func HEAD(path: String, parameters: [String : AnyObject]? = nil, options: [RequestBuilder.Option]? = nil) -> RequestBuilder {
        return requestBuilder(.HEAD, path: path, parameters: parameters, options: options)
    }
}

extension RequestBuilder {
    
    func requestBuilder(method: Request.Method, path: String, parameters: [String : AnyObject]? = nil, options: [RequestBuilder.Option]? = nil) -> RequestBuilder {
        var builder = self
        
        builder.method = method
        builder.url = absoluteURLString(path)
        
        if let parameters = parameters {
            builder = builder.mergeParameters(parameters)
        }
        
        if let options = options {
            builder = builder.encodeOptions(options)
        }
        
        return builder
    }
}

// MARK: - URL String Construction

extension RequestBuilder {
    /**
    Return an absolute URL string relative to the baseURLString value.
    
    - parameter string: URL string.
    - returns: An absoulte URL string relative to the value of `baseURLString`.
    */
    public func absoluteURLString(string: String) -> String {
        return constructURLString(string, relativeToURLString: url)
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

extension Request.ParameterEncoding {
    /**
    Encode query parameters in an existing URL.
    
    - parameter url: Query string will be appended to this NSURL value.
    - parameter parameters: Query parameters to be encoded as a query string.
    - returns: A NSURL value with query string parameters encoded.
    */
    public func encodeURL(url: NSURL, parameters: [String : AnyObject]) -> NSURL? {
        if let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false) {
            components.appendPercentEncodedQuery(parameters.percentEncodedQueryString)
            return components.URL
        }
        
        return nil
    }
    
    /**
    Encode query parameters into a NSData value for request body.
    
    - parameter parameters: Query parameters to be encoded as HTTP body.
    - returns: NSData value with containing encoded parameters.
    */
    public func encodeBody(parameters: [String : AnyObject]) -> NSData? {
        switch self {
        case .Percent:
            return parameters.percentEncodedQueryString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        case .JSON:
            do {
                return try NSJSONSerialization.dataWithJSONObject(parameters, options: NSJSONWritingOptions())
            } catch _ {
                return nil
            }
        }
    }
}

// MARK: - RequestBuilder Options

extension RequestBuilder {
    
    /// An `Option` value defines a rule for encoding part of a `Request` value.
    public enum Option {
        /// Defines the parameter encoding for the HTTP request.
        case ParameterEncoding(Request.ParameterEncoding)
        /// Defines a HTTP header field name and value to set in the `Request`.
        case Header(String, String)
        /// Defines the cache policy to set in the `Request` value.
        case CachePolicy(NSURLRequestCachePolicy)
        /// Defines the HTTP body contents of the HTTP request.
        case Body(NSData)
        /// Defines the JSON object that will be serialized as the body of the HTTP request.
        case BodyJSON(AnyObject)
    }
    
    /// Uses an array of `Option` values as rules for mutating a `Request` value.
    func encodeOptions(options: [Option]) -> RequestBuilder {
        var request = self
        
        for option in options {
            switch option {
                
            case .ParameterEncoding(let encoding):
                request.parameterEncoding = encoding
                
            case .Header(let name, let value):
                request.headers[name] = value
                
            case .CachePolicy(let cachePolicy):
                request.cachePolicy = cachePolicy
                
            case .Body(let data):
                request.body = data
                
            case .BodyJSON(let json):
                request.body = try? NSJSONSerialization.dataWithJSONObject(json, options: NSJSONWritingOptions(rawValue: 0))
            }
        }
        
        return request
    }
}

// MARK: - Parameter Merging

extension RequestBuilder {
    private mutating func mergeParameters(parameters: [String : AnyObject]) -> RequestBuilder {
        var builder = self
        for (key, value) in parameters {
            builder.parameters[key] = value
        }
        return builder
    }
}

// MARK: - Query String

extension Dictionary {
    
    /// Return an encoded query string using the elements in the dictionary.
    var percentEncodedQueryString: String {
        var components = [String]()
        
        for (name, value) in self {
            if let percentEncodedPair = percentEncode((name, value)) {
                components.append(percentEncodedPair)
            }
        }
        
        return components.joinWithSeparator("&")
    }
    
    /// Percent encode a Key/Value pair.
    func percentEncode(element: Element) -> String? {
        let (name, value) = element
        
        if let encodedName  = "\(name)".percentEncodeURLQueryCharacters,
            let encodedValue = "\(value)".percentEncodeURLQueryCharacters {
                return "\(encodedName)=\(encodedValue)"
        }
        
        return nil
    }
}

// MARK: - Percent Encoded String

extension String {
    /**
    Returns a new string by replacing all characters allowed in an URL's query
    component with percent encoded characters.
    */
    var percentEncodeURLQueryCharacters: String? {
        return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
    }
}

// MARK: - Percent Encoded Query

extension NSURLComponents {
    
    /// Append an encoded query string to the existing percentEncodedQuery value.
    func appendPercentEncodedQuery(query: String) {
        if percentEncodedQuery == nil {
            percentEncodedQuery = query
        } else {
            percentEncodedQuery = "\(percentEncodedQuery)&\(query)"
        }
    }
}
