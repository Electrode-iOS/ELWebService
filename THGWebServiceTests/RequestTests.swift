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
    func testConstructURLRequest() {
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
    
    func testURLEncodedParameters() {
        var request = RequestTests.CreateTestRequest()
        let parameters = ["foo" : "bar", "paramName" : "paramValue"]
        request.parameters = parameters
        
        let urlRequest = request.encodeURLRequest()
        let components = NSURLComponents(URL: urlRequest.URL!, resolvingAgainstBaseURL: false)!
        
        if let queryItems = components.queryItems {
            for item in queryItems as! [NSURLQueryItem] {
                let originalValue = parameters[item.name]!
                XCTAssertEqual(item.value!, originalValue)
            }
            
        } else {
            XCTAssert(true, "queryItems should not be nil")
        }
        
        XCTAssertEqual(count(components.queryItems!), count(parameters.keys))
    }
    
}
