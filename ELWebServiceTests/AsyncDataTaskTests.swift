//
//  AsyncDataTaskTests.swift
//  ELWebServiceTests
//
//  Created by Alex Johnson on 1/31/19.
//  Copyright © 2019 WalmartLabs. All rights reserved.
//

@testable import ELWebService
import XCTest

class AsyncDataTaskTests: XCTestCase {

    func test_successFlow() {
        var sendBody: ((AsyncDataResult) -> Void)?
        var result: AsyncDataResult?

        let task = AsyncDataTask({ sendBody = $0 }, completion: { result = $0 })

        XCTAssertEqual(task.state, .suspended)

        task.resume()

        XCTAssertEqual(task.state, .running)

        sendBody?(.success("Hello".data(using: .utf8)!))

        XCTAssertEqual(task.state, .completed)

        task.cancel()

        XCTAssertEqual(task.state, .completed)

        switch result {
        case .success(let data)?:
            XCTAssertEqual(data, "Hello".data(using: .utf8)!)
        case .failure(let error)?:
            XCTFail("Should not have received error: \(error)")
        case nil:
            XCTFail("Should have received result")
        }
    }

    func test_failureFlow() {
        var sendBody: ((AsyncDataResult) -> Void)?
        var result: AsyncDataResult?
        struct MockError: Error {}

        let task = AsyncDataTask({ sendBody = $0 }, completion: { result = $0 })

        XCTAssertEqual(task.state, .suspended)

        task.resume()

        XCTAssertEqual(task.state, .running)

        sendBody?(.failure(MockError()))

        XCTAssertEqual(task.state, .completed)

        switch result {
        case .success(let data)?:
            XCTFail("Should not have received data \(data)")
        case .failure(let error)?:
            XCTAssert(error is MockError, "Should not have received error: \(error)")
        case nil:
            XCTFail("Should have received result")
        }
    }

    func test_cancelFlow() {
        var result: AsyncDataResult?

        let task = AsyncDataTask({ _ = $0 }, completion: { result = $0 })

        XCTAssertEqual(task.state, .suspended)

        task.resume()

        XCTAssertEqual(task.state, .running)

        task.cancel()

        XCTAssertEqual(task.state, .completed)

        switch result {
        case .success(let data)?:
            XCTFail("Should not have received data \(data)")
        case .failure(let error)?:
            XCTAssertEqual((error as NSError).domain, NSURLErrorDomain)
            XCTAssertEqual((error as NSError).code, NSURLErrorCancelled)
        case nil:
            XCTFail("Should have received result")
        }
    }

    func test_cancelCompletesEvenWhenSuspended() {
        var result: AsyncDataResult?

        let task = AsyncDataTask({ _ = $0 }, completion: { result = $0 })

        XCTAssertEqual(task.state, .suspended)

        task.cancel()

        XCTAssertEqual(task.state, .completed)

        switch result {
        case .success(let data)?:
            XCTFail("Should not have received data \(data)")
        case .failure(let error)?:
            XCTAssertEqual((error as NSError).domain, NSURLErrorDomain)
            XCTAssertEqual((error as NSError).code, NSURLErrorCancelled)
        case nil:
            XCTFail("Should have received result")
        }
    }

    func test_stateCannotChangeAfterComplete() {
        var sendBody: ((AsyncDataResult) -> Void)?
        var result: AsyncDataResult?

        let task = AsyncDataTask({ sendBody = $0 }, completion: { result = $0 })

        XCTAssertEqual(task.state, .suspended)

        task.resume()

        XCTAssertEqual(task.state, .running)

        sendBody?(.success("Hello".data(using: .utf8)!))

        XCTAssertEqual(task.state, .completed)

        task.suspend()

        XCTAssertEqual(task.state, .completed)

        task.resume()

        XCTAssertEqual(task.state, .completed)

        task.cancel()

        XCTAssertEqual(task.state, .completed)

        switch result {
        case .success(let data)?:
            XCTAssertEqual(data, "Hello".data(using: .utf8)!)
        case .failure(let error)?:
            XCTFail("Should not have received error: \(error)")
        case nil:
            XCTFail("Should have received result")
        }
    }

    func test_suspendAndResume() {
        var sendBody: ((AsyncDataResult) -> Void)?
        var result: AsyncDataResult?

        let task = AsyncDataTask(
            {
                XCTAssertNil(sendBody, "block should only be called once")
                sendBody = $0
            },
            completion: {
                XCTAssertNil(result, "completion should only be called once")
                result = $0
            }
        )

        XCTAssertEqual(task.state, .suspended)

        task.resume()

        XCTAssertEqual(task.state, .running)

        task.suspend()

        XCTAssertEqual(task.state, .suspended)

        task.resume()

        XCTAssertEqual(task.state, .running)

        task.suspend()

        XCTAssertEqual(task.state, .suspended)

        sendBody?(.success("Hello".data(using: .utf8)!))

        XCTAssertEqual(task.state, .suspended, "Task should not complete while suspended")

        task.resume()

        XCTAssertEqual(task.state, .completed, "Task should complete once resumed")

        switch result {
        case .success(let data)?:
            XCTAssertEqual(data, "Hello".data(using: .utf8)!)
        case .failure(let error)?:
            XCTAssert(error is MockError, "Should not have received error: \(error)")
        case nil:
            XCTFail("Should have received result")
        }
    }
}
