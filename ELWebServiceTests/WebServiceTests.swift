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
    func test_request_constructsValidAbsoluteURL() {
        let service = WebService(baseURLString:  "http://httpbin.org/")
        let session = RequestRecordingSession()
        service.session = session

        let task = service.request(.GET, path: "get")
        task.resume()


        let recordedRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedRequest)

        let url = recordedRequest?.url
        XCTAssertNotNil(url)

        let absoluteString = url!.absoluteString
        XCTAssertEqual(absoluteString, "http://httpbin.org/get")
    }

    func test_absoluteURLString_constructsValidAbsoluteURL() {
        let service = WebService(baseURLString: "http://www.walmart.com")

        let url = service.absoluteURLString("/v1/foo/bar")

        XCTAssertEqual(url, "http://www.walmart.com/v1/foo/bar")
    }

    func test_absoluteURLString_constructsValidURLWhenPathDoesNotStartWithSlash() {
        let service = WebService(baseURLString: "http://www.walmart.com/")

        let url = service.absoluteURLString("v1/foo/bar")

        XCTAssertEqual(url, "http://www.walmart.com/v1/foo/bar")
    }
    
     func test_absoluteURLString_constructsValidURLWhenBaseHasRootPath() {
        let service = WebService(baseURLString: "http://localhost:8000/rootPath")

        let url = service.absoluteURLString("/v1/foo/bar")

        XCTAssertEqual(url, "http://localhost:8000/rootPath/v1/foo/bar")
    }

    func test_absoluteURLString_constructsValidURLWhenBaseHasRootPathWithSlash() {
        let service = WebService(baseURLString: "http://localhost:8000/rootPath/")

        let url = service.absoluteURLString("v1/foo/bar")

        XCTAssertEqual(url, "http://localhost:8000/rootPath/v1/foo/bar")
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

// MARK: - URL initializers
extension WebServiceTests {
    func test_init_baseURL() {
        guard let baseURL = URL(string: "http://httpbin.org") else {
            XCTFail()
            return
        }

        let service = WebService(baseURL: baseURL)
        XCTAssertEqual(service.baseURL.absoluteString, "http://httpbin.org")
    }

    func test_init_baseURL_passthroughDelegate() {
        guard let baseURL = URL(string: "http://httpbin.org") else {
            XCTFail()
            return
        }
        let service = WebService(baseURL: baseURL, passthroughDelegate: WebService.mockPassthroughDelegate)
        XCTAssertEqual(service.baseURL.absoluteString, "http://httpbin.org")
    }
}
