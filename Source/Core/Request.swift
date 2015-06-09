//
//  Request.swift
//  Swallow
//
//  Created by Angelo Di Paolo on 2/25/15.
//  Copyright (c) 2015 TheHolyGrail. All rights reserved.
//

import Foundation

public protocol ParameterEncodable {
    func encodeURL(url: NSURL, parameters: [String : AnyObject]) -> NSURL?
    func encodeBody(parameters: [String : AnyObject]) -> NSData?
}

public protocol URLRequestEncodable {
    func encodeURLRequest() -> NSURLRequest
}

/**
 Encapsulates the data required to send an HTTP request.
*/
public struct Request {
    
    public enum Method: String {
        case GET = "GET"
        case HEAD = "HEAD"
        case POST = "POST"
        case PUT = "PUT"
        case DELETE = "DELETE"
    }
    
    // MARK: Parameter Encodings
    
    public enum ParameterEncoding: ParameterEncodable {
        case Percent
        case JSON
        
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
    
    // MARK: HTTP Header Constants
    
    public struct Headers {
        public static let userAgent = "User-Agent"
        public static let contentType = "Content-Type"
        public static let contentLength = "Content-Length"
        public static let accept = "Accept"
        public static let cacheControl = "Cache-Control"
    }
    
    // MARK: Content Type Constants
    
    public struct ContentType {
        public static let formEncoded = "application/x-www-form-urlencoded"
        public static let json = "application/json"
    }
    
    // MARK: Request Properties
    
    public let method: Method
    public let url: String
    public var parameters = [String : AnyObject]()
    public var headers = [String : String]()
    public var cachePolicy = NSURLRequestCachePolicy.UseProtocolCachePolicy
    public var parameterEncoding = ParameterEncoding.Percent {
        didSet {
            if parameterEncoding == .JSON {
                contentType = ContentType.json
            }
        }
    }
    
    public var contentType: String? {
        set { headers[Headers.contentType] = newValue }
        get { return headers[Headers.contentType] }
    }
    
    public var userAgent: String? {
        set { headers[Headers.userAgent] = newValue }
        get { return headers[Headers.userAgent] }
    }
    
    // MARK: Initialization
    
    /**
     Intialize a request value.
     
     :params: method Request method.
     :params: url URL string of the request.
    */
    public init(_ method: Method, url: String) {
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
    public func encodeURLRequest() -> NSURLRequest {

        let urlRequest = NSMutableURLRequest(URL: NSURL(string: url)!)
        urlRequest.HTTPMethod = method.rawValue
        urlRequest.cachePolicy = cachePolicy
        
        for (name, value) in headers {
            urlRequest.addValue(value, forHTTPHeaderField: name)
        }
        
        switch method {
        case .GET, .DELETE:
            if let url = urlRequest.URL,
                encodedURL = parameterEncoding.encodeURL(url, parameters: parameters) {
                    urlRequest.URL = encodedURL
            }
        default:
            if let data = parameterEncoding.encodeBody(parameters) {
                urlRequest.HTTPBody = data
                
                if urlRequest.valueForHTTPHeaderField(Headers.contentType) == nil {
                    urlRequest.setValue(ContentType.formEncoded, forHTTPHeaderField: Headers.contentType)
                }
            }
        }

        return urlRequest.copy() as! NSURLRequest
    }
}

// MARK: - Request Options

extension Request {
    
    public enum Option {
        case ParameterEncoding(Request.ParameterEncoding)
        case Header(String, String)
        case CachePolicy(NSURLRequestCachePolicy)
    }
    
    public func encodeOptions(options: [Option]) -> Request {
        var request = self
        
        for option in options {
            switch option {
                
            case .ParameterEncoding(let encoding):
                request.parameterEncoding = encoding
                
            case .Header(let name, let value):
                request.headers[name] = value
                
            case .CachePolicy(let cachePolicy):
                request.cachePolicy = cachePolicy
            }
        }
        
        return request
    }
}

// MARK: - Query String

extension Dictionary {
    /**
     Return an encoded query string using the elements in the dictionary.
    */
    var percentEncodedQueryString: String {
        var components = [String]()
        
        for (name, value) in self {
            if let percentEncodedPair = percentEncode((name, value)) {
                components.append(percentEncodedPair)
            }
        }
        
        return "&".join(components)
    }
    
    /**
     Percent encode a Key/Value pair.
    */
    func percentEncode(element: Element) -> String? {
        let (name, value) = element
        
        if let encodedName  = "\(name)".stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding),
            let encodedValue = "\(value)".stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding) {
                return "\(encodedName)=\(encodedValue)"
        }
        
        return nil
    }
}

// MARK: - Percent Encoded Query

extension NSURLComponents {
    /**
     Append an encoded query string to the existing percentEncodedQuery value.
    */
    func appendPercentEncodedQuery(query: String) {
        if percentEncodedQuery == nil {
            percentEncodedQuery = query
        } else {
            percentEncodedQuery = "\(percentEncodedQuery)&\(query)"
        }
    }
}
