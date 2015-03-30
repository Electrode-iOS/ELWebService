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
        case Percent
        case JSON
        
        /**
         Encode query parameters in an existing URL.
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
        */
        public func encodeBody(parameters: [String : AnyObject]) -> NSData? {
            switch self {
            case .Percent:
                return parameters.percentEncodedQueryString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            case .JSON:
                return NSJSONSerialization.dataWithJSONObject(parameters, options: NSJSONWritingOptions.allZeros, error: nil)
            }
        }
    }
    
    // MARK: HTTP Headers
    
    public struct Headers {
        public static let userAgent = "User-Agent"
        public static let contentType = "Content-Type"
        public static let contentLength = "Content-Length"
        public static let accept = "Accept"
        public static let cacheControl = "Cache-Control"
    }
    
    // MARK: Request Properties
    
    public let method: Method
    public let url: String
    public var parameters = [String : AnyObject]()
    public var headers = [String : String]()
    public var parameterEncoding = ParameterEncoding.Percent
    
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
    /**
     Encode a NSURLRequest based on the value of Request.
    */
    public func encodeURLRequest() -> NSURLRequest {

        var urlRequest = NSMutableURLRequest(URL: url.URLValue)
        urlRequest.HTTPMethod = method.rawValue
        
        for (name, value) in headers {
            urlRequest.addValue(value, forHTTPHeaderField: name)
        }
        
        if method != .GET {
            if let data = parameterEncoding.encodeBody(parameters) {
                urlRequest.HTTPBody = data
                urlRequest.setValue(String(data.length), forHTTPHeaderField: Headers.contentLength)
            }
        } else {
            if let url = urlRequest.URL,
                encodedURL = parameterEncoding.encodeURL(url, parameters: parameters) {
                urlRequest.URL = encodedURL
            }
        }

        return urlRequest.copy() as! NSURLRequest
    }
}

// MARK: - Protocols

// MARK: Parameter Encoding

public protocol ParameterEncodable {
    func encodeURL(url: NSURL, parameters: [String : AnyObject]) -> NSURL?
    func encodeBody(parameters: [String : AnyObject]) -> NSData?
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
    /**
     Converts a string value.
    */
    public var URLValue: NSURL {
        return NSURL(string: self)!
    }
}

// MARK: Query String

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

// MARK: Percent Encoded Query

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
