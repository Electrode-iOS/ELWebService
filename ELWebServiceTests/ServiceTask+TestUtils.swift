//
//  ServiceTask+TestUtils.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 2/3/16.
//  Copyright © 2016 WalmartLabs. All rights reserved.
//

import Foundation
@testable import ELWebService

extension ServiceTask {
    // expose internal handleResponse method to obj-c tests via injectResponse()
    @objc public func injectResponse(response: NSURLResponse?, data: NSData?, error: NSError?) {
        handleResponse(response, data: data, error: error)
    }
}

// MARK: - Response Mock

extension NSURLResponse {
    static func mockResponse() -> NSURLResponse {
        let url = NSURL(string: "foo")!
        return NSURLResponse(URL: url, MIMEType: nil, expectedContentLength: 0, textEncodingName: nil)
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
