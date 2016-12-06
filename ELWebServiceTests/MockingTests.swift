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
        
        XCTAssertEqual(task.state, NSURLSessionTaskState.Suspended)
    }
    
    func test_mockDataTask_changesStateWhenCancelled() {
        let task = MockDataTask()
        
        task.cancel()
        
        XCTAssertEqual(task.state, NSURLSessionTaskState.Canceling)
    }
    
    
    func test_mockDataTask_changesStateWhenResumed() {
        let task = MockDataTask()
        
        task.resume()
        
        XCTAssertEqual(task.state, NSURLSessionTaskState.Running)
    }

    // MARK: - Mock Session
    func test_mockSession_matchesStubWhenMatcherReturnsTrue() {
        struct StubRequest: URLRequestEncodable {
            var urlRequestValue: NSURLRequest {
                return NSURLRequest(URL: NSURL(string: "")!)
            }
        }
        
        let session = MockSession()
        let response = MockResponse(statusCode: 200)
        session.addStub(response) { _ in return true }
        
        let (_, urlResponse, error) = session.stubbedResponse(request: StubRequest())
        
        let httpResponse = urlResponse as? NSHTTPURLResponse
        
        XCTAssertNotNil(httpResponse)
        XCTAssertEqual(httpResponse!.statusCode, 200)
        XCTAssertNil(error)
    }
    
    func test_mockSession_failsToMatchStubWhenMatcherReturnsFalse() {
        struct StubRequest: URLRequestEncodable {
            var urlRequestValue: NSURLRequest {
                return NSURLRequest(URL: NSURL(string: "")!)
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

    // MARK: - Mock Response
    func test_mockResponse_initializationWithData() {
        let data = NSData()
        let response = MockResponse(statusCode: 200, data: data)
        
        XCTAssertNotNil(response.data)
        XCTAssertEqual(data, response.data)
    }
    
    func test_mockResponse_returnsErrorResultWhenRequestURLIsInvalid() {
        struct InvalidURLRequestEncodable: URLRequestEncodable {
            var urlRequestValue: NSURLRequest {
                return NSURLRequest()
            }
        }
        
        let data = NSData()
        let mockedResponse = MockResponse(statusCode: 200, data: data)
        
        let (responseData, httpResponse, error) = mockedResponse.dataTaskResult(InvalidURLRequestEncodable())
        
        XCTAssertNil(httpResponse)
        XCTAssertNil(responseData)
        XCTAssertNotNil(error)
    }

    func test_urlResponse_mockableDataTask() {
        let url = NSURL(string: "/test_urlResponse_mockableDataTask")!
        let response = NSURLResponse(URL: url, MIMEType: nil, expectedContentLength: 0, textEncodingName: nil)
        let request = NSURLRequest(URL: url)
        
        let (_, urlResponse, _) = response.dataTaskResult(request)
        
        XCTAssertEqual(urlResponse, response)
    }
    
    func test_error_mockableDataTask() {
        let error = NSError(domain: "test", code: 500, userInfo: nil)
        let request = NSURLRequest(URL: NSURL(string: "/test_error_mockableDataTask")!)
        
        let (_, _, resultError) = error.dataTaskResult(request)
        
        XCTAssertEqual(resultError, error)
    }
}
