//
//  NSURLComponentsTests.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 3/3/16.
//  Copyright © 2016 WalmartLabs. All rights reserved.
//

import XCTest
@testable import ELWebService

class NSURLComponentsTests: XCTestCase {
    func test_appendQueryItems_appendsWhenQueryItemsExists() {
        var components = URLComponents(string: "http://httpbin.org/get?foo=bar")!
        let items = [URLQueryItem(name: "boo", value: "far")]
        
        components.appendQueryItems(items)
        
        XCTAssertNotNil(components.queryItems)
        XCTAssertEqual(components.queryItems!.count, 2)
    }
    
    func test_appendQueryItems_appendsWhenPercentEncodedQueryIsNil() {
        var components = URLComponents(string: "http://httpbin.org/get")!
        let items = [URLQueryItem(name: "boo", value: "far")]
        
        components.appendQueryItems(items)
        
        XCTAssertNotNil(components.queryItems)
        XCTAssertEqual(components.queryItems!.count, 1)
    }
}
