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
        let components = NSURLComponents(string: "http://httpbin.org/get?foo=bar")!
        let items = [NSURLQueryItem(name: "boo", value: "far")]
        
        components.appendQueryItems(items)
        
        XCTAssertNotNil(components.queryItems)
        XCTAssertEqual(components.queryItems!.count, 2)
    }
    
    func test_appendQueryItems_appendsWhenPercentEncodedQueryIsNil() {
        let components = NSURLComponents(string: "http://httpbin.org/get")!
        let items = [NSURLQueryItem(name: "boo", value: "far")]
        
        components.appendQueryItems(items)
        
        XCTAssertNotNil(components.queryItems)
        XCTAssertEqual(components.queryItems!.count, 1)
    }
}
