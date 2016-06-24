//
//  ParameterEncodingTests.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 3/3/16.
//  Copyright © 2016 WalmartLabs. All rights reserved.
//

import XCTest
@testable import ELWebService

class ParameterEncodingTests: XCTestCase {
    
    // MARK: encodeURL
    
    func test_encodeURL_percentEncodesWithSpacesInStrings() {
        let url = URL(string: "http://httpbin.org/get")!
        let parameters = ["percentEncoded" : "this needs percent encoded"]
        let encoding = Request.ParameterEncoding.percent
        
        let encodedURL = encoding.encodeURL(url, parameters: parameters)
        
        XCTAssertNotNil(encodedURL, "Encoded URL should be not be nil")
        XCTAssertNotNil(encodedURL?.query, "Encoded URL query should be not be nil")
        
        let stringValue = encodedURL!.query!
        let components = stringValue.components(separatedBy: "=")
        XCTAssertEqual(components[0], "percentEncoded")
        XCTAssertEqual(components[1], "this%20needs%20percent%20encoded")
    }
    
    func test_encodeURL_percentEncodesWithIntValue() {
        let url = URL(string: "http://httpbin.org/get")!
        let parameters = ["number" : 500]
        let encoding = Request.ParameterEncoding.percent
        
        let encodedURL = encoding.encodeURL(url, parameters: parameters)
        
        XCTAssertNotNil(encodedURL, "Encoded URL should be not be nil")
        XCTAssertNotNil(encodedURL?.query, "Encoded URL query should be not be nil")
        
        let stringValue = encodedURL!.query!
        let components = stringValue.components(separatedBy: "=")
        XCTAssertEqual(components[1], "500")
    }
    
    func test_encodeURL_percentEncodesWithBoolValue() {
        let url = URL(string: "http://httpbin.org/get")!
        let parameters = ["boolValue" : true]
        let encoding = Request.ParameterEncoding.percent
        
        let encodedURL = encoding.encodeURL(url, parameters: parameters)
        
        XCTAssertNotNil(encodedURL, "Encoded URL should be not be nil")
        XCTAssertNotNil(encodedURL?.query, "Encoded URL query should be not be nil")
        
        let stringValue = encodedURL!.query!
        let components = stringValue.components(separatedBy: "=")
        XCTAssertEqual(components[1], "1")
    }
    
    func test_encodeURL_custom() {
        let url = URL(string: "http://httpbin.org/get")!
        let parameters = ["key" : "part1+part2:part3"]
        let encoding = Request.ParameterEncoding.custom(transformer: .URL({
            (url: URL, parameters: [String : Any]) -> URL? in
            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return nil
            }
            components.queryItems = parameters.queryItems
            guard let encodedQueryString = components.url?.query else {
                return nil
            }
            let characterSet = CharacterSet(charactersIn: "+:").inverted
            components.percentEncodedQuery = encodedQueryString.addingPercentEncoding(withAllowedCharacters: characterSet)
            return components.url
        }))
        
        let encodedURL = encoding.encodeURL(url, parameters: parameters)
        
        XCTAssertNotNil(encodedURL, "Encoded URL should be not be nil")
        XCTAssertNotNil(encodedURL?.query, "Encoded URL query should be not be nil")
        
        let stringValue = encodedURL!.query!
        XCTAssertEqual(stringValue, "key=part1%2Bpart2%3Apart3")
    }
    
    // MARK: encodeBody

    func test_encodeBody_percentEncodesWithSpacesInStrings() {
        let parameters = ["percentEncoded" : "this needs percent encoded"]
        let encoding = Request.ParameterEncoding.percent
        
        let encodedData = encoding.encodeBody(parameters)
        
        XCTAssertNotNil(encodedData, "Encoded body should be non-nil")
        
        let stringValue = NSString(data: encodedData!, encoding: String.Encoding.utf8.rawValue)!
        let components = stringValue.components(separatedBy: "=")
        XCTAssertEqual(components[0], "percentEncoded")
        XCTAssertEqual(components[1], "this%20needs%20percent%20encoded")
    }

    func test_encodeBody_charSet() {
        let parameters = ["percentEncoded" : "this + needs percent / encoded"]
        let encoding = Request.ParameterEncoding.percent
        let encodedData = encoding.encodeBody(parameters, allowedCharacters: CharacterSet.alphanumerics)
        XCTAssertNotNil(encodedData, "Encoded body should be non-nil")

        let stringValue = NSString(data: encodedData!, encoding: String.Encoding.utf8.rawValue)!
        let components = stringValue.components(separatedBy: "=")
        XCTAssertEqual(components[0], "percentEncoded")
        XCTAssertEqual(components[1], "this%20%2B%20needs%20percent%20%2F%20encoded")
    }

    func test_encodeBody_encodesJSONParameters() {
        let encoding = Request.ParameterEncoding.json
        let parameters: [String: Any] = ["foo" : "bar", "paramName" : "paramValue", "number" : 42]
        
        let data = encoding.encodeBody(parameters)
        XCTAssert(data != nil, "Encoded JSON data should not be nil")
        
        let json = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions())
        XCTAssertNotNil(json, "Serialized JSON should not be nil")
        
        // test original parameters against encoded
        if let json = json as? [String : Any] {
            ELTestAssertRequestParametersEqual(json, parameters)
        } else {
            XCTFail("Failed to cast JSON as [String : Any]")
        }
    }
    
    func test_encodeBody_custom() {
        let parameters = ["key" : "part1+part2:part3"]
        let encoding = Request.ParameterEncoding.custom(transformer: .body({
            (parameters: [String : Any]) -> Data? in
            let url = URL(string: "http://httpbin.org/get")!
            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return nil
            }
            components.queryItems = parameters.queryItems
            guard let encodedQueryString = components.url?.query else {
                return nil
            }
            let characterSet = CharacterSet(charactersIn: "+:").inverted
            guard let percentEncodedQuery = encodedQueryString.addingPercentEncoding(withAllowedCharacters: characterSet) else {
                return nil
            }
            return percentEncodedQuery.data(using: String.Encoding.utf8)
        }, contentType: "sample"))
        let encodedData = encoding.encodeBody(parameters)
        
        XCTAssertNotNil(encodedData, "Encoded body should be non-nil")
        
        let stringValue = NSString(data: encodedData!, encoding: String.Encoding.utf8.rawValue)!
        XCTAssertEqual(stringValue, "key=part1%2Bpart2%3Apart3")
    }
}
