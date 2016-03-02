//
//  ServiceTaskTests.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 3/2/16.
//  Copyright © 2016 WalmartLabs. All rights reserved.
//

import XCTest
@testable import ELWebService

class ServiceTaskTests: XCTestCase {
    func test_updateUI_runsOnTheMainThread() {
        let expectation = expectationWithDescription("updateUI handler is run")
        let request = Request(.GET, url: "/foo")
        let task = ServiceTask(request: request, session: RespondsWith200Session())
        
        task.response { data, response in
                return .Empty
            }
            .updateUI { value in
                XCTAssertTrue(NSThread.isMainThread())
                expectation.fulfill()
            }
            .resume()
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func test_updateUI_receivesResponseHandlerValue() {
        let expectation = expectationWithDescription("updateUI handler is run")
        let request = Request(.GET, url: "/foo")
        let task = ServiceTask(request: request, session: RespondsWith200Session())

        task.response { data, response in
                return ServiceTaskResult.Value(true)
            }
            .updateUI { value in
                if let value = value as? Bool {
                    XCTAssertTrue(value, "Expected response handler value to be true")
                    expectation.fulfill()
                } else {
                    XCTFail("Failed to cast resopnse handler value as Bool")
                    
                }
            }
            .resume()
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func test_response_runsOnBackgroundThread() {
        let expectation = expectationWithDescription("response handler is run")
        let request = Request(.GET, url: "/foo")
        let task = ServiceTask(request: request, session: RespondsWith200Session())
        
        task.response { data, response in
                XCTAssertTrue(!NSThread.isMainThread())
                expectation.fulfill()
   
                return .Empty
            }
            .resume()
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
}

// MARK: - JSON

extension ServiceTaskTests {
    func test_responseJSON_handlerIsCalledWhenJSONIsValid() {
        let expectation = expectationWithDescription("JSON response handler is called")
        let request = Request(.GET, url: "/status/200")
        let task = ServiceTask(request: request, session: JSONSession())
        
        task.responseJSON { json in
                expectation.fulfill()
                return .Empty
            }
            .resume()
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func test_responseJSON_errorHandlerIsCalledWhenJSONIsInvalid() {
        let expectation = expectationWithDescription("Error handler is called")
        let request = Request(.GET, url: "/status/200")
        let task = ServiceTask(request: request, session: InvalidJSONSession())
        
        task.responseJSON { json in
                XCTFail("responseJSON handler should not be called when JSON is invalid")
                return .Empty
            }
            .responseError { error in
                expectation.fulfill()
            }
            .resume()
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
}

// MARK: - Errors

extension ServiceTaskTests {
    func test_responseError_handlerCalledWhenSessionReturnsError() {
        let expectation = expectationWithDescription("Error handler called when session returns an error")
        let request = Request(.GET, url: "/status/200")
        let task = ServiceTask(request: request, session: ErrorSession())
        
        task.responseError { error in
                expectation.fulfill()
            }
            .resume()
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func test_responseError_responseHandlerIsNotCalled() {
        let expectation = expectationWithDescription("Error handler called when session returns an error")
        let request = Request(.GET, url: "/status/200")
        let task = ServiceTask(request: request, session: ErrorSession())
        
        task.response { data, response in
                XCTFail("Response handler should not be called when session returns an error")
                return .Empty
            }
            .responseError { error in
                expectation.fulfill()
            }
            .resume()
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func test_responseError_runsOnBackgroundThread() {
        let expectation = expectationWithDescription("Error handler called when session returns an error")
        let request = Request(.GET, url: "/status/200")
        let task = ServiceTask(request: request, session: ErrorSession())
        
        task.responseError { error in
                XCTAssertTrue(!NSThread.isMainThread())
                expectation.fulfill()
            }
            .resume()
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func test_updateErrorUI_handlerCalledWhenSessionReturnsError() {
        let expectation = expectationWithDescription("Error handler called when session returns an error")
        let request = Request(.GET, url: "/status/200")
        let task = ServiceTask(request: request, session: ErrorSession())
        
        task.updateErrorUI { error in
                expectation.fulfill()
            }
            .resume()
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func test_updateErrorUI_runsOnMainThread() {
        let expectation = expectationWithDescription("Error handler called when session returns an error")
        let request = Request(.GET, url: "/status/200")
        let task = ServiceTask(request: request, session: ErrorSession())
        
        task.updateErrorUI { error in
                XCTAssertTrue(NSThread.isMainThread(), "updateErrorUI handler should be running on the main thread")
                expectation.fulfill()
            }
            .resume()
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
}

// MARK: - Request

extension ServiceTaskTests {
    func test_setHeaders_headerValuesGetEncodedInURLRequest() {
        let request = Request(.GET, url: "/status/200")
        let session = RequestRecordingSession()
        let task = ServiceTask(request: request, session: session)
        let headers =  ["Some-Test-Header" :"testValue"]
        
        task.setHeaders(headers)
        task.resume()
        
        let urlRequest = session.request?.urlRequestValue
        XCTAssertNotNil(urlRequest)
        
        
        XCTAssertNotNil(urlRequest?.allHTTPHeaderFields)
        
        let deliveredHeaders = urlRequest!.allHTTPHeaderFields!
        RequestTests.assertRequestParametersNotEqual(deliveredHeaders, toOriginalParameters: request.headers)
    }
}
