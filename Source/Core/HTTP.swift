//
//  HTTP.swift
//  ELWebService
//
//  Created by Manoj Kumar Mahapatra on 10/9/19.
//  Copyright © 2019 WalmartLabs. All rights reserved.
//

import Foundation

public enum HTTP {}

extension HTTP {
    /// HTTP header files are components of the header section of request and response messages in the HTTP
    struct Header: Hashable, StringValue {
        let stringValue: String
        fileprivate init(_ value: String) { stringValue = value }
    }
}

extension HTTP.Header {
    /// Used by requests to specify the user agent
    static let userAgent = HTTP.Header("User-Agent")
    /// Used by requests to specify the `HTTP.ContentType` of the request body
    /// and by responses to specify the `HTTP.ContentType` of the response body
    static let contentType = HTTP.Header("Content-Type")
    /// The length of the request body
    static let contentLength = HTTP.Header("Content-Length")
    /// Used by requests to specify the `HTTP.ContentType`s that are acceptable responses
    static let accept = HTTP.Header("Accept")
    /// Used to specify directives that must be obeyed by all caching mechanisms along the request-response chain
    static let cacheControl = HTTP.Header("Cache-Control")
}

extension HTTP {
    /// Represents valid values for `HTTP.Header.contentType`
    struct ContentType: Hashable, StringValue {
        let stringValue: String
        fileprivate init(_ value: String) { stringValue = value }
    }
}

extension HTTP.ContentType {
    /// The content type used by html forms
    static let formEncoded = HTTP.ContentType("application/x-www-form-urlencoded")
    /// The content type used for json
    static let json = HTTP.ContentType("application/json")
}

extension HTTP {
    /// The `Method` enum defines the supported HTTP methods.
    public enum Method: String, CaseIterable {
        /// The `GET` method requests a representation of the specified resource
        case GET = "GET"
        /// The `HEAD` method asks for a response identical to that of a GET request, but without the response body
        case HEAD = "HEAD"
        /// The `POST` method requests that the server accept the entity enclosed in the request as a new
        /// subordinate of the web resource identified by the URI
        case POST = "POST"
        /// The `PUT` method requests that the enclosed entity be stored under the supplied URI
        case PUT = "PUT"
        /// The `PATCH` method applies partial modifications to a resource
        case PATCH = "PATCH"
        /// The `DELETE` method deletes the specified resource.
        case DELETE = "DELETE"
        
        /// Whether requests using this method should encode parameters in the URL, instead of the body.
        ///
        /// `GET`, `HEAD` and `DELETE` requests encode parameters in the URL, `PUT`, `POST` and `PATCH` encode
        /// them in the body.
        func encodesParametersInURL() -> Bool {
            switch self {
            case .GET, .HEAD, .DELETE:
                return true
            default:
                return false
            }
        }
    }
}
