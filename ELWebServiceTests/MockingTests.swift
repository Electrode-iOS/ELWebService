//
//  MockingTests.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 3/2/16.
//  Copyright © 2016 WalmartLabs. All rights reserved.
//

import XCTest
import ELWebService

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
}

extension MockingTests {
    func test_mockResponse_initializationWithData() {
        let data = NSData()
        let response = MockResponse(statusCode: 200, data: data)
        
        XCTAssertNotNil(response.data)
        XCTAssertEqual(data, response.data)
    }
}

extension MockingTests {
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
}
