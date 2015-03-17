//
//  WebServiceTests.swift
//  THGWebService
//
//  Created by Angelo Di Paolo on 3/11/15.
//  Copyright (c) 2015 TheHolyGrail. All rights reserved.
//

import UIKit
import XCTest
import THGWebService

class WebServiceTests: XCTestCase {
    
    // MARK: -
    
    var baseURL: String {
        get {
            return "http://httpbin.org/"
        }
    }
    
    func responseHandler(#expectation: XCTestExpectation) -> (NSData?, NSURLResponse?) -> Void {
        return { data, response in
            let httpResponse = response as! NSHTTPURLResponse
            
            if httpResponse.statusCode == 200 {
                expectation.fulfill()
            }
        }
    }

    // MARK: - Tests
    
    func testGetEndpoint() {
        let successExpectation = expectationWithDescription("Received status 200")
        let handler = responseHandler(expectation: successExpectation)
        let service = WebService(baseURLString: baseURL)
        let task = service
                    .GET("/get")
                    .response(handler)
        
        XCTAssertEqual(task.state, NSURLSessionTaskState.Running, "Task should be running by default")
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testPostEndpoint() {
        let successExpectation = expectationWithDescription("Received status 200")
        let handler = responseHandler(expectation: successExpectation)
        let service = WebService(baseURLString: baseURL)
        let task = service
            .POST("/post")
            .response(handler)
        
        XCTAssertEqual(task.state, NSURLSessionTaskState.Running, "Task should be running by default")
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testPutEndpoint() {
        let successExpectation = expectationWithDescription("Received status 200")
        let handler = responseHandler(expectation: successExpectation)
        let service = WebService(baseURLString: baseURL)
        let task = service
            .PUT("/put")
            .response(handler)
        
        XCTAssertEqual(task.state, NSURLSessionTaskState.Running, "Task should be running by default")
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testDeleteEndpoint() {
        let successExpectation = expectationWithDescription("Received status 200")
        let handler = responseHandler(expectation: successExpectation)
        let service = WebService(baseURLString: baseURL)
        let task = service
            .DELETE("/delete")
            .response(handler)
        
        XCTAssertEqual(task.state, NSURLSessionTaskState.Running, "Task should be running by default")
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testHeadEndpoint() {
        let successExpectation = expectationWithDescription("Received status 200")
        let handler = responseHandler(expectation: successExpectation)
        let service = WebService(baseURLString: baseURL)
        let task = service
            .HEAD("/head")
            .response(handler)
        
        XCTAssertEqual(task.state, NSURLSessionTaskState.Running, "Task should be running by default")
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testDisableStartTasksImmediately() {
        let baseURL = "http://httpbin.org/"
        
        var service = WebService(baseURLString: baseURL)
        service.startTasksImmediately = false
        
        let task = service.GET("/get")

        XCTAssertEqual(task.state, NSURLSessionTaskState.Suspended, "Task should be suspended when startTasksImmediately is disabled")
    }

    func testErrorHandler() {
        let baseURL = "httpppppp://httpbin.org/"
        let errorExpectation = expectationWithDescription("Error handler called for bad URL")
        var wasResponseCalled = false
        
        WebService(baseURLString: baseURL)
            .GET("/")
            .response { data, response in
                wasResponseCalled = true
            }
            .responseError { error in
                println("error called")

                if let error = error {
                    
                    XCTAssertFalse(wasResponseCalled, "Response should not be called for error cases")
                    errorExpectation.fulfill()
                }
            }
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testConstructRequestPath() {
        let service = WebService(baseURLString: "http://httpbin.org/")
        let method = Request.Method.DELETE
        let servicePath = "/post"
        let requestPath = service.constructRequestPath(relativePath: servicePath)
        
        XCTAssertEqual(requestPath, servicePath)
    }
    
    
    func testConstructRequest() {
        let service = WebService(baseURLString: "http://httpbin.org/")
        let method = Request.Method.DELETE
        let url = "/delete"
        let request = service.constructRequest(method, url: url)
        
        XCTAssertEqual(request.method, method)
        XCTAssertEqual(request.url, url)
    }
}

