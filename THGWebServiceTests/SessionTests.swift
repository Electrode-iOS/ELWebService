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

class SessionTests: XCTestCase {
    
    // MARK: Utilities
    
    var baseURL: String {
        get {
            return "http://httpbin.org/"
        }
    }
    
    var session = Session()
    
    func responseHandler(expectation expectation: XCTestExpectation) -> (NSData?, NSURLResponse?) -> Void {
        return { data, response in
            
            let httpResponse = response as! NSHTTPURLResponse
            
            if httpResponse.statusCode == 200 {
                expectation.fulfill()
            }
        }
    }
    
    func jsonResponseHandler(expectation expectation: XCTestExpectation) -> (AnyObject?) -> Void {
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
        let request = RequestBuilder(url: baseURL).GET("/get").request
        let task = session.enqueue(request)
                    .response(handler)
        
        XCTAssertEqual(task.state, NSURLSessionTaskState.Running, "Task should be running by default")
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    /// Verify that absolute paths work against a different base URL.
    func testGetAbsolutePath() {
        let successExpectation = expectationWithDescription("Received status 200")
        let handler = responseHandler(expectation: successExpectation)
        let request = RequestBuilder(url: "www.walmart.com")
            .GET("http://httpbin.org/get")
            .request
        let task = session.enqueue(request)
            .response(handler)
        
        XCTAssertEqual(task.state, NSURLSessionTaskState.Running, "Task should be running by default")
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testPostEndpoint() {
        let successExpectation = expectationWithDescription("Received status 200")
        let handler = responseHandler(expectation: successExpectation)
        let request = RequestBuilder(url: baseURL)
            .POST("/post")
            .request
        let task = session.enqueue(request)
            .response(handler)
        
        XCTAssertEqual(task.state, NSURLSessionTaskState.Running, "Task should be running by default")
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testPutEndpoint() {
        let successExpectation = expectationWithDescription("Received status 200")
        let handler = responseHandler(expectation: successExpectation)
        let request = RequestBuilder(url: baseURL)
            .PUT("/put")
            .request
        let task = session.enqueue(request)
            .response(handler)
        
        XCTAssertEqual(task.state, NSURLSessionTaskState.Running, "Task should be running by default")
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testDeleteEndpoint() {
        let successExpectation = expectationWithDescription("Received status 200")
        let handler = responseHandler(expectation: successExpectation)
        let request = RequestBuilder(url: baseURL)
            .DELETE("/delete")
            .request
        let task = session.enqueue(request)
            .response(handler)
        
        XCTAssertEqual(task.state, NSURLSessionTaskState.Running, "Task should be running by default")
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testDisableStartTasksImmediately() {
        let baseURL = "http://httpbin.org/"
        
        let session = Session()
        session.startTasksImmediately = false
        
        let request = RequestBuilder(url: baseURL)
            .GET("/get")
            .request
        let task = session.enqueue(request)

        XCTAssertEqual(task.state, NSURLSessionTaskState.Suspended, "Task should be suspended when startTasksImmediately is disabled")
    }

    func testErrorHandler() {
        let baseURL = "httpppppp://httpbin.org/"
        let errorExpectation = expectationWithDescription("Error handler called for bad URL")
        var wasResponseCalled = false
        
        let request = RequestBuilder(url: baseURL)
            .GET("/")
            .request
            
        session.enqueue(request)
            .response { data, response in
                wasResponseCalled = true
            }
            .responseError { error in
                XCTAssertFalse(wasResponseCalled, "Response should not be called for error cases")
                errorExpectation.fulfill()
            }
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testSpecifyingResponseHandlerQueue() {
        let successExpectation = expectationWithDescription("Received status 200")
        let backgroundExpectation = expectationWithDescription("Background handler ran")
        let queue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)

        let request = RequestBuilder(url: baseURL)
            .GET("/get")
            .request
        
        let task = session.enqueue(request)
            .response(queue) { data, response in
                backgroundExpectation.fulfill()
            }
            .response { data, response in
                successExpectation.fulfill()
        }
        
        XCTAssertEqual(task.state, NSURLSessionTaskState.Running, "Task should be running by default")
        waitForExpectationsWithTimeout(4, handler: nil)
    }
    
    func testGetJSON() {
        let successExpectation = expectationWithDescription("Received status 200")
        let handler = jsonResponseHandler(expectation: successExpectation)
        
        let request = RequestBuilder(url: baseURL)
            .GET("/get")
            .request
        
        let task = session.enqueue(request)
            .responseJSON(handler)
        
        XCTAssertEqual(task.state, NSURLSessionTaskState.Running, "Task should be running by default")
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testGetJSONWithSpecificQueue() {
        let successExpectation = expectationWithDescription("Received status 200")
        let handler = jsonResponseHandler(expectation: successExpectation)
        let queue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
        let request = RequestBuilder(url: baseURL)
            .GET("/get")
            .request
        let task = session.enqueue(request)
            .responseJSON(queue, handler: handler)
        
        XCTAssertEqual(task.state, NSURLSessionTaskState.Running, "Task should be running by default")
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testGetPercentEncodedParameters() {
        let successExpectation = expectationWithDescription("Received status 200")
        let parameters = ["foo" : "bar", "percentEncoded" : "this needs percent encoded"]
        let request = RequestBuilder(url: baseURL)
            .GET("/get", parameters: parameters)
            .request
        
        session.enqueue(request)
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
        let parameters = ["foo" : "bar", "percentEncoded" : "this needs percent encoded"]
        
        let request = RequestBuilder(url: baseURL)
            .POST("/post", parameters: parameters)
            .request

        session.enqueue(request)
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
        let parameters = ["foo" : "bar", "number" : 42]
        
        let request = RequestBuilder(url: baseURL)
            .POST("/post",
                parameters: parameters,
                options: [.ParameterEncoding(.JSON)])
            .request

        session.enqueue(request)
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
    
    func testPostJSONEncodedArray() {
        let successExpectation = expectationWithDescription("Received status 200")
        
        let jsonObject = ["foo" : "bar", "number" : 42]
        let jsonArray = [jsonObject, jsonObject]
        
        let request = RequestBuilder(url: baseURL)
            .POST("/post",
                parameters: nil,
                options: [
                    .ParameterEncoding(.JSON),
                    .BodyJSON(jsonArray)
                ])
            .request

        session.enqueue(request)
            .response { data, response in
                
                let httpResponse = response as! NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    successExpectation.fulfill()
                }
            }
            .responseJSON { json in
                let castedJSON = json as? [String : AnyObject]
                XCTAssert(castedJSON != nil)
                
                let deliveredArray = castedJSON!["json"] as? [[String : AnyObject]]
                XCTAssert(deliveredArray != nil)
                
                for deliveredJSONObject in deliveredArray! {
                    RequestTests.assertRequestParametersNotEqual(deliveredJSONObject, toOriginalParameters: jsonObject)
                }
        }
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testHeadersDelivered() {
        let successExpectation = expectationWithDescription("Received status 200")
        let headers = ["Some-Test-Header" :"testValue"]
        
        let request = RequestBuilder(url: baseURL)
            .GET("/get",
                parameters: nil,
                options: [.Header("Some-Test-Header", "testValue")])
            .request
        
        session.enqueue(request)
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

