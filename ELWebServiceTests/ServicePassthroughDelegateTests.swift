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
        service.session = Responds200MockSession()
        
        let _ = service
            .GET("/get")
            .response { data, response in
                return true
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
        service.session = Responds200MockSession()

        let _ = service
            .GET("/get")
            .response { data, response in
                return nil
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
        service.session = Responds200MockSession()
        
        
        let shouldThrow = true
        
        let _ = service
            .GET("/get")
            .response { data, response in
                guard !shouldThrow else {
                    throw MockError.SomethingWentHorriblyWrong
                }
                
                return nil
            }
            .resume()
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func test_passthroughDelegate_modifiedRequestReturnsNil() {
        let passthroughSpy = ServicePassthroughDelegateSpy()
        
        let result = passthroughSpy.modifiedRequest(NSURLRequest())
        
        XCTAssertNil(result)
    }
}

// MARK - Mocks

class Responds200MockSession: MockSession {
    override init() {
        super.init()
        addStub(MockResponse(statusCode: 200))
    }
}

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
    
    func serviceResultFailure(response: NSURLResponse?, data: NSData?, request: NSURLRequest?, error: ErrorType) {
        serviceResultFailureExpecation?.fulfill()
    }
}
