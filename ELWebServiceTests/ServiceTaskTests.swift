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
        let expectation = self.expectation(description: "updateUI handler is called")
        let task = successfulTask()
        
        task.response { data, response in
                return .empty
            }
            .updateUI { value in
                XCTAssertTrue(Thread.isMainThread)
                expectation.fulfill()
            }
            .resume()
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test_updateUI_isNotCalledWhenResponseHandlerReturnsFailure() {
        enum ResponseError: Error {
            case iveMadeAHugeMistake
        }
        
        let expectation = self.expectation(description: "responseError handler is called")
        let task = successfulTask()
        
        task
            .response { data, response in
                return .failure(ResponseError.iveMadeAHugeMistake)
            }
            .updateUI { value in
                XCTFail("updateUI handler should not be called")
            }
            .responseError { error in
                expectation.fulfill()
            }
            .resume()
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test_updateUI_receivesResponseHandlerValue() {
        let expectation = self.expectation(description: "updateUI handler is called")
        let task = successfulTask()

        task.response { data, response in
                return ServiceTaskResult.value(true)
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
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test_response_runsOnBackgroundThread() {
        let expectation = self.expectation(description: "response handler is called")
        let task = successfulTask()
        
        task.response { data, response in
                XCTAssertTrue(!Thread.isMainThread)
                expectation.fulfill()
   
                return .empty
            }
            .resume()
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test_updateUI_blocksHandlerChainExecution() {
        let expectation = self.expectation(description: "response handler is called")
        var updateUIExecuted = false
        
        successfulTask()
            .response { _, _ in
                return .value(true)
            }
            .updateUI { _ in
                sleep(1)
                updateUIExecuted = true
            }
            .response { _, _ in
                XCTAssertTrue(updateUIExecuted, "Expected updateUI handler to block and complete execution before response handler is executed")
                expectation.fulfill()
                return .empty
            }
            .resume()
        
        waitForExpectations(timeout: 2, handler: nil)
    }
}

// MARK: - JSON

extension ServiceTaskTests {
    func test_responseJSON_handlerIsCalledWhenJSONIsValid() {
        let expectation = self.expectation(description: "JSON response handler is called")
        let session = MockSession()
        
        session.addStub(MockResponse(statusCode: 200, json: ["foo": "bar"]))
        let task = ServiceTask(request: Request(.GET, url: "/json"), session: session)
        
        task.responseJSON { json, _  in
                expectation.fulfill()
                return .empty
            }
            .resume()
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test_responseJSON_errorHandlerIsCalledWhenJSONIsInvalid() {
        let expectation = self.expectation(description: "Error handler is called")
        let session = MockSession()
        
        let badJSONData = NSString(string: "{}couldneverbeJSON-[][[42").data(using: String.Encoding.utf8.rawValue)
        let response = MockResponse(statusCode: 204, data: badJSONData!)
        session.addStub(response)
        
        let task = ServiceTask(request: Request(.GET, url: "/json"), session: session)
        
        task.responseJSON { json, _  in
                XCTFail("responseJSON handler should not be called when JSON is invalid")
                return .empty
            }
            .responseError { error in
                expectation.fulfill()
            }
            .resume()
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test_responseJSON_errorHandlerIsCalledWhenJSONIsNil() {
        let expectation = self.expectation(description: "Error handler is called")
        let session = MockSession()
        session.addStub(MockResponse(statusCode: 204))
        let task = ServiceTask(request: Request(.GET, url: "/json"), session: session)
        
        task.responseJSON { json, _  in
                XCTFail("responseJSON handler should not be called when JSON is invalid")
                return .empty
            }
            .responseError { error in
                expectation.fulfill()
            }
            .resume()
        
        waitForExpectations(timeout: 2, handler: nil)
    }
}

// MARK: - Errors

extension ServiceTaskTests {
    // MARK: Stub
    
    func errorTask() -> ServiceTask {
        enum TaskTestError: Error {
            case requestFailed
        }
        
        let session = MockSession()
        session.addStub(TaskTestError.requestFailed as NSError)
        
        return ServiceTask(request: Request(.GET, url: "/error"), session: session)
    }
    
    // MARK: Tests
    
    func test_responseError_handlerCalledWhenSessionReturnsError() {
        let expectation = self.expectation(description: "Error handler called when session returns an error")
        let task = errorTask()
        
        task.responseError { error in
                expectation.fulfill()
            }
            .resume()
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test_responseError_responseHandlerIsNotCalled() {
        let expectation = self.expectation(description: "Error handler called when session returns an error")
        let task = errorTask()
        
        task.response { data, response in
                XCTFail("Response handler should not be called when session returns an error")
                return .empty
            }
            .responseError { error in
                expectation.fulfill()
            }
            .resume()
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test_responseError_runsOnBackgroundThread() {
        let expectation = self.expectation(description: "Error handler called when session returns an error")
        let task = errorTask()
        
        task.responseError { error in
                XCTAssertTrue(!Thread.isMainThread)
                expectation.fulfill()
            }
            .resume()
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test_responseError_calledWhenResposneHandlerReturnsFailure() {
        enum ResponseError: Error {
            case stubError
        }
        let expectation = self.expectation(description: "Error handler called when session returns an error")
        let task = successfulTask()
        
        task
            .response { data, response in
                return .failure(ResponseError.stubError)
            }
            .response { data, response in
                XCTFail("response handler should not be called")
                return .empty
            }
            .responseError { error in
                expectation.fulfill()
            }
            .resume()
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test_responseError_isNotCalledWhenReturningResultsInResponseHandlers() {
        let expectation = self.expectation(description: "response handler is called")
        let session = MockSession()
        session.addStub(MockResponse(statusCode: 200))
        
        let task = ServiceTask(request: Request(.GET, url: "/status/200"), session: session)
        
        task
            .response { data, response in
                return .empty
            }
            .response { data, response in
                return .value(1)
            }
            .responseError { error in
                XCTFail("responseError should not be called")
            }
            .response { data, response in
                expectation.fulfill()
                return .empty
            }
            .resume()
        
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func test_updateErrorUI_isNotCalledWhenReturningResultsInResponseHandlers() {
        let expectation = self.expectation(description: "response handler is called")
        let session = MockSession()
        session.addStub(MockResponse(statusCode: 200))
        
        let task = ServiceTask(request: Request(.GET, url: "/status/200"), session: session)
        
        task
            .response { data, response in
                return .empty
            }
            .response { data, response in
                return .value(1)
            }
            .updateErrorUI { error in
                XCTFail("updateErrorUI should not be called")
            }
            .response { data, response in
                expectation.fulfill()
                return .empty
            }
            .resume()
        
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func test_updateErrorUI_handlerCalledWhenSessionReturnsError() {
        let expectation = self.expectation(description: "Error handler called when session returns an error")
        let task = errorTask()
        
        task.updateErrorUI { error in
                expectation.fulfill()
            }
            .resume()
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test_updateErrorUI_runsOnMainThread() {
        let expectation = self.expectation(description: "Error handler called when session returns an error")
        let task = errorTask()
        
        task.updateErrorUI { error in
                XCTAssertTrue(Thread.isMainThread, "updateErrorUI handler should be running on the main thread")
                expectation.fulfill()
            }
            .resume()
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test_updateErrorUI_blocksHandlerChainExecution() {
        let expectation = self.expectation(description: "response handler is called")
        var updateErrorUIExecuted = false
        
        errorTask()
            .updateErrorUI { _ in
                sleep(1)
                updateErrorUIExecuted = true
            }
            .responseError { _ in
                XCTAssertTrue(updateErrorUIExecuted, "Expected updateErrorUI handler to block and complete execution before response handler is executed")
                expectation.fulfill()
            }
            .resume()
        
        waitForExpectations(timeout: 2, handler: nil)
    }
}

// MARK: - Transform

extension ServiceTaskTests {
    func test_transform_closureNotCalledIfAddedBeforeResponseHandler() {
        let done = expectation(description: "done")

        successfulTask()
            .transform { _ in
                XCTFail("Did not expect transform closure to be called")
                return .empty
            }
            .response { _, _ in
                done.fulfill()
                return .empty
            }
            .resume()

        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test_transform_closureCalled() {
        let closureCalled = expectation(description: "transform closure called")

        successfulTask()
            .response { _, _ in
                return .empty
            }
            .transform { _ in
                closureCalled.fulfill()
                return .empty
            }
            .resume()

        waitForExpectations(timeout: 2, handler: nil)
    }

    func test_transform_closureNotCalledForError() {
        let done = expectation(description: "done")

        errorTask()
            .response { _, _ in
                return .empty
            }
            .transform { _ in
                XCTFail("Did not expect transform closure to be called")
                return .empty
            }
            .updateErrorUI { _ in
                done.fulfill()
            }
            .resume()

        waitForExpectations(timeout: 2, handler: nil)
    }

    func test_transform_ordering() {
        let closure1Called = expectation(description: "transform closure 1 called")
        let closure2Called = expectation(description: "transform closure 2 called")
        var closure1CalledFirst = false

        successfulTask()
            .response { _, _ in
                return .empty
            }
            .transform { _ in
                closure1CalledFirst = true
                closure1Called.fulfill()
                return .empty
            }
            .transform { _ in
                XCTAssertTrue(closure1CalledFirst, "Expected closure 1 to be called before closure 2")
                closure2Called.fulfill()
                return .empty
            }
            .resume()

        waitForExpectations(timeout: 2, handler: nil)
    }

    func test_transform_resultPropagation() {
        let closure1Called = expectation(description: "transform closure 1 called")
        let closure2Called = expectation(description: "transform closure 2 called")
        let closure3Called = expectation(description: "transform closure 3 called")
        let done = expectation(description: "done")

        successfulTask()
            .response { _, _ in
                return .value("response value")
            }
            .transform { value in
                if let value = value as? String {
                    XCTAssertEqual(value, "response value", "Expected to receive result of response handler")
                } else {
                    XCTFail("Expected to receive result of previous handler")
                }

                closure1Called.fulfill()
                return .value("transform 1 value")
            }
            .transform { value in
                if let value = value as? String {
                    XCTAssertEqual(value, "transform 1 value", "Expected to receive result of previous handler")
                } else {
                    XCTFail("Expected to receive result of previous handler")
                }

                closure2Called.fulfill()
                return .empty
            }
            .transform { value in
                XCTAssertNil(value, "Expected .Empty result to propagate as nil")

                closure3Called.fulfill()
                return .value("transform 3 value")
            }
            .updateUI { value in
                if let value = value as? String {
                    XCTAssertEqual(value, "transform 3 value", "Expected to receive result of previous handler")
                } else {
                    XCTFail("Expected to receive result of previous handler")
                }

                done.fulfill()
            }
            .resume()

        waitForExpectations(timeout: 2, handler: nil)
    }
}

// MARK: - Recover

extension ServiceTaskTests {
    func test_recover_closureCalled() {
        let closureCalled = expectation(description: "closure called")

        errorTask()
            .recover { error in
                closureCalled.fulfill()
                return .failure(error)
            }
            .resume()

        waitForExpectations(timeout: 2, handler: nil)
    }

    func test_recover_closureNotCalledForSuccess() {
        let done = expectation(description: "done")

        successfulTask()
            .response { _, _ in
                return .empty
            }
            .recover { error in
                XCTFail("Did not expect recover closure to be called")
                return .failure(error)
            }
            .updateUI { _ in
                done.fulfill()
            }
            .resume()

        waitForExpectations(timeout: 2, handler: nil)
    }

    func test_recover_ordering() {
        let closure1Called = expectation(description: "recover closure 1 callled")
        let closure2Called = expectation(description: "recover closure 2 callled")
        var closure1CalledFirst = false

        errorTask()
            .recover { error in
                closure1CalledFirst = true
                closure1Called.fulfill()
                return .failure(error)
            }
            .recover { error in
                XCTAssertTrue(closure1CalledFirst, "Expected closure 1 to be called before closure 2")
                closure2Called.fulfill()
                return .failure(error)
            }
            .resume()

        waitForExpectations(timeout: 2, handler: nil)
    }

    func test_recover_resultPropagation() {
        let closure1Called = expectation(description: "recover closure 1 callled")
        let closure2Called = expectation(description: "recover closure 2 callled")
        let closure3Called = expectation(description: "recover closure 3 callled")
        let done = expectation(description: "done")

        enum ServiceTaskTestError: Error {
            case oops(detail: String)
        }

        errorTask()
            .recover { error in
                closure1Called.fulfill()
                return .failure(error)
            }
            .recover { error in
                closure2Called.fulfill()
                return .failure(ServiceTaskTestError.oops(detail: "closure 2 error"))
            }
            .recover { error in
                if let error = error as? ServiceTaskTestError {
                    switch error {
                    case .oops(let detail):
                        XCTAssertEqual(detail, "closure 2 error", "Expected to receive result of previous handler")
                    }
                } else {
                    XCTFail("Expected to receive result of previous handler")
                }

                closure3Called.fulfill()
                return .failure(ServiceTaskTestError.oops(detail: "closure 3 error"))
            }
            .updateErrorUI { error in
                if let error = error as? ServiceTaskTestError {
                    switch error {
                    case .oops(let detail):
                        XCTAssertEqual(detail, "closure 3 error", "Expected to receive result of previous handler")
                    }
                } else {
                    XCTFail("Expected to receive result of previous handler")
                }

                done.fulfill()
            }
            .resume()
        
        waitForExpectations(timeout: 2, handler: nil)
    }
}

// MARK: - Transform and Recover Control Flow

extension ServiceTaskTests {
    func test_transformAndRecover_controlFlow() {
        let closure1Called = expectation(description: "recover closure 1 callled")
        let closure3Called = expectation(description: "recover closure 3 callled")
        let done = expectation(description: "done")

        enum ServiceTaskTestError: Error {
            case oops
        }

        successfulTask()
            .response { _, _ in
                return .empty
            }
            .transform { _ in
                closure1Called.fulfill()
                return .failure(ServiceTaskTestError.oops)
            }
            .transform { _ in
                XCTFail("Did not expect transform closure to be called after failure")
                return .empty
            }
            .recover { _ in
                closure3Called.fulfill()
                return .value("closure 3 value")
            }
            .recover { error in
                XCTFail("Did not expect recover closure to be called after recovery")
                return .failure(error)
            }
            .updateErrorUI { _ in
                XCTFail("Did not expect update UI (error) closure to be called after recovery")
            }
            .updateUI { _ in
                done.fulfill()
            }
            .resume()

        waitForExpectations(timeout: 2, handler: nil)
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
        
        ELTestAssertRequestParametersEqual(deliveredHeaders, request.headers)
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
        let bodyData = Data()
        let request = Request(.GET, url: "/test_setBody_encodesDataInURLRequest")
        let session = RequestRecordingSession()
        let task = ServiceTask(request: request, session: session)
        
        task.setBody(bodyData)
        task.resume()
        
        let recordedURLRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedURLRequest)
        XCTAssertEqual(recordedURLRequest!.httpBody, bodyData)
        
    }

    // setBodyContentType

    func test_setBodyContentType_setsHTTPBodyAndContentTypeHaderInURLRequest() {
        let bodyData = Data()
        let contentType = "image/png"
        let request = Request(.GET, url: "/test_setBodyContentType_setsHTTPBodyAndContentTypeHaderInURLRequest")
        let session = RequestRecordingSession()
        let task = ServiceTask(request: request, session: session)

        task.setBody(bodyData, contentType: contentType)
        task.resume()

        let recordedURLRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedURLRequest)
        XCTAssertEqual(recordedURLRequest!.httpBody, bodyData)
        XCTAssertEqual(recordedURLRequest?.allHTTPHeaderFields?[Request.Headers.contentType], contentType)
    }


    func test_setCachePolicy_setsPolicyInURLRequest() {
        let request = Request(.GET, url: "/test_setBody_encodesDataInURLRequest")
        let session = RequestRecordingSession()
        let task = ServiceTask(request: request, session: session)
        
        task.setCachePolicy(.reloadIgnoringLocalCacheData)
        task.resume()
        
        let recordedURLRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedURLRequest)
        XCTAssertEqual(recordedURLRequest!.cachePolicy, NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData)
    }

    // setJSON
    
    func test_setParametersEncoding_setsParameterEncodingInRequest() {
        var request = Request(.POST, url: "/test_setParametersEncoding_setsParameterEncodingInRequest")
        request.parameters = ["foo": "bar"]
        let session = RequestRecordingSession()
        let task = ServiceTask(request: request, session: session)
        
        task.setParameterEncoding(.json)
        task.resume()
        
        let recordedURLRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedURLRequest)
        XCTAssertNotNil(recordedURLRequest?.httpBody)
    }

    // setJSONData

    func test_setBodyAndContentType_setsBodyAndContentTypeHeaderInRequest() {
        let request = Request(.POST, url: "/test_setBodyAndContentType_setsBodyAndContentTypeHeaderInRequest")
        let contentType = "image/jpg"
        let bodyData = Data()
        let session = RequestRecordingSession()
        let task = ServiceTask(request: request, session: session)

        task.setBody(bodyData, contentType: contentType)
        task.resume()

        let recordedURLRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedURLRequest)
        XCTAssertEqual(recordedURLRequest!.httpBody, bodyData)
        XCTAssertEqual(recordedURLRequest?.allHTTPHeaderFields?[Request.Headers.contentType], contentType)
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
        XCTAssertNotNil(recordedURLRequest?.url)

        let components = URLComponents(url: recordedURLRequest!.url!, resolvingAgainstBaseURL: false)!
        
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
        XCTAssertNotNil(recordedURLRequest?.url)
        
        let encodedData = recordedURLRequest!.httpBody
        XCTAssertNotNil(encodedData)
        
        let stringValue = NSString(data: encodedData!, encoding: String.Encoding.utf8.rawValue)!
        let components = stringValue.components(separatedBy: "=")
        XCTAssertEqual(components[0], "percentEncoded")
        XCTAssertEqual(components[1], "this%20needs%20percent%20encoded")
    }
    
    func test_setJSON_encodesDataInRequestBody() {
        let json: [String : Any] = ["foo" : "bar", "paramName" : "paramValue", "numberValue" : 42]
        let session = RequestRecordingSession()
        let task = ServiceTask(request: Request(.POST, url: "/test"), session: session)
        
        task.setJSON(json)
        task.resume()
        
        let recordedURLRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedURLRequest)
        XCTAssertNotNil(recordedURLRequest!.httpBody)
        
        let bodyJSON = try? JSONSerialization.jsonObject(with: recordedURLRequest!.httpBody!, options: JSONSerialization.ReadingOptions())
        XCTAssertNotNil(json, "JSON should not be nil")
        
        // test original parameters against encoded
        if let bodyJSON = bodyJSON as? [String : AnyObject] {
            ELTestAssertRequestParametersEqual(bodyJSON, json)
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
        request.parameterEncoding = .json
        let session = RequestRecordingSession()
        let task = ServiceTask(request: request, session: session)
        
        task.setPercentParameterEncodingObjC()
        task.resume()
        
        let recordedURLRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedURLRequest)
        XCTAssertNotNil(recordedURLRequest?.httpBody)
        
        let encodedData = recordedURLRequest!.httpBody
        XCTAssertNotNil(encodedData)
        
        let stringValue = NSString(data: encodedData!, encoding: String.Encoding.utf8.rawValue)!
        let components = stringValue.components(separatedBy: "=")
        XCTAssertEqual(components[0], "percentEncoded")
        XCTAssertEqual(components[1], "this%20needs%20percent%20encoded")
    }
    
    func test_setJSONParameterEncodingObjC_encodedParametersAsJSON() {
        var request = Request(.POST, url: "/test_setJSONParameterEncodingObjC_")
        request.parameters = ["percentEncoded": "this needs percent encoded"]
        request.parameterEncoding = .percent
        let session = RequestRecordingSession()
        let task = ServiceTask(request: request, session: session)
        
        task.setJSONParameterEncodingObjC()
        task.resume()
        
        let recordedURLRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedURLRequest)
        XCTAssertNotNil(recordedURLRequest!.httpBody)
        
        let bodyJSON = try? JSONSerialization.jsonObject(with: recordedURLRequest!.httpBody!, options: JSONSerialization.ReadingOptions())
        XCTAssertNotNil(bodyJSON, "JSON should not be nil")
        
        // test original parameters against encoded
        if let bodyJSON = bodyJSON as? [String : AnyObject] {
            ELTestAssertRequestParametersEqual(bodyJSON, request.parameters)
        } else {
            XCTFail("Failed to cast JSON as [String : AnyObject]")
        }
    }
    
    func test_setPercentEncodedParametersObjC_encodesParametersAsPercent() {
        var request = Request(.POST, url: "/test_setPercentParameterEncodingObjC_")
        request.parameterEncoding = .json
        let parameters = ["percentEncoded": "this needs percent encoded"]
        let session = RequestRecordingSession()
        let task = ServiceTask(request: request, session: session)
        
        task.setPercentEncodedParametersObjC(parameters)
        task.resume()
        
        let recordedURLRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedURLRequest)
        XCTAssertNotNil(recordedURLRequest?.httpBody)
        
        let encodedData = recordedURLRequest!.httpBody
        XCTAssertNotNil(encodedData)
        
        let stringValue = NSString(data: encodedData!, encoding: String.Encoding.utf8.rawValue)!
        let components = stringValue.components(separatedBy: "=")
        XCTAssertEqual(components[0], "percentEncoded")
        XCTAssertEqual(components[1], "this%20needs%20percent%20encoded")
    }
    
    func test_setJSONParameterEncodingObjC_encodesParametersAsJSON() {
        var request = Request(.POST, url: "/test_setJSONParameterEncodingObjC_")
        let parameters = ["percentEncoded": "this needs percent encoded"]
        request.parameterEncoding = .percent
        let session = RequestRecordingSession()
        let task = ServiceTask(request: request, session: session)
        
        task.setJSONEncodedParametersObjC(parameters)
        task.resume()
        
        let recordedURLRequest = session.recordedRequests.first?.urlRequestValue
        XCTAssertNotNil(recordedURLRequest)
        XCTAssertNotNil(recordedURLRequest!.httpBody)
        
        let bodyJSON = try? JSONSerialization.jsonObject(with: recordedURLRequest!.httpBody!, options: JSONSerialization.ReadingOptions())
        XCTAssertNotNil(bodyJSON, "JSON should not be nil")
        
        if let bodyJSON = bodyJSON as? [String : AnyObject] {
            // test original parameters against encoded
            ELTestAssertRequestParametersEqual(bodyJSON, request.parameters)
        } else {
            XCTFail("Failed to cast JSON as [String : AnyObject]")
        }
    }
}

// MARK: - DataTask API

extension ServiceTaskTests {
    class NonRespondingSession: Session {
        func dataTask(request: URLRequestEncodable, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> DataTask {
            return MockDataTask()
        }
    }
    
    func test_dataTask_entersCancelStateWhenCancelled() {
        let session = NonRespondingSession()
        let task = ServiceTask(request: Request(.GET, url: "/test"), session: session)
        task.resume()
        
        task.cancel()
        
        XCTAssertEqual(task.state, URLSessionTask.State.canceling)
    }
    
    func test_dataTask_entersSuspendedStateWhenSuspended() {
        let session = NonRespondingSession()
        let task = ServiceTask(request: Request(.GET, url: "/test"), session: session)
        task.resume()
        
        task.suspend()
        
        XCTAssertEqual(task.state, URLSessionTask.State.suspended)
    }
    
    func test_taskResult_returnsSuspendedStateWhenDataTaskIsNil() {
        let session = NonRespondingSession()
        let task = ServiceTask(request: Request(.GET, url: "/test"), session: session)
                
        XCTAssertEqual(task.state, URLSessionTask.State.suspended)
    }
}
