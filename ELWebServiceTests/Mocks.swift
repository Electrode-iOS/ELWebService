//
//  Mocks.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 3/2/16.
//  Copyright © 2016 WalmartLabs. All rights reserved.
//

import Foundation
import ELWebService

// MARK: - Session Mocks

class RequestRecordingSession: MockSession {
    var request: URLRequestEncodable?
    
    func stubbedResponse(request request: URLRequestEncodable) -> (NSData?, NSURLResponse?, NSError?) {
        self.request = request
        return (nil, nil, nil)
    }
}

class RespondsWith200Session: MockSession {
    func response(request: NSURLRequest) -> NSURLResponse? {
        return nil
    }
    
    func stubbedResponse(request request: URLRequestEncodable) -> (NSData?, NSURLResponse?, NSError?) {
        guard let url = request.urlRequestValue.URL else {
            let error = NSError(domain: "com.walmart", code: 500, userInfo: [NSLocalizedDescriptionKey: "Request contained an invalid URL"])
            return (nil, nil, error)
        }
        
        let response = NSHTTPURLResponse(URL: url, statusCode: 200, HTTPVersion: nil, headerFields: nil)
        return (nil, response, nil)
    }
}

// MARK: JSON

class JSONSession: MockSession {
    func stubbedResponse(request request: URLRequestEncodable) -> (NSData?, NSURLResponse?, NSError?) {
        var response: NSHTTPURLResponse?
        
        if let url = request.urlRequestValue.URL {
            response = NSHTTPURLResponse(URL: url, statusCode: 200, HTTPVersion: nil, headerFields: nil)
        }
        
        return (NSData.mockJSONData(), response, nil)
    }
}

class InvalidJSONSession: MockSession {
    func stubbedResponse(request request: URLRequestEncodable) -> (NSData?, NSURLResponse?, NSError?) {
        var response: NSHTTPURLResponse?
        
        if let url = request.urlRequestValue.URL {
            response = NSHTTPURLResponse(URL: url, statusCode: 200, HTTPVersion: nil, headerFields: nil)
        }
        
        return (NSData(), response, nil)
    }
}

// MARK: Errors

class ErrorSession: MockSession {
    func stubbedResponse(request request: URLRequestEncodable) -> (NSData?, NSURLResponse?, NSError?) {
        let error = NSError(domain: "com.electrode.tests", code: 500, userInfo: nil)
        return (nil, nil, error)
    }
}

// MARK: - Response Data Mock

extension NSData {
    static func mockJSONData() -> NSData {
        let json = ["foo": "bar"]
        let data = try! NSJSONSerialization.dataWithJSONObject(json, options: NSJSONWritingOptions(rawValue:  0))
        return data
    }
}
