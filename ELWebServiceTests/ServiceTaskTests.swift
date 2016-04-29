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
    // MARK: Stub
    
    func successfulTask() -> ServiceTask {
        let session = MockSession()
        session.addStub(MockResponse(statusCode: 200))
        
        return ServiceTask(request: Request(.GET, url: "/status/200"), session: session)
    }
    
    // MARK: Tests
    
    func test_updateUI_runsOnTheMainThread() {
        let expectation = expectationWithDescription("updateUI handler is called")
        let task = successfulTask()
        
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
    
    func test_updateUI_isNotCalledWhenResponseHandlerReturnsFailure() {
        enum ResponseError: ErrorType {
            case IveMadeAHugeMistake
        }
        
        let expectation = expectationWithDescription("responseError handler is called")
        let task = successfulTask()
        
        task
            .response { data, response in
                return .Failure(ResponseError.IveMadeAHugeMistake)
            }
            .updateUI { value in
                XCTFail("updateUI handler should not be called")
            }
            .responseError { error in
                expectation.fulfill()
            }
            .resume()
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func test_updateUI_receivesResponseHandlerValue() {
        let expectation = expectationWithDescription("updateUI handler is called")
        let task = successfulTask()

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
        let expectation = expectationWithDescription("response handler is called")
        let task = successfulTask()
        
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
        let session = MockSession()
        
        session.addStub(MockResponse(statusCode: 200, json: ["foo": "bar"]))
        let task = ServiceTask(request: Request(.GET, url: "/json"), session: session)
        
        task.responseJSON { json in
                expectation.fulfill()
                return .Empty
            }
            .resume()
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func test_responseJSON_errorHandlerIsCalledWhenJSONIsInvalid() {
        let expectation = expectationWithDescription("Error handler is called")
        let session = MockSession()
        
        let badJSONData = NSString(string: "{}couldneverbeJSON-[][[42").dataUsingEncoding(NSUTF8StringEncoding)
        let response = MockResponse(statusCode: 204, data: badJSONData!)
        session.addStub(response)
        
        let task = ServiceTask(request: Request(.GET, url: "/json"), session: session)
        
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
    
    func test_responseJSON_errorHandlerIsCalledWhenJSONIsNil() {
        let expectation = expectationWithDescription("Error handler is called")
        let session = MockSession()
        session.addStub(MockResponse(statusCode: 204))
        let task = ServiceTask(request: Request(.GET, url: "/json"), session: session)
        
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
    // MARK: Stub
    
    func errorTask() -> ServiceTask {
        enum TaskTestError: ErrorType {
            case RequestFailed
        }
        
        let session = MockSession()
        session.addStub(TaskTestError.RequestFailed as NSError)
        
        return ServiceTask(request: Request(.GET, url: "/error"), session: session)
    }
    
    // MARK: Tests
    
    func test_responseError_handlerCalledWhenSessionReturnsError() {
        let expectation = expectationWithDescription("Error handler called when session returns an error")
        let task = errorTask()
        
        task.responseError { error in
                expectation.fulfill()
            }
            .resume()
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func test_responseError_responseHandlerIsNotCalled() {
        let expectation = expectationWithDescription("Error handler called when session returns an error")
        let task = errorTask()
        
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
        let task = errorTask()
        
        task.responseError { error in
                XCTAssertTrue(!NSThread.isMainThread())
                expectation.fulfill()
            }
            .resume()
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func test_responseError_calledWhenResposneHandlerReturnsFailure() {
        enum ResponseError: ErrorType {
            case StubError
        }
        let expectation = expectationWithDescription("Error handler called when session returns an error")
        let task = successfulTask()
        
        task
            .response { data, response in
                return .Failure(ResponseError.StubError)
            }
            .response { data, response in
                XCTFail("response handler should not be called")
                return .Empty
            }
            .responseError { error in
                expectation.fulfill()
            }
            .resume()
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func test_responseError_isNotCalledWhenReturningResultsInResponseHandlers() {
        let expectation = expectationWithDescription("response handler is called")
        let session = MockSession()
        session.addStub(MockResponse(statusCode: 200))
        
        let task = ServiceTask(request: Request(.GET, url: "/status/200"), session: session)
        
        task
            .response { data, response in
                return .Empty
            }
            .response { data, response in
                return .Value(1)
            }
            .responseError { error in
                XCTFail("responseError should not be called")
            }
            .response { data, response in
                expectation.fulfill()
                return .Empty
            }
            .resume()
        
        waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    func test_updateErrorUI_isNotCalledWhenReturningResultsInResponseHandlers() {
        let expectation = expectationWithDescription("response handler is called")
        let session = MockSession()
        session.addStub(MockResponse(statusCode: 200))
        
        let task = ServiceTask(request: Request(.GET, url: "/status/200"), session: session)
        
        task
            .response { data, response in
                return .Empty
            }
            .response { data, response in
                return .Value(1)
            }
            .updateErrorUI { error in
                XCTFail("updateErrorUI should not be called")
            }
            .response { data, response in
                expectation.fulfill()
                return .Empty
            }
            .resume()
        
        waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    func test_updateErrorUI_handlerCalledWhenSessionReturnsError() {
        let expectation = expectationWithDescription("Error handler called when session returns an error")
        let task = errorTask()
        
        task.updateErrorUI { error in
                expectation.fulfill()
            }
            .resume()
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func test_updateErrorUI_runsOnMainThread() {
        let expectation = expectationWithDescription("Error handler called when session returns an error")
        let task = errorTask()
        
        task.updateErrorUI { error in
                XCTAssertTrue(NSThread.isMainThread(), "updateErrorUI handler should be running on the main thread")
                expectation.fulfill()
            }
            .resume()
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
}

// MARK: - Transform

extension ServiceTaskTests {
    func test_transform_closureCalled() {
        let closureCalled = expectationWithDescription("transform closure called")

        successfulTask()
            .transform { _ in
                closureCalled.fulfill()
                return .Empty
            }
            .resume()

        waitForExpectationsWithTimeout(2, handler: nil)
    }

    func test_transform_closureNotCalledForError() {
        let done = expectationWithDescription("done")

        errorTask()
            .transform { _ in
                XCTFail("Did not expect transform closure to be called")
                return .Empty
            }
            .updateErrorUI { _ in
                done.fulfill()
            }
            .resume()

        waitForExpectationsWithTimeout(2, handler: nil)
    }

    func test_transform_ordering() {
        let closure1Called = expectationWithDescription("transform closure 1 called")
        let closure2Called = expectationWithDescription("transform closure 2 called")
        var closure1CalledFirst = false

        successfulTask()
            .transform { _ in
                closure1CalledFirst = true
                closure1Called.fulfill()
                return .Empty
            }
            .transform { _ in
                XCTAssertTrue(closure1CalledFirst, "Expected closure 1 to be called before closure 2")
                closure2Called.fulfill()
                return .Empty
            }
            .resume()

        waitForExpectationsWithTimeout(2, handler: nil)
    }

    func test_transform_resultPropagation() {
        let closure1Called = expectationWithDescription("transform closure 1 called")
        let closure2Called = expectationWithDescription("transform closure 2 called")
        let closure3Called = expectationWithDescription("transform closure 3 called")
        let closure4Called = expectationWithDescription("transform closure 4 called")
        let done = expectationWithDescription("done")

        successfulTask()
            .transform { value in
                XCTAssertNil(value, "Expected initial value to be nil")

                closure1Called.fulfill()
                return .Value("transform 1 value")
            }
            .response { _, _ in
                return .Value("response value")
            }
            .transform { value in
                if let value = value as? String {
                    XCTAssertEqual(value, "response value", "Expected to receive result of response handler")
                } else {
                    XCTFail("Expected to receive result of previous handler")
                }

                closure2Called.fulfill()
                return .Value("transform 2 value")
            }
            .transform { value in
                if let value = value as? String {
                    XCTAssertEqual(value, "transform 2 value", "Expected to receive result of previous handler")
                } else {
                    XCTFail("Expected to receive result of previous handler")
                }

                closure3Called.fulfill()
                return .Empty
            }
            .transform { value in
                XCTAssertNil(value, "Expected .Empty result to propagate as nil")

                closure4Called.fulfill()
                return .Value("transform 4 value")
            }
            .updateUI { value in
                if let value = value as? String {
                    XCTAssertEqual(value, "transform 4 value", "Expected to receive result of previous handler")
                } else {
                    XCTFail("Expected to receive result of previous handler")
                }

                done.fulfill()
            }
            .resume()

        waitForExpectationsWithTimeout(2, handler: nil)
    }
}

// MARK: - Recover

extension ServiceTaskTests {
    func test_recover_closureCalled() {
        let closureCalled = expectationWithDescription("closure called")

        errorTask()
            .recover { error in
                closureCalled.fulfill()
                return .Failure(error)
            }
            .resume()

        waitForExpectationsWithTimeout(2, handler: nil)
    }

    func test_recover_closureNotCalledForSuccess() {
        let done = expectationWithDescription("done")

        successfulTask()
            .recover { error in
                XCTFail("Did not expect recover closure to be called")
                return .Failure(error)
            }
            .updateUI { _ in
                done.fulfill()
            }
            .resume()

        waitForExpectationsWithTimeout(2, handler: nil)
    }

    func test_recover_ordering() {
        let closure1Called = expectationWithDescription("recover closure 1 callled")
        let closure2Called = expectationWithDescription("recover closure 2 callled")
        var closure1CalledFirst = false

        errorTask()
            .recover { error in
                closure1CalledFirst = true
                closure1Called.fulfill()
                return .Failure(error)
            }
            .recover { error in
                XCTAssertTrue(closure1CalledFirst, "Expected closure 1 to be called before closure 2")
                closure2Called.fulfill()
                return .Failure(error)
            }
            .resume()

        waitForExpectationsWithTimeout(2, handler: nil)
    }

    func test_recover_resultPropagation() {
        let closure1Called = expectationWithDescription("recover closure 1 callled")
        let closure2Called = expectationWithDescription("recover closure 2 callled")
        let closure3Called = expectationWithDescription("recover closure 3 callled")
        let done = expectationWithDescription("done")

        enum ServiceTaskTestError: ErrorType {
            case Oops(detail: String)
        }

        errorTask()
            .recover { error in
                closure1Called.fulfill()
                return .Failure(error)
            }
            .recover { error in
                closure2Called.fulfill()
                return .Failure(ServiceTaskTestError.Oops(detail: "closure 2 error"))
            }
            .recover { error in
                if let error = error as? ServiceTaskTestError {
                    switch error {
                    case .Oops(let detail):
                        XCTAssertEqual(detail, "closure 2 error", "Expected to receive result of previous handler")
                    }
                } else {
                    XCTFail("Expected to receive result of previous handler")
                }

                closure3Called.fulfill()
                return .Failure(ServiceTaskTestError.Oops(detail: "closure 3 error"))
            }
            .updateErrorUI { error in
                if let error = error as? ServiceTaskTestError {
                    switch error {
                    case .Oops(let detail):
                        XCTAssertEqual(detail, "closure 3 error", "Expected to receive result of previous handler")
                    }
                } else {
                    XCTFail("Expected to receive result of previous handler")
                }

                done.fulfill()
            }
            .resume()
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
}

// MARK: - Transform and Recover Control Flow

extension ServiceTaskTests {
    func test_transformAndRecover_controlFlow() {
        let closure1Called = expectationWithDescription("recover closure 1 callled")
        let closure3Called = expectationWithDescription("recover closure 3 callled")
        let done = expectationWithDescription("done")

        enum ServiceTaskTestError: ErrorType {
            case Oops
        }

        successfulTask()
            .transform { _ in
                closure1Called.fulfill()
                return .Failure(ServiceTaskTestError.Oops)
            }
            .transform { _ in
                XCTFail("Did not expect transform closure to be called after failure")
                return .Empty
            }
            .recover { _ in
                closure3Called.fulfill()
                return .Value("closure 3 value")
            }
            .recover { error in
                XCTFail("Did not expect recover closure to be called after recovery")
                return .Failure(error)
            }
            .updateErrorUI { _ in
                XCTFail("Did not expect update UI (error) closure to be called after recovery")
            }
            .updateUI { _ in
                done.fulfill()
            }
            .resume()

        waitForExpectationsWithTimeout(2, handler: nil)
    }
}

// MARK: - Request API

extension ServiceTaskTests {
    func test_setHeaders_encodesValuesInURLRequest() {
        let request = Request(.GET, url: "/test_setHeaders_encodesValuesInURLRequest")
        let session = RequestRecordingSession()
        let task = ServiceTask(request: request, session: session)
        let headers =  ["Some-Test-Header" :"testValue"]
        
        task.setHeaders(headers)
        task.resume()
        
        let recordedURLRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedURLRequest)
        XCTAssertNotNil(recordedURLRequest?.allHTTPHeaderFields)
        
        let deliveredHeaders = recordedURLRequest!.allHTTPHeaderFields!
        RequestTests.assertRequestParametersNotEqual(deliveredHeaders, toOriginalParameters: request.headers)
    }
    
    func test_setHeaderValue_encodesValuesInURLRequest() {
        let request = Request(.GET, url: "/test_setHeaderValue_encodesValuesInURLRequest")
        let session = RequestRecordingSession()
        let task = ServiceTask(request: request, session: session)
        let testValue = "testValue"
        
        task.setHeaderValue(testValue, forName: "Some-Test-Header")
        task.resume()
        
        let recordedURLRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedURLRequest)
        XCTAssertNotNil(recordedURLRequest?.allHTTPHeaderFields)
        
        let deliveredHeaders = recordedURLRequest!.allHTTPHeaderFields!
        
        XCTAssertNotNil(deliveredHeaders["Some-Test-Header"])
        XCTAssertEqual(deliveredHeaders["Some-Test-Header"], testValue)
    }
    
    // setBody
    
    func test_setBody_encodesDataInURLRequest() {
        let bodyData = NSData()
        let request = Request(.GET, url: "/test_setBody_encodesDataInURLRequest")
        let session = RequestRecordingSession()
        let task = ServiceTask(request: request, session: session)
        
        task.setBody(bodyData)
        task.resume()
        
        let recordedURLRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedURLRequest)
        XCTAssertEqual(recordedURLRequest!.HTTPBody, bodyData)
        
    }
    
    func test_setCachePolicy_setsPolicyInURLRequest() {
        let request = Request(.GET, url: "/test_setBody_encodesDataInURLRequest")
        let session = RequestRecordingSession()
        let task = ServiceTask(request: request, session: session)
        
        task.setCachePolicy(.ReloadIgnoringLocalCacheData)
        task.resume()
        
        let recordedURLRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedURLRequest)
        XCTAssertEqual(recordedURLRequest!.cachePolicy, NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData)
        
    }
    
    
    // setJSON
    
    func test_setParametersEncoding_setsParameterEncodingInRequest() {
        var request = Request(.POST, url: "/test_setParametersEncoding_setsParameterEncodingInRequest")
        request.parameters = ["foo": "bar"]
        let session = RequestRecordingSession()
        let task = ServiceTask(request: request, session: session)
        
        task.setParameterEncoding(.JSON)
        task.resume()
        
        let recordedURLRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedURLRequest)
        XCTAssertNotNil(recordedURLRequest?.HTTPBody)
    }
    
    // setParameters
    
    func test_setParameters_encodesDataInURLAsPercentEncoding() {
        let parameters = ["foo" : "bar", "paramName" : "paramValue", "percentEncoded" : "this needs percent encoded"]
        let session = RequestRecordingSession()
        let task = ServiceTask(request: Request(.GET, url: "/test"), session: session)
        
        task.setParameters(parameters)
        task.resume()

        let recordedURLRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedURLRequest)
        XCTAssertNotNil(recordedURLRequest?.URL)

        let components = NSURLComponents(URL: recordedURLRequest!.URL!, resolvingAgainstBaseURL: false)!
        
        if let queryItems = components.queryItems {
            for item in queryItems {
                let originalValue = parameters[item.name]!
                XCTAssertEqual(item.value!, originalValue)
            }
            
        } else {
            XCTFail("queryItems should not be nil")
        }
        
        XCTAssertEqual((components.queryItems!).count, parameters.keys.count)
    }
    
    func test_setParameters_encodesDataInBodyAsPercentEncoding() {
        let parameters = ["percentEncoded" : "this needs percent encoded"]
        let session = RequestRecordingSession()
        let task = ServiceTask(request: Request(.POST, url: "/test"), session: session)
        
        task.setParameters(parameters)
        task.resume()
        
        let recordedURLRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedURLRequest)
        XCTAssertNotNil(recordedURLRequest?.URL)
        
        let encodedData = recordedURLRequest!.HTTPBody
        XCTAssertNotNil(encodedData)
        
        let stringValue = NSString(data: encodedData!, encoding: NSUTF8StringEncoding)!
        let components = stringValue.componentsSeparatedByString("=")
        XCTAssertEqual(components[0], "percentEncoded")
        XCTAssertEqual(components[1], "this%20needs%20percent%20encoded")
    }
    
    func test_setJSON_encodesDataInRequestBody() {
        let json = ["foo" : "bar", "paramName" : "paramValue", "numberValue" : 42]
        let session = RequestRecordingSession()
        let task = ServiceTask(request: Request(.POST, url: "/test"), session: session)
        
        task.setJSON(json)
        task.resume()
        
        let recordedURLRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedURLRequest)
        XCTAssertNotNil(recordedURLRequest!.HTTPBody)
        
        let bodyJSON = try? NSJSONSerialization.JSONObjectWithData(recordedURLRequest!.HTTPBody!, options: NSJSONReadingOptions())
        XCTAssertNotNil(json, "JSON should not be nil")
        
        // test original parameters against encoded
        if let bodyJSON = bodyJSON as? [String : AnyObject] {
            RequestTests.assertRequestParametersNotEqual(bodyJSON, toOriginalParameters: json)
        } else {
            XCTFail("Failed to cast JSON as [String : AnyObject]")
        }
    }
}

// MARK: - Obj-C Request API

extension WebServiceTests {
    func test_setPercentParameterEncodingObjC_encodesParametersAsPercent() {
        var request = Request(.POST, url: "/test_setPercentParameterEncodingObjC_")
        request.parameters = ["percentEncoded": "this needs percent encoded"]
        request.parameterEncoding = .JSON
        let session = RequestRecordingSession()
        let task = ServiceTask(request: request, session: session)
        
        task.setPercentParameterEncodingObjC()
        task.resume()
        
        let recordedURLRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedURLRequest)
        XCTAssertNotNil(recordedURLRequest?.HTTPBody)
        
        let encodedData = recordedURLRequest!.HTTPBody
        XCTAssertNotNil(encodedData)
        
        let stringValue = NSString(data: encodedData!, encoding: NSUTF8StringEncoding)!
        let components = stringValue.componentsSeparatedByString("=")
        XCTAssertEqual(components[0], "percentEncoded")
        XCTAssertEqual(components[1], "this%20needs%20percent%20encoded")
    }
    
    func test_setJSONParameterEncodingObjC_encodedParametersAsJSON() {
        var request = Request(.POST, url: "/test_setJSONParameterEncodingObjC_")
        request.parameters = ["percentEncoded": "this needs percent encoded"]
        request.parameterEncoding = .Percent
        let session = RequestRecordingSession()
        let task = ServiceTask(request: request, session: session)
        
        task.setJSONParameterEncodingObjC()
        task.resume()
        
        let recordedURLRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedURLRequest)
        XCTAssertNotNil(recordedURLRequest!.HTTPBody)
        
        let bodyJSON = try? NSJSONSerialization.JSONObjectWithData(recordedURLRequest!.HTTPBody!, options: NSJSONReadingOptions())
        XCTAssertNotNil(bodyJSON, "JSON should not be nil")
        
        // test original parameters against encoded
        if let bodyJSON = bodyJSON as? [String : AnyObject] {
            RequestTests.assertRequestParametersNotEqual(bodyJSON, toOriginalParameters: request.parameters)
        } else {
            XCTFail("Failed to cast JSON as [String : AnyObject]")
        }
    }
    
    func test_setPercentEncodedParametersObjC_encodesParametersAsPercent() {
        var request = Request(.POST, url: "/test_setPercentParameterEncodingObjC_")
        request.parameterEncoding = .JSON
        let parameters = ["percentEncoded": "this needs percent encoded"]
        let session = RequestRecordingSession()
        let task = ServiceTask(request: request, session: session)
        
        task.setPercentEncodedParametersObjC(parameters)
        task.resume()
        
        let recordedURLRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedURLRequest)
        XCTAssertNotNil(recordedURLRequest?.HTTPBody)
        
        let encodedData = recordedURLRequest!.HTTPBody
        XCTAssertNotNil(encodedData)
        
        let stringValue = NSString(data: encodedData!, encoding: NSUTF8StringEncoding)!
        let components = stringValue.componentsSeparatedByString("=")
        XCTAssertEqual(components[0], "percentEncoded")
        XCTAssertEqual(components[1], "this%20needs%20percent%20encoded")
    }
    
    func test_setJSONParameterEncodingObjC_encodesParametersAsJSON() {
        var request = Request(.POST, url: "/test_setJSONParameterEncodingObjC_")
        let parameters = ["percentEncoded": "this needs percent encoded"]
        request.parameterEncoding = .Percent
        let session = RequestRecordingSession()
        let task = ServiceTask(request: request, session: session)
        
        task.setJSONEncodedParametersObjC(parameters)
        task.resume()
        
        let recordedURLRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedURLRequest)
        XCTAssertNotNil(recordedURLRequest!.HTTPBody)
        
        let bodyJSON = try? NSJSONSerialization.JSONObjectWithData(recordedURLRequest!.HTTPBody!, options: NSJSONReadingOptions())
        XCTAssertNotNil(bodyJSON, "JSON should not be nil")
        
        // test original parameters against encoded
        if let bodyJSON = bodyJSON as? [String : AnyObject] {
            RequestTests.assertRequestParametersNotEqual(bodyJSON, toOriginalParameters: request.parameters)
        } else {
            XCTFail("Failed to cast JSON as [String : AnyObject]")
        }
    }
}

// MARK: - DataTask API

extension ServiceTaskTests {
    class NonRespondingSession: Session {
        func dataTask(request request: URLRequestEncodable, completion: (NSData?, NSURLResponse?, NSError?) -> Void) -> DataTask {
            return MockDataTask()
        }
    }
    
    func test_dataTask_entersCancelStateWhenCancelled() {
        let session = NonRespondingSession()
        let task = ServiceTask(request: Request(.GET, url: "/test"), session: session)
        task.resume()
        
        task.cancel()
        
        XCTAssertEqual(task.state, NSURLSessionTaskState.Canceling)
    }
    
    func test_dataTask_entersSuspendedStateWhenSuspended() {
        let session = NonRespondingSession()
        let task = ServiceTask(request: Request(.GET, url: "/test"), session: session)
        task.resume()
        
        task.suspend()
        
        XCTAssertEqual(task.state, NSURLSessionTaskState.Suspended)
    }
    
    func test_taskResult_returnsSuspendedStateWhenDataTaskIsNil() {
        let session = NonRespondingSession()
        let task = ServiceTask(request: Request(.GET, url: "/test"), session: session)
                
        XCTAssertEqual(task.state, NSURLSessionTaskState.Suspended)
    }
}
