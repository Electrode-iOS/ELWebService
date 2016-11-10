//
//  RequestTests.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 3/11/15.
//  Copyright (c) 2015 WalmartLabs. All rights reserved.
//

import Foundation
import XCTest
@testable import ELWebService

///  Tests the functionality of the Request struct.
class RequestTests: XCTestCase {
    func test_urlRequestValue_encodedHeaderFields() {
        let request = Request(.GET, url: "http://httpbin.org/get")
        
        let urlRequest = request.urlRequestValue
        
        XCTAssertEqual(urlRequest.httpMethod!, request.method.rawValue)
        
        for (name, value) in request.headers {
            let resultingValue = urlRequest.value(forHTTPHeaderField: name)!
            XCTAssertEqual(value, resultingValue)
        }
    }
    
    func test_urlRequestValue_validURLWithEmptyParameters() {
        let request = Request(.GET, url: "http://httpbin.org/")
        
        let urlRequest = request.urlRequestValue
        
        let urlString = urlRequest.url?.absoluteString
        XCTAssertNotNil(urlString)
        XCTAssertFalse(urlString!.contains("?"))
    }
    
    func test_headerProperties_setValuesInTheCorrectHeaderFields() {
        let contentType = "application/json"
        let userAgent = "user agent value"
        var request = Request(.GET, url: "http://httpbin.org/get")
        
        request.contentType = contentType
        request.userAgent = userAgent
        
        XCTAssertEqual(request.headers["Content-Type"]!, contentType)
        XCTAssertEqual(request.headers["User-Agent"]!, userAgent)
        XCTAssertEqual(Request.Headers.userAgent, "User-Agent")
        XCTAssertEqual(Request.Headers.contentType, "Content-Type")
        XCTAssertEqual(Request.Headers.accept, "Accept")
        XCTAssertEqual(Request.Headers.cacheControl, "Cache-Control")
    }
    
    func test_headerProperties_getValuesFromTheCorrectHeaderFields() {
        let contentType = "application/json"
        let userAgent = "user agent value"
        var request = Request(.GET, url: "http://httpbin.org/get")
        
        request.headers["Content-Type"] = contentType
        request.headers["User-Agent"] = userAgent
        
        XCTAssertEqual(request.userAgent, userAgent)
        XCTAssertEqual(request.contentType, contentType)
    }
    
    func test_parameters_encodedInURLAsPercentEncoding() {
        var request = Request(.GET, url: "http://httpbin.org/get")
        let parameters = ["foo" : "bar", "paramName" : "paramValue", "percentEncoded" : "this needs percent encoded"]
        request.parameters = parameters as [String: Any]
        request.parameterEncoding = .percent
        
        let urlRequest = request.urlRequestValue
        
        ELTestAssertURLQueryEqual(url: urlRequest.url!, parameters: parameters)
    }
    
    func test_parameters_encodedInBodyAsPercentEncoding() {
        var request = Request(.POST, url: "http://httpbin.org/")
        let parameters = ["percentEncoded" : "this needs percent encoded"]
        request.parameters = parameters
        request.parameterEncoding = .percent
        
        let urlRequest = request.urlRequestValue
        
        let encodedData = urlRequest.httpBody
        XCTAssertNotNil(encodedData)
        
        let stringValue = NSString(data: encodedData!, encoding: String.Encoding.utf8.rawValue)!
        let components = stringValue.components(separatedBy: "=")
        XCTAssertEqual(components[0], "percentEncoded")
        XCTAssertEqual(components[1], "this%20needs%20percent%20encoded")
    }

    func test_settingParameterEncodingToJSON_setsContentTypeToJSON() {
        var request = Request(.GET, url: "http://httpbin.org/")
        
        request.parameterEncoding = .json
        
        XCTAssertEqual(request.contentType, Request.ContentType.json)
    }
    
    func test_setBody_overwritesExistingBodyData() {
        var request = Request(.POST, url: "http://httpbin.org/")
        let parameters = ["percentEncoded" : "this needs percent encoded"]
        request.parameters = parameters
        request.parameterEncoding = .percent
        let testData = "newBody".data(using: String.Encoding.utf8, allowLossyConversion: false)
        request.body = testData
        
        let urlRequest = request.urlRequestValue
    
        let encodedBody = urlRequest.httpBody
        XCTAssertNotNil(encodedBody)
        let stringValue = NSString(data: encodedBody!, encoding: String.Encoding.utf8.rawValue)!
        let components = stringValue.components(separatedBy: "=")
        XCTAssertEqual(components.count, 1)
        XCTAssertEqual(encodedBody, testData)
    }
    
    func test_queryParameters_encodesDataInURL() {
        var request = Request(.GET, url: "http://httpbin.org/get")
        let parameters = ["foo" : "bar", "paramName" : "paramValue", "percentEncoded" : "this needs percent encoded"]
        request.queryParameters = parameters
        
        let urlRequest = request.urlRequestValue
        
        ELTestAssertURLQueryEqual(url: urlRequest.url!, parameters: parameters)
    }
    
    func test_formParameters_setsFormEncodedHeaderField() {
        var request = Request(.POST, url: "http://httpbin.org/")
        request.formParameters = ["percentEncoded" : "this needs percent encoded"]
        
        XCTAssertNotNil(request.contentType)
        XCTAssertEqual(request.contentType!, Request.ContentType.formEncoded)
    }
    
    func test_formParameters_encodesDataInRequestBody() {
        var request = Request(.POST, url: "http://httpbin.org/")
        let parameters = ["percentEncoded" : "this needs percent encoded"]
        request.formParameters = parameters
        
        let encodedData = request.body
        XCTAssertNotNil(encodedData)
        
        let stringValue = NSString(data: encodedData!, encoding: String.Encoding.utf8.rawValue)!
        let components = stringValue.components(separatedBy: "=")
        XCTAssertEqual(components[0], "percentEncoded")
        XCTAssertEqual(components[1], "this%20needs%20percent%20encoded")

    }
    
    func test_formParameters_encodesDataInURLRequestBody() {
        var request = Request(.POST, url: "http://httpbin.org/")
        let parameters = ["percentEncoded" : "this needs percent encoded"]
        request.formParameters = parameters
        
        let urlRequest = request.urlRequestValue
        
        let encodedData = urlRequest.httpBody
        XCTAssertNotNil(encodedData)
        
        let stringValue = NSString(data: encodedData!, encoding: String.Encoding.utf8.rawValue)!
        let components = stringValue.components(separatedBy: "=")
        XCTAssertEqual(components[0], "percentEncoded")
        XCTAssertEqual(components[1], "this%20needs%20percent%20encoded")
    }
    
    // MARK: - Where do parameters go?
    
    func test_urlRequestValue_parametersInURL() {
        test_urlRequestValue_parametersInURL(.GET)
        test_urlRequestValue_parametersInURL(.HEAD)
        test_urlRequestValue_parametersInURL(.DELETE)
    }
    
    func test_urlRequestValue_parametersInURL(_ method: Request.Method) {
        var request = Request(method, url: "http://httpbin.org/")
        request.parameters = ["x" : "1"]
        
        let query = request.urlRequestValue.url!.query!
        
        XCTAssertEqual(query, "x=1")
    }
    
    func test_urlRequestValue_parametersInBody() {
        test_urlRequestValue_parametersInBody(.PUT)
        test_urlRequestValue_parametersInBody(.POST)
    }
    
    func test_urlRequestValue_parametersInBody(_ method: Request.Method) {
        var request = Request(method, url: "http://httpbin.org/")
        request.parameters = ["x" : "1"]
        
        let body = NSString(data: request.urlRequestValue.httpBody!, encoding: String.Encoding.utf8.rawValue)
        
        XCTAssertEqual(body, "x=1")
    }
}

// MARK: - Assert Helpers

func ELTestAssertURLQueryEqual(url: URL, parameters: [String: String]) {
    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!

    if let queryItems = components.queryItems {
        for item in queryItems {
            let originalValue = parameters[item.name]!
            XCTAssertEqual(item.value!, originalValue)
        }
        
    } else {
        XCTFail("queryItems should not be nil")
    }
    
    XCTAssertEqual((components.queryItems!).count, parameters.keys.count)
}

func ELTestAssertRequestParametersEqual(_ parameters: [String: Any], _ originalParameters: [String: Any]) {
    for (name, originalValue) in originalParameters {
        let comparisonValue: Any? = parameters[name]
        
        XCTAssert(comparisonValue != nil, "value should not be nil for key \(name)")
        
        if let originalValue = originalValue as? String,
            let comparisonValue = comparisonValue as? String {
            XCTAssertEqual(originalValue, comparisonValue)
        } else if let originalValue = originalValue as? Int,
            let comparisonValue = comparisonValue as? Int {
            XCTAssertEqual(originalValue, comparisonValue)
        } else {
            XCTFail("Failed to downcast values for originalValue: \(originalValue) and \(comparisonValue)")
        }
    }
}
