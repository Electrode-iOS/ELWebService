//
//  WebServiceTests.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 3/11/15.
//  Copyright (c) 2015 WalmartLabs. All rights reserved.
//

import UIKit
import XCTest
@testable import ELWebService

class WebServiceTests: XCTestCase {
    var baseURL: String {
        return "http://httpbin.org/"
    }
}

// MARK: - Request Creation

extension WebServiceTests {
    func test_request_constructsValidAbsoluteURL() {
        let service = WebService(baseURLString:  "http://httpbin.org/")
        let session = RequestRecordingSession()
        service.session = session
        
        let task = service.request(.GET, path: "/get")
        task.resume()
        
        
        let recordedRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedRequest)
        
        let url = recordedRequest?.URL
        XCTAssertNotNil(url)
        
        let absoluteString = url!.absoluteString
        XCTAssertEqual(absoluteString, "http://httpbin.org/get")
    }
    
    func test_get_createsGETRequest() {
        let service = WebService(baseURLString:  "http://httpbin.org/")
        let session = RequestRecordingSession()
        service.session = session
        
        let task = service.GET("/get")
        task.resume()
        
        let recordedRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedRequest)
        
        let method = recordedRequest?.HTTPMethod
        XCTAssertNotNil(method)
        
        XCTAssertEqual(method!, "GET")
    }
    
    func test_post_createPOSTRequest() {
        let service = WebService(baseURLString:  "http://httpbin.org/")
        let session = RequestRecordingSession()
        service.session = session
        
        let task = service.POST("/post")
        task.resume()
        
        let recordedRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedRequest)
        
        let method = recordedRequest?.HTTPMethod
        XCTAssertNotNil(method)
        
        XCTAssertEqual(method!, "POST")
    }
    
    func test_delete_createDELETERequest() {
        let service = WebService(baseURLString:  "http://httpbin.org/")
        let session = RequestRecordingSession()
        service.session = session
        
        let task = service.DELETE("/delete")
        task.resume()
        
        let recordedRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedRequest)
        
        let method = recordedRequest?.HTTPMethod
        XCTAssertNotNil(method)
        
        XCTAssertEqual(method!, "DELETE")
    }
    
    func test_head_createHEADRequest() {
        let service = WebService(baseURLString:  "http://httpbin.org/")
        let session = RequestRecordingSession()
        service.session = session
        
        let task = service.HEAD("/head")
        task.resume()
        
        let recordedRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedRequest)
        
        let method = recordedRequest?.HTTPMethod
        XCTAssertNotNil(method)
        
        XCTAssertEqual(method!, "HEAD")
    }
    
    func test_put_createPUTRequest() {
        let service = WebService(baseURLString:  "http://httpbin.org/")
        let session = RequestRecordingSession()
        service.session = session
        
        let task = service.PUT("/put")
        task.resume()
        
        let recordedRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedRequest)
        
        let method = recordedRequest?.HTTPMethod
        XCTAssertNotNil(method)
        
        XCTAssertEqual(method!, "PUT")
    }
}

// MARK: - absoluteURLString

extension WebServiceTests {
    func test_absoluteURLString_constructsValidAbsoluteURL() {
        let service = WebService(baseURLString: "http://www.walmart.com/")
        
        let url = service.absoluteURLString("/foo")
        
        XCTAssertEqual(url, "http://www.walmart.com/foo")
    }
    
    func test_absoluteURLString_constructsValidURLWhenPathIsAbsoluteURL() {
        let service = WebService(baseURLString: "http://www.walmart.com/")
        
        let url = service.absoluteURLString("http://httpbin.org/get")
        
        XCTAssertEqual(url, "http://httpbin.org/get")
    }
}
