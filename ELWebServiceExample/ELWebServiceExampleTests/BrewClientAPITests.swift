//
//  BrewClientAPITests.swift
//  ELWebServiceExample
//
//  Created by Angelo Di Paolo on 3/4/16.
//  Copyright © 2016 WalmartLabs. All rights reserved.
//

import XCTest
import ELWebService
@testable import ELWebServiceExample

// MARK: - Mock Client

class MockBrewClient: BrewClientAPI {
    let webService = WebService(baseURLString: "http://brewhapi.herokuapp.com/")
    
    init(session: MockSession) {
        webService.session = session
    }
}

// MARK: - Request Encoding Tests

class BrewClientAPITests: XCTestCase {
    func test_fetchBrewWithBrewID_constructsPathWithBrewID() {
        let brewID = "12345"
        let expectedPath = "/brews/\(brewID)"
        let session = RequestRecordingSession()
        let client = MockBrewClient(session: session)
        
        client.fetchBrewWithBrewID(brewID).resume()
        
        let recordedURLRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedURLRequest)
        
        let url = recordedURLRequest?.URL
        XCTAssertNotNil(url)
        
        let path = url?.path
        XCTAssertNotNil(path)
        XCTAssertEqual(path, expectedPath)
    }
}

// MARK: - Resposnse Handling Tests

extension BrewClientAPITests {
    var brewJSONStub: AnyObject {
        let brewery = ["name": "Long Trail Brewing Company", "location": "Vermont"]
        let brew = ["name": "Limbo IPA", "id": "1", "style": "Imperial IPA", "brewery": brewery]
        return ["brews": [brew]]
    }
    
    func test_responseAsBrews_callsCompletionHandlerWhenJSONIsValid() {
        let expectation = expectationWithDescription("responseAsBrews handler called when JSON is valid")
        let session = MockSession()
        session.addStub(MockResponse(statusCode: 200, json: brewJSONStub))
        let client = MockBrewClient(session: session)
        
        client
            .fetchBrewWithBrewID("12345")
            .responseAsBrews { brews in
                XCTAssertEqual(brews.count, 1)
                expectation.fulfill()
            }.updateErrorUI { error in
                XCTFail("updateErrorUI handler should not be called when JSON is valid")
            }
            .resume()
        
        
        waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    func test_responseAsBrews_callsErrorHandlerWhenJSONIsInvalid() {
        let expectation = expectationWithDescription("updateErrorUI handler called when JSON is invalid")
        let session = MockSession()
        session.addStub(MockResponse(statusCode: 200, json: ["brewsssss": ["bad json"]]))
        let client = MockBrewClient(session: session)
        
        client
            .fetchBrewWithBrewID("12345")
            .responseAsBrews { brews in
                XCTFail("responseAsBrews handler should not be called when JSON is invalid")
            }.updateErrorUI { error in
                expectation.fulfill()
            }
            .resume()
        
        
        waitForExpectationsWithTimeout(2.0, handler: nil)
    }
}
