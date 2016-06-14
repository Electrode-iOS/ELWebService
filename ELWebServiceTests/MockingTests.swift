//
//  MockingTests.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 3/2/16.
//  Copyright © 2016 WalmartLabs. All rights reserved.
//

import XCTest
import ELWebService

// MARK: - Mock Data Task

class MockingTests: XCTestCase {
    func test_mockDataTask_changesStateWhenSuspended() {
        let task = MockDataTask()
        task.resume()
        
        task.suspend()
        
        XCTAssertEqual(task.state, URLSessionTask.State.suspended)
    }
    
    func test_mockDataTask_changesStateWhenCancelled() {
        let task = MockDataTask()
        
        task.cancel()
        
        XCTAssertEqual(task.state, URLSessionTask.State.canceling)
    }
    
    
    func test_mockDataTask_changesStateWhenResumed() {
        let task = MockDataTask()
        
        task.resume()
        
        XCTAssertEqual(task.state, URLSessionTask.State.running)
    }
}

// MARK: - Mock Session

extension MockingTests {
    func test_mockSession_matchesStubWhenMatcherReturnsTrue() {
        struct StubRequest: URLRequestEncodable {
            var urlRequestValue: URLRequest {
                return URLRequest(url: URL(string: "")!)
            }
        }
        
        let session = MockSession()
        let response = MockResponse(statusCode: 200)
        session.addStub(response) { _ in return true }
        
        let (_, urlResponse, error) = session.stubbedResponse(request: StubRequest())
        
        let httpResponse = urlResponse as? HTTPURLResponse
        
        XCTAssertNotNil(httpResponse)
        XCTAssertEqual(httpResponse!.statusCode, 200)
        XCTAssertNil(error)
    }
    
    func test_mockSession_failsToMatchStubWhenMatcherReturnsFalse() {
        struct StubRequest: URLRequestEncodable {
            var urlRequestValue: URLRequest {
                return URLRequest(url: URL(string: "")!)
            }
        }
        
        let session = MockSession()
        let response = MockResponse(statusCode: 200)
        session.addStub(response) { _ in return false }
        
        let (data, urlResponse, error) = session.stubbedResponse(request: StubRequest())

        XCTAssertNil(data)
        XCTAssertNil(urlResponse)
        XCTAssertNil(error)
    }
}

// MARK: - Mock Response

extension MockingTests {
    func test_mockResponse_initializationWithData() {
        let data = Data()
        let response = MockResponse(statusCode: 200, data: data)
        
        XCTAssertNotNil(response.data)
        XCTAssertEqual(data, response.data)
    }
    
    func test_mockResponse_returnsErrorResultWhenRequestURLIsInvalid() {
        struct InvalidURLRequestEncodable: URLRequestEncodable {
            var urlRequestValue: URLRequest {
                var url = URL(string: "    ")!
                return URLRequest(url: url)
            }
        }
        
        let data = Data()
        let mockedResponse = MockResponse(statusCode: 200, data: data)
        
        let (responseData, httpResponse, error) = mockedResponse.dataTaskResult(InvalidURLRequestEncodable())
        
        XCTAssertNil(httpResponse)
        XCTAssertNil(responseData)
        XCTAssertNotNil(error)
    }
}

extension MockingTests {
    func test_urlResponse_mockableDataTask() {
        let url = URL(string: "/test_urlResponse_mockableDataTask")!
        let response = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let request = URLRequest(url: url)
        
        let (_, urlResponse, _) = response.dataTaskResult(request)
        
        XCTAssertEqual(urlResponse, response)
    }
    
    func test_error_mockableDataTask() {
        let error = NSError(domain: "test", code: 500, userInfo: nil)
        let request = URLRequest(url: URL(string: "/test_error_mockableDataTask")!)
        
        let (_, _, resultError) = error.dataTaskResult(request)
        
        XCTAssertEqual(resultError, error)
    }
}
