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
    
    func responseHandler(expectation expectation: XCTestExpectation) -> (NSData?, NSURLResponse?) -> ServiceTaskResult {
        return { data, response in
            XCTAssertTrue(!NSThread.isMainThread())

            let httpResponse = response as! NSHTTPURLResponse
            
            if httpResponse.statusCode == 200 {
                expectation.fulfill()
            }
            
            return ServiceTaskResult.Empty
        }
    }
    
    func jsonResponseHandler(expectation expectation: XCTestExpectation) -> (AnyObject) -> ServiceTaskResult {
        return { json in
            XCTAssertTrue(!NSThread.isMainThread())

            if json is NSDictionary {
                expectation.fulfill()
            }
            
            return ServiceTaskResult.Empty
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
                    .resume()

        XCTAssertEqual(task.state, NSURLSessionTaskState.Running, "Task should be running by default")
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testAbsoluteURLString() {
        let service = WebService(baseURLString: "http://www.walmart.com/")
        let url = service.absoluteURLString("/foo")
        XCTAssertEqual(url, "http://www.walmart.com/foo")
    }
    
    /// Verify that absolute paths work against a different base URL.
    func testGetAbsolutePath() {
        let successExpectation = expectationWithDescription("Received status 200")
        let handler = responseHandler(expectation: successExpectation)
        let service = WebService(baseURLString: "www.walmart.com")
        let task = service
            .GET("http://httpbin.org/get")
            .response(handler)
            .resume()

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
            .resume()
        
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
            .resume()

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
            .resume()
        
        XCTAssertEqual(task.state, NSURLSessionTaskState.Running, "Task should be running by default")
        waitForExpectationsWithTimeout(2, handler: nil)
    }

    func testErrorHandler() {
        let baseURL = "httpppppp://httpbin.org/"
        let errorExpectation = expectationWithDescription("Error handler called for bad URL")
        var wasResponseCalled = false
        
        WebService(baseURLString: baseURL)
            .GET("/")
            .response { data, response in
                wasResponseCalled = true
                return ServiceTaskResult.Empty
            }
            .responseError { error in
                XCTAssertTrue(!NSThread.isMainThread())
                XCTAssertFalse(wasResponseCalled, "Response should not be called for error cases")
                errorExpectation.fulfill()
            }
            .resume()

        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testUpdateErrorUIHandler() {
        let baseURL = "httpppppp://httpbin.org/"
        let errorExpectation = expectationWithDescription("Error handler called for bad URL")
        var wasResponseCalled = false
        
        WebService(baseURLString: baseURL)
            .GET("/")
            .response { data, response in
                wasResponseCalled = true
                return ServiceTaskResult.Empty
            }
            .updateErrorUI { error in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertFalse(wasResponseCalled, "Response should not be called for error cases")
                errorExpectation.fulfill()
            }
            .resume()
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    
    
    func testGetJSON() {
        let successExpectation = expectationWithDescription("Received status 200")
        let handler = jsonResponseHandler(expectation: successExpectation)
        let service = WebService(baseURLString: baseURL)
        let task = service
            .GET("/get")
            .responseJSON(handler)
            .resume()

        XCTAssertEqual(task.state, NSURLSessionTaskState.Running, "Task should be running by default")
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testGetPercentEncodedParameters() {
        let successExpectation = expectationWithDescription("Received status 200")
        let service = WebService(baseURLString: baseURL)
        let parameters = ["foo" : "bar", "percentEncoded" : "this needs percent encoded"]
        
        service
            .GET("/get")
                .setParameters(parameters)
            .response { data, response in
                
                let httpResponse = response as! NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    successExpectation.fulfill()
                }
                
                return .Empty
            }
            .responseJSON { json in
                let castedJSON = json as? [String : AnyObject]
                XCTAssert(castedJSON != nil)

                let deliveredParameters = castedJSON!["args"] as? [String : AnyObject]
                XCTAssert(deliveredParameters != nil)
                
                RequestTests.assertRequestParametersNotEqual(deliveredParameters!, toOriginalParameters: parameters)
                
                return .Empty
            }
            .resume()

        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testPostPercentEncodedParameters() {
        let successExpectation = expectationWithDescription("Received status 200")
        let service = WebService(baseURLString: baseURL)
        let parameters = ["foo" : "bar", "percentEncoded" : "this needs percent encoded"]
        
        service
            .POST("/post")
                .setParameters(parameters)
            .response { data, response in
                
                let httpResponse = response as! NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    successExpectation.fulfill()
                }
                
                return .Empty
            }
            .responseJSON { json in
                let castedJSON = json as? [String : AnyObject]
                XCTAssert(castedJSON != nil)
                
                let deliveredParameters = castedJSON!["form"] as? [String : AnyObject]
                XCTAssert(deliveredParameters != nil)
                
                RequestTests.assertRequestParametersNotEqual(deliveredParameters!, toOriginalParameters: parameters)
                
                return .Empty
            }
            .resume()

        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testPostJSONEncodedParameters() {
        let successExpectation = expectationWithDescription("Received status 200")
        let service = WebService(baseURLString: baseURL)
        let parameters = ["foo" : "bar", "number" : 42]
        
        service
            .POST("/post")
                .setParameters(parameters, encoding: .JSON)
            .response { data, response in
                let httpResponse = response as! NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    successExpectation.fulfill()
                }
                
                return .Empty
            }
            .responseJSON { json in
                let castedJSON = json as? [String : AnyObject]
                XCTAssert(castedJSON != nil)
                
                let deliveredParameters = castedJSON!["json"] as? [String : AnyObject]
                XCTAssert(deliveredParameters != nil)
                
                RequestTests.assertRequestParametersNotEqual(deliveredParameters!, toOriginalParameters: parameters)
                
                return .Empty
            }
            .resume()
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testPostJSONEncodedArray() {
        let successExpectation = expectationWithDescription("Received status 200")
        let service = WebService(baseURLString: baseURL)
        
        let jsonObject = ["foo" : "bar", "number" : 42]
        let jsonArray = [jsonObject, jsonObject]
        
        service
            .POST("/post")
                .setParameterEncoding(.JSON)
                .setJSON(jsonArray)
            .response { data, response in
                let httpResponse = response as! NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    successExpectation.fulfill()
                }
                
                return .Empty
            }
            .responseJSON { json in
                let castedJSON = json as? [String : AnyObject]
                XCTAssert(castedJSON != nil)
                
                let deliveredArray = castedJSON!["json"] as? [[String : AnyObject]]
                XCTAssert(deliveredArray != nil)
                
                for deliveredJSONObject in deliveredArray! {
                    RequestTests.assertRequestParametersNotEqual(deliveredJSONObject, toOriginalParameters: jsonObject)
                }
                
                return .Empty
            }
            .resume()
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testHeadersDelivered() {
        let successExpectation = expectationWithDescription("Received status 200")
        let service = WebService(baseURLString: baseURL)
        let headers =  ["Some-Test-Header" :"testValue"]
        
        service
            .GET("/get")
                .setHeaders(headers)
            .response { data, response in
                let httpResponse = response as! NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    successExpectation.fulfill()
                }
                
                return .Empty
            }
            .responseJSON { json in
                let castedJSON = json as? [String : AnyObject]
                XCTAssert(castedJSON != nil)
                
                let deliveredHeaders = castedJSON!["headers"] as? [String : AnyObject]
                XCTAssert(deliveredHeaders != nil)
                
                RequestTests.assertRequestParametersNotEqual(deliveredHeaders!, toOriginalParameters: headers)
                
                return .Empty
            }
            .resume()
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
}

