//
//  ServicePassthroughDelegateTests.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 2/9/16.
//  Copyright © 2016 WalmartLabs. All rights reserved.
//

import XCTest
@testable import ELWebService

private let baseURL = URL(string: "http://httpbin.org/")!

class ServicePassthroughDelegateTests: XCTestCase {
    func test_passthroughDelegate_receivesEventsWhenResponseIsValid() {
        let passthroughSpy = ServicePassthroughDelegateSpy()
        passthroughSpy.requestSentExpectation = expectation(description: "requestSent passthrough called")
        passthroughSpy.responseReceivedExpectation = expectation(description: "responseReceived passthrough called")
        passthroughSpy.updateUIBeginExpectation = expectation(description: "updateUIBegin passthrough called")
        passthroughSpy.updateUIEndExpectation = expectation(description: "updateUIEnd passthrough called")
        let service = WebService(baseURL: baseURL, passthroughDelegate: passthroughSpy)
        service.session = Responds200MockSession()
        
        let _ = service
            .GET("/get")
            .response { data, response in
                return .Value(true)
            }
            .updateUI { value in
            }
            .resume()
        
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test_passthroughDelegate_receivesEventsWhenResponseHandlerReturnsEmpty() {
        let passthroughSpy = ServicePassthroughDelegateSpy()
        passthroughSpy.requestSentExpectation = expectation(description: "requestSent passthrough called")
        passthroughSpy.responseReceivedExpectation = expectation(description: "responseReceived passthrough called")
        passthroughSpy.updateUIBeginExpectation = expectation(description: "updateUIBegin passthrough called")
        passthroughSpy.updateUIEndExpectation = expectation(description: "updateUIEnd passthrough called")
        let service = WebService(baseURL: baseURL, passthroughDelegate: passthroughSpy)
        service.session = Responds200MockSession()

        let _ = service
            .GET("/get")
            .response { data, response in
                return .empty
            }
            .updateUI { value in
            }
            .resume()
        
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test_passthroughDelegate_receivesFailureEventWhenResponseHandlerReturnsFailure() {
        let passthroughSpy = ServicePassthroughDelegateSpy()
        passthroughSpy.serviceResultFailureExpecation = expectation(description: "serviceResultFailure passthrough called")
        let service = WebService(baseURL: baseURL, passthroughDelegate: passthroughSpy)
        service.session = Responds200MockSession()

        let _ = service
            .GET("/get")
            .response { data, response in
                return .failure(MockError.somethingWentHorriblyWrong)
            }
            .resume()
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test_passthroughDelegate_modifiedRequestReturnsNil() {
        let passthroughSpy = ServicePassthroughDelegateSpy()
        
        let result = passthroughSpy.modifiedRequest(URLRequest(url: URL(string: "")!))
        
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

enum MockError: Error {
    case somethingWentHorriblyWrong
}

class ServicePassthroughDelegateSpy: ServicePassthroughDelegate {
    var requestSentExpectation: XCTestExpectation?
    var responseReceivedExpectation: XCTestExpectation?
    var updateUIBeginExpectation: XCTestExpectation?
    var updateUIEndExpectation: XCTestExpectation?
    var serviceResultFailureExpecation: XCTestExpectation?
    
    func requestSent(_ request: URLRequest) {
        requestSentExpectation?.fulfill()
    }
    
    func responseReceived(_ response: URLResponse?, data: Data?, request: URLRequest?, error: NSError?) {
        responseReceivedExpectation?.fulfill()
    }
    
    func updateUIBegin(_ response: URLResponse?) {
        updateUIBeginExpectation?.fulfill()
    }
    
    func updateUIEnd(_ response: URLResponse?) {
        updateUIEndExpectation?.fulfill()
    }
    
    func serviceResultFailure(_ response: URLResponse?, data: Data?, request: URLRequest?, error: Error) {
        serviceResultFailureExpecation?.fulfill()
    }
}
