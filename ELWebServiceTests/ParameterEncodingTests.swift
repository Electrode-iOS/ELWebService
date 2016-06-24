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
        let url = NSURL(string: "http://httpbin.org/get")!
        let parameters = ["percentEncoded" : "this needs percent encoded"]
        let encoding = Request.ParameterEncoding.Percent
        
        let encodedURL = encoding.encodeURL(url, parameters: parameters)
        
        XCTAssertNotNil(encodedURL, "Encoded URL should be not be nil")
        XCTAssertNotNil(encodedURL?.query, "Encoded URL query should be not be nil")
        
        let stringValue = encodedURL!.query!
        let components = stringValue.componentsSeparatedByString("=")
        XCTAssertEqual(components[0], "percentEncoded")
        XCTAssertEqual(components[1], "this%20needs%20percent%20encoded")
    }
    
    func test_encodeURL_percentEncodesWithIntValue() {
        let url = NSURL(string: "http://httpbin.org/get")!
        let parameters = ["number" : 500]
        let encoding = Request.ParameterEncoding.Percent
        
        let encodedURL = encoding.encodeURL(url, parameters: parameters)
        
        XCTAssertNotNil(encodedURL, "Encoded URL should be not be nil")
        XCTAssertNotNil(encodedURL?.query, "Encoded URL query should be not be nil")
        
        let stringValue = encodedURL!.query!
        let components = stringValue.componentsSeparatedByString("=")
        XCTAssertEqual(components[1], "500")
    }

    func test_encodeURL_percentEncodesWithBoolValue() {
        let url = NSURL(string: "http://httpbin.org/get")!
        let parameters = ["boolValue" : true]
        let encoding = Request.ParameterEncoding.Percent

        let encodedURL = encoding.encodeURL(url, parameters: parameters)

        XCTAssertNotNil(encodedURL, "Encoded URL should be not be nil")
        XCTAssertNotNil(encodedURL?.query, "Encoded URL query should be not be nil")

        let stringValue = encodedURL!.query!
        let components = stringValue.componentsSeparatedByString("=")
        XCTAssertEqual(components[1], "1")
    }

    func test_encodeURL_custom() {
        let url = NSURL(string: "http://httpbin.org/get")!
        let parameters = ["key" : "part1+part2:part3"]
        let encoding = Request.ParameterEncoding.Custom(transformer: .URL({
            (url: NSURL, parameters: [String : AnyObject]) -> NSURL? in
            guard let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false) else {
                return nil
            }
            components.queryItems = parameters.queryItems
            guard let encodedQueryString = components.URL?.query else {
                return nil
            }
            let characterSet = NSMutableCharacterSet(charactersInString: "+:")
            characterSet.invert()
            components.percentEncodedQuery = encodedQueryString.stringByAddingPercentEncodingWithAllowedCharacters(characterSet)
            return components.URL
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
        let encoding = Request.ParameterEncoding.Percent
        
        let encodedData = encoding.encodeBody(parameters)
        
        XCTAssertNotNil(encodedData, "Encoded body should be non-nil")
        
        let stringValue = NSString(data: encodedData!, encoding: NSUTF8StringEncoding)!
        let components = stringValue.componentsSeparatedByString("=")
        XCTAssertEqual(components[0], "percentEncoded")
        XCTAssertEqual(components[1], "this%20needs%20percent%20encoded")
    }
    
    func test_encodeBody_encodesJSONParameters() {
        let encoding = Request.ParameterEncoding.JSON
        let parameters: [String: AnyObject] = ["foo" : "bar", "paramName" : "paramValue", "number" : 42]
        
        let data = encoding.encodeBody(parameters)
        XCTAssert(data != nil, "Encoded JSON data should not be nil")
        
        let json = try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions())
        XCTAssertNotNil(json, "Serialized JSON should not be nil")
        
        // test original parameters against encoded
        if let json = json as? [String : AnyObject] {
            ELTestAssertRequestParametersEqual(json, parameters)
        } else {
            XCTFail("Failed to cast JSON as [String : AnyObject]")
        }
    }

    func test_encodeBody_custom() {
        let parameters = ["key" : "part1+part2:part3"]
        let encoding = Request.ParameterEncoding.Custom(transformer: .Body({
            (parameters: [String : AnyObject]) -> NSData? in
            guard let components = NSURLComponents(URL: nil, resolvingAgainstBaseURL: false) else {
                return nil
            }
            components.queryItems = parameters.queryItems
            guard let encodedQueryString = components.URL?.query else {
                return nil
            }
            let characterSet = NSMutableCharacterSet(charactersInString: "+:")
            characterSet.invert()
            components.percentEncodedQuery = encodedQueryString.stringByAddingPercentEncodingWithAllowedCharacters(characterSet)
            return components.URL
        }))
        let encodedData = encoding.encodeBody(parameters)

        XCTAssertNotNil(encodedData, "Encoded body should be non-nil")

        let stringValue = NSString(data: encodedData!, encoding: NSUTF8StringEncoding)!
        XCTAssertEqual(stringValue, "key=part1%2Bpart2%3Apart3")
    }

}
