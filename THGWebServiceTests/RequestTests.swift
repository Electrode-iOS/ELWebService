//
//  RequestTests.swift
//  THGWebService
//
//  Created by Angelo Di Paolo on 3/11/15.
//  Copyright (c) 2015 TheHolyGrail. All rights reserved.
//

import Foundation
import THGWebService
import XCTest

/**
 Tests the functionality of the Request struct.
*/
class RequestTests: XCTestCase {
    
    /**
     Creates a Request value for testing.
    */
    static func CreateTestRequest() -> Request {
        let url = "http://httpbin.org/get"
        var request = Request(.GET, url: url)
        request.headers["foo"] = "bar"
        return request
    }
    
    /**
     Test Request's conformance to URLRequestConstructible.
    */
    func testEncodeURLRequest() {
        let request = RequestTests.CreateTestRequest()
        let urlRequest = request.encodeURLRequest()
        
        XCTAssertEqual(urlRequest.HTTPMethod!, request.method.rawValue)
        
        for (name, value) in request.headers {
            let resultingValue = urlRequest.valueForHTTPHeaderField(name)!
            XCTAssertEqual(value, resultingValue)
        }
    }
    
    /**
     Test HTTP header computed properties and constants.
    */
    func testHeaderProperties() {
        let contentType = "application/json"
        let userAgent = "user agent value"
        
        var request = RequestTests.CreateTestRequest()
        request.contentType = contentType
        request.userAgent = userAgent
        
        XCTAssertEqual(request.headers["Content-Type"]!, contentType)
        XCTAssertEqual(request.headers["User-Agent"]!, userAgent)
        XCTAssertEqual(Request.Headers.userAgent, "User-Agent")
        XCTAssertEqual(Request.Headers.contentType, "Content-Type")
        XCTAssertEqual(Request.Headers.accept, "Accept")
        XCTAssertEqual(Request.Headers.cacheControl, "Cache-Control")
    }
    
    func testPercentEncodedParameters() {
        var request = RequestTests.CreateTestRequest()
        let parameters = ["foo" : "bar", "paramName" : "paramValue", "percentEncoded" : "this needs percent encoded"]
        request.parameters = parameters
        request.parameterEncoding = .Percent
        
        let urlRequest = request.encodeURLRequest()
        let components = NSURLComponents(URL: urlRequest.URL!, resolvingAgainstBaseURL: false)!
        
        if let queryItems = components.queryItems {
            for item in queryItems as! [NSURLQueryItem] {
                let originalValue = parameters[item.name]!
                XCTAssertEqual(item.value!, originalValue)
            }
            
        } else {
            XCTAssert(false, "queryItems should not be nil")
        }
        
        XCTAssertEqual(count(components.queryItems!), count(parameters.keys))
    }
    
    func testJSONEncodedParameters() {
        let encoding = Request.ParameterEncoding.JSON
        let parameters: [String: AnyObject] = ["foo" : "bar", "paramName" : "paramValue", "number" : 42]
        let data = encoding.encodeBody(parameters)
        var error: NSError?
        
        XCTAssert(data != nil, "Encoded JSON data should not be nil")
        
        let json = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.allZeros, error: &error) as? [String : AnyObject]
        
        XCTAssert(json != nil, "Serialized JSON should not be nil")
        
        for (name, value) in json! {
            let originalValue: AnyObject? = parameters[name]
            
            XCTAssert(originalValue != nil, "originalValue you should not be nil for key \(name)")
            
            if let originalValue = originalValue as? String,
                let value = value as? String {
                    XCTAssertEqual(originalValue, value)
            } else if let originalValue = originalValue as? Int,
                    let value = value as? Int {
                    XCTAssertEqual(originalValue, value)
            } else {
                XCTAssert(false, "Failed to downcast JSON values for originalValue: \(originalValue) and \(value)")
            }
        }
    }
}
