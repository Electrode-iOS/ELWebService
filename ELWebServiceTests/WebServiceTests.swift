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

// MARK: - Request Creation

class WebServiceTests: XCTestCase {
    func test_request_constructsValidAbsoluteURL() {
        let service = WebService(baseURLString:  "http://httpbin.org/")
        let session = RequestRecordingSession()
        service.session = session
        
        let task = service.request(.GET, path: "/get")
        task.resume()
        
        
        let recordedRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedRequest)
        
        let url = recordedRequest?.url
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
        
        let method = recordedRequest?.httpMethod
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
        
        let method = recordedRequest?.httpMethod
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
        
        let method = recordedRequest?.httpMethod
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
        
        let method = recordedRequest?.httpMethod
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
        
        let method = recordedRequest?.httpMethod
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

// MARK - dataTaskWithRequest

extension WebServiceTests {
    // TODO: legacy test, remove after dataTaskWithRequest API is removed
    func test_dataTaskWithRequest_returnsSuspendedDataTask() {
        let service = WebService(baseURLString: "http://httpbin.org/")
        let request = URLRequest(url: URL(string: "http://httpbin.org/")!)
        
        let task = service.dataTaskWithRequest(request) { data, response, error in }
        
        XCTAssertEqual(task.state, URLSessionTask.State.suspended)
    }
}

// MARK: - dataTaskSource

extension WebServiceTests {
    // TODO: legacy test, remove after dataTaskSource API is removed
    func test_dataTaskSource_setterSetsSession() {
        let urlSession = URLSession.shared()
        let service = WebService(baseURLString: "http://httpbin.org/")
        service.dataTaskSource = urlSession
        
        XCTAssertTrue(service.session is URLSession)
        XCTAssertTrue(service.session as! URLSession === urlSession)
    }
    
    // TODO: legacy test, remove after dataTaskSource API is removed
    func test_dataTaskSource_returnsDataTask() {
        final class MockDataTaskSource: SessionDataTaskDataSource {
            func dataTaskWithRequest(_ request: URLRequest, completionHandler: (Data?, URLResponse?, NSError?) -> Void) -> URLSessionDataTask {
                return URLSession.shared().dataTask(with: request, completionHandler: completionHandler)
            }
        }
        let dataTaskSource = MockDataTaskSource()
        let request = URLRequest(url: URL(string: "http://httpbin.org/")!)
        
        let task = dataTaskSource.dataTask(request: request) { data, response, error in }
        
        XCTAssertTrue(task is URLSessionDataTask)
        XCTAssertEqual((task as! URLSessionDataTask).state, URLSessionTask.State.suspended)
    }
}

// MARK: - servicePassthroughDelegate

extension WebService: ServicePassthroughDataSource {
    static let mockPassthroughDelegate = ServicePassthroughDelegateSpy()
    
    public var servicePassthroughDelegate: ServicePassthroughDelegate {
        return WebService.mockPassthroughDelegate
    }
}

extension WebServiceTests {
    func test_servicePassthroughDelegate_setsToSelfWhenImplemented() {
        let service = WebService(baseURLString: "http://httpbin.org/")
        
        XCTAssertNotNil(service.passthroughDelegate)
        XCTAssertTrue(service.passthroughDelegate! === WebService.mockPassthroughDelegate as ServicePassthroughDelegate)
    }
}
