//
//  ServicePassthroughDelegateTests.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 2/9/16.
//  Copyright © 2016 WalmartLabs. All rights reserved.
//

import XCTest
@testable import ELWebService

class ServicePassthroughDelegateTests: XCTestCase {
    func test_passthroughDelegate_receivesEventsWhenResponseIsValid() {
        let passthroughSpy = ServicePassthroughDelegateSpy()
        passthroughSpy.requestSentExpectation = expectationWithDescription("requestSent passthrough called")
        passthroughSpy.responseReceivedExpectation = expectationWithDescription("responseReceived passthrough called")
        passthroughSpy.updateUIBeginExpectation = expectationWithDescription("updateUIBegin passthrough called")
        passthroughSpy.updateUIEndExpectation = expectationWithDescription("updateUIEnd passthrough called")
        let service = WebService(baseURLString: "http://httpbin.org/", passthroughDelegate: passthroughSpy)
        
        let _ = service
            .GET("/get")
            .response { data, response in
                return .Value(true)
            }
            .updateUI { value in
            }
            .resume()
        
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func test_passthroughDelegate_receivesEventsWhenResponseHandlerReturnsEmpty() {
        let passthroughSpy = ServicePassthroughDelegateSpy()
        passthroughSpy.requestSentExpectation = expectationWithDescription("requestSent passthrough called")
        passthroughSpy.responseReceivedExpectation = expectationWithDescription("responseReceived passthrough called")
        passthroughSpy.updateUIBeginExpectation = expectationWithDescription("updateUIBegin passthrough called")
        passthroughSpy.updateUIEndExpectation = expectationWithDescription("updateUIEnd passthrough called")
        let service = WebService(baseURLString: "http://httpbin.org/", passthroughDelegate: passthroughSpy)
        
        let _ = service
            .GET("/get")
            .response { data, response in
                return .Empty
            }
            .updateUI { value in
            }
            .resume()
        
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func test_passthroughDelegate_receivesFailureEventWhenResponseHandlerReturnsFailure() {
        let passthroughSpy = ServicePassthroughDelegateSpy()
        passthroughSpy.serviceResultFailureExpecation = expectationWithDescription("serviceResultFailure passthrough called")
        let service = WebService(baseURLString: "http://httpbin.org/", passthroughDelegate: passthroughSpy)
        
        let _ = service
            .GET("/get")
            .response { data, response in
                return .Failure(MockError.SomethingWentHorriblyWrong)
            }
            .resume()
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
}

// MARK - Mocks

enum MockError: ErrorType {
    case SomethingWentHorriblyWrong
}

class ServicePassthroughDelegateSpy: ServicePassthroughDelegate {
    var requestSentExpectation: XCTestExpectation?
    var responseReceivedExpectation: XCTestExpectation?
    var updateUIBeginExpectation: XCTestExpectation?
    var updateUIEndExpectation: XCTestExpectation?
    var serviceResultFailureExpecation: XCTestExpectation?
    
    func requestSent(request: NSURLRequest) {
        requestSentExpectation?.fulfill()
    }
    
    func responseReceived(response: NSURLResponse?, data: NSData?, request: NSURLRequest?, error: NSError?) {
        responseReceivedExpectation?.fulfill()
    }
    
    func updateUIBegin(response: NSURLResponse?) {
        updateUIBeginExpectation?.fulfill()
    }
    
    func updateUIEnd(response: NSURLResponse?) {
        updateUIEndExpectation?.fulfill()
    }
    
    func serviceResultFailure(error: ErrorType) {
        serviceResultFailureExpecation?.fulfill()
    }
}
