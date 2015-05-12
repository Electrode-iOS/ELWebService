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
    
    // MARK: Utilities
    
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
    
    func jsonResponseHandler(#expectation: XCTestExpectation) -> (AnyObject?) -> Void {
        return { json in
            
            if json is NSDictionary {
                expectation.fulfill()
            }
        }
    }

    // MARK: Tests  
    
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
    
    /**
     Verify that absolute paths work against a different base URL.
    */
    func testGetAbsolutePath() {
        let successExpectation = expectationWithDescription("Received status 200")
        let handler = responseHandler(expectation: successExpectation)
        let service = WebService(baseURLString: "www.walmart.com")
        let task = service
            .GET("http://httpbin.org/get")
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
        let requestPath = service.requestPath(relativePath: servicePath)
        
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
    
    func testSpecifyingResponseHandlerQueue() {
        let successExpectation = expectationWithDescription("Received status 200")
        let backgroundExpectation = expectationWithDescription("Background handler ran")
        var backgroundRan = false
        let handler = responseHandler(expectation: successExpectation)
        let service = WebService(baseURLString: baseURL)
        let queue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)

        let task = service
            .GET("/get")
            .response(queue) { data, response in
                backgroundExpectation.fulfill()
                backgroundRan = true
            }
            .response { data, response in
                let httpResponse = response as! NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 && backgroundRan {
                    successExpectation.fulfill()
                }
        }
        
        XCTAssertEqual(task.state, NSURLSessionTaskState.Running, "Task should be running by default")
        waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    func testGetJSON() {
        let successExpectation = expectationWithDescription("Received status 200")
        let handler = jsonResponseHandler(expectation: successExpectation)
        let service = WebService(baseURLString: baseURL)
        let task = service
            .GET("/get")
            .responseJSON(handler)
        
        XCTAssertEqual(task.state, NSURLSessionTaskState.Running, "Task should be running by default")
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testGetJSONWithSpecificQueue() {
        let successExpectation = expectationWithDescription("Received status 200")
        let handler = jsonResponseHandler(expectation: successExpectation)
        let service = WebService(baseURLString: baseURL)
        let queue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
        let task = service
            .GET("/get")
            .responseJSON(queue, handler: handler)
        
        XCTAssertEqual(task.state, NSURLSessionTaskState.Running, "Task should be running by default")
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testGetPercentEncodedParameters() {
        let successExpectation = expectationWithDescription("Received status 200")
        let handler = responseHandler(expectation: successExpectation)
        let service = WebService(baseURLString: baseURL)
        let parameters = ["foo" : "bar", "percentEncoded" : "this needs percent encoded"]
        
        let task = service
        .GET("/get", parameters: parameters)
        .response { data, response in
            
            let httpResponse = response as! NSHTTPURLResponse
            
            if httpResponse.statusCode == 200 {
                successExpectation.fulfill()
            }
        }
        .responseJSON { json in
            let castedJSON = json as? [String : AnyObject]
            XCTAssert(castedJSON != nil)

            let deliveredParameters = castedJSON!["args"] as? [String : AnyObject]
            XCTAssert(deliveredParameters != nil)
            
            RequestTests.assertRequestParametersNotEqual(deliveredParameters!, toOriginalParameters: parameters)
        }
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testPostPercentEncodedParameters() {
        let successExpectation = expectationWithDescription("Received status 200")
        let handler = responseHandler(expectation: successExpectation)
        let service = WebService(baseURLString: baseURL)
        let parameters = ["foo" : "bar", "percentEncoded" : "this needs percent encoded"]
        
        let task = service
            .POST("/post", parameters: parameters)
            .response { data, response in
                
                let httpResponse = response as! NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    successExpectation.fulfill()
                }
            }
            .responseJSON { json in
                let castedJSON = json as? [String : AnyObject]
                XCTAssert(castedJSON != nil)
                
                let deliveredParameters = castedJSON!["form"] as? [String : AnyObject]
                XCTAssert(deliveredParameters != nil)
                
                RequestTests.assertRequestParametersNotEqual(deliveredParameters!, toOriginalParameters: parameters)
        }
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testPostJSONEncodedParameters() {
        let successExpectation = expectationWithDescription("Received status 200")
        let handler = responseHandler(expectation: successExpectation)
        let service = WebService(baseURLString: baseURL)
        let parameters = ["foo" : "bar", "number" : 42]
        
        let task = service
            .POST("/post",
                parameters: parameters,
                options: [.ParameterEncoding(.JSON)])
            .response { data, response in
                
                let httpResponse = response as! NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    successExpectation.fulfill()
                }
            }
            .responseJSON { json in
                let castedJSON = json as? [String : AnyObject]
                XCTAssert(castedJSON != nil)
                
                let deliveredParameters = castedJSON!["json"] as? [String : AnyObject]
                XCTAssert(deliveredParameters != nil)
                
                RequestTests.assertRequestParametersNotEqual(deliveredParameters!, toOriginalParameters: parameters)
        }
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testHeadersDelivered() {
        let successExpectation = expectationWithDescription("Received status 200")
        let handler = responseHandler(expectation: successExpectation)
        let service = WebService(baseURLString: baseURL)
        var headers = ["Some-Test-Header" :"testValue"]
        
        let task = service
            .GET("/get",
                parameters: nil,
                options: [.Header("Some-Test-Header", "testValue")])
            .response { data, response in
                
                let httpResponse = response as! NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    successExpectation.fulfill()
                }
            }
            .responseJSON { json in
                let castedJSON = json as? [String : AnyObject]
                XCTAssert(castedJSON != nil)
                
                let deliveredHeaders = castedJSON!["headers"] as? [String : AnyObject]
                XCTAssert(deliveredHeaders != nil)
                
                RequestTests.assertRequestParametersNotEqual(deliveredHeaders!, toOriginalParameters: headers)
        }
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
}

