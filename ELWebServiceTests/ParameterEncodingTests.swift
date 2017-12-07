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
}
